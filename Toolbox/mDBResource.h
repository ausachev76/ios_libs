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
#import "TBXML.h"

/**
 * Description of the data structures used in the project
 * mDBResource - an integral resource that contains a refernce to a local resource (buildin) and external reference.
 */
@interface mDBResource : NSObject<NSCoding, NSCopying>

 /**
  * External resource reference.
  */
  @property(nonatomic, strong) id<NSCoding, NSCopying> external;

 /**
  * Local resource reference.
  */
  @property(nonatomic, strong) id<NSCoding, NSCopying> local;

  +(mDBResource *)localizedURLResourceWithElement:(TBXMLElement *)parent
                                  externalTagName:(NSString *)externalTagName
                                     localTagName:(NSString *)localTagName;

  +(mDBResource *)URLResourceWithElement:(TBXMLElement *)parent
                         externalTagName:(NSString *)externalTagName
                            localTagName:(NSString *)localTagName;


  +(NSString *)localResourceFilePathWithFileName:(NSString *)filename_;
  +(NSURL *)localURLResourceWithValue:(NSString *)value_;
  +(NSURL *)externalURLResourceWithValue:(NSString *)value_;

@end
