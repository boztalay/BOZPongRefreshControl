//
//  BOZScrollViewController.m
//  PongRefreshControlDemo
//
//  Created by Ben Oztalay on 12/7/13.
//  Copyright (c) 2013 Ben Oztalay. All rights reserved.
//

#import "BOZScrollViewController.h"

#define STRIPE_HEIGHT 50.0f
#define NUM_STRIPES 11
#define SCROLLVIEW_CONTENT_HEIGHT (STRIPE_HEIGHT * NUM_STRIPES)

@implementation BOZScrollViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, SCROLLVIEW_CONTENT_HEIGHT);
    
    for(int i = 0; i < NUM_STRIPES; i++) {
        UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, i * STRIPE_HEIGHT, self.scrollView.frame.size.width, STRIPE_HEIGHT)];
        
        CGFloat proportionOfScrollViewFilled = ((float)(i + 1) / (NUM_STRIPES + 1.0f));
        CGFloat whiteValue = 1.0f - proportionOfScrollViewFilled;
        
        view.backgroundColor = [UIColor colorWithWhite:whiteValue alpha:1.0f];
        
        if(i == 0) {
            UILabel* scrollMeLabel = [[UILabel alloc] initWithFrame:CGRectZero];
            scrollMeLabel.text = @"Scroll Me!";
            [scrollMeLabel sizeToFit];
            scrollMeLabel.center = CGPointMake(view.frame.size.width / 2.0f, view.frame.size.height / 2.0f);
            [view addSubview:scrollMeLabel];
        }
        
        [self.scrollView addSubview:view];
    }
    
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
    self.pongRefreshControl = [BOZPongRefreshControl attachToScrollView:self.scrollView
                                                      withRefreshTarget:self
                                                       andRefreshAction:@selector(refreshTriggered)];
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

@end
