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

@interface NSURLCache (externalCache)

  /**
   * Check whether the external caching system is used.
   */
  +(BOOL)isExternalCacheEnabled;

  /**
   * Enable / disable external caching system.
   *
   * @param bEnabled_ = YES - enable an external caching system
   *                     NO - disable an external caching system
   */
  +(void)externalCacheEnabled:(BOOL)bEnabled_;

@end
