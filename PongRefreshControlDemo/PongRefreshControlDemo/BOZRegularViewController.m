//
//  BOZRegularViewController.m
//  PongRefreshControlDemo
//
//  Created by Ben Oztalay on 12/7/13.
//  Copyright (c) 2013 Ben Oztalay. All rights reserved.
//

#import "BOZRegularViewController.h"

@implementation BOZRegularViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /* NOTE: Do not attach the refresh control in viewDidLoad!
     * If you do this here, it'll act very funny if you have
     * a navigation bar or other such similar thing that iOS 7
     * automatically offsets content for. You have to wait for
     * the subviews to get laid out first so the refresh
     * control knows how big that offset is!
     */
}

- (void)viewDidLayoutSubviews
{
    self.pongRefreshControl = [BOZPongRefreshControl attachToTableView:self.tableView
                                                     withRefreshTarget:self
                                                      andRefreshAction:@selector(refreshTriggered)];
    self.pongRefreshControl.backgroundColor = [UIColor whiteColor];
    self.pongRefreshControl.foregroundColor = [UIColor blackColor];
}

//Resetting the refresh control if the user leaves the screen
- (void)viewWillDisappear:(BOOL)animated
{
    [self.pongRefreshControl finishedLoading];
}

#pragma mark - Notifying the pong refresh control of scrolling

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.pongRefreshControl scrollViewDidScroll];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self.pongRefreshControl scrollViewDidEndDragging];
}

#pragma mark - Listening for the user to trigger a refresh

- (void)refreshTriggered
{
    
}

#pragma mark - Resetting the refresh control when loading is done

- (IBAction)doneLoadingButtonPressed:(id)sender
{
    [self.pongRefreshControl finishedLoading];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 7;
}

- (UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [NSString stringWithFormat:@"Row %d", indexPath.row];
    
    CGFloat redComponent = 1.0f - (float)(indexPath.row + 1) / (float)([tableView numberOfRowsInSection:0] + 1);
    cell.contentView.backgroundColor = [UIColor colorWithRed:redComponent green:0.1f blue:0.1f alpha:1.0f];
    
    return cell;
}

@end
