//
//  PickerController.m
//  PopoverThingie
//
//  Created by Chris Eplett on 5/25/13.
//  Copyright (c) 2013 Wouldja Software. All rights reserved.
//

#import "PickerController.h"

@interface PickerController ()
@property (nonatomic, copy) NSArray *items;
@property (nonatomic) NSInteger numberOfItems;
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@end

@implementation PickerController

- (void)viewDidLoad
{
	[super viewDidLoad];
	self.items = @[@"Item One",
				@"Item Two",
				@"Item Three",
				@"Item Four",
				@"Item Five",
				@"Item Six",
				@"Item Seven"];
	self.numberOfItems = 4;
}

- (IBAction)toggleSize:(id)sender
{
	self.numberOfItems = (self.numberOfItems == 7) ? 4 : 7;
}

- (void)setNumberOfItems:(NSInteger)numberOfItems
{
	_numberOfItems = numberOfItems;
	[self.tableView reloadData];
	self.contentSizeForViewInPopover = CGSizeMake(300, 44 + _numberOfItems * self.tableView.rowHeight);
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	NSLog(@"viewWillAppear");
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	NSLog(@"viewDidAppear");
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
	NSLog(@"viewWillDisappear");
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	NSLog(@"viewDidDisappear");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	return self.numberOfItems;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"PickerItem"];
	cell.textLabel.text = self.items[indexPath.row];
	return cell;
}

@end
