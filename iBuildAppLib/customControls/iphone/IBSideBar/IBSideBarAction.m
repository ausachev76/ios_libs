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

#import "IBSideBarAction.h"

@implementation IBSideBarAction

-(instancetype)init
{
  self = [super init];
  
  if(self)
  {
    _selected = NO;
    _enabled = YES;
    _closesSidebarWhenCalled = YES;
  }
  
  return self;
}

-(void)dealloc
{
  self.label = nil;
  self.iconImage = nil;
  self.highlightedIconImage = nil;
  self.customView = nil;
  
  [super dealloc];
}

-(void)setLabel:(NSString *)label
{
  if(label == _label)
  {
    return;
  }

  [label retain];
  [_label release];
  
  _label = label;
  
  [self.delegate sideBarActionHasBeenUpdated:self];
}

-(void)setSelected:(BOOL)selected
{
  if(selected == _selected)
  {
    return;
  }
  
  _selected = selected;
  
  [self.delegate sideBarActionHasBeenUpdated:self];
}

-(void)setEnabled:(BOOL)enabled
{
  if(enabled == _enabled)
  {
    return;
  }
  
  _enabled = enabled;
  
  [self.delegate sideBarActionHasBeenUpdated:self];
}

-(UIImage *)highlightedIconImage
{
  if(!_highlightedIconImage)
  {
    return _iconImage;
  }
  
  return _highlightedIconImage;
}

-(UIImage *)currentIconImage
{
  if(self.highlighted)
  {
    return self.highlightedIconImage;
  }
  
  return self.iconImage;
}

-(void)performAction
{
  self.highlighted = !self.highlighted;
}

@end
