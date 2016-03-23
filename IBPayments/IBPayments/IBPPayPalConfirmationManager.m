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

#import "IBPPayPalConfirmationManager.h"
#import "IBPDBManager.h"
#import "appbuilderappconfig.h"
#import "IBPCart.h"
#import "IBPItem.h"

#define kPaymentConfirmationParameterKey @"paypal_payment_confirmation"
#define kPaymentAppIdParameterKey @"app_id"
#define kPaymentWidgetIdParameterKey @"widget_id"

#define kPaymentConfirmationEndpoint @"/endpoint/payment.php"

static IBPPayPalConfirmationManager *sharedConfirmationManager = nil;

@implementation IBPPayPalConfirmationManager
{
  NSString *IBPayPalPaymentConfirmationEndpoint;
  NSString *IBPayPalPaymentConfirmationHost;
  NSOperationQueue *queue;
}

-(instancetype)init
{
  self = [super init];
  
  if(self){
    
    IBPayPalPaymentConfirmationHost = [[NSString stringWithFormat:@"http://%@",
                                       appIBuildAppHostName()] retain];
    
    IBPayPalPaymentConfirmationEndpoint = [[NSString stringWithFormat:@"%@%@",
                                           IBPayPalPaymentConfirmationHost,
                                            kPaymentConfirmationEndpoint] retain];
    
    queue = [[NSOperationQueue alloc] init];
  }
  
  return self;
}

+(instancetype)sharedInstance
{
  if(!sharedConfirmationManager)
  {
    sharedConfirmationManager = [[self alloc] init];
  }
  
  return sharedConfirmationManager;
}

-(void)dealloc
{
  if(queue){
    [queue release];
    queue = nil;
  }
  
  if(IBPayPalPaymentConfirmationEndpoint){
    [IBPayPalPaymentConfirmationEndpoint release];
    IBPayPalPaymentConfirmationEndpoint = nil;
  }
  
  if(IBPayPalPaymentConfirmationHost){
    [IBPayPalPaymentConfirmationHost release];
    IBPayPalPaymentConfirmationHost = nil;
  }
  
  [super dealloc];
}

-(void)sendConfirmation:(NSString *)confirmation
             forPayable:(id<IBPPayable>)item
             fromWidget:(NSInteger)widgetId
{
  static NSString* confirmationRequestParametersTemplate =
  @"paypal_payment_confirmation=%@&app_id=%@&widget_id=%ld&%@";
  
  NSString *postBodyString = [NSString stringWithFormat:confirmationRequestParametersTemplate,
                              [confirmation stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding],
                              appProjectID(),
                              widgetId,
                              [self itemsStringForPayable:item]
                              ];
  
  void (^saveIfFailed)(NSURLResponse *response, NSData *data, NSError *connectionError) =
  
  ^(NSURLResponse *response, NSData *data, NSError *connectionError){
    if(!connectionError && [(NSHTTPURLResponse*)response statusCode] == 200){
      NSLog(@"IBPayPalConfirmationManager: Confirmation successfully sent.");
    }
    else {
      NSLog(@"IBPayPalConfirmationManager: Confirmation sending error:\n%@\nConfirmation data saved.", [connectionError description]);
      [[IBPDBManager sharedInstance] savePendingConfirmationPOSTBody:postBodyString];
    }
  };
  
  [self sendConfirmation:postBodyString
              completion:saveIfFailed];
  
}

-(NSString *)itemsStringForPayable:(id<IBPPayable>)payable{
  
  NSString *result = nil;
  
  NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
  
  if([payable isKindOfClass:[IBPCart class]]){
    
    for(IBPCartItem *item in ((IBPCart *)payable).allItems){
      [jsonDict setObject:@(item.count) forKey:@(item.item.pid).stringValue];
    }
    
  } else if([payable isKindOfClass:[IBPItem class]]){
    IBPItem *item = (IBPItem *)payable;
    [jsonDict setObject:@(1) forKey:@(item.pid).stringValue];
  }
  
  NSError *error = nil;
  NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                     options:0
                                                       error:&error];
  
  if (error) {
    
    NSLog(@"IBP PayPal JSON Parsing error: %@", error);
    
  } else {
    
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    result = [NSString stringWithFormat:@"items=%@", [jsonString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  }
  
  return result;
}

-(void)sendConfirmation:(NSString *)confirmation
             completion:(void (^)(NSURLResponse *response, NSData *data, NSError *connectionError))completion
{
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:IBPayPalPaymentConfirmationEndpoint]
                                                         cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                     timeoutInterval:60.0f];
  
  NSData *postBodyData = [confirmation dataUsingEncoding:NSUTF8StringEncoding];
  
  [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postBodyData.length] forHTTPHeaderField:@"Content-Length"];
  
  [request setHTTPMethod:@"POST"];
  [request setHTTPBody:postBodyData];
  
  [NSURLConnection sendAsynchronousRequest:request
                                     queue:queue
                         completionHandler:completion];
}


-(void)sendPendingConfirmationsIfAny
{
  void (^resendBlock)() = ^{
    NSArray *confirmations = [[IBPDBManager sharedInstance] selectPendingConfirmations];
    
    if(!confirmations.count){
      return;
    }
    
    NSLog(@"IBPayPalConfirmationManager: resending %lu pending request(s)", (unsigned long)confirmations.count);
    
    for(NSDictionary *confirmation in confirmations){
      
      NSString *Id = confirmation[@"Id"];
      NSString *confirmationPOSTBody = confirmation[@"ConfirmationPOSTBody"];
      
      void (^deleteIfSent)(NSURLResponse *response, NSData *data, NSError *connectionError) =
      
      ^(NSURLResponse *response, NSData *data, NSError *connectionError){
        if(!connectionError  && [(NSHTTPURLResponse*)response statusCode] == 200){
          NSLog(@"IBPayPalConfirmationManager: Confirmation successfully sent. Instance with Id = %@ removed from DB.", Id);
          [[IBPDBManager sharedInstance] deletePendingConfirmationWithId:Id];
        }
        else {
          NSLog(@"IBPayPalConfirmationManager: Confirmation sending error:\n%@\n.\
                Retry on app restart or when internet becomes available again.", [connectionError description]);
        }
      };
      
      [self sendConfirmation:confirmationPOSTBody
                  completion:deleteIfSent];
      
    }
  };
  
  NSBlockOperation *resendOperation = [NSBlockOperation blockOperationWithBlock:resendBlock];
  [queue addOperation:resendOperation];
}

@end
