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

@interface mDBLocalizedResource : NSObject<NSCoding, NSCopying>
  -(id)initWithXMLElement:(TBXMLElement *)element
                  process:(id<NSCopying, NSCoding>(^)(NSString *value))completionBlock;
  -(id)initWithXMLElement:(TBXMLElement *)element
        processWithLocale:(id<NSCopying, NSCoding>(^)(NSString *value, NSString *locale))callback;
  -(id)initWithXMLElement:(TBXMLElement *)element;
  -(id)initWithResourceMap:(NSMutableDictionary *)resourceMap_;
  -(NSArray *)languageCodes;
  -(NSArray *)allObjects;

  -(id)copyWithProcess:(id<NSCopying, NSCoding>(^)(id<NSCopying, NSCoding> value, NSString *locale))callback;
  -(id)resourceForLocale:(NSString *)languageCode;
  -(void)setResource:(id<NSCoding, NSCopying>)resource
           forLocale:(NSString *)languageCode;
@end

