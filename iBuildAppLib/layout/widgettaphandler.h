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
#import <UIKit/UIKit.h>

@class TWidgetAction;
/**
 * Widget's tap handler. There is UITapGestureRecognizer events hanling inside.
 */
@interface TWidgetTapHandler : NSObject

+(UIViewController *)createViewControllerWithName:(NSString *)moduleName_
                                          nibName:(NSString *)nibName_
                                           bundle:(NSString *)bundleName_;

+(UIViewController *)createModuleViewControllerWithName:(NSString *)moduleName_
                                              andParams:(NSDictionary *)moduleParams_;

+(BOOL)createAnimationForAction:(TWidgetAction *)action_
                       withView:(UIView *)view_
                       delegate:(id)delegate_;
@end
