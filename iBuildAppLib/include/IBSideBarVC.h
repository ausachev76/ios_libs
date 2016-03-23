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

/**
 * State of a side bar, as a view currently presneted.
 */
static NS_ENUM(NSInteger, IBSideBarToggledState)
{
  IBSideBarToggledNone,
  IBSideBarToggledCenterView,
  IBSideBarToggledLeftView,
  IBSideBarToggledRightView
};

@class IBSideBarVC;

/**
 * Protocol to observe side bar's state and transitions at run time.
 */
@protocol IBSideBarDelegate

@optional
/**
 * Called when side bar's centerView is about to move to the new position.
 */
-(void)sideBar:(IBSideBarVC *)sideBar willChangeCenterViewOriginFrom:(CGPoint)from to:(CGPoint)to;

/**
 * Called when side bar's centerView has been already moved to the new position.
 */
-(void)sideBar:(IBSideBarVC *)sideBar didChangeCenterViewOriginFrom:(CGPoint)from to:(CGPoint)to;

/**
 * Called when side is about to transition to a new state.
 */
-(void)sideBar:(IBSideBarVC *)sideBar willToggleState:(enum IBSideBarToggledState)state;

/**
 * Called when side bar has transitioned to a new state.
 */
-(void)sideBar:(IBSideBarVC *)sideBar didToggleState:(enum IBSideBarToggledState)state;

@end


/**
 * Implementation for sidebar with main view, left and / or right views.
 * Supports panning and swipe.
 */
@interface IBSideBarVC : UIViewController

/**
 * Initializes a new instance.
 */
-(instancetype)init NS_DESIGNATED_INITIALIZER;

/**
 * Returns IBSideBarVC singleton.
 * This does not prevent you from using your own instances.
 */
+(IBSideBarVC *)appWideSideBar;


#pragma mark - Opening / closing side views
/**
 * Method to open left view, if it is not opened,
 * or to close - otherwise.
 */
-(void)toggleLeftViewAnimated:(BOOL)animated completion:(void(^)())completion;

/**
 * Method to close any side views and show a center view.
 */
-(void)toggleCenterViewAnimated:(BOOL)animated completion:(void(^)())completion;

/**
 * Method to open right view, if it is not opened,
 * or to close - otherwise.
 */
-(void)toggleRightViewAnimated:(BOOL)animated completion:(void(^)())completion;

/**
 * Сurrent state of a side bar, as a view currently presneted.
 */
@property (nonatomic, assign, readonly) enum IBSideBarToggledState toggledState;


#pragma mark - Child view controllers
/**
 * View controller, which view appears from the left.
 */
@property (nonatomic, retain) UIViewController *leftViewController;

/**
 * Main view controller, placed in center.
 */
@property (nonatomic, retain) UIViewController *centerViewController;

/**
 * View controller, which view appears from the right.
 */
@property (nonatomic, retain) UIViewController *rightViewController;


#pragma mark - Views from child view controllers
/**
 * View for leftViewController
 */
@property (nonatomic, readonly) UIView *leftView;

/**
 * View for centerViewController
 */
@property (nonatomic, readonly) UIView *centerView;

/**
 * View for rightViewController
 */
@property (nonatomic, readonly) UIView *rightView;

/**
 * Animation duration for side bar opening.
 */
@property (nonatomic, assign) NSTimeInterval openingDuration;

/**
 * Animation duration for side bar closing.
 */
@property (nonatomic, assign) NSTimeInterval closingDuration;

/**
 * Instance of IBSideBarDelegate.
 * @see IBSideBarDelegate
 */
@property (nonatomic, assign) NSObject<IBSideBarDelegate> *delegate;

/**
 * Whether side bar can respond for swipe.
 * Default is YES.
 */
@property (nonatomic, assign) BOOL swipeEnabled;

/**
 * Whether side bar can respond for pan.
 * Default is YES.
 */
@property (nonatomic, assign) BOOL panEnabled;

@end