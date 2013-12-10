//
//  BOZPongRefreshControl.h
//  Ben Oztalay
//
//  Created by Ben Oztalay on 11/22/13.
//  Copyright (c) 2013 Ben Oztalay. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BOZPongRefreshControl : UIView <UIScrollViewDelegate>

+ (BOZPongRefreshControl*)attachToScrollView:(UIScrollView*)scrollView
                           withRefreshTarget:(id)refreshTarget
                            andRefreshAction:(SEL)refreshAction;

+ (BOZPongRefreshControl*)attachToTableView:(UITableView*)tableView
                          withRefreshTarget:(id)refreshTarget
                           andRefreshAction:(SEL)refreshAction;

@property (strong, nonatomic) UIColor* foregroundColor;

- (void)finishedLoading;

- (void)scrollViewScrolled;
- (void)userStoppedDragging;

@end
