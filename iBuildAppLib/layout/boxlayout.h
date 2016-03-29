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

#import <UIKit/UIKit.h>
#import "widget.h"

@interface TBoxLayoutData : TWidgetData

/**
 * Array of TWidgetData elements inside the container.
 */
@property (nonatomic, retain) NSArray *items;

-(void)parseXMLitems:(TBXMLElement *)item_
      withAttributes:(NSDictionary *)attributes_;

@end

/**
 * TBoxLayout - base class for container objects, used to laying out and
 * grouping UI elements. Inherits TWidget.
 */
@interface TBoxLayout : TWidget

-(id)initWithParams:(TBoxLayoutData *)params_;

/**
 * Adds widget to container
 *
 * @param widget_ - object of type TWidget
 */
-(void)addWidget:(TWidget *)widget_;

/**
 * Removes widget from container
 *
 * @param widget_ - object to remove of type TWidget
 */
-(void)removeWidget:(TWidget *)widget_;

/**
 * Clears container from widgets.
 */
-(void)clear;

/**
 * Retreives widget by index.
 *
 * @param index - object to remove of type TWidget.
 *
 * @return object of type TWidget if object with this index exists. Otherwise - nil.
 */
-(TWidget *)widgetAtIndex:(NSUInteger)index;

@end
