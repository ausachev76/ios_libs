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

static NS_ENUM(NSInteger, IBSideBarModuleSystemActionType)
{
  IBSideBarModuleSystemActionTypeHome = 1,
  IBSideBarModuleSystemActionTypeFlag,
  IBSideBarModuleSystemActionTypeShare,
  IBSideBarModuleSystemActionTypeFavourite
};

/**
 * Module-specific action, e.g. opening shopping cart or saving an image.
 */
@interface IBSideBarModuleAction : IBSideBarAction

/**
 * Init with type as a member of <code>IBSideBarModuleSystemActionType</code> enum.
 */
-(instancetype)initWithModuleSystemAction:(enum IBSideBarModuleSystemActionType)actionType;

/**
 * Target for action, usually module's <code>self</code>.
 */
@property (nonatomic, assign) id target;

/**
 * Selector for action. Usually a method from <code>target</code>.
 */
@property (nonatomic, assign) SEL selector;

/**
 * Action type as a member of IBSideBarModuleSystemActionType enum.
 */
@property (nonatomic, assign) enum IBSideBarModuleSystemActionType actionType;

@end
