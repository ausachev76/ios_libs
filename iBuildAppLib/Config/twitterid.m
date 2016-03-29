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

#import "twitterid.h"

@implementation TwitterID
@synthesize consumerKey = _consumerKey,
         consumerSecret = _consumerSecret;


static TwitterID *instance_ = nil;

static void singleton_remover()
{
  [instance_ release];
}

+(TwitterID *)instance
{
  @synchronized(self)
  {
    if( instance_ == nil ) {
      [[self alloc] init];
    }
  }
  return instance_;
}

- (id)init
{
  self = [super init];
  instance_ = self;
  
  _consumerKey    = nil;
  _consumerSecret = nil;
  
  atexit(singleton_remover);
  return self;
}

- (void)dealloc
{
  self.consumerKey    = nil;
  self.consumerSecret = nil;
  [super dealloc];
}

+(void)setConsumerKey:(NSString *)consumerKey_
{
  [TwitterID instance].consumerKey = consumerKey_;
}

+(NSString *)getConsumerKey
{
  return [TwitterID instance].consumerKey;
}

+(void)setConsumerSecret:(NSString *)consumerSecret_
{
  [TwitterID instance].consumerSecret = consumerSecret_;
}

+(NSString *)getConsumerSecret
{
  return [TwitterID instance].consumerSecret;
}


+(void)storeAccessToken:(NSString *)accessToken
{
  [[NSUserDefaults standardUserDefaults]setObject:accessToken forKey:@"SavedAccessHTTPBody"];
}

+(NSString *)loadAccessToken
{
  return [[NSUserDefaults standardUserDefaults]objectForKey:@"SavedAccessHTTPBody"];
}


@end
