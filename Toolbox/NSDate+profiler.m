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

#import "NSDate+profiler.h"

static NSDate *g_profilerDateTime = nil;

@implementation NSDate (profiler)

+(void)startProfiler
{
  if ( g_profilerDateTime )
  {
    [g_profilerDateTime release];
    g_profilerDateTime = nil;
  }
  g_profilerDateTime = [[NSDate date] retain];
}

+(NSTimeInterval)stopProfiler
{
  NSTimeInterval result = 0.f;
  if ( g_profilerDateTime )
  {
    result = -[g_profilerDateTime timeIntervalSinceNow];
    [g_profilerDateTime release];
    g_profilerDateTime = nil;
  }
  return result;
}


@end
