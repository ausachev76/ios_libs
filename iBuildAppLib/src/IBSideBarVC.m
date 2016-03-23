/****************************************************************************
 *                                                                           *
 *  Copyright (C) 2014-2015 iBuildApp, Inc. ( http://ibuildapp.com )         *
 *                                                                           *
 *  This file is part of iBuildApp.                                          *
 *                                                                           *
 *  This Source Code Form is subject to the terms of the iBuildApp License.  *
 *  You can obtain one at http://ibuildapp.com/license/                      *
 *                                                                           *
 ****************************************************************************/

#import "IBSideBarVC.h"

#import <MessageUI/MessageUI.h>
#import "appbuilderappconfig.h"

#ifdef IBUILDAPP_BUSINESS_APP
#import "buisinessapp.h"
#import "mBAModuleSideBarActionHandler.h"
#endif

#define kHiddenViewWidth kSideBarWidth
#define kVelocityShowThreshold 120.0f
#define kDiffXShowThreshold 60.0f
#define kSwipeThreshold 1000.0f

#define kSideBarDefaultAnimationDuration 1.0f
#define kSideBarOpeningRatio (1.0f / 4.0f)
#define kSideBarClosingRatio (2.0f / 3.0f)

NS_ENUM(NSInteger, IBSideBarPanDirection)
{
  IBSideBarPanNone,
  IBSideBarPanLeft,
  IBSideBarPanRight
};

@interface IBSideBarVC ()<MFMailComposeViewControllerDelegate>
{
  CGFloat currentX; // used for calculating distance finger moved on
  enum IBSideBarPanDirection currentDirection;
  
  BOOL togglingInProgress;
}

@property (nonatomic, retain) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic, assign, readwrite) enum IBSideBarToggledState toggledState;

@end

@implementation IBSideBarVC

- (instancetype) init
{
  self = [super init];
  
  if(self){
    [self setup];
  }
  return self;
}

-(void)setup
{
  _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
  _toggledState = IBSideBarToggledCenterView;
  
  togglingInProgress = NO;
  
  _openingDuration = kSideBarDefaultAnimationDuration;
  _closingDuration = kSideBarDefaultAnimationDuration;
  
  _swipeEnabled = YES;
  _panEnabled = YES;
  
  currentX = -1.0f;
}

+(IBSideBarVC *)appWideSideBar
{
  static IBSideBarVC *appWideSideBar = nil;
  
  static dispatch_once_t onceToken = 0;
  
  dispatch_once(&onceToken, ^{
    appWideSideBar = [[IBSideBarVC alloc] init];
  });
  
  return appWideSideBar;
}

-(void)dealloc
{
  self.leftViewController = nil;
  self.centerViewController = nil;
  self.rightViewController = nil;
  
  self.panGestureRecognizer = nil;
  
  [super dealloc];
}

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = [UIColor blackColor];
  
  [self.view addSubview:self.centerView];
  
  [self.view insertSubview:self.rightView belowSubview:self.centerView];
  [self.view insertSubview:self.leftView belowSubview:self.centerView];
}

#pragma mark - Drag & swipe handling
/**
 * Method to move centerView by pan, hiding and showing left/right views accordingly.
 */
- (void)handlePan:(UIPanGestureRecognizer*) gestureRecognizer
{
  if(!self.leftView && !self.rightView)
  {
    return;
  }
  
  if(!self.swipeEnabled && !self.panEnabled)
  {
    return;
  }
  
  CGFloat x = [gestureRecognizer locationInView:self.view].x;
  
  CGPoint velocity = [gestureRecognizer velocityInView:self.view];
  
  togglingInProgress = YES;
  
  // init distance first point
  // prevents first drag distance to be 273 pts or similar big value
  if(x != currentX)
  {
    if(currentX == -1)
    {
      currentX = x;
      return;
    }
    
    BOOL overdrag = [self handleOverdragForX:x
                                withVelocity:velocity];
    
    if(overdrag)
    {
      return;
    }

    CGPoint newOrigin = [self newCenterViewOriginForX:x
                                         withVelocity:velocity];
    
    [self hanldeViewsHiddenStateForCenterViewOrigin:newOrigin];
    
    if(self.panEnabled)
    {
      [self setCenterViewOrigin:newOrigin
                       animated:NO
                     completion:nil];
    }
    
    currentX = x;
  }

  //Swipe handling
  if(gestureRecognizer.state == UIGestureRecognizerStateRecognized ||
     gestureRecognizer.state == UIGestureRecognizerStateEnded ||
     gestureRecognizer.state == UIGestureRecognizerStateCancelled ||
     gestureRecognizer.state == UIGestureRecognizerStateFailed)
  {
    currentX = -1.0f;
    
    //Toggle views with swipe
    if(fabs(velocity.x) > kSwipeThreshold)
    {
      if(self.swipeEnabled)
      {
        [self handleSwipe:currentDirection];
      }
      
      return;
    }
    
    // after drag completes, do not leave side bar in an indetermined state
    [self completeTransitionForDirection:currentDirection];
  }
}

/**
 * Method to set the origin of a a center view.
 */
-(void)setCenterViewOrigin:(CGPoint)origin
                  animated:(BOOL)animated
                completion:(void (^)(BOOL finished))completion
{
  CGRect centerViewFrame = self.centerView.frame;
  CGFloat diffX = fabs(centerViewFrame.origin.x - origin.x);
  
  CGPoint oldOrigin = centerViewFrame.origin;
  
  centerViewFrame.origin = origin;
  
  void(^completionCopy)(BOOL finished) = [completion copy];
  
  NSTimeInterval duration = animated ? [self animationDuration] : 0.0f;
  
  [UIView animateWithDuration:duration
                        delay:0.0f
                      options:UIViewAnimationOptionCurveEaseOut
                   animations:^{
                     
                     [self notifyWillChangeOriginFrom:oldOrigin to:origin];
                     
                     self.centerView.frame = centerViewFrame;
                   }
                   completion:^(BOOL finished) {
                     if(completionCopy)
                     {
                       completionCopy(finished);
                     }
                     
                     [self notifyDidChangeOriginFrom:oldOrigin to:origin];
                   }];
  
  togglingInProgress = NO;
}

/**
 * Method to show/hide auxiliary views when moving centerView.
 * The problem is, left/right views may be wider than (screen width / 2) overlapping each other.
 * this method is intended to prevent it.
 */
-(void)hanldeViewsHiddenStateForCenterViewOrigin:(CGPoint)newCenterViewOrigin
{
  BOOL leftViewHidden = newCenterViewOrigin.x <= 0.0f;
  BOOL rightViewHidden = newCenterViewOrigin.x >= 0.0f;
  
  self.leftView.hidden = leftViewHidden;
  self.rightView.hidden = rightViewHidden;
}

/**
 * Method letting user to pan the center view only in bounds of available space of
 * leftView width + centerView width + reightViewWidth.
 */
-(BOOL)handleOverdragForX:(CGFloat)x withVelocity:(CGPoint)velocity
{
  //prevents from dragging over the screen bounds
  //without this thing view dribbled hard on drags
  //in clear toggledStates
  if(self.centerView.frame.origin.x == [self maxOriginX])
  {
    if(velocity.x > 0){
      return YES;
    }
    if(currentX < x){
      currentX = x;
      return YES;
    }
  }
  else if (self.centerView.frame.origin.x == [self minOriginX])
  {
    if (velocity.x < 0){
      return YES;
    }
    if(currentX > x){
      currentX = x;
      return YES;
    }
  }
  
  return NO;
}

/**
 * Method to calculate new center view origin position while panning.
 */
-(CGPoint)newCenterViewOriginForX:(CGFloat)x withVelocity:(CGPoint)velocity
{
  CGFloat panDiffX = x - currentX;
  
  currentDirection = panDiffX > 0 ? IBSideBarPanRight : IBSideBarPanLeft;
  
  // moves sidebar by finger drag
  // no far than underlying views
  if(self.centerView.frame.origin.x <= [self maxOriginX] &&
     self.centerView.frame.origin.x >= [self minOriginX])
  {
    CGFloat availableSpaceX = 0.0f;
    
    if(currentDirection == IBSideBarPanLeft)
    {
      availableSpaceX = [self minOriginX] - self.centerView.frame.origin.x;
      if(panDiffX < availableSpaceX)
      {
        panDiffX = availableSpaceX;
      }
    }
    else if(currentDirection == IBSideBarPanRight)
    {
      
      availableSpaceX = [self maxOriginX] - self.centerView.frame.origin.x;
      
      if(panDiffX > availableSpaceX)
      {
        panDiffX = availableSpaceX;
      }
    }
  }
  
  CGPoint newOrigin = self.centerView.frame.origin;
  newOrigin.x += panDiffX;
  
  return newOrigin;
}

/**
 * Method to detect and handle situations when pan is acting like swipe.
 */
-(void)handleSwipe:(enum IBSideBarPanDirection)direction
{
  if(self.toggledState == IBSideBarToggledLeftView)
  {
    if(direction == IBSideBarPanLeft)
    { // swiped left <---
      [self toggleCenterViewAnimated:YES completion:nil];
    } else if(direction == IBSideBarPanRight)
    {
      [self toggleLeftViewAnimated:YES completion:nil];
    }
  }
  
  else if(self.toggledState == IBSideBarToggledCenterView)
  {
    if(direction == IBSideBarPanRight)
    { // swiped right --->
      [self toggleLeftViewAnimated:YES completion:nil];
    }
    if(direction == IBSideBarPanLeft)
    { // swiped left <---
      [self toggleRightViewAnimated:YES completion:nil];
    }
  }
  
  if(self.toggledState == IBSideBarToggledRightView)
  {
    if(direction == IBSideBarPanRight)
    { // swiped right -->
      [self toggleCenterViewAnimated:YES completion:nil];
    } else if(direction == IBSideBarPanLeft)
    {
      [self toggleRightViewAnimated:YES completion:nil];
    }
  }
}

/**
 * Method to implement 'sticky' side bar behavior.
 * When pan gesture ends, we do not leave the center view in indetermined state.
 * When side view is opened wide enough, we expand it.
 * When closed enough - collapse it.
 */
-(void)completeTransitionForDirection:(enum IBSideBarPanDirection)direction
{
  CGFloat originX = self.centerView.frame.origin.x;
  
  switch(self.toggledState)
  {
    case IBSideBarToggledLeftView:
    {
      CGFloat leftViewClosingThreshold = self.leftView.bounds.size.width * kSideBarClosingRatio;
      if(originX <= leftViewClosingThreshold)
      {
        [self toggleCenterViewAnimated:YES completion:nil];
        return;
      }
      [self toggleLeftViewAnimated:YES completion:nil];
      break;
    }
    
    default:
    case IBSideBarToggledCenterView:
    {
      if(direction == IBSideBarPanRight) // --->
      {
        CGFloat leftViewOpeningThreshold = self.leftView.bounds.size.width * kSideBarOpeningRatio;
        if(originX >= leftViewOpeningThreshold)
        {
          [self toggleLeftViewAnimated:YES completion:nil];
          
          return;
        }
      } else if(direction == IBSideBarPanLeft) // <---
      {
        CGFloat rightViewOpeningThreshold = 0.0f - self.rightView.bounds.size.width * kSideBarOpeningRatio;
        
        if(originX <= rightViewOpeningThreshold)
        {
          [self toggleRightViewAnimated:YES completion:nil];
          
          return;
        }
      }
      
      [self toggleCenterViewAnimated:YES completion:nil];
      break;
    }
      
    case IBSideBarToggledRightView:
    {
      CGFloat rightViewClosingThreshold = 0 - self.rightView.bounds.size.width * kSideBarClosingRatio;
      if(originX >= rightViewClosingThreshold)
      {
        [self toggleCenterViewAnimated:YES completion:nil];
        return;
      }
      
      [self toggleRightViewAnimated:YES completion:nil];
      break;
    }
  }
}

#pragma mark - Opening / closing side views.
/**
 * Method to open left view, if it is not opened, 
 * or to close - otherwise.
 */
-(void)toggleLeftViewAnimated:(BOOL)animated completion:(void (^)())completion
{
  if(!self.leftView)
  {
    return;
  }
  
  if(self.toggledState == IBSideBarToggledLeftView &&
     !togglingInProgress)
  {
    [self toggleCenterViewAnimated:animated completion:completion];
    return;
  }
  
  CGPoint newOrigin = self.centerView.frame.origin;
  newOrigin.x = self.leftView.bounds.size.width;
  
  [self hanldeViewsHiddenStateForCenterViewOrigin:newOrigin];

  void(^completionCopy)() = [completion copy];
  
  [self setCenterViewOrigin:newOrigin
                   animated:animated
                 completion:^(BOOL finished) {
                   if(completionCopy)
                   {
                     completionCopy();
                     [completionCopy release];
                   }
                   
                   self.toggledState = IBSideBarToggledLeftView;
                   [self notifyDidToggleState:self.toggledState];
                 }];
}

/**
 * Method to close any side view and show center view.
 */
-(void)toggleCenterViewAnimated:(BOOL)animated completion:(void (^)())completion
{
  if(!self.centerView)
  {
    return;
  }
  
  CGPoint newOrigin = self.centerView.frame.origin;
  newOrigin.x = 0.0f;

  void(^completionCopy)() = [completion copy];
  
  [self setCenterViewOrigin:newOrigin
                   animated:animated
                 completion:^(BOOL finished) {
                   if(completionCopy)
                   {
                     completionCopy();
                     [completionCopy release];
                   }
                   
                   [self hanldeViewsHiddenStateForCenterViewOrigin:newOrigin];

                   self.toggledState = IBSideBarToggledCenterView;
                   [self notifyDidToggleState:self.toggledState];
                 }];
}

/**
 * Method to open right view, if it is not opened,
 * or to close - otherwise.
 */
-(void)toggleRightViewAnimated:(BOOL)animated completion:(void (^)())completion
{
  if(!self.rightView)
  {
    return;
  }
  
  if(self.toggledState == IBSideBarToggledRightView &&
     !togglingInProgress)
  {
    [self toggleCenterViewAnimated:animated completion:completion];
    return;
  }
  
  CGPoint newOrigin = self.centerView.frame.origin;
  newOrigin.x = 0.0f - self.rightView.bounds.size.width;
  
  [self hanldeViewsHiddenStateForCenterViewOrigin:newOrigin];
  
  void(^completionCopy)() = [completion copy];
  
  [self setCenterViewOrigin:newOrigin
                   animated:animated
                 completion:^(BOOL finished) {
                   if(completionCopy)
                   {
                     completionCopy();
                     [completionCopy release];
                   }
                   
                   self.toggledState = IBSideBarToggledRightView;
                   [self notifyDidToggleState:self.toggledState];
                 }];
}

#pragma mark - Side controller setters.
-(void)setLeftViewController:(UIViewController *)leftViewController
{
  if(_leftViewController != leftViewController)
  {
    [self.leftView removeFromSuperview];
    
    [_leftViewController release];
    [leftViewController retain];
    
    _leftViewController = leftViewController;
    
    [self repositionLeftView];
    
    if(self.centerView)
    {
      [self.view insertSubview:self.leftView belowSubview:self.centerView];
    } else
    {
      [self.view addSubview:self.leftView];
    }
    
  } else {
    [self repositionLeftView];
  }
}

-(void)setCenterViewController:(UIViewController *)centerViewController
{
  if(_centerViewController != centerViewController)
  {
    [self.centerView removeFromSuperview];
    
    [_centerViewController release];
    [centerViewController retain];
    
    _centerViewController = centerViewController;
    
    [self.view addSubview:self.centerView];
    
    [self.view bringSubviewToFront:self.centerView];
    
    [self enablePan];
    
    [self hanldeViewsHiddenStateForCenterViewOrigin:self.centerView.frame.origin];
  }
}

-(void)setRightViewController:(UIViewController *)rightViewController
{
  if(_rightViewController != rightViewController)
  {
    [self.rightView removeFromSuperview];
    
    [_rightViewController release];
    [rightViewController retain];
    
    _rightViewController = rightViewController;
    
    [self repositionRightView];
    
    if(self.centerView)
    {
      [self.view insertSubview:self.rightView belowSubview:self.centerView];
    } else
    {
      [self.view addSubview:self.rightView];
    }
    
  } else {
    [self repositionRightView];
  }
}

#pragma mark -
-(void)enablePan
{
  //self.view?
  [self.centerView addGestureRecognizer:self.panGestureRecognizer];
}

-(void)repositionLeftView
{
  CGRect newLeftViewFrame = self.leftView.frame;
  newLeftViewFrame.origin.x = 0.0f;
  
  self.leftView.frame = newLeftViewFrame;
}

-(void)repositionRightView
{
  CGFloat originX = CGRectGetMaxX(self.view.bounds) - self.rightView.frame.size.width;
  
  CGRect newRightViewFrame = self.rightView.frame;
  newRightViewFrame.origin.x = originX;
  
  self.rightView.frame = newRightViewFrame;
}

#pragma mark - Views for controllers.
-(UIView *)leftView
{
  return _leftViewController.view;
}

-(UIView *)centerView
{
  return _centerViewController.view;
}

-(UIView *)rightView
{
  return _rightViewController.view;
}

#pragma mark - Pan bounds indicators.
-(CGFloat)minOriginX
{
  return -(self.rightView.frame.size.width);
}

-(CGFloat)maxOriginX
{
  return CGRectGetMaxX(self.leftView.frame);
}

-(NSTimeInterval)animationDuration
{
  NSTimeInterval animationDuration = kSideBarDefaultAnimationDuration;
  
  if(self.toggledState == IBSideBarToggledCenterView)
  {
    animationDuration = self.openingDuration;
  }
  else
  {
    animationDuration = self.closingDuration;
  }
  
  return animationDuration;
}

#pragma mark - IBSideBar delegate helpers
-(void)notifyWillChangeOriginFrom:(CGPoint)from to:(CGPoint)to
{
  if([self.delegate respondsToSelector:@selector(sideBar:willChangeCenterViewOriginFrom:to:)])
  {
    [self.delegate sideBar:self willChangeCenterViewOriginFrom:from to:to];
  }
}

-(void)notifyDidChangeOriginFrom:(CGPoint)from to:(CGPoint)to
{
  if([self.delegate respondsToSelector:@selector(sideBar:didChangeCenterViewOriginFrom:to:)])
  {
    [self.delegate sideBar:self didChangeCenterViewOriginFrom:from to:to];
  }
}

-(void)notifyWillToggleState:(enum IBSideBarToggledState)toggledState
{
  if([self.delegate respondsToSelector:@selector(sideBar:willToggleState:)])
  {
    [self.delegate sideBar:self willToggleState:toggledState];
  }
}

-(void)notifyDidToggleState:(enum IBSideBarToggledState)toggledState
{
  if([self.delegate respondsToSelector:@selector(sideBar:didToggleState:)])
  {
    [self.delegate sideBar:self didToggleState:toggledState];
  }
}

#pragma mark -
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [self.centerViewController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (BOOL)shouldAutorotate
{
  return [self.centerViewController shouldAutorotate];
}

-(enum UIInterfaceOrientationMask)supportedInterfaceOrientations
{
  return [self.centerViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return [self.centerViewController preferredInterfaceOrientationForPresentation];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [self toggleCenterViewAnimated:NO completion:nil];
  
  [self.centerViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self.rightViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self.leftViewController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];

  [super willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
  
  [self.centerViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  [self.rightViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
  [self.leftViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];

  [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
                                         duration:(NSTimeInterval)duration
{

  [self.centerViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation
                                                              duration:duration];
  
  [self.rightViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation
                                                             duration:duration];
  
  [self.leftViewController willAnimateRotationToInterfaceOrientation:toInterfaceOrientation
                                                            duration:duration];

  [super willAnimateRotationToInterfaceOrientation:toInterfaceOrientation
                                          duration:duration];
}

- (void)willAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
  [self.centerViewController willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self.rightViewController willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
  [self.leftViewController willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];

  [super willAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation duration:duration];
}

- (void)didAnimateFirstHalfOfRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  [self.centerViewController didAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation];
  [self.rightViewController didAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation];
  [self.leftViewController didAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation];

  [super didAnimateFirstHalfOfRotationToInterfaceOrientation:toInterfaceOrientation];
}

- (void)willAnimateSecondHalfOfRotationFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation duration:(NSTimeInterval)duration
{
  [self.centerViewController willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];
  [self.rightViewController willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];
  [self.leftViewController willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];

  [super willAnimateSecondHalfOfRotationFromInterfaceOrientation:fromInterfaceOrientation duration:duration];
}

#ifdef IBUILDAPP_BUSINESS_APP
- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)composeResult
                        error:(NSError *)error;
{
#ifdef MASTERAPP_STATISTICS
  if (composeResult == MFMailComposeResultSent)
  {
    NSInteger curAppId = [[mBAModuleSideBarActionHandler sharedInstance] curAppId];
    [[BuisinessApp analyticsManager] logSharingByEmailWithAppId:curAppId];
  }
#endif
  [self dismissViewControllerAnimated:YES completion:nil];
}
#endif

@end
