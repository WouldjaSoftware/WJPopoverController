//
//  ViewController.m
//  PopoverThingie
//
//  Created by Chris Eplett on 5/24/13.
//  Copyright (c) 2013 Wouldja Software. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (IBAction)presentPicker:(id)sender
{
	UIViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"Picker"];
	WJPopoverController *popover = [[WJPopoverController alloc] initWithContentViewController:vc];
	popover.delegate = self;
	if ([sender isKindOfClass:[UIBarButtonItem class]]) {
		[popover presentPopoverFromBarButtonItem:sender
						permittedArrowDirections:UIPopoverArrowDirectionAny
										animated:YES];
	}
	else if ([sender isKindOfClass:[UIView class]]) {
		[popover presentPopoverFromRect:[sender bounds]
								 inView:sender
			   permittedArrowDirections:UIPopoverArrowDirectionAny
							   animated:YES];
	}
}

- (BOOL)popoverControllerShouldDismissPopover:(WJPopoverController *)popoverController
{
	NSLog(@"popoverControllerShouldDismissPopover");
	return YES;
}

- (void)popoverControllerDidDismissPopover:(WJPopoverController *)popoverController
{
	NSLog(@"popoverControllerDidDismissPopover");
}

@end
