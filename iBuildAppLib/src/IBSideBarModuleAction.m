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

#import "IBSideBarModuleAction.h"

@implementation IBSideBarModuleAction

-(instancetype)initWithModuleSystemAction:(enum IBSideBarModuleSystemActionType)actionType
{
  self = [super init];
  
  if(self)
  {
    _actionType = actionType;
    [self setupForActionType:actionType];
  }
  
  return self;
}

-(void)setupForActionType:(enum IBSideBarModuleSystemActionType)actionType
{
  UIImage *iconImage = nil;
  UIImage *highlightedIconImage = nil;
  
  NSString *label = @"";
  
  switch (actionType) {
    case IBSideBarModuleSystemActionTypeHome:
    {
      iconImage = [UIImage imageNamed:@"home"];
      highlightedIconImage = iconImage;
      
      label = NSLocalizedString(@"masterApp_Home", @"Home");
    }
    break;
      
    case IBSideBarModuleSystemActionTypeFlag:
    {
      iconImage = [UIImage imageNamed:@"report"];
      highlightedIconImage = iconImage;
      
      label = NSLocalizedString(@"masterApp_FlagContent", @"Flag Content");
    }
    break;
      
    case IBSideBarModuleSystemActionTypeShare:
    {
      iconImage = [UIImage imageNamed:@"mBA_share"];
      highlightedIconImage = iconImage;
      
      label = NSLocalizedString(@"masterApp_Share", @"Share");
    }
    break;
      
    case IBSideBarModuleSystemActionTypeFavourite:
    {
      iconImage = [UIImage imageNamed:@"favorite"];
      highlightedIconImage = [UIImage imageNamed:@"favorite_on"];
      
      label = NSLocalizedString(@"masterApp_Favorite", @"Favorite";);
    }
    break;
  }
  
  self.iconImage = iconImage;
  self.highlightedIconImage = highlightedIconImage;
  self.label = label;
}

-(void)setTarget:(id)target
{
  if(target == _target)
  {
    return;
  }
  
  _target = target;
  
  [self.delegate sideBarActionHasBeenUpdated:self];
}

-(void)setSelector:(SEL)selector
{
  if(selector == _selector)
  {
    return;
  }
  
  _selector = selector;
  
  [self.delegate sideBarActionHasBeenUpdated:self];
}

-(void)performAction
{
  [super performAction];
  
  if(self.selected)
  {
    return;
  }
  
  if ([self.target respondsToSelector:self.selector]) {
    [self.target performSelector:self.selector];
  }
}

@end
