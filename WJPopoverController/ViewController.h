//
//  ViewController.h
//  PopoverThingie
//
//  Created by Chris Eplett on 5/24/13.
//  Copyright (c) 2013 Wouldja Software. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "WJPopoverController.h"

@interface ViewController : UIViewController <WJPopoverControllerDelegate>

- (IBAction)presentPicker:(id)sender;

@end
