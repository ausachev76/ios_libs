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
#import "IBPPayable.h"

/**
 * Class for sending and resending PayPal confirmations to IBA server.
 */
@interface IBPPayPalConfirmationManager : NSObject

/**
 * Returns shared instance of IBPPayPalConfirmationManager.
 */
+(instancetype)sharedInstance;

/**
 * Sends PayPal confirmation to IBA server.
 *
 * @param confirmation - PayPay JSON response as NSString
 * @param item - payable for confirtaion
 * @param widgetId - id of a widget where the purchase was initiated.
 *
 * @see IBPPayable
 */
-(void)sendConfirmation:(NSString *)confirmation
             forPayable:(id<IBPPayable>)item
             fromWidget:(NSInteger)widgetId;

/**
 * Tries to resend PayPal all pending confirmation to IBA server.
 * Removes a successfully resent pending confirmation from DB.
 */
-(void)sendPendingConfirmationsIfAny;


@end
