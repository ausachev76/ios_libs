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
#import "IBPItem.h"
#import "IBPCart.h"
#import "PayPalMobile.h"//"PayPalMobile/PayPalMobile.h"

typedef NS_ENUM(NSInteger, IBPaymentSystem)
{
  IBPaymentSystemPayPal
};

#ifndef IBP_PAYPAL
  #define IBP_PAYPAL
#endif

//#define IBP_PAYPAL_DEBUG

extern NSString* const IBPayPalPaymentCompleted;
extern NSString* const IBPayPalPaymentCancelled;
extern NSString* const IBPayPalPaymentIsNotProcessable;

/**
 * Wrapper for buying via PayPal.
 */
@interface IBPPayPalManager : NSObject<PayPalPaymentDelegate>

/**
 * Host View Controller to present native PayPal View Controller.
 */
@property (nonatomic, assign) UIViewController *presentingViewController;

/**
 * Id of a widget that asks for a payment.
 */
@property (nonatomic) NSInteger widgetId;

/**
 * Initializes PayPal SDK with PayPal client Id for Production environment.
 */
+(void)initializePayPalWithClientId:(NSString *)clientId;

/**
 * Tries to resent all available pending confirmations.
 */
+(void)sendPendingConfirmationsIfAny;

/**
 * Preconnect to PayPal. Try to do it a bit earlier than user clicks "Buy",
 * e.g. in viewDidLoad:.
 * This technique improves user expirience by eliminating "Loading..." dialog when user
 * makes a purchase.
 *
 * @see preconnectWithEnvironment: method in PayPal iOS SDK.
 */
-(void)preconnect;

/**
 * Opens a PayPal payment dialog with item payment info.
 *
 * @param item - item to purchase.
 */
-(void)buyWithPayPal:(IBPItem *)item;

/**
 * Opens a PayPal payment dialog with cart payment info.
 *
 * @param cart - cart to checkout.
 */
-(void)checkoutCartWithPayPal:(IBPCart *)cart;

@end
