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
#import "IBSideBarAction.h"

#import "TBXML.h"

/**
 * Action to launch a widget.
 */
@interface IBSideBarWidgetAction : IBSideBarAction

/**
 * Inits an action from <code><sideBarItem></code>  config element.
 */
+(instancetype)widgetActionFromXMLElement:(TBXMLElement *)element;

/**
 * Widget's uid as <code><func></code> from config.
 */
@property (nonatomic, assign) NSInteger uid;

@end
