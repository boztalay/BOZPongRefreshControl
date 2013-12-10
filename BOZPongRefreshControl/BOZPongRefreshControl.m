//
//  BOZPongRefreshControl.m
//  Ben Oztalay
//
//  Created by Ben Oztalay on 11/22/13.
//  Copyright (c) 2013 Ben Oztalay. All rights reserved.
//

#import "BOZPongRefreshControl.h"

#define REFRESH_CONTROL_HEIGHT 65.0f
#define HALF_REFRESH_CONTROL_HEIGHT (REFRESH_CONTROL_HEIGHT / 2.0f)

#define DEFAULT_FOREGROUND_COLOR [UIColor whiteColor]
#define DEFAULT_BACKGROUND_COLOR [UIColor colorWithWhite:0.10f alpha:1.0f]

#define DEFAULT_TOTAL_HORIZONTAL_TRAVEL_TIME_FOR_BALL 1.0f

#define PI 3.14159265359f

typedef enum {
    BOZPongRefreshControlStateIdle = 0,
    BOZPongRefreshControlStateRefreshing = 1,
    BOZPongRefreshControlStateResetting = 2
} BOZPongRefreshControlState;

@interface BOZPongRefreshControl() {
    BOZPongRefreshControlState state;
    
    CGFloat originalTopContentInset;
    
    UIView* leftPaddleView;
    UIView* rightPaddleView;
    UIView* ballView;
    
    CGPoint leftPaddleIdleOrigin;
    CGPoint rightPaddleIdleOrigin;
    CGPoint ballIdleOrigin;
    
    CGPoint ballOrigin;
    CGPoint ballDestination;
    CGPoint ballDirection;
    
    CGFloat leftPaddleDestination;
    CGFloat rightPaddleDestination;
    
    //This is here so the pong refresh control
    //doesn't show under translucent headers
    UIView* coverView;
}

@property (strong, nonatomic) UIScrollView* scrollView;
@property (strong, nonatomic) id refreshTarget;
@property (nonatomic) SEL refreshAction;

@end

@implementation BOZPongRefreshControl

#pragma mark - Attaching a pong refresh control to a UIScrollView or UITableView

#pragma mark UIScrollView
+ (BOZPongRefreshControl*)attachToScrollView:(UIScrollView*)scrollView
                           withRefreshTarget:(id)refreshTarget
                            andRefreshAction:(SEL)refreshAction
{
    BOOL isScrollViewATableView = [scrollView isKindOfClass:[UITableView class]];
    if(isScrollViewATableView) {
        return [self attachToTableView:(UITableView*)scrollView
                     withRefreshTarget:refreshTarget
                      andRefreshAction:refreshAction];
    }
    
    BOZPongRefreshControl* existingPongRefreshControl = [self findPongRefreshControlInScrollView:scrollView];
    if(existingPongRefreshControl != nil) {
        return existingPongRefreshControl;
    }
    
    BOZPongRefreshControl* pongRefreshControl = [[BOZPongRefreshControl alloc] initWithFrame:CGRectMake(0.0f, -REFRESH_CONTROL_HEIGHT, scrollView.frame.size.width, REFRESH_CONTROL_HEIGHT)
                                                                               andScrollView:scrollView
                                                                            andRefreshTarget:refreshTarget
                                                                            andRefreshAction:refreshAction];

    [scrollView addSubview:pongRefreshControl];

    return pongRefreshControl;
}

+ (BOZPongRefreshControl*)findPongRefreshControlInScrollView:(UIScrollView*)scrollView
{
    for(UIView* subview in scrollView.subviews) {
        if([subview isKindOfClass:[BOZPongRefreshControl class]]) {
            return (BOZPongRefreshControl*)subview;
        }
    }
    
    return nil;
}

#pragma mark UITableVIew
+ (BOZPongRefreshControl*)attachToTableView:(UITableView*)tableView
                          withRefreshTarget:(id)refreshTarget
                           andRefreshAction:(SEL)refreshAction
{
    if([self doesTableViewAlreadyHaveAPongRefreshControl:tableView]) {
        return (BOZPongRefreshControl*)tableView.tableHeaderView;
    }
    
    BOZPongRefreshControl* pongRefreshControl = [[BOZPongRefreshControl alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableView.frame.size.width, REFRESH_CONTROL_HEIGHT)
                                                                               andScrollView:(UIScrollView*)tableView
                                                                            andRefreshTarget:refreshTarget
                                                                            andRefreshAction:refreshAction];
    
    [tableView setTableHeaderView:pongRefreshControl];
    
    return pongRefreshControl;
}

+ (BOOL)doesTableViewAlreadyHaveAPongRefreshControl:(UITableView*)tableView
{
    return (tableView.tableHeaderView != nil && [tableView.tableHeaderView isKindOfClass:[BOZPongRefreshControl class]]);
}

#pragma mark - Initializing a new pong refresh control

- (id)initWithFrame:(CGRect)frame
      andScrollView:(UIScrollView*)scrollView
   andRefreshTarget:(id)refreshTarget
   andRefreshAction:(SEL)refreshAction
{
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = YES;
        
        self.scrollView = scrollView;
        self.refreshTarget = refreshTarget;
        self.refreshAction = refreshAction;
        
        [self calculateOriginalTopContentInset];
        [self setNewTopContentInsetOnScrollView];
        
        self.foregroundColor = DEFAULT_FOREGROUND_COLOR;
        self.backgroundColor = DEFAULT_BACKGROUND_COLOR;
        
        [self setUpPaddles];
        [self setUpBall];
        
        [self setUpCoverView];
        
        state = BOZPongRefreshControlStateIdle;
    }
    return self;
}

- (void)calculateOriginalTopContentInset
{
    originalTopContentInset = self.scrollView.contentInset.top;
    if(![self.scrollView isKindOfClass:[UITableView class]]) {
        originalTopContentInset += REFRESH_CONTROL_HEIGHT;
    }
}

- (void)setNewTopContentInsetOnScrollView
{
    UIEdgeInsets newContentInset = self.scrollView.contentInset;
    newContentInset.top = originalTopContentInset - REFRESH_CONTROL_HEIGHT;
    self.scrollView.contentInset = newContentInset;
}

- (void)setUpPaddles
{
    leftPaddleIdleOrigin = CGPointMake(self.frame.size.width * 0.25f, self.frame.size.height);
    leftPaddleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 2.0f, 15.0f)];
    leftPaddleView.center = leftPaddleIdleOrigin;
    leftPaddleView.backgroundColor = self.foregroundColor;
    
    rightPaddleIdleOrigin = CGPointMake(self.frame.size.width * 0.75f, self.frame.size.height);
    rightPaddleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 2.0f, 15.0f)];
    rightPaddleView.center = rightPaddleIdleOrigin;
    rightPaddleView.backgroundColor = self.foregroundColor;
    
    [self addSubview:leftPaddleView];
    [self addSubview:rightPaddleView];
}

- (void)setUpBall
{
    ballIdleOrigin = CGPointMake(self.frame.size.width * 0.50f, 0.0f);
    ballView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 3.0f, 3.0f)];
    ballView.center = ballIdleOrigin;
    ballView.backgroundColor = self.foregroundColor;
    
    self.totalHorizontalTravelTimeForBall = DEFAULT_TOTAL_HORIZONTAL_TRAVEL_TIME_FOR_BALL;
    
    [self addSubview:ballView];
}

- (void)setUpCoverView
{
    coverView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
    coverView.backgroundColor = self.scrollView.backgroundColor;
    
    [self.scrollView addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew context:nil];
    
    [self addSubview:coverView];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    //This is to make sure the cover stays consistent with whatever background
    //color the parent UIScrollView has.
    if(object == self.scrollView && [keyPath isEqualToString:@"backgroundColor"]) {
        coverView.backgroundColor = self.scrollView.backgroundColor;
    }
}

#pragma mark - Handling various configuration changes

- (void)setForegroundColor:(UIColor*)foregroundColor
{
    _foregroundColor = foregroundColor;
    
    leftPaddleView.backgroundColor = foregroundColor;
    rightPaddleView.backgroundColor = foregroundColor;
    ballView.backgroundColor = foregroundColor;
}

- (void)setShouldCoverRefreshControlUnderHeader:(BOOL)shouldCoverRefreshControlUnderHeader
{
    coverView.hidden = !shouldCoverRefreshControlUnderHeader;
}

#pragma mark - Listening to scroll delegate events

#pragma mark Actively scrolling

- (void)scrollViewDidScroll
{
    if(state == BOZPongRefreshControlStateIdle) {
        CGFloat rawOffset = REFRESH_CONTROL_HEIGHT - self.scrollView.contentOffset.y - originalTopContentInset;
        CGFloat ballAndPaddlesOffset = MIN(rawOffset / 2.0f, HALF_REFRESH_CONTROL_HEIGHT);
        
        [self offsetBallAndPaddlesBy:ballAndPaddlesOffset];
        [self rotatePaddlesAccordingToOffset:ballAndPaddlesOffset];
        
        [self offsetCoverBy:rawOffset];
    }
}

- (void)offsetBallAndPaddlesBy:(CGFloat)offset
{
    ballView.center = CGPointMake(ballIdleOrigin.x, ballIdleOrigin.y + offset);
    leftPaddleView.center = CGPointMake(leftPaddleIdleOrigin.x, leftPaddleIdleOrigin.y - offset);
    rightPaddleView.center = CGPointMake(rightPaddleIdleOrigin.x, rightPaddleIdleOrigin.y - offset);
}

- (void)rotatePaddlesAccordingToOffset:(CGFloat)offset
{
    CGFloat proportionOfMaxOffset = (offset / HALF_REFRESH_CONTROL_HEIGHT);
    CGFloat angleToRotate = PI * proportionOfMaxOffset;
    
    leftPaddleView.transform = CGAffineTransformMakeRotation(angleToRotate);
    rightPaddleView.transform = CGAffineTransformMakeRotation(-angleToRotate);
}

- (void)offsetCoverBy:(CGFloat)offset
{
    coverView.center = CGPointMake(self.center.x, self.center.y - offset);
}

#pragma mark Letting go of the scroll view, checking for refresh trigger

- (void)scrollViewDidEndDragging
{
    if(state == BOZPongRefreshControlStateIdle) {
        if([self didUserScrollFarEnoughToTriggerRefresh]) {
            state = BOZPongRefreshControlStateRefreshing;
        
            [self animateScrollViewBackIntoPlaceWithRefreshControlShowing];
            [self startPong];
            [self notifyTargetOfRefreshTrigger];
        }
    }
}

- (BOOL)didUserScrollFarEnoughToTriggerRefresh
{
    return (self.scrollView.contentOffset.y < -originalTopContentInset);
}

- (void)animateScrollViewBackIntoPlaceWithRefreshControlShowing
{
    [UIView animateWithDuration:0.2f animations:^(void) {
        UIEdgeInsets newInsets = self.scrollView.contentInset;
        newInsets.top = originalTopContentInset;
        self.scrollView.contentInset = newInsets;
    }];
}

- (void)notifyTargetOfRefreshTrigger
{
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.refreshTarget performSelector:self.refreshAction];
    #pragma clang diagnostic pop
}

#pragma mark - Resetting after loading finished

- (void)finishedLoading
{
    if(state != BOZPongRefreshControlStateRefreshing) {
        return;
    }
    
    state = BOZPongRefreshControlStateResetting;
    
    [UIView animateWithDuration:0.2f animations:^(void)
     {
         [self resetCoverViewAndScrollViewContentInsets];
     }
     completion:^(BOOL finished)
     {
         [self resetPaddlesAndBall];
         state = BOZPongRefreshControlStateIdle;
     }];
}

- (void)resetCoverViewAndScrollViewContentInsets
{
    UIEdgeInsets newInsets = self.scrollView.contentInset;
    newInsets.top = originalTopContentInset - REFRESH_CONTROL_HEIGHT;
    self.scrollView.contentInset = newInsets;
    
    coverView.center = self.center;
}

- (void)resetPaddlesAndBall
{
    [leftPaddleView.layer removeAllAnimations];
    [rightPaddleView.layer removeAllAnimations];
    [ballView.layer removeAllAnimations];
    
    leftPaddleView.center = leftPaddleIdleOrigin;
    rightPaddleView.center = rightPaddleIdleOrigin;
    ballView.center = ballIdleOrigin;
}

#pragma mark - Playing pong

#pragma mark Starting the game

- (void)startPong
{
    ballOrigin = ballView.center;
    [self pickRandomStartingBallDestination];
    [self determineNextPaddleDestinations];
    [self animateBallAndPaddlesToDestinations];
}

- (void)pickRandomStartingBallDestination
{
    CGFloat destinationX = [self leftPaddleContactX];
    if(arc4random() % 2 == 1) {
        destinationX = [self rightPaddleContactX];
    }
    CGFloat destinationY = (float)(arc4random() % (int)self.frame.size.height);
    
    ballDestination = CGPointMake(destinationX, destinationY);
    ballDirection = CGPointMake((ballDestination.x - ballOrigin.x), (ballDestination.y - ballOrigin.y));
    ballDirection = [self normalizeVector:ballDirection];
}

#pragma mark Playing the game

//Yeah, sorry... I'll clean this up in a bit.
- (void)determineNextBallDestination
{
    CGFloat newBallDestinationX;
    CGFloat newBallDestinationY;
    
    CGPoint reflectedBallDirection;
    
    if([self didBallHitWall]) {
        reflectedBallDirection = CGPointMake(ballDirection.x, -ballDirection.y);
    } else if([self didBallHitPaddle]) {
        reflectedBallDirection = CGPointMake(-ballDirection.x, ballDirection.y);
    }
    
    CGFloat distanceToNextWall;
    CGFloat verticalDistanceToNextWall;
    
    if(reflectedBallDirection.y > 0.0f) {
        verticalDistanceToNextWall = [self floorContactY] - ballDestination.y;
    } else {
        verticalDistanceToNextWall = [self ceilingContactY] - ballDestination.y;
    }
    distanceToNextWall = verticalDistanceToNextWall / reflectedBallDirection.y;
    
    CGFloat horizontalDistanceToNextWall = distanceToNextWall * reflectedBallDirection.x;
    CGFloat horizontalDistanceToNextPaddle;
    
    if(reflectedBallDirection.x < 0.0f) {
        horizontalDistanceToNextPaddle = [self leftPaddleContactX] - ballDestination.x;
    } else {
        horizontalDistanceToNextPaddle = [self rightPaddleContactX] - ballDestination.x;
    }
    
    if(fabsf(horizontalDistanceToNextPaddle) < fabsf(horizontalDistanceToNextWall)) {
        newBallDestinationX = ballDestination.x + horizontalDistanceToNextPaddle;
        CGFloat verticalDistanceToNextPaddle = fabs(horizontalDistanceToNextPaddle) * reflectedBallDirection.y;
        newBallDestinationY = ballDestination.y + verticalDistanceToNextPaddle;
    } else {
        newBallDestinationX = ballDestination.x + horizontalDistanceToNextWall;
        newBallDestinationY = ballDestination.y + verticalDistanceToNextWall;
    }
    
    ballOrigin = ballDestination;
    ballDestination = CGPointMake(newBallDestinationX, newBallDestinationY);
    ballDirection = CGPointMake((ballDestination.x - ballOrigin.x), (ballDestination.y - ballOrigin.y));
    ballDirection = [self normalizeVector:ballDirection];
}

- (BOOL)didBallHitWall
{
    return ([self isFloat:ballDestination.y equalToFloat:[self ceilingContactY]] || [self isFloat:ballDestination.y equalToFloat:[self floorContactY]]);
}

- (BOOL)didBallHitPaddle
{
    return ([self isFloat:ballDestination.x equalToFloat:[self leftPaddleContactX]] || [self isFloat:ballDestination.x equalToFloat:[self rightPaddleContactX]]);
}

- (void)determineNextPaddleDestinations
{
    static CGFloat lazyFactor = 0.25f;
    static CGFloat normalFactor = 0.5f;
    static CGFloat holyCrapFactor = 1.0f;
    
    CGFloat leftPaddleVerticalDistanceToBallDestination = ballDestination.y - leftPaddleView.center.y;
    CGFloat rightPaddleVerticalDistanceToBallDestination = ballDestination.y - rightPaddleView.center.y;
    
    if(ballDirection.x < 0.0f) {
        //Going toward the left paddle
        
        //Destination is the left paddle
        if([self isFloat:ballDestination.x equalToFloat:[self leftPaddleContactX]]) {
            leftPaddleDestination = leftPaddleView.center.y + (leftPaddleVerticalDistanceToBallDestination * holyCrapFactor);
            rightPaddleDestination = rightPaddleView.center.y + (rightPaddleVerticalDistanceToBallDestination * lazyFactor);
        } else {
            //Destination is a wall
            leftPaddleDestination = leftPaddleView.center.y + (leftPaddleVerticalDistanceToBallDestination * normalFactor);
            rightPaddleDestination = rightPaddleView.center.y - (rightPaddleVerticalDistanceToBallDestination * normalFactor);
        }
    } else {
        //Going toward the right paddle
        
        //Destination is the right paddle
        if([self isFloat:ballDestination.x equalToFloat:[self rightPaddleContactX]]) {
            leftPaddleDestination = leftPaddleView.center.y + (leftPaddleVerticalDistanceToBallDestination * lazyFactor);
            rightPaddleDestination = rightPaddleView.center.y + (rightPaddleVerticalDistanceToBallDestination * holyCrapFactor);
        } else {
            //Destination is a wall
            leftPaddleDestination = leftPaddleView.center.y - (leftPaddleVerticalDistanceToBallDestination * normalFactor);
            rightPaddleDestination = rightPaddleView.center.y + (rightPaddleVerticalDistanceToBallDestination * normalFactor);
        }
    }
    
    if(leftPaddleDestination < [self ceilingLeftPaddleContactY]) {
        leftPaddleDestination = [self ceilingLeftPaddleContactY];
    } else if(leftPaddleDestination > [self floorLeftPaddleContactY]) {
        leftPaddleDestination = [self floorLeftPaddleContactY];
    }
    
    if(rightPaddleDestination < [self ceilingRightPaddleContactY]) {
        rightPaddleDestination = [self ceilingRightPaddleContactY];
    } else if(rightPaddleDestination > [self floorRightPaddleContactY]) {
        rightPaddleDestination = [self floorRightPaddleContactY];
    }
}

- (void)animateBallAndPaddlesToDestinations
{
    CGFloat endToEndDistance = [self rightPaddleContactX] - [self leftPaddleContactX];
    CGFloat proportionOfHorizontalDistanceLeftForBallToTravel = fabsf((ballDestination.x - ballView.center.x) / endToEndDistance);
    CGFloat animationDuration = self.totalHorizontalTravelTimeForBall * proportionOfHorizontalDistanceLeftForBallToTravel;
    
    [UIView animateWithDuration:animationDuration delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^(void)
     {
         ballView.center = ballDestination;
         leftPaddleView.center = CGPointMake(leftPaddleView.center.x, leftPaddleDestination);
         rightPaddleView.center = CGPointMake(rightPaddleView.center.x, rightPaddleDestination);
     }
     completion:^(BOOL finished)
     {
         if(finished) {
             [self determineNextBallDestination];
             [self determineNextPaddleDestinations];
             [self animateBallAndPaddlesToDestinations];
         }
     }];
}

#pragma mark Helper functions for collision detection

#pragma mark Ball collisions

- (CGFloat)leftPaddleContactX
{
    return leftPaddleView.center.x + (ballView.frame.size.width / 2.0f);
}

- (CGFloat)rightPaddleContactX
{
    return rightPaddleView.center.x - (ballView.frame.size.width / 2.0f);
}

- (CGFloat)ceilingContactY
{
    return (ballView.frame.size.height / 2.0f);
}

- (CGFloat)floorContactY
{
    return self.frame.size.height - (ballView.frame.size.height / 2.0f);
}

#pragma mark Paddle collisions

- (CGFloat)ceilingLeftPaddleContactY
{
    return (leftPaddleView.frame.size.height / 2.0f);
}

- (CGFloat)floorLeftPaddleContactY
{
    return self.frame.size.height - (leftPaddleView.frame.size.height / 2.0f);
}

- (CGFloat)ceilingRightPaddleContactY
{
    return (rightPaddleView.frame.size.height / 2.0f);
}

- (CGFloat)floorRightPaddleContactY
{
    return self.frame.size.height - (rightPaddleView.frame.size.height / 2.0f);
}

#pragma mark - Etc, some basic math functions

- (CGPoint)normalizeVector:(CGPoint)vector
{
    CGFloat magnitude = sqrtf(vector.x * vector.x + vector.y * vector.y);
    return CGPointMake(vector.x / magnitude, vector.y / magnitude);
}

- (BOOL)isFloat:(CGFloat)float1 equalToFloat:(CGFloat)float2
{
    static CGFloat ellipsis = 0.01f;
    
    return (fabsf(float1 - float2) < ellipsis);
}

@end
