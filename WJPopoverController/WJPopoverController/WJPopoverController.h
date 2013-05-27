//
//  WJPopoverController.h
//
//  Copyright (c) 2013 Wouldja Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WJPopoverControllerDelegate;

@interface WJPopoverController : NSObject

@property (nonatomic, strong) UIViewController *contentViewController;
@property (nonatomic, weak) id<WJPopoverControllerDelegate> delegate;

@property (nonatomic, strong) Class popoverBackgroundViewClass;
@property (nonatomic, readwrite) UIEdgeInsets popoverLayoutMargins;

- (id)initWithContentViewController:(UIViewController *)viewController;

- (void)presentPopoverFromRect:(CGRect)rect inView:(UIView *)view permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated;
- (void)presentPopoverFromBarButtonItem:(UIBarButtonItem *)item permittedArrowDirections:(UIPopoverArrowDirection)arrowDirections animated:(BOOL)animated;
- (void)dismissPopoverAnimated:(BOOL)animated;

@end

@protocol WJPopoverControllerDelegate <NSObject>
@optional
- (BOOL)popoverControllerShouldDismissPopover:(WJPopoverController *)popoverController;
- (void)popoverControllerDidDismissPopover:(WJPopoverController *)popoverController;
@end

@interface UIViewController (WJPopoverController)
@property (nonatomic, readonly) WJPopoverController *wjPopoverController;
@end
