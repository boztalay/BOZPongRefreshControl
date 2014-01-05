//
//  BOZPongRefreshControl.m
//  Ben Oztalay
//
//  Created by Ben Oztalay on 11/22/13.
//  Copyright (c) 2013 Ben Oztalay. All rights reserved.
//
//  Version 0.1.1
//  https://www.github.com/boztalay/BOZPongRefreshControl
//

#import "BOZPongRefreshControl.h"

#define REFRESH_CONTROL_HEIGHT 65.0f
#define HALF_REFRESH_CONTROL_HEIGHT (REFRESH_CONTROL_HEIGHT / 2.0f)

#define DEFAULT_FOREGROUND_COLOR [UIColor whiteColor]
#define DEFAULT_BACKGROUND_COLOR [UIColor colorWithWhite:0.10f alpha:1.0f]

#define DEFAULT_TOTAL_HORIZONTAL_TRAVEL_TIME_FOR_BALL 1.0f

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

    UIView* coverView;
    UIView* gameView;
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

#pragma mark UITableView

+ (BOZPongRefreshControl*)attachToTableView:(UITableView*)tableView
                          withRefreshTarget:(id)refreshTarget
                           andRefreshAction:(SEL)refreshAction
{
    if([self doesTableViewAlreadyHaveAPongRefreshControl:tableView]) {
        return (BOZPongRefreshControl*)[tableView.tableHeaderView.subviews firstObject];
    }
    
    BOZPongRefreshControl* pongRefreshControl = [[BOZPongRefreshControl alloc] initWithFrame:CGRectMake(0.0f, 0.0f, tableView.frame.size.width, REFRESH_CONTROL_HEIGHT)
                                                                               andScrollView:(UIScrollView*)tableView
                                                                            andRefreshTarget:refreshTarget
                                                                            andRefreshAction:refreshAction];
    
    UIView* headerView = [[UIView alloc] initWithFrame:pongRefreshControl.frame];
    headerView.clipsToBounds = NO;
    
    [headerView addSubview:pongRefreshControl];
    [tableView setTableHeaderView:headerView];
    
    return pongRefreshControl;
}

+ (BOOL)doesTableViewAlreadyHaveAPongRefreshControl:(UITableView*)tableView
{
    if(tableView.tableHeaderView != nil) {
        if(tableView.tableHeaderView.subviews.count == 1) {
            return [[tableView.tableHeaderView.subviews firstObject] isKindOfClass:[BOZPongRefreshControl class]];
        }
    }
    
    return NO;
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
        
        [self setUpCoverViewAndGameView];
        
        self.foregroundColor = DEFAULT_FOREGROUND_COLOR;
        self.backgroundColor = DEFAULT_BACKGROUND_COLOR;
        
        [self setUpPaddles];
        [self setUpBall];
        
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

- (void)setUpCoverViewAndGameView
{
    gameView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
    gameView.backgroundColor = [UIColor clearColor];
    [self addSubview:gameView];
    
    coverView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height)];
    coverView.backgroundColor = self.scrollView.backgroundColor;
    [self.scrollView addObserver:self forKeyPath:@"backgroundColor" options:NSKeyValueObservingOptionNew context:nil];
    [gameView addSubview:coverView];
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

- (void)setUpPaddles
{
    leftPaddleIdleOrigin = CGPointMake(gameView.frame.size.width * 0.25f, gameView.frame.size.height);
    leftPaddleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 2.0f, 15.0f)];
    leftPaddleView.center = leftPaddleIdleOrigin;
    leftPaddleView.backgroundColor = self.foregroundColor;
    
    rightPaddleIdleOrigin = CGPointMake(gameView.frame.size.width * 0.75f, gameView.frame.size.height);
    rightPaddleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 2.0f, 15.0f)];
    rightPaddleView.center = rightPaddleIdleOrigin;
    rightPaddleView.backgroundColor = self.foregroundColor;
    
    [gameView addSubview:leftPaddleView];
    [gameView addSubview:rightPaddleView];
}

- (void)setUpBall
{
    ballIdleOrigin = CGPointMake(gameView.frame.size.width * 0.50f, 0.0f);
    ballView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 3.0f, 3.0f)];
    ballView.center = ballIdleOrigin;
    ballView.backgroundColor = self.foregroundColor;
    
    self.totalHorizontalTravelTimeForBall = DEFAULT_TOTAL_HORIZONTAL_TRAVEL_TIME_FOR_BALL;
    
    [gameView addSubview:ballView];
}

#pragma mark - Handling various configuration changes

- (void)setBackgroundColor:(UIColor *)backgroundColor
{
    [super setBackgroundColor:backgroundColor];
}

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
    CGFloat rawOffset = REFRESH_CONTROL_HEIGHT - self.scrollView.contentOffset.y - originalTopContentInset;
    
    [self offsetCoverAndGameViewBy:rawOffset];
    
    if(state == BOZPongRefreshControlStateIdle) {
        CGFloat ballAndPaddlesOffset = MIN(rawOffset / 2.0f, HALF_REFRESH_CONTROL_HEIGHT);
        
        [self offsetBallAndPaddlesBy:ballAndPaddlesOffset];
        [self rotatePaddlesAccordingToOffset:ballAndPaddlesOffset];
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
    CGFloat angleToRotate = M_PI * proportionOfMaxOffset;
    
    leftPaddleView.transform = CGAffineTransformMakeRotation(angleToRotate);
    rightPaddleView.transform = CGAffineTransformMakeRotation(-angleToRotate);
}

- (void)offsetCoverAndGameViewBy:(CGFloat)offset
{
    if(offset > REFRESH_CONTROL_HEIGHT) {
        //This is here so we don't see any snap back on the top when the user releases.
        //It has to do with the scroll view scrolling and being animated at the same time.
        //Also, it's totally weird and will be changing soon.
        CGFloat offsetAndChange = offset + 100.0f;
        
        CGRect newFrame = self.frame;
        newFrame.size.height = offsetAndChange;
        newFrame.origin.y = -(offsetAndChange - REFRESH_CONTROL_HEIGHT);
        if(![self.scrollView isKindOfClass:[UITableView class]]) {
            newFrame.origin.y -= originalTopContentInset;
        }
        
        self.frame = newFrame;
        
        CGRect newGameViewFrame = gameView.frame;
        newGameViewFrame.origin.y = self.frame.size.height - gameView.frame.size.height;
        gameView.frame = newGameViewFrame;
    }
    
    coverView.center = CGPointMake(gameView.frame.size.width / 2.0f, (gameView.frame.size.height / 2.0f) - offset);
}

#pragma mark Letting go of the scroll view, checking for refresh trigger

- (void)scrollViewDidEndDragging
{
    if(state == BOZPongRefreshControlStateIdle) {
        if([self didUserScrollFarEnoughToTriggerRefresh]) {
            state = BOZPongRefreshControlStateRefreshing;
        
            [self beginLoading];
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

- (void)beginLoading
{
    [self animateScrollViewBackIntoPlaceWithRefreshControlShowing];
    [self startPong];
}

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
    
    coverView.center = CGPointMake(gameView.frame.size.width / 2.0f, gameView.frame.size.height / 2.0f);
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
    CGFloat destinationY = (float)(arc4random() % (int)gameView.frame.size.height);
    
    ballDestination = CGPointMake(destinationX, destinationY);
    ballDirection = CGPointMake((ballDestination.x - ballOrigin.x), (ballDestination.y - ballOrigin.y));
    ballDirection = [self normalizeVector:ballDirection];
}

#pragma mark Playing the game

#pragma mark Ball behavior

- (void)determineNextBallDestination
{
    CGFloat newBallDestinationX;
    CGFloat newBallDestinationY;
    
    ballDirection = [self determineReflectedDirectionOfBall];
    
    CGFloat verticalDistanceToNextWall = [self calculateVerticalDistanceFromBallToNextWall];
    CGFloat distanceToNextWall = verticalDistanceToNextWall / ballDirection.y;
    CGFloat horizontalDistanceToNextWall = distanceToNextWall * ballDirection.x;
    
    CGFloat horizontalDistanceToNextPaddle = [self calculateHorizontalDistanceFromBallToNextPaddle];
    
    if(fabs(horizontalDistanceToNextPaddle) < fabs(horizontalDistanceToNextWall)) {
        newBallDestinationX = ballDestination.x + horizontalDistanceToNextPaddle;
        
        CGFloat verticalDistanceToNextPaddle = fabs(horizontalDistanceToNextPaddle) * ballDirection.y;
        newBallDestinationY = ballDestination.y + verticalDistanceToNextPaddle;
    } else {
        newBallDestinationX = ballDestination.x + horizontalDistanceToNextWall;
        newBallDestinationY = ballDestination.y + verticalDistanceToNextWall;
    }
    
    ballOrigin = ballDestination;
    ballDestination = CGPointMake(newBallDestinationX, newBallDestinationY);
}

- (CGPoint)determineReflectedDirectionOfBall
{
    CGPoint reflectedBallDirection = ballDirection;
    
    if([self didBallHitWall]) {
        reflectedBallDirection =  CGPointMake(ballDirection.x, -ballDirection.y);
    } else if([self didBallHitPaddle]) {
        reflectedBallDirection =  CGPointMake(-ballDirection.x, ballDirection.y);
    }
    
    return reflectedBallDirection;
}

- (BOOL)didBallHitWall
{
    return ([self isFloat:ballDestination.y equalToFloat:[self ceilingContactY]] || [self isFloat:ballDestination.y equalToFloat:[self floorContactY]]);
}

- (BOOL)didBallHitPaddle
{
    return ([self isFloat:ballDestination.x equalToFloat:[self leftPaddleContactX]] || [self isFloat:ballDestination.x equalToFloat:[self rightPaddleContactX]]);
}

- (CGFloat)calculateVerticalDistanceFromBallToNextWall
{
    if(ballDirection.y > 0.0f) {
        return [self floorContactY] - ballDestination.y;
    } else {
        return [self ceilingContactY] - ballDestination.y;
    }
}

- (CGFloat)calculateHorizontalDistanceFromBallToNextPaddle
{
    if(ballDirection.x < 0.0f) {
        return [self leftPaddleContactX] - ballDestination.x;
    } else {
        return [self rightPaddleContactX] - ballDestination.x;
    }
}

#pragma mark Paddle behavior

- (void)determineNextPaddleDestinations
{
    static CGFloat lazySpeedFactor = 0.25f;
    static CGFloat normalSpeedFactor = 0.5f;
    static CGFloat holyCrapSpeedFactor = 1.0f;
    
    CGFloat leftPaddleVerticalDistanceToBallDestination = ballDestination.y - leftPaddleView.center.y;
    CGFloat rightPaddleVerticalDistanceToBallDestination = ballDestination.y - rightPaddleView.center.y;

    CGFloat leftPaddleOffset;
    CGFloat rightPaddleOffset;
    
    //Determining how far each paddle will mode
    if(ballDirection.x < 0.0f) {
        //Ball is going toward the left paddle

        if([self isBallDestinationIsTheLeftPaddle]) {
            leftPaddleOffset = (leftPaddleVerticalDistanceToBallDestination * holyCrapSpeedFactor);
            rightPaddleOffset = (rightPaddleVerticalDistanceToBallDestination * lazySpeedFactor);
        } else {
            //Destination is a wall
            leftPaddleOffset = (leftPaddleVerticalDistanceToBallDestination * normalSpeedFactor);
            rightPaddleOffset = -(rightPaddleVerticalDistanceToBallDestination * normalSpeedFactor);
        }
    } else {
        //Ball is going toward the right paddle
        
        if([self isBallDestinationIsTheRightPaddle]) {
            leftPaddleOffset = (leftPaddleVerticalDistanceToBallDestination * lazySpeedFactor);
            rightPaddleOffset = (rightPaddleVerticalDistanceToBallDestination * holyCrapSpeedFactor);
        } else {
            //Destination is a wall
            leftPaddleOffset = -(leftPaddleVerticalDistanceToBallDestination * normalSpeedFactor);
            rightPaddleOffset = (rightPaddleVerticalDistanceToBallDestination * normalSpeedFactor);
        }
    }
    
    leftPaddleDestination = leftPaddleView.center.y + leftPaddleOffset;
    rightPaddleDestination = rightPaddleView.center.y + rightPaddleOffset;

    [self capPaddleDestinationsToWalls];
}

- (BOOL)isBallDestinationIsTheLeftPaddle
{
    return ([self isFloat:ballDestination.x equalToFloat:[self leftPaddleContactX]]);
}

- (BOOL)isBallDestinationIsTheRightPaddle
{
    return ([self isFloat:ballDestination.x equalToFloat:[self rightPaddleContactX]]);
}

- (void)capPaddleDestinationsToWalls
{
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

#pragma mark Actually animating the balls and paddles to where they need to go

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
    return gameView.frame.size.height - (ballView.frame.size.height / 2.0f);
}

#pragma mark Paddle collisions

- (CGFloat)ceilingLeftPaddleContactY
{
    return (leftPaddleView.frame.size.height / 2.0f);
}

- (CGFloat)floorLeftPaddleContactY
{
    return gameView.frame.size.height - (leftPaddleView.frame.size.height / 2.0f);
}

- (CGFloat)ceilingRightPaddleContactY
{
    return (rightPaddleView.frame.size.height / 2.0f);
}

- (CGFloat)floorRightPaddleContactY
{
    return gameView.frame.size.height - (rightPaddleView.frame.size.height / 2.0f);
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
