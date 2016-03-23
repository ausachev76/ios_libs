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

@class IBSideBarAction;

/**
 * Custom UITableViewCell to display an action in side bar action list controller
 *
 * @see IBSideBarActionListViewController
 */
@interface IBSideBarTableViewCell : UITableViewCell

/**
 * Action to display in a cell
 */
@property (nonatomic, strong) IBSideBarAction *action;

/**
 * Whether a cell should show a separator on the bottom.
 * Use it to delimit module actions from default actions.
 */
@property (nonatomic, assign) BOOL shouldShowSeparator;

/**
 * Cell height for a given action.
 */
+(CGFloat)heightForSideBarAction:(IBSideBarAction *)item;

@end
