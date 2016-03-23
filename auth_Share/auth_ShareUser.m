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

#import "auth_ShareUser.h"

@implementation auth_ShareUser : NSObject

@synthesize authentificatedWith;
@synthesize ID;
@synthesize name;
@synthesize avatar;

-(id)init {
  self = [super init];
  if (self) {
    self.authentificatedWith = auth_ShareServiceTypeNone;
    self.type                = nil;
    self.ID                  = nil;
    self.name                = nil;
    self.avatar              = nil;
  }
  return self;
}

-(void)dealloc {
  self.authentificatedWith = auth_ShareServiceTypeNone;
  self.type                = nil;
  self.ID                  = nil;
  self.name                = nil;
  self.avatar              = nil;
  
  [super dealloc];
}

- (auth_ShareServiceType) getCurrentServiceType
{
  if (!self.type)
    {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.type = [userDefaults objectForKey: @"mAccountType"];
    }
  
  if (self.type
      && ([self.type isEqualToString:@"none"] || [self.type isEqualToString:@"guest"]))
    return auth_ShareServiceTypeNone;
  
  if ([self.type isEqualToString:@"twitter"])
    return auth_ShareServiceTypeTwitter;
  
  if ([self.type isEqualToString:@"facebook"])
    return auth_ShareServiceTypeFacebook;
  
  if ([self.type isEqualToString:@"ibuildapp"])
    return auth_ShareServiceTypeEmail;
  
  return auth_ShareServiceTypeNone;
}

@end