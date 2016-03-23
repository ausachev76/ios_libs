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
 *  Class for realizing scenario "Tap to call"
 */
@interface TPhoneCaller : NSObject

/**
 *  Call number
 *
 *  @param num phone number
 */
-(void)callNumber:(NSString*)num;

/**
 *  Show alert with variants: call, add to address book, cancel
 *
 *  @param num         phone number
 *  @param contactName contact name
 */
-(void)callNumberOrAdd:(NSString*)num
             showAddTo:(NSString*)contactName;
@end
