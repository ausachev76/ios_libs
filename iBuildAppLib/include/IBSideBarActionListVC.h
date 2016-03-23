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
#import "IBSideBarAction.h"

@class IBSideBarWidgetAction;

/**
 * Controller to display list of actions available in sidebar.
 */
@interface IBSideBarActionListViewController : UIViewController<UITableViewDelegate,
                                                                UITableViewDataSource,
                                                                IBSideBarActionDelegate>

/**
 * <code>IBSideBarActionListViewController</code> singleton.
 */
+(IBSideBarActionListViewController *)appWideActionListVC;

/**
 * Sets auxiliary actions like share or flag in masterapp.
 */
-(void)setServiceActions:(NSArray *)actions;

/**
 * Sets app-wide actions.
 */
-(void)setDefaultActions:(NSArray *)actions;

/**
 * Sets module-specific actions.
 */
-(void)setModuleActions:(NSArray *)actions;

/**
 * Clears module-specific actions.
 */
-(void)clearModuleActions;

/**
 * Clears service actions.
 */
-(void)clearServiceActions;

-(void)insertAction:(IBSideBarAction *)actionToInsert
        belowAction:(IBSideBarAction *)existentAction;

-(void)removeAction:(IBSideBarAction *)actionToRemove;

/**
 * IBSideBarActions currently available in side bar
 */
@property (nonatomic, readonly) NSMutableArray *actions;

/**
 * Whether the action list is enabled, i.e. has any actions to display.
 */
@property (nonatomic, assign, readonly) BOOL isEnabled;

/**
 * Sets provided <code>IBSideBarWidgetAction</code> as selected.
 * If <code>IBSideBarWidgetAction</code> object is not a member of side bar actions list, does nothing.
 * Also, sets <code>selectedWidgetActionUid</code> to <code>selectedWidgetAction.uid</code>.
 */
@property (nonatomic, retain) IBSideBarWidgetAction *selectedWidgetAction;

/**
 * Marks <code>IBSideBarWidgetAction</code> with uid <code>selectedWidgetActionUid</code> as selected.
 * If there is no <code>IBSideBarWidgetAction</code> with uid <code>selectedWidgetActionUid</code> in the list, does nothing.
 */
@property (nonatomic, assign) NSInteger selectedWidgetActionUid;

@end
