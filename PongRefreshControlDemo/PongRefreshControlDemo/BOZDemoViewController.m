//
//  BOZDemoViewController.m
//  PongRefreshControlDemo
//
//  Created by Ben Oztalay on 12/6/13.
//  Copyright (c) 2013 Ben Oztalay. All rights reserved.
//

#import "BOZDemoViewController.h"
#import "BOZPongRefreshControl.h"

@interface BOZDemoViewController() {
    NSArray* tableViewContent;
}
@end

@implementation BOZDemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pongRefreshControl = [BOZPongRefreshControl attachToTableView:self.tableView
                                                            withTarget:self
                                                             andAction:@selector(refreshTriggered)];
    
    tableViewContent = [NSArray arrayWithObjects:@"Row 1", @"Row 2", @"Row3", nil];
}

#pragma mark - Notifying the pong refresh control of scrolling

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.pongRefreshControl tableViewScrolled];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.pongRefreshControl userStoppedDragging];
}

#pragma mark - Listening for the user to trigger a refresh

- (void)refreshTriggered
{
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return tableViewContent.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [tableViewContent objectAtIndex:indexPath.row];
    
    return cell;
}

@end
