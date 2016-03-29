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
 * Proocol to notify whether an action was updated, i.e. label or enabled state changed.
 */
@protocol IBSideBarActionDelegate <NSObject>

/**
 * Notify whether an action was updated, e.g. label or enabled state changed.
 */
-(void)sideBarActionHasBeenUpdated:(IBSideBarAction *)action;

@end

/**
 * Abstract superclass for any action available for side bar.
 */
@interface IBSideBarAction : NSObject

/**
 * Action's name to show in actions list.
 */
@property (nonatomic, strong) NSString *label;

/**
 * Whether this action is currently launched.
 * Default is NO.
 */
@property (nonatomic, assign) BOOL selected;

/**
 * Whether this action is allowed to perform its action.
 * Default is <code>YES</code>.
 */
@property (nonatomic, assign) BOOL enabled;

/**
 * Whether this action was performed and it should indicate it with image.
 */
@property (nonatomic, assign) BOOL highlighted;

/**
 * Whether the sidebar should be closed when action cell is tapped.
 * Default is <code>YES</code>.
 */
@property (nonatomic, assign) BOOL closesSidebarWhenCalled;

/**
 * Prevents cell with action appear selected.
 * Default is <code>NO</code>.
 */
@property (nonatomic, assign) BOOL preventsSelection;

/**
 * IBSideBarActionDelegate instance.
 */
@property (nonatomic, assign) NSObject<IBSideBarActionDelegate> *delegate;

/**
 * Image, depicting the meaning of the action.
 */
@property (nonatomic, strong) UIImage *iconImage;

/**
 * Highlighted image, depicting the meaning of the action.
 */
@property (nonatomic, strong) UIImage *highlightedIconImage;

/**
 * Current image, depending on the action's highlighted state.
 */
@property (nonatomic, readonly) UIImage *currentIconImage;

/**
 * Custom view to display in a cell instead of the 'icon + label' combination.
 */
@property (nonatomic, strong) UIView *customView;

/**
 * Method for action to do its work.
 *
 * Must be reimplemented in subclasses.
 * Default implementation checks whether the action is currently launched, and if it is, quits.
 */
-(void)performAction;

@end
