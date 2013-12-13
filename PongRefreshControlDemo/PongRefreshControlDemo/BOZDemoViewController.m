//
//  BOZDemoViewController.m
//  PongRefreshControlDemo
//
//  Created by Ben Oztalay on 12/6/13.
//  Copyright (c) 2013 Ben Oztalay. All rights reserved.
//

#import "BOZDemoViewController.h"

@implementation BOZDemoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    /* NOTE: Do NOT attach the refresh control in viewDidLoad!
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
}

- (void)viewWillDisappear:(BOOL)animated
{
    //Resetting the refresh control if the user leaves the screen
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
//    UIAlertView *alert = [[UIAlertView alloc]
//                          initWithTitle:@"Whoa!"
//                          message:@"You triggered a refresh! Hit \"Done Loading\" to make it stop."
//                          delegate:nil
//                          cancelButtonTitle:@"Sweet!"
//                          otherButtonTitles:nil];
//    [alert show];
}

#pragma mark - Resetting the refresh control when loading is done

- (IBAction)doneLoadingButtonPressed:(id)sender
{
    [self.pongRefreshControl finishedLoading];
}

@end
