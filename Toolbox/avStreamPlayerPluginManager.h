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

typedef void(^avStreamPlayerPluginCompletionHandler)(NSURL *streamURL, NSError *error);

@protocol avStreamPlayerPluginDelegate<NSObject>
  @optional

@end

@interface avStreamPlayerPlugin : NSObject
  -(void)resolveStreamURL:(NSURL *)url_
    withCompletionHandler:(avStreamPlayerPluginCompletionHandler)completionHandler;
@end


@interface avStreamPlayerPluginManager : NSObject
  +(avStreamPlayerPlugin *)pluginWithStreamURL:(NSURL *)streamURL_;
@end