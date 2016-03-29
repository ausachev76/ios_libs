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

typedef void(^URLLoaderSuccessBlock)(NSData *data);
typedef void(^URLLoaderFailureBlock)(NSError *error);

@interface IBURLLoader : NSObject

  -(id)initWithRequest:(NSURLRequest *)request_
               success:(URLLoaderSuccessBlock)success_
               failure:(URLLoaderFailureBlock)failure_;

  -(void)cancel;

@end
