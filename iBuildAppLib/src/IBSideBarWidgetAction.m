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

#import "IBSideBarWidgetAction.h"
#import "notifications.h"

@implementation IBSideBarWidgetAction

+(instancetype)widgetActionFromXMLElement:(TBXMLElement *)element
{
  IBSideBarWidgetAction *action = [IBSideBarWidgetAction new];
  
  TBXMLElement *widgetNumElement = [TBXML childElementNamed:@"func" parentElement:element];
  if (widgetNumElement)
    action.uid = [[TBXML textForElement:widgetNumElement] integerValue];
  
  TBXMLElement *labelElement = [TBXML childElementNamed:@"label" parentElement:element];
  if (labelElement)
    action.label = [TBXML textForElement:labelElement];
  
  return action;
}

-(void)performAction
{
  [super performAction];
  
  if(self.selected)
  {
    return;
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:kAPP_NOTIFICATION_SIDEBAR_ITEM_TAP
                                                      object:[NSNumber numberWithInteger:self.uid]];
}

-(void)setUid:(NSInteger)uid
{
  if(_uid == uid)
  {
    return;
  }
  
  _uid = uid;
  
  [self.delegate sideBarActionHasBeenUpdated:self];
}

-(NSString *)debugDescription
{
  return [NSString stringWithFormat:@"%ld - %@ - %@", (long)self.uid, self.label, self.selected ? @"SELECTED" : @"NOT SELECTED"];
}

@end
