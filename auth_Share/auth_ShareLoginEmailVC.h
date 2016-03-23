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
#import "auth_ShareLoginVC.h"

/**
 * View controller to perform a login with email for users registered on iBuildApp.
 */
@interface auth_ShareLoginEmailVC : UIViewController <UITextFieldDelegate,
                                              UITableViewDataSource,
                                              UITableViewDelegate>
/**
 * Application Id.
 */
@property (nonatomic, retain) NSString *appID;

/**
 * Module Id.
 */
@property (nonatomic, retain) NSString *moduleID;

@end