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

#import "IBPPayPalManager.h"
#import "IBPPayPalConfirmationManager.h"
#import "appbuilderappconfig.h"

#define kPayPalClientId @"<YOUR_TEST_ID>"

NSString* const IBPayPalPaymentCompleted = @"IBPayPalPaymentCompleted";
NSString* const IBPayPalPaymentCancelled = @"IBPayPalPaymentCancelled";
NSString* const IBPayPalPaymentIsNotProcessable = @"IBPayPalPaymentNotProcessable";

static IBPPayPalManager *sharedManager = nil;

@interface IBPPayPalManager ()

@property (nonatomic, strong) PayPalConfiguration *payPalConfiguration;
@property (nonatomic, strong) id<IBPPayable> currentPayable;

@end

@implementation IBPPayPalManager

-(instancetype)init
{
  self = [super init];
  
  if(self){
    _widgetId = 0;
    
    _currentPayable = nil;
    
    _payPalConfiguration = [[PayPalConfiguration alloc] init];
    _payPalConfiguration.acceptCreditCards = YES;
    _payPalConfiguration.payPalShippingAddressOption = PayPalShippingAddressOptionPayPal;
  }
  
  return self;
}

-(void)dealloc
{
  self.payPalConfiguration = nil;
  self.currentPayable = nil;
  
  [super dealloc];
}

+(void)initializePayPalWithClientId:(NSString *)clientId;
{
  [PayPalMobile initializeWithClientIdsForEnvironments:
   @{
#ifdef IBP_PAYPAL_DEBUG
     PayPalEnvironmentSandbox:clientId
#else
     PayPalEnvironmentProduction:clientId
#endif
     }];
}

+(instancetype)sharedPaymentsManager
{
  if(!sharedManager){
    sharedManager = [[IBPPayPalManager alloc] init];
  }
  
  return sharedManager;
}

-(void)preconnect
{
#ifdef IBP_PAYPAL_DEBUG
  [PayPalMobile preconnectWithEnvironment:PayPalEnvironmentSandbox];
#else
  [PayPalMobile preconnectWithEnvironment:PayPalEnvironmentProduction];
#endif
}

-(void)buyWithPayPal:(IBPItem *)item
{
  self.currentPayable = item;
  
  PayPalPayment *payment = [[[PayPalPayment alloc] init] autorelease];
  
  payment.amount = item.price;
  payment.currencyCode = item.currencyCode;
  payment.shortDescription = item.name;
  
  [self presentPaymentDialogForPayment:payment];
}

-(void)checkoutCartWithPayPal:(IBPCart *)cart
{
  self.currentPayable = cart;
  
  if(!cart.allItems.count)
  {
    NSLog(@"IBPPayPalManager: ERROR processing cart, cart is empty!");
    [self notifyPaymentIsNotProcessable];
    return;
  }
  
  PayPalPayment *payment = [[[PayPalPayment alloc] init] autorelease];
  NSMutableArray *ppItems = [NSMutableArray array];
  
  NSArray *cartItems = cart.allItems;
  
  NSMutableString *shortDescription = [NSMutableString string];
  
  static NSString *shortDescriptionDelimiter = @", ";
  
  for(IBPCartItem *cartItem in cartItems){
    IBPItem *ibpItem = cartItem.item;
    
    if(ibpItem.price.doubleValue > 0.0f){
      PayPalItem *ppItem = [PayPalItem itemWithName:ibpItem.shortDescription
                                       withQuantity:cartItem.count
                                          withPrice:ibpItem.price
                                       withCurrency:ibpItem.currencyCode
                                            withSku:nil];
      
      [shortDescription appendFormat:@"%@%@", ibpItem.name, shortDescriptionDelimiter];
      
      [ppItems addObject:ppItem];
      
    }
  }
  
  if(!ppItems.count)
  {
    //Simulate empty PayPal response for cart of zero-priced items
    //and send confirmation to IBA server to inform the merchant via email
    [[IBPPayPalConfirmationManager sharedInstance] sendConfirmation:@"{}"
                                                         forPayable:self.currentPayable
                                                         fromWidget:self.widgetId];
    [self notifyPaymentCompleted];
    
    return;
  }
  
  payment.amount = [PayPalItem totalPriceForItems:ppItems];
  payment.currencyCode = ((PayPalItem *)[ppItems firstObject]).currency;
  payment.shortDescription = [shortDescription substringWithRange:NSMakeRange(0, shortDescription.length - shortDescriptionDelimiter.length - 1)];
  payment.items = ppItems;
  
  [self presentPaymentDialogForPayment:payment];
}

-(void)presentPaymentDialogForPayment:(PayPalPayment *)payment
{
  payment.intent = PayPalPaymentIntentSale;
  
  if(!payment.processable){
    [self notifyPaymentIsNotProcessable];
    return;
  }
  
  PayPalPaymentViewController *payPalController = [[PayPalPaymentViewController alloc] initWithPayment:payment
                                                                                         configuration:self.payPalConfiguration
                                                                                              delegate:self];
  
  [self.presentingViewController presentViewController:payPalController animated:YES completion:nil];
}

-(void)payPalPaymentViewController:(PayPalPaymentViewController *)controller
                didCompletePayment:(PayPalPayment *)completedPayment
{
  NSLog(@"PayPal: Payment completed");
  
  [self verifyCompletedPayment:completedPayment];
  [self notifyPaymentCompleted];
  
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

-(void)payPalPaymentDidCancel:(PayPalPaymentViewController *)paymentViewController
{
  NSLog(@"PayPal: Payment cancelled");
  
  self.currentPayable = nil;
  
  [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
  
  [[NSNotificationCenter defaultCenter] postNotificationName:IBPayPalPaymentCancelled object:nil];
}

-(void)verifyCompletedPayment:(PayPalPayment *)payment
{
  NSData *confirmation = [NSJSONSerialization dataWithJSONObject:payment.confirmation
                                                         options:0
                                                           error:nil];
  
  NSString *confirmationString = [[[NSString alloc] initWithData:confirmation encoding:NSUTF8StringEncoding] autorelease];
  
  [[IBPPayPalConfirmationManager sharedInstance] sendConfirmation:confirmationString
                                                       forPayable:self.currentPayable
                                                       fromWidget:self.widgetId];
  self.currentPayable = nil;
}

+(void)sendPendingConfirmationsIfAny
{
  [[IBPPayPalConfirmationManager sharedInstance] sendPendingConfirmationsIfAny];
}

-(void)notifyPaymentIsNotProcessable
{
  [[NSNotificationCenter defaultCenter] postNotificationName:IBPayPalPaymentIsNotProcessable
                                                      object:self.currentPayable];
}

-(void)notifyPaymentCompleted
{
  [[NSNotificationCenter defaultCenter] postNotificationName:IBPayPalPaymentCompleted object:nil];
}

@end
