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

// allow queries through FHSTwitterEngine,
// if it is denied for this app to access system Twitter account
#define ENABLE_CONNECTION_WITH_BLOCKED_SYSTEM_ACCOUNT

@interface TwitterID : NSObject

+(TwitterID*)instance;
+(void)setConsumerKey:(NSString *)consumerKey_;
+(NSString *)getConsumerKey;
+(void)setConsumerSecret:(NSString *)consumerSecret_;
+(NSString *)getConsumerSecret;

+(void)storeAccessToken:(NSString *)accessToken;
+(NSString *)loadAccessToken;


@property (nonatomic, strong) NSString *consumerKey;
@property (nonatomic, strong) NSString *consumerSecret;

@end
