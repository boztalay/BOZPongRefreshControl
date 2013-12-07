//
//  BOZNoNavBarViewController.m
//  PongRefreshControlDemo
//
//  Created by Ben Oztalay on 12/6/13.
//  Copyright (c) 2013 Ben Oztalay. All rights reserved.
//

#import "BOZNoNavBarViewController.h"

@implementation BOZNoNavBarViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.pongRefreshControl = [BOZPongRefreshControl attachToTableView:self.tableView
                                                            withTarget:self
                                                             andAction:@selector(refreshTriggered)];
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

#pragma mark - Resetting the refresh control when loading is done

- (IBAction)doneLoadingButtonPressed:(id)sender
{
    [self.pongRefreshControl finishedLoading];
}

#pragma mark - Going back

- (IBAction)goBackButtonPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
