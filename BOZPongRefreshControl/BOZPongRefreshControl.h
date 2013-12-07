//
//  BOZPongRefreshControl.h
//  Ben Oztalay
//
//  Created by Ben Oztalay on 11/22/13.
//  Copyright (c) 2013 Ben Oztalay. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BOZPongRefreshControl : UIView <UIScrollViewDelegate>

@property (weak, nonatomic) UIScrollView* scrollView;
@property (weak, nonatomic) UIViewController* target;
@property (nonatomic) SEL refreshAction;

+ (BOZPongRefreshControl*)attachToScrollView:(UIScrollView*)scrollView
                                  withTarget:(UIViewController*)target
                                   andAction:(SEL)refreshAction;

- (id)initWithFrame:(CGRect)frame
      andScrollView:(UIScrollView*)scrollView
          andTarget:(UIViewController*)target
   andRefreshAction:(SEL)refreshAction;

- (void)finishedLoading;

- (void)scrollViewScrolled;
- (void)userStoppedDragging;

@end
