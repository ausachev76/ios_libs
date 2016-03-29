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

#import <Foundation/Foundation.h>
#import "uiwidgets.h"

@interface uiLayoutItem : NSObject <NSCopying, NSCoding>
  @property ( nonatomic, assign ) NSInteger     pos;
  @property ( nonatomic, strong ) uiWidgetData *widget;
@end


@interface uiBoxLayout : uiWidgetData <NSCopying, NSCoding>
{
  NSMutableArray *m_subWidgets;
}

@property (nonatomic,readonly) NSMutableArray *subWidgets;

/**
 * Adds widget to container.
 * 
 * @param widget_ - TWidget to add.
 */
-(void)addWidget:(uiWidgetData *)widget_;

/**
 * Removes widget from container.
 *
 * @param widget_ - TWidget to remove.
 */
-(void)removeWidget:(uiWidgetData *)widget_;

/**
 * Removes several widgets from container.
 *
 * @param widgetList_ - NSArray of TWidget to remove.
 */
-(void)removeWidgets:(NSArray *)widgetList_;

/**
 * Removes widget with index from container.
 *
 * @param index - index of widget to remove.
 */
-(void)removeWidgetAtIndex:(NSInteger)index;

/**
 * Removes all widgets from container.
 */
-(void)clear;

/**
 * Adds widget to container.
 *
 * @param widgetList_ - NSArray of TWidget to add.
 */
-(void)insertWidgets:(NSArray *)widgetList;

/**
 * Retreives widget with index from container.
 *
 * @param index - index of TWidget to get.
 *
 * @return object of type uiWidgetData if index exists, nil - otherwise.
 */
-(uiWidgetData *)widgetAtIndex:(NSUInteger)index;

-(void)layoutWidgets:(CGRect)frame;

@end
