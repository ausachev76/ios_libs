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

#import "NSURLCache+external.h"
#import "SDURLCache.h"
#import <UIKit/UIKit.h>

#define kDefaultMemoryCacheSize     (1024*1024*8)    //   8MB mem cache
#define kDefaultDiskCacheSize       (1024*1024*128)  // 128MB disk cache

NSURLCache *g_defaultSharedCache = nil;

@implementation NSURLCache (externalCache)

+(BOOL)isExternalCacheEnabled
{
  return g_defaultSharedCache != nil;
}

+(void)externalCacheEnabled:(BOOL)bEnabled_
{
  if ( bEnabled_ )
  {
    if ( !g_defaultSharedCache )
    {
      
      g_defaultSharedCache = [[NSURLCache sharedURLCache] retain];
      

      SDURLCache *urlCache = [[SDURLCache alloc] initWithMemoryCapacity:kDefaultMemoryCacheSize
                                                           diskCapacity:kDefaultDiskCacheSize
                                                               diskPath:[SDURLCache defaultCachePath]];
      urlCache.minCacheInterval                         = 5.f;
      urlCache.ignoreMemoryOnlyStoragePolicy            = YES;
    
      [NSURLCache setSharedURLCache:urlCache];
      [urlCache release];
      //------------------------------------------------------------------------------------------------------------
    }
  }else{
    if ( g_defaultSharedCache )
    {
      [NSURLCache setSharedURLCache:g_defaultSharedCache];
      [g_defaultSharedCache release];
      g_defaultSharedCache = nil;
    }
  }
  
}
@end
