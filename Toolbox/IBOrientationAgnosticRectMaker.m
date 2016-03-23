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

#import "IBOrientationAgnosticRectMaker.h"

@implementation IBOrientationAgnosticRectMaker

/**
 *  Due to iOS 8+ behavior, when screen size in portrait and landscape differs,
 *  we need to set screen size to 768x1024 to keep our old code working
 */
+ (CGRect)orientationAgnosticRect:(CGRect)rect
{
  if(rect.size.width > rect.size.height){
    rect.size = (CGSize){rect.size.height, rect.size.width};
  }
  return rect;
}

@end
