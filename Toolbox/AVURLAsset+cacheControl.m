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

#import "AVURLAsset+cacheControl.h"
#import "NSURLCache+external.h"
#import <objc/runtime.h>
#import <objc/message.h>

@implementation AVURLAsset (cacheControl)

+(void)swizzleAVURLAsset
{
#ifdef __IPHONE_7_0
  if( floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1 )
  {
    // swizzle the nav bar and exchange method implementations
    Method instanceLoadValues = class_getInstanceMethod([AVURLAsset class], @selector(loadValuesAsynchronouslyForKeys:completionHandler:));
    Method customLoadValues   = class_getInstanceMethod([AVURLAsset class], @selector(customLoadValuesAsynchronouslyForKeys:completionHandler:));
    method_exchangeImplementations( customLoadValues, instanceLoadValues );
  }
#endif
}

-(void)customLoadValuesAsynchronouslyForKeys:(NSArray *)keys
                           completionHandler:(void (^)(void))handler
{
  // disable cache system
  BOOL bState = [NSURLCache isExternalCacheEnabled];
  [NSURLCache externalCacheEnabled:NO];
  
  [self customLoadValuesAsynchronouslyForKeys:keys
            completionHandler:^{
              [NSURLCache externalCacheEnabled:bState];
              if ( handler )
                handler();
            }];
}


@end
