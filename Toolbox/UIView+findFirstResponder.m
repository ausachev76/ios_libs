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

#import "UIView+findFirstResponder.h"
#import "NSObject+AssociatedObjects.h"

static void *kLockViewListAssociationKey = &kLockViewListAssociationKey;


@interface TFRLockViewState : NSObject
  @property(nonatomic, strong) UIView *view;
  @property(nonatomic, assign) BOOL    state;
  -(id)initWithView:(UIView *)view_;
@end

@implementation TFRLockViewState

+ (id)lockStateWithView:(UIView *)view_
{
  return [[[TFRLockViewState alloc] initWithView:view_] autorelease];
}

- (id)initWithView:(UIView *)view_
{
  self = [super init];
  if ( self )
  {
    _view = nil;
    self.view = view_;
    _state = view_.userInteractionEnabled;
  }
  return self;
}

- (id)init
{
  self = [super init];
  if ( self )
  {
    _view  = nil;
    _state = NO;
  }
  return self;
}

- (void)dealloc
{
  self.view = nil;
  [super dealloc];
}

@end



@implementation UIView (findFirstResponder)

- (UIView *)findFirstResponder
{
  // Search recursively for first responder
  for ( UIView *childView in self.subviews )
  {
    if ( [childView respondsToSelector:@selector(isFirstResponder)] &&
         [childView isFirstResponder] )
      return childView;
    UIView *result = [childView findFirstResponder];
    if ( result )
      return result;
  }
  return nil;
}


-(void)lockSubviewsExceptViews:(NSArray *)exclusionList_
{
  if ( ![exclusionList_ count] )
    return;
  
  NSMutableArray *lockViewList = [[NSMutableArray alloc] init];
  
  UIView *currentView = [exclusionList_ firstObject];
  while( currentView != self )
  {
    currentView = [currentView superview];
    for ( UIView *childView in [currentView subviews] )
    {
      if ( ![exclusionList_ containsObject:childView] )
      {
        [lockViewList addObject:[TFRLockViewState lockStateWithView:childView]];
        childView.userInteractionEnabled = NO;
      }
    }
  }
  // store lock view array
  [self associateValue:[NSArray arrayWithArray:lockViewList]
               withKey:kLockViewListAssociationKey];
  [lockViewList release];
}


-(void)lockSubviewsExceptView:(UIView *)firstResponderView_
{
  if ( !firstResponderView_ )
    return;
  
  NSMutableArray *lockViewList = [[NSMutableArray alloc] init];
  
  UIView *currentView = firstResponderView_;
  while( currentView != self )
  {
    UIView *thisView = currentView;
    currentView = [currentView superview];
    
    for ( UIView *childView in [currentView subviews] )
    {
      if ( childView != thisView )
      {
        [lockViewList addObject:[TFRLockViewState lockStateWithView:childView]];
        childView.userInteractionEnabled = NO;
      }
    }
  }
  // store lock view array
  [self associateValue:[NSArray arrayWithArray:lockViewList]
               withKey:kLockViewListAssociationKey];
  [lockViewList release];
}

-(void)unlockSubviews
{
  NSArray *lockViewList = [self associatedValueForKey:kLockViewListAssociationKey];
  for ( TFRLockViewState *viewState in lockViewList )
    [viewState.view setUserInteractionEnabled:viewState.state];
  
  // release lock view array
  [self associateValue:nil
               withKey:kLockViewListAssociationKey];
}

@end
