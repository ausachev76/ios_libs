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
#import "SQLiteManager.h"//"SQLiteManager/SQLiteManager.h"

/**
 * Database manager to store confirmation requests which were failed to send and
 * therefore need to be resent.
 *
 * Used for PayPal confirmations that the app sends to the server and server then
 * resends them to the merchnt to validate.
 */
@interface IBPDBManager : SQLiteManager

/**
 * Returns a shared instance of a manager.
 */
+(instancetype)sharedInstance;

/**
 * Saves a POST body of a confirmation that needs to be resent.
 *
 * @param confirmation - confirmation's POST body.
 */
-(void)savePendingConfirmationPOSTBody:(NSString *)confirmation;

/**
 * Returns an array of confirmations (as string POST bodies) to be resent.
 */
-(NSArray *)selectPendingConfirmations;

/**
 * Deletes a confirmation with id specified.
 *
 * @param Id - id of the confirmation in DB.
 */
-(void)deletePendingConfirmationWithId:(NSString *)Id;

@end
