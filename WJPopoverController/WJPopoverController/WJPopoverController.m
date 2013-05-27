//
//  WJPopoverController.m
//
//  Copyright (c) 2013 Wouldja Software. All rights reserved.
//

#import "WJPopoverController.h"
#import "WJPopoverBackgroundView.h"

UIKIT_STATIC_INLINE CGRect UIEdgeInsetsOutsetRect(CGRect rect, UIEdgeInsets insets) {
    rect.origin.x    -= insets.left;
    rect.origin.y    -= insets.top;
    rect.size.width  += (insets.left + insets.right);
    rect.size.height += (insets.top  + insets.bottom);
    return rect;
}

CG_INLINE CGFloat CGRectGetArea(CGRect r)
{
	return r.size.width * r.size.height;
}

#pragma mark -

@interface WJPopoverDimmerView : UIView
@property (nonatomic, weak) WJPopoverController *popover;
@property (nonatomic, weak) UIView *anchorView;
@property (nonatomic) CGRect anchorRect;
@property (nonatomic, readonly) CGRect layoutRect;
@property (nonatomic, readonly) CGRect localAnchorRect;
@property (nonatomic) UIPopoverArrowDirection permittedArrowDirections;
@property (nonatomic, readonly) UIEdgeInsets contentViewInsets;
@property (nonatomic, readonly) CGFloat arrowHeight;
@property (nonatomic, readonly) WJPopoverBackgroundView *backgroundView;
@end

@interface WJPopoverController ()
@property (nonatomic, strong) id retainLock;
@property (nonatomic, strong) WJPopoverDimmerView *dimmer;
@end

#pragma mark -

@implementation WJPopoverController

- (id)initWithContentViewController:(UIViewController *)viewController
{
	if ((self = [super init])) {
		self.contentViewController = viewController;
		self.popoverLayoutMargins = UIEdgeInsetsMake(10, 10, 10, 10);
		self.extraVerticalOffset = 0;
	}
	return self;
}

- (void)presentPopoverFromRect:(CGRect)rect
						inView:(UIView *)view
	  permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
					  animated:(BOOL)animated
{
	NSAssert(self.retainLock == nil, @"Popover is already displayed");
	
	self.retainLock = self;
	
	self.dimmer = [[WJPopoverDimmerView alloc] initWithFrame:CGRectZero];
	self.dimmer.translatesAutoresizingMaskIntoConstraints = NO;
	self.dimmer.popover = self;
	
	[view.window addSubview:self.dimmer];
	NSDictionary *views = @{@"dimmer": self.dimmer};
	[view.window addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[dimmer]|" options:0 metrics:nil views:views]];
	[view.window addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[dimmer]|" options:0 metrics:nil views:views]];
	
	Class backgroundViewClass = self.popoverBackgroundViewClass;
	if (!backgroundViewClass)
		backgroundViewClass = [WJPopoverBackgroundView class];
	NSAssert([backgroundViewClass isSubclassOfClass:[WJPopoverBackgroundView class]], @"backgroundViewClass must be a subclass of WJPopoverBackgroundView");
	WJPopoverBackgroundView *backgroundView = [[backgroundViewClass alloc] initWithFrame:CGRectZero];
	backgroundView.arrowDirection = UIPopoverArrowDirectionUnknown;
	[self.dimmer addSubview:backgroundView];

	UIView *contentView = self.contentViewController.view; // This forces viewDidLoad to be called.
	[self.contentViewController beginAppearanceTransition:YES animated:animated];
	[self.dimmer addSubview:contentView];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(screenWillRotate:)
												 name:UIApplicationWillChangeStatusBarOrientationNotification
											   object:nil];
	
	self.dimmer.alpha = 0;
	self.dimmer.anchorRect = rect;
	self.dimmer.anchorView = view;
	self.dimmer.permittedArrowDirections = arrowDirections;
	[self updateToOrientation:[UIApplication sharedApplication].statusBarOrientation];
	[self addObserver:self forKeyPath:@"contentViewController.contentSizeForViewInPopover" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"extraVerticalOffset" options:0 context:NULL];
	[self addObserver:self forKeyPath:@"extraHorizontalOffset" options:0 context:NULL];
	[self.dimmer layoutIfNeeded];
	[UIView animateWithDuration:animated ? 0.1 : 0
					 animations:^{
						 self.dimmer.alpha = 1;
					 }
					 completion:^(BOOL finished) {
						 [self.contentViewController endAppearanceTransition];
					 }];
}

- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item
			   permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections
							   animated:(BOOL)animated
{
	// When presenting from a bar button item, limit arrow directions to up or down:
	arrowDirections &= UIPopoverArrowDirectionUp | UIPopoverArrowDirectionDown;

	// Attempt to determine the view of the toolbar item:
	UIView *view = item.customView;
	if (!view && [item respondsToSelector:@selector(view)])
		view = [item performSelector:@selector(view)];
	NSAssert(view != nil, @"Could not identify view for UIBarButtonItem");

	[self presentPopoverFromRect:view.bounds
						  inView:view
		permittedArrowDirections:arrowDirections
						animated:animated];
}

- (void)dismissPopoverAnimated:(BOOL)animated
{
	[self dismissPopoverAnimated:animated completion:nil];
}

- (void)dismissPopoverAnimated:(BOOL)animated completion:(void(^)(BOOL finished))completion
{
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:UIApplicationWillChangeStatusBarOrientationNotification
												  object:nil];
	[self removeObserver:self forKeyPath:@"contentViewController.contentSizeForViewInPopover"];
	[self removeObserver:self forKeyPath:@"extraVerticalOffset"];
	[self removeObserver:self forKeyPath:@"extraHorizontalOffset"];
	[self.contentViewController beginAppearanceTransition:NO animated:animated];
	[UIView animateWithDuration:animated ? 0.2 : 0
					 animations:^{
						 self.dimmer.alpha = 0;
					 }
					 completion:^(BOOL finished) {
						 [self.contentViewController.view removeFromSuperview];
						 [self.contentViewController endAppearanceTransition];
						 [self.dimmer removeFromSuperview];
						 if (completion)
							 completion(finished);
						 self.retainLock = nil;
					 }];
}

#pragma mark Internals

- (void)animateLayout
{
	[self.dimmer setNeedsLayout];
	[UIView animateWithDuration:0.2
					 animations:^{
						 [self.dimmer layoutIfNeeded];
					 }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([@"contentViewController.contentSizeForViewInPopover" isEqualToString:keyPath] ||
		[@"extraVerticalOffset" isEqualToString:keyPath] ||
		[@"extraHorizontalOffset" isEqualToString:keyPath]) {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(animateLayout) object:nil];
		[self performSelector:@selector(animateLayout) withObject:nil afterDelay:0];
	}
}

- (void)updateToOrientation:(UIInterfaceOrientation)orientation
{
	CGAffineTransform rotation;
	
	switch (orientation) {
		case UIInterfaceOrientationPortraitUpsideDown:
			rotation = CGAffineTransformMakeRotation(M_PI);
			break;
		case UIInterfaceOrientationLandscapeLeft:
			rotation = CGAffineTransformMakeRotation(-M_PI_2);
			break;
		case UIInterfaceOrientationLandscapeRight:
			rotation = CGAffineTransformMakeRotation(M_PI_2);
			break;
		default:
			rotation = CGAffineTransformIdentity;
			break;
	}

	self.dimmer.transform = rotation;
}

- (void)screenWillRotate:(NSNotification *)note
{
	[self updateToOrientation:[note.userInfo[UIApplicationStatusBarOrientationUserInfoKey] intValue]];
}

- (void)dismissPopoverUsingDelegate
{
	BOOL shouldDismiss = YES;

	if ([self.delegate respondsToSelector:@selector(popoverControllerShouldDismissPopover:)])
		shouldDismiss = [self.delegate popoverControllerShouldDismissPopover:self];

	if (shouldDismiss) {
		[self dismissPopoverAnimated:YES
						  completion:^(BOOL finished) {
							  if ([self.delegate respondsToSelector:@selector(popoverControllerDidDismissPopover:)])
								  [self.delegate popoverControllerDidDismissPopover:self];
						  }];
	}
}

@end

#pragma mark -

@implementation WJPopoverDimmerView

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.opaque = NO;
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	[self.popover dismissPopoverUsingDelegate];
}

- (CGFloat)arrowHeight
{
	return [[self.backgroundView class] arrowHeight];
}

- (UIEdgeInsets)contentViewInsets
{
	return [[self.backgroundView class] contentViewInsets];
}

- (CGRect)localAnchorRect
{
	return [self convertRect:self.anchorRect fromView:self.anchorView];
}

- (CGRect)frameBelowOffset:(CGFloat *)outOffset
{
	CGRect bounds = self.layoutRect;
	CGRect anchor = self.localAnchorRect;
	bounds.size.height = CGRectGetMaxY(bounds) - CGRectGetMaxY(anchor);
	bounds.origin.y = CGRectGetMaxY(anchor);
	bounds = UIEdgeInsetsInsetRect(bounds, self.contentViewInsets);
	bounds.origin.y += self.arrowHeight;
	bounds.size.height -= self.arrowHeight;

	CGRect frame = CGRectZero;
	CGFloat offset = 0;
	frame.size = self.popover.contentViewController.contentSizeForViewInPopover;
	frame.size.height = MIN(CGRectGetHeight(frame), CGRectGetHeight(bounds));
	frame.size.width = MIN(CGRectGetWidth(frame), CGRectGetWidth(bounds));
	frame.origin.x = floorf(CGRectGetMidX(anchor) - CGRectGetWidth(frame) / 2) - self.popover.extraHorizontalOffset;
	frame.origin.y = CGRectGetMinY(bounds);

	if (CGRectGetMaxX(frame) > CGRectGetMaxX(bounds))
		offset = CGRectGetMaxX(frame) - CGRectGetMaxX(bounds);
	else if (CGRectGetMinX(frame) < CGRectGetMinX(bounds))
		offset = CGRectGetMinX(frame) - CGRectGetMinX(bounds);

	frame.origin.x -= offset;
	offset += self.popover.extraHorizontalOffset;

	if (outOffset)
		*outOffset = offset;
	return frame;
}

- (CGRect)frameAboveOffset:(CGFloat *)outOffset
{
	CGRect bounds = self.layoutRect;
	CGRect anchor = self.localAnchorRect;
	bounds.size.height = CGRectGetMinY(anchor) - CGRectGetMinY(bounds);
	bounds = UIEdgeInsetsInsetRect(bounds, self.contentViewInsets);
	bounds.size.height -= self.arrowHeight;

	CGRect frame = CGRectZero;
	CGFloat offset = 0;
	frame.size = self.popover.contentViewController.contentSizeForViewInPopover;
	frame.size.width = MIN(CGRectGetWidth(frame), CGRectGetWidth(bounds));
	frame.size.height = MIN(CGRectGetHeight(frame), CGRectGetHeight(bounds));
	frame.origin.x = floorf(CGRectGetMidX(anchor) - CGRectGetWidth(frame) / 2) - self.popover.extraHorizontalOffset;
	frame.origin.y = CGRectGetMaxY(bounds) - CGRectGetHeight(frame);

	if (CGRectGetMaxX(frame) > CGRectGetMaxX(bounds))
		offset = CGRectGetMaxX(frame) - CGRectGetMaxX(bounds);
	else if (CGRectGetMinX(frame) < CGRectGetMinX(bounds))
		offset = CGRectGetMinX(frame) - CGRectGetMinX(bounds);

	frame.origin.x -= offset;
	offset += self.popover.extraHorizontalOffset;

	if (outOffset)
		*outOffset = offset;
	return frame;
}

- (CGRect)frameToLeftOffset:(CGFloat *)outOffset
{
	CGRect bounds = self.layoutRect;
	CGRect anchor = self.localAnchorRect;
	bounds.size.width = CGRectGetMinX(anchor) - CGRectGetMinX(bounds);
	bounds = UIEdgeInsetsInsetRect(bounds, self.contentViewInsets);
	bounds.size.width -= self.arrowHeight;

	CGRect frame = CGRectZero;
	CGFloat offset = 0;
	frame.size = self.popover.contentViewController.contentSizeForViewInPopover;
	frame.size.width = MIN(CGRectGetWidth(frame), CGRectGetWidth(bounds));
	frame.size.height = MIN(CGRectGetHeight(frame), CGRectGetHeight(bounds));
	frame.origin.x = CGRectGetMaxX(bounds) - CGRectGetWidth(frame);
	frame.origin.y = floorf(CGRectGetMidY(anchor) - CGRectGetHeight(frame) / 2) - self.popover.extraVerticalOffset;

	if (CGRectGetMaxY(frame) > CGRectGetMaxY(bounds))
		offset = CGRectGetMaxY(frame) - CGRectGetMaxY(bounds);
	else if (CGRectGetMinY(frame) < CGRectGetMinY(bounds))
		offset = CGRectGetMinY(frame) - CGRectGetMinY(bounds);
	
	frame.origin.y -= offset;
	offset += self.popover.extraVerticalOffset;
	
	if (outOffset)
		*outOffset = offset;
	return frame;
}

- (CGRect)frameToRightOffset:(CGFloat *)outOffset
{
	CGRect bounds = self.layoutRect;
	CGRect anchor = self.localAnchorRect;
	bounds.size.width = CGRectGetMaxX(bounds) - CGRectGetMaxX(anchor);
	bounds.origin.x = CGRectGetMaxX(anchor);
	bounds = UIEdgeInsetsInsetRect(bounds, self.contentViewInsets);
	bounds.origin.x += self.arrowHeight;
	bounds.size.width -= self.arrowHeight;

	CGRect frame = CGRectZero;
	CGFloat offset = 0;
	frame.size = self.popover.contentViewController.contentSizeForViewInPopover;
	frame.size.width = MIN(CGRectGetWidth(frame), CGRectGetWidth(bounds));
	frame.size.height = MIN(CGRectGetHeight(frame), CGRectGetHeight(bounds));
	frame.origin.x = CGRectGetMinX(bounds);
	frame.origin.y = floorf(CGRectGetMidY(anchor) - CGRectGetHeight(frame) / 2) - self.popover.extraVerticalOffset;
	
	if (CGRectGetMaxY(frame) > CGRectGetMaxY(bounds))
		offset = CGRectGetMaxY(frame) - CGRectGetMaxY(bounds);
	else if (CGRectGetMinY(frame) < CGRectGetMinY(bounds))
		offset = CGRectGetMinY(frame) - CGRectGetMinY(bounds);
	
	frame.origin.y -= offset;
	offset += self.popover.extraVerticalOffset;
	
	if (outOffset)
		*outOffset = offset;
	return frame;
}

- (CGRect)layoutRect
{
	UIEdgeInsets layoutMargins = self.popover.popoverLayoutMargins;
	CGRect statusBarFrame = [self convertRect:[UIApplication sharedApplication].statusBarFrame fromView:nil];
	layoutMargins.top += CGRectGetHeight(statusBarFrame);
	return UIEdgeInsetsInsetRect(self.bounds, layoutMargins);
}

- (WJPopoverBackgroundView *)backgroundView
{
	for (UIView *subview in self.subviews) {
		if ([subview isKindOfClass:[WJPopoverBackgroundView class]])
			return (WJPopoverBackgroundView *)subview;
	}
	return nil;
}

- (void)layoutPopover
{
	CGFloat offset;
	CGRect frame;
	UIEdgeInsets insets = self.contentViewInsets;

	switch (self.backgroundView.arrowDirection) {
		case UIPopoverArrowDirectionUp:
			frame = [self frameBelowOffset:&offset];
			self.popover.contentViewController.view.frame = frame;
			self.backgroundView.arrowDirection = UIPopoverArrowDirectionUp;
			self.backgroundView.arrowOffset = offset;
			insets.top += self.arrowHeight;
			self.backgroundView.frame = UIEdgeInsetsOutsetRect(frame, insets);
			break;
			
		case UIPopoverArrowDirectionDown:
			frame = [self frameAboveOffset:&offset];
			self.popover.contentViewController.view.frame = frame;
			self.backgroundView.arrowDirection = UIPopoverArrowDirectionDown;
			self.backgroundView.arrowOffset = offset;
			insets.bottom += self.arrowHeight;
			self.backgroundView.frame = UIEdgeInsetsOutsetRect(frame, insets);
			break;
			
		case UIPopoverArrowDirectionLeft:
			frame = [self frameToRightOffset:&offset];
			self.popover.contentViewController.view.frame = frame;
			self.backgroundView.arrowDirection = UIPopoverArrowDirectionLeft;
			self.backgroundView.arrowOffset = offset;
			insets.left += self.arrowHeight;
			self.backgroundView.frame = UIEdgeInsetsOutsetRect(frame, insets);
			break;
			
		case UIPopoverArrowDirectionRight:
			frame = [self frameToLeftOffset:&offset];
			self.popover.contentViewController.view.frame = frame;
			self.backgroundView.arrowDirection = UIPopoverArrowDirectionRight;
			self.backgroundView.arrowOffset = offset;
			insets.right += self.arrowHeight;
			self.backgroundView.frame = UIEdgeInsetsOutsetRect(frame, insets);
			break;
			
		default:
			NSAssert(NO, @"Unsupported popover configuration");
			break;
	}
}

- (void)layoutSubviews
{
	[super layoutSubviews];

	// If the arrow direction has been previously calculated, then don't do
	// so again. This way, if the popover resizes it won't jump around the
	// anchor.
	if (self.backgroundView.arrowDirection != UIPopoverArrowDirectionUnknown)
		return [self layoutPopover];

	CGFloat belowOffset, toRightOffset, toLeftOffset, aboveOffset;
	CGRect belowFrame, toRightFrame, toLeftFrame, aboveFrame;
	CGSize contentSize = self.popover.contentViewController.contentSizeForViewInPopover;
	
	belowFrame = [self frameBelowOffset:&belowOffset];
	aboveFrame = [self frameAboveOffset:&aboveOffset];
	toLeftFrame = [self frameToLeftOffset:&toLeftOffset];
	toRightFrame = [self frameToRightOffset:&toRightOffset];
	
	// First pass: If the popover will fit in a supported direction without
	// resizing or offsetting, then do so. For this pass, we use the
	// following priority: to the right, to the left, below, above
	if ((self.permittedArrowDirections & UIPopoverArrowDirectionLeft) != 0) {
		if (CGSizeEqualToSize(toRightFrame.size, contentSize) && toRightOffset == 0) {
			self.backgroundView.arrowDirection = UIPopoverArrowDirectionLeft;
			return [self layoutPopover];
		}
	}
	if ((self.permittedArrowDirections & UIPopoverArrowDirectionRight) != 0) {
		if (CGSizeEqualToSize(toLeftFrame.size, contentSize) && toLeftOffset == 0) {
			self.backgroundView.arrowDirection = UIPopoverArrowDirectionRight;
			return [self layoutPopover];
		}
	}
	if ((self.permittedArrowDirections & UIPopoverArrowDirectionUp) != 0) {
		if (CGSizeEqualToSize(belowFrame.size, contentSize) && belowOffset == 0) {
			self.backgroundView.arrowDirection = UIPopoverArrowDirectionUp;
			return [self layoutPopover];
		}
	}
	if ((self.permittedArrowDirections & UIPopoverArrowDirectionDown) != 0) {
		if (CGSizeEqualToSize(aboveFrame.size, contentSize) && aboveOffset == 0) {
			self.backgroundView.arrowDirection = UIPopoverArrowDirectionDown;
			return [self layoutPopover];
		}
	}

	// Second pass: If the popover will fit in a supported direction without
	// resizing, then do so. For this pass, we use the following priority:
	// to the right, to the left, below, above
	if ((self.permittedArrowDirections & UIPopoverArrowDirectionLeft) != 0) {
		if (CGSizeEqualToSize(toRightFrame.size, contentSize)) {
			self.backgroundView.arrowDirection = UIPopoverArrowDirectionLeft;
			return [self layoutPopover];
		}
	}
	if ((self.permittedArrowDirections & UIPopoverArrowDirectionRight) != 0) {
		if (CGSizeEqualToSize(toLeftFrame.size, contentSize)) {
			self.backgroundView.arrowDirection = UIPopoverArrowDirectionRight;
			return [self layoutPopover];
		}
	}
	if ((self.permittedArrowDirections & UIPopoverArrowDirectionUp) != 0) {
		if (CGSizeEqualToSize(belowFrame.size, contentSize)) {
			self.backgroundView.arrowDirection = UIPopoverArrowDirectionUp;
			return [self layoutPopover];
		}
	}
	if ((self.permittedArrowDirections & UIPopoverArrowDirectionDown) != 0) {
		if (CGSizeEqualToSize(aboveFrame.size, contentSize)) {
			self.backgroundView.arrowDirection = UIPopoverArrowDirectionDown;
			return [self layoutPopover];
		}
	}

	// If the popover *must* be resized, pick a supported direction that will
	// maximize the area of the popover.
	NSArray *areas = @[
		@{@"dir": @(UIPopoverArrowDirectionUp),    @"area": @(CGRectGetArea(belowFrame))},
		@{@"dir": @(UIPopoverArrowDirectionDown),  @"area": @(CGRectGetArea(aboveFrame))},
		@{@"dir": @(UIPopoverArrowDirectionLeft),  @"area": @(CGRectGetArea(toRightFrame))},
		@{@"dir": @(UIPopoverArrowDirectionRight), @"area": @(CGRectGetArea(toLeftFrame))},
	];
	areas = [areas sortedArrayUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
		return [b[@"area"] compare:a[@"area"]];
	}];
	for (NSDictionary *dict in areas) {
		UIPopoverArrowDirection dir = [dict[@"dir"] intValue];
		if ((dir & self.permittedArrowDirections) != 0) {
			self.backgroundView.arrowDirection = dir;
			return [self layoutPopover];
		}
	};

	NSAssert(NO, @"Unsupported popover configuration");
}

@end

@implementation UIViewController (WJPopoverController)

- (WJPopoverController *)wjPopoverController
{
	UIView *view = self.view;
	while ((view = view.superview)) {
		if ([view isKindOfClass:[WJPopoverDimmerView class]])
			return ((WJPopoverDimmerView *)view).popover;
	}
	return nil;
}

@end