//
//  WJPopoverBackgroundView.m
//
//  Copyright (c) 2013 Wouldja Software. All rights reserved.
//

#import "WJPopoverBackgroundView.h"
#import <QuartzCore/QuartzCore.h>

@interface WJPopoverBackgroundView ()
@property (nonatomic, strong) UIImageView *borderView;
@property (nonatomic, strong) UIImageView *arrowView;
@end

@implementation WJPopoverBackgroundView

@synthesize arrowOffset = _arrowOffset;
@synthesize arrowDirection = _arrowDirection;

+ (CGFloat)arrowHeight
{
	return 10;
}

+ (CGFloat)arrowBase
{
	return 20;
}

+ (UIEdgeInsets)contentViewInsets
{
	return UIEdgeInsetsMake(8, 8, 8, 8);
}

+ (BOOL)wantsDefaultContentAppearance
{
	return NO;
}

- (id)initWithFrame:(CGRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		UIImage *border = [[UIImage imageNamed:@"PopoverBorder"] resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
		UIImage *arrow  = [UIImage imageNamed:@"PopoverArrow"];
		self.borderView = [[UIImageView alloc] initWithImage:border];
		self.arrowView  = [[UIImageView alloc] initWithImage:arrow];
		self.borderView.layer.shadowColor = [UIColor blackColor].CGColor;
		self.borderView.layer.shadowOpacity = 0.5;
		self.borderView.layer.shadowOffset = CGSizeMake(0, 5);
		self.borderView.layer.shadowRadius = 10;
		[self addSubview:self.borderView];
		[self addSubview:self.arrowView];
	}
	return self;
}

- (void)setArrowOffset:(CGFloat)arrowOffset
{
	_arrowOffset = arrowOffset;
	[self setNeedsLayout];
}

- (void)setArrowDirection:(UIPopoverArrowDirection)arrowDirection
{
	_arrowDirection = arrowDirection;
	[self setNeedsLayout];
}

- (void)layoutSubviews
{
	CGRect borderFrame = self.bounds;
	CGPoint arrowCenter = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
	CGFloat arrowHeight = [[self class] arrowHeight];
	CGFloat arrowCenterInset = arrowHeight / 2;
	CGAffineTransform arrowRotation = CGAffineTransformIdentity;

	switch (self.arrowDirection) {
		case UIPopoverArrowDirectionUp:
			borderFrame = UIEdgeInsetsInsetRect(borderFrame, UIEdgeInsetsMake(arrowHeight, 0, 0, 0));
			arrowCenter.y = CGRectGetMinY(self.bounds) + arrowCenterInset;
			arrowCenter.x += self.arrowOffset;
			break;
		case UIPopoverArrowDirectionDown:
			borderFrame = UIEdgeInsetsInsetRect(borderFrame, UIEdgeInsetsMake(0, 0, arrowHeight, 0));
			arrowCenter.y = CGRectGetMaxY(self.bounds) - arrowCenterInset;
			arrowCenter.x += self.arrowOffset;
			arrowRotation = CGAffineTransformMakeRotation(M_PI);
			break;
		case UIPopoverArrowDirectionLeft:
			borderFrame = UIEdgeInsetsInsetRect(borderFrame, UIEdgeInsetsMake(0, arrowHeight, 0, 0));
			arrowCenter.x = CGRectGetMinX(self.bounds) + arrowCenterInset;
			arrowCenter.y += self.arrowOffset;
			arrowRotation = CGAffineTransformMakeRotation(-M_PI_2);
			break;
		case UIPopoverArrowDirectionRight:
			borderFrame = UIEdgeInsetsInsetRect(borderFrame, UIEdgeInsetsMake(0, 0, 0, arrowHeight));
			arrowCenter.x = CGRectGetMaxX(self.bounds) - arrowCenterInset;
			arrowCenter.y += self.arrowOffset;
			arrowRotation = CGAffineTransformMakeRotation(M_PI_2);
			break;
		default:
			break;
	}

	self.arrowView.center = arrowCenter;
	self.arrowView.transform = arrowRotation;
	self.borderView.frame = borderFrame;
}

@end
