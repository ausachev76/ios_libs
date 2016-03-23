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

#import "UIApplication+terminate.h"

@implementation UIApplication (terminate)

+(void)terminate
{
  static NSString *suspendSelectorName = @"suspend";
  void (*pExit)(int) = &exit;

  UIApplication *app = [UIApplication sharedApplication];
  
  SEL selector = NSSelectorFromString( suspendSelectorName );
  
  [app performSelector:selector];
  
  //wait 2 seconds while app is going background
  [NSThread sleepForTimeInterval:2.0];
  
  //exit app when app is in background
  pExit( 0 );
}

@end
