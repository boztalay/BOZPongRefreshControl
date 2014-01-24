//
//  BOZPongRefreshControl.m
//  Ben Oztalay
//
//  Created by Ben Oztalay on 11/22/13.
//  Copyright (c) 2013 Ben Oztalay. All rights reserved.
//
//  Version 1.0.0
//  https://www.github.com/boztalay/BOZPongRefreshControl
//

#import "BOZPongRefreshControl.h"

#define REFRESH_CONTROL_HEIGHT 65.0f
#define HALF_REFRESH_CONTROL_HEIGHT (REFRESH_CONTROL_HEIGHT / 2.0f)

#define DEFAULT_FOREGROUND_COLOR [UIColor whiteColor]
#define DEFAULT_BACKGROUND_COLOR [UIColor colorWithWhite:0.10f alpha:1.0f]

#define DEFAULT_TOTAL_HORIZONTAL_TRAVEL_TIME_FOR_BALL 0.75f

#define TRANSITION_ANIMATION_DURATION 0.2f

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
    
    CGFloat leftPaddleOrigin;
    CGFloat rightPaddleOrigin;
    CGFloat leftPaddleDestination;
    CGFloat rightPaddleDestination;

    UIView* gameView;
    
    NSDate* currentAnimationStartTime;
    CGFloat currentAnimationDuration;
}

@property (strong, nonatomic) UIScrollView* scrollView;
@property (strong, nonatomic) id refreshTarget;
@property (nonatomic) SEL refreshAction;
@property (nonatomic, readonly) CGFloat distanceScrolled;

@end

@implementation BOZPongRefreshControl

#pragma mark - Attaching a pong refresh control to a UIScrollView or UITableView

#pragma mark UITableView

+ (BOZPongRefreshControl*)attachToTableView:(UITableView*)tableView
                          withRefreshTarget:(id)refreshTarget
                           andRefreshAction:(SEL)refreshAction
{
    return [self attachToScrollView:tableView
                  withRefreshTarget:refreshTarget
                   andRefreshAction:refreshAction];
}

#pragma mark UIScrollView

+ (BOZPongRefreshControl*)attachToScrollView:(UIScrollView*)scrollView
                           withRefreshTarget:(id)refreshTarget
                            andRefreshAction:(SEL)refreshAction
{
    BOZPongRefreshControl* existingPongRefreshControl = [self findPongRefreshControlInScrollView:scrollView];
    if(existingPongRefreshControl != nil) {
        return existingPongRefreshControl;
    }
    
    //Initialized height to 0 to hide it
    BOZPongRefreshControl* pongRefreshControl = [[BOZPongRefreshControl alloc] initWithFrame:CGRectMake(0.0f, 0.0f, scrollView.frame.size.width, 0.0f)
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
        
        originalTopContentInset = scrollView.contentInset.top;
        
        [self setUpGameView];
        [self setUpGamePieceIdleOrigins];
        [self setUpPaddles];
        [self setUpBall];
        
        state = BOZPongRefreshControlStateIdle;
        
        self.foregroundColor = DEFAULT_FOREGROUND_COLOR;
        self.backgroundColor = DEFAULT_BACKGROUND_COLOR;
        
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleOrientationChange)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        
    }
    return self;
}

- (void)setUpGameView
{
    gameView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.frame.size.width, REFRESH_CONTROL_HEIGHT)];
    gameView.backgroundColor = [UIColor clearColor];
    [self addSubview:gameView];
}

- (void)setUpGamePieceIdleOrigins
{
    leftPaddleIdleOrigin = CGPointMake(gameView.frame.size.width * 0.25f, gameView.frame.size.height);
    rightPaddleIdleOrigin = CGPointMake(gameView.frame.size.width * 0.75f, gameView.frame.size.height);
    ballIdleOrigin = CGPointMake(gameView.frame.size.width * 0.50f, 0.0f);
}

- (void)setUpPaddles
{
    leftPaddleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 2.0f, 15.0f)];
    leftPaddleView.center = leftPaddleIdleOrigin;
    leftPaddleView.backgroundColor = self.foregroundColor;
    
    rightPaddleView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 2.0f, 15.0f)];
    rightPaddleView.center = rightPaddleIdleOrigin;
    rightPaddleView.backgroundColor = self.foregroundColor;
    
    [gameView addSubview:leftPaddleView];
    [gameView addSubview:rightPaddleView];
}

- (void)setUpBall
{
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

#pragma mark - Listening to scroll delegate events

#pragma mark Actively scrolling

- (void)scrollViewDidScroll
{
    CGFloat rawOffset = -self.distanceScrolled;
    
    [self offsetGameViewBy:rawOffset];
    
    if(state == BOZPongRefreshControlStateIdle) {
        CGFloat ballAndPaddlesOffset = MIN(rawOffset / 2.0f, HALF_REFRESH_CONTROL_HEIGHT);
        
        [self offsetBallAndPaddlesBy:ballAndPaddlesOffset];
        [self rotatePaddlesAccordingToOffset:ballAndPaddlesOffset];
    }
}

- (CGFloat)distanceScrolled
{
    return (self.scrollView.contentOffset.y + self.scrollView.contentInset.top);
}

- (void)offsetGameViewBy:(CGFloat)offset
{
    CGFloat offsetConsideringState = offset;
    if(state != BOZPongRefreshControlStateIdle) {
        offsetConsideringState += REFRESH_CONTROL_HEIGHT;
    }
    
    [self setHeightAndOffsetOfRefreshControl:offsetConsideringState];
    [self stickGameViewToBottomOfRefreshControl];
}

- (void)setHeightAndOffsetOfRefreshControl:(CGFloat)offset
{
    CGRect newFrame = self.frame;
    newFrame.size.height = offset;
    newFrame.origin.y = -offset;
    self.frame = newFrame;
}

- (void)stickGameViewToBottomOfRefreshControl
{
    CGRect newGameViewFrame = gameView.frame;
    newGameViewFrame.origin.y = self.frame.size.height - gameView.frame.size.height;
    gameView.frame = newGameViewFrame;
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

#pragma mark Letting go of the scroll view, checking for refresh trigger

- (void)scrollViewDidEndDragging
{
    if(state == BOZPongRefreshControlStateIdle) {
        if([self didUserScrollFarEnoughToTriggerRefresh]) {
            [self beginLoading];
            [self notifyTargetOfRefreshTrigger];
        }
    }
}

- (BOOL)didUserScrollFarEnoughToTriggerRefresh
{
    return (-self.distanceScrolled > REFRESH_CONTROL_HEIGHT);
}

- (void)notifyTargetOfRefreshTrigger
{
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    
    if ([self.refreshTarget respondsToSelector:self.refreshAction])
        [self.refreshTarget performSelector:self.refreshAction];
    
    #pragma clang diagnostic pop
}

#pragma mark - Manually starting a refresh

- (void)beginLoading
{
    [self beginLoadingAnimated:YES];
}

- (void)beginLoadingAnimated:(BOOL)animated
{
    if (state != BOZPongRefreshControlStateRefreshing) {
        state = BOZPongRefreshControlStateRefreshing;

        [self scrollRefreshControlToVisibleAnimated:animated];
        [self startPong];
    }
}

- (void)scrollRefreshControlToVisibleAnimated:(BOOL)animated
{
    CGFloat animationDuration = 0.0f;
    if(animated) {
        animationDuration = TRANSITION_ANIMATION_DURATION;
    }
    
    [UIView animateWithDuration:animationDuration animations:^(void) {
        UIEdgeInsets newInsets = self.scrollView.contentInset;
        newInsets.top = originalTopContentInset + REFRESH_CONTROL_HEIGHT;
        self.scrollView.contentInset = newInsets;
    }];
}

#pragma mark - Resetting after loading finished

- (void)finishedLoading
{
    if(state != BOZPongRefreshControlStateRefreshing) {
        return;
    }
    
    state = BOZPongRefreshControlStateResetting;
    
    [UIView animateWithDuration:TRANSITION_ANIMATION_DURATION animations:^(void)
     {
         [self resetScrollViewContentInsets];
         [self setHeightAndOffsetOfRefreshControl:0.0f];
     }
     completion:^(BOOL finished)
     {
         [self resetPaddlesAndBall];
         state = BOZPongRefreshControlStateIdle;
     }];
}

- (void)resetScrollViewContentInsets
{
    UIEdgeInsets newInsets = self.scrollView.contentInset;
    newInsets.top = originalTopContentInset;
    self.scrollView.contentInset = newInsets;
}

- (void)resetPaddlesAndBall
{
    [self removeAnimations];
    
    leftPaddleView.center = leftPaddleIdleOrigin;
    rightPaddleView.center = rightPaddleIdleOrigin;
    ballView.center = ballIdleOrigin;
}

- (void)removeAnimations
{
    [leftPaddleView.layer removeAllAnimations];
    [rightPaddleView.layer removeAllAnimations];
    [ballView.layer removeAllAnimations];
}

#pragma mark - Playing pong

#pragma mark Starting the game

- (void)startPong
{
    ballOrigin = ballView.center;
    leftPaddleOrigin = leftPaddleIdleOrigin.y;
    rightPaddleOrigin = rightPaddleIdleOrigin.y;
    
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

        if([self isBallDestinationTheLeftPaddle]) {
            leftPaddleOffset = (leftPaddleVerticalDistanceToBallDestination * holyCrapSpeedFactor);
            rightPaddleOffset = (rightPaddleVerticalDistanceToBallDestination * lazySpeedFactor);
        } else {
            //Destination is a wall
            leftPaddleOffset = (leftPaddleVerticalDistanceToBallDestination * normalSpeedFactor);
            rightPaddleOffset = -(rightPaddleVerticalDistanceToBallDestination * normalSpeedFactor);
        }
    } else {
        //Ball is going toward the right paddle
        
        if([self isBallDestinationTheRightPaddle]) {
            leftPaddleOffset = (leftPaddleVerticalDistanceToBallDestination * lazySpeedFactor);
            rightPaddleOffset = (rightPaddleVerticalDistanceToBallDestination * holyCrapSpeedFactor);
        } else {
            //Destination is a wall
            leftPaddleOffset = -(leftPaddleVerticalDistanceToBallDestination * normalSpeedFactor);
            rightPaddleOffset = (rightPaddleVerticalDistanceToBallDestination * normalSpeedFactor);
        }
    }
    leftPaddleOrigin = leftPaddleDestination;
    rightPaddleOrigin = rightPaddleDestination;
    leftPaddleDestination = leftPaddleView.center.y + leftPaddleOffset;
    rightPaddleDestination = rightPaddleView.center.y + rightPaddleOffset;

    [self capPaddleDestinationsToWalls];
}

- (BOOL)isBallDestinationTheLeftPaddle
{
    return ([self isFloat:ballDestination.x equalToFloat:[self leftPaddleContactX]]);
}

- (BOOL)isBallDestinationTheRightPaddle
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
    currentAnimationStartTime = [NSDate date];
    currentAnimationDuration = [self calculateAnimationDuration];
    
    [UIView animateWithDuration:currentAnimationDuration delay:0.0f options:UIViewAnimationOptionCurveLinear animations:^(void)
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

- (CGFloat)calculateAnimationDuration
{
    CGFloat endToEndDistance = [self rightPaddleContactX] - [self leftPaddleContactX];
    CGFloat proportionOfHorizontalDistanceLeftForBallToTravel = fabsf((ballDestination.x - ballOrigin.x) / endToEndDistance);
    return (self.totalHorizontalTravelTimeForBall * proportionOfHorizontalDistanceLeftForBallToTravel);
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

#pragma mark - Handling orientation changes

- (void)handleOrientationChange {
    self.frame = CGRectMake(0.0f, 0.0f, self.scrollView.frame.size.width, 0.0f);
    CGFloat gameViewWidthBeforeOrientationChange = gameView.frame.size.width;
    gameView.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, REFRESH_CONTROL_HEIGHT);
    
    originalTopContentInset = self.scrollView.contentInset.top;
    
    [self setUpGamePieceIdleOrigins];
    
    if(state == BOZPongRefreshControlStateRefreshing) {
        originalTopContentInset -= REFRESH_CONTROL_HEIGHT;
        [self setHeightAndOffsetOfRefreshControl:REFRESH_CONTROL_HEIGHT];
        
        [self removeAnimations];
        CGFloat horizontalScaleFactor = gameView.frame.size.width / gameViewWidthBeforeOrientationChange;
        [self setGamePiecePositionsForAnimationStop:horizontalScaleFactor];
        
        [self animateBallAndPaddlesToDestinations];
    } else {
        [self setGamePiecePositionsToIdle];
    }
}

- (void)setGamePiecePositionsForAnimationStop:(CGFloat)horizontalScaleFactor
{
    //Place the game pieces as though the animation got cut off
    
    CGFloat timeSinceCurrentAnimationStarted = -[currentAnimationStartTime timeIntervalSinceNow];
    CGFloat proportionOfCurrentAnimationCompleted = timeSinceCurrentAnimationStarted / currentAnimationDuration;
 
    CGPoint totalBallDisplacementForCurrentAnimation = CGPointMake(ballDestination.x - ballOrigin.x, ballDestination.y - ballOrigin.y);
    CGFloat totalLeftPaddleDisplacementForCurrentAnimation = leftPaddleDestination - leftPaddleOrigin;
    CGFloat totalRightPaddleDisplacementForCurrentAnimation = rightPaddleDestination - rightPaddleOrigin;
    
    ballView.center = CGPointMake(ballOrigin.x + (totalBallDisplacementForCurrentAnimation.x * proportionOfCurrentAnimationCompleted),
                                  ballOrigin.y + (totalBallDisplacementForCurrentAnimation.y * proportionOfCurrentAnimationCompleted));
    leftPaddleView.center = CGPointMake(leftPaddleView.center.x,
                                        leftPaddleOrigin + (totalLeftPaddleDisplacementForCurrentAnimation * proportionOfCurrentAnimationCompleted));
    rightPaddleView.center = CGPointMake(rightPaddleView.center.x,
                                         rightPaddleOrigin + (totalRightPaddleDisplacementForCurrentAnimation * proportionOfCurrentAnimationCompleted));
    
    ballOrigin = ballView.center;
    leftPaddleOrigin = leftPaddleView.center.y;
    rightPaddleOrigin = rightPaddleView.center.y;
    
    //Now scale everything for the change in horizontal distance
    
    leftPaddleView.center = CGPointMake(leftPaddleView.center.x * horizontalScaleFactor, leftPaddleView.center.y);
    rightPaddleView.center = CGPointMake(rightPaddleView.center.x * horizontalScaleFactor, rightPaddleView.center.y);
    
    ballView.center = CGPointMake(ballView.center.x * horizontalScaleFactor, ballView.center.y);
    ballOrigin = CGPointMake(ballOrigin.x * horizontalScaleFactor, ballOrigin.y);
    ballDestination = CGPointMake(ballDestination.x * horizontalScaleFactor, ballDestination.y);
    ballDirection = [self normalizeVector:CGPointMake(ballDirection.x * horizontalScaleFactor, ballDirection.y)];
}

- (void)setGamePiecePositionsToIdle
{
    leftPaddleView.center = leftPaddleIdleOrigin;
    rightPaddleView.center = rightPaddleIdleOrigin;
    ballView.center = ballIdleOrigin;
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
