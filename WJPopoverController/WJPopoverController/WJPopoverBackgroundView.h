//
//  WJPopoverBackgroundView.h
//
//  Copyright (c) 2013 Wouldja Software. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WJPopoverBackgroundView : UIPopoverBackgroundView

@property (nonatomic, readwrite) CGFloat arrowOffset;

@property (nonatomic, readwrite) UIPopoverArrowDirection arrowDirection;

+ (CGFloat)arrowHeight;
+ (CGFloat)arrowBase;
+ (UIEdgeInsets)contentViewInsets;

@end
