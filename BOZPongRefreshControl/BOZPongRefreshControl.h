//
//  BOZPongRefreshControl.h
//  Ben Oztalay
//
//  Created by Ben Oztalay on 11/22/13.
//  Copyright (c) 2013 Ben Oztalay. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BOZPongRefreshControl : UIView <UIScrollViewDelegate>

@property (weak, nonatomic) UITableView* tableView;
@property (weak, nonatomic) id target;
@property (nonatomic) SEL refreshAction;

+ (BOZPongRefreshControl*)attachToTableView:(UITableView*)tableView withTarget:(id)target andAction:(SEL)refreshAction;

- (void)finishedLoading;

- (void)tableViewScrolled;
- (void)userStoppedDragging;

@end
