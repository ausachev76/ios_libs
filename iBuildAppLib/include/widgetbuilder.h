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

@class TWidgetData;
@class TWidget;
@class TURLImageDictionary;

@interface TWidgetBuilder : NSObject

+(NSArray *)createWidgets:(NSArray *)items;

+(void)setData:(TWidgetData *)items_
     forWidget:(TWidget *)widget_;

+(void)fillImageDictionary:(TURLImageDictionary *)imgDictionary_
               withWidgets:(NSArray *)items_;

/**
 * Recursively fills array of actions depending on the widgets_.
 *
 * @param actions_ - array of actions to fill.
 * @param widgets_ - array of widgets to analyze for actions.
 */
+(void)fillActionSet:(NSMutableSet *)actions_
         withWidgets:(NSArray *)widgets_;

@end
