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


@interface TWebDataItem : NSObject<NSCoding, NSCopying>
  @property(nonatomic, strong) NSData *localData;
  @property(nonatomic, strong) NSData *webData;

  -(id)initWithWebData:(NSData *)webData_
             localData:(NSData *)localData_;

@end

@interface TWebDataDictionary : NSObject<NSCoding, NSCopying>

  -(void)setItem:(TWebDataItem *)item_ forURL:(NSURL *)url_;

  -(TWebDataItem *)itemForURL:(NSURL *)url_;

  -(id)initWithDictionary:(NSDictionary *)dictionary_;

  -(NSUInteger)count;

  -(NSArray *)allKeys;

  -(NSArray *)allValues;

  -(void)removeAllObjects;

-(void)removeObjectForKey: (NSString *)key;

@end
