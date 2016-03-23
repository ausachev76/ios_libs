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

#import <UIKit/UIKit.h>

#define RGBUIColor8bit(_red_, _green_, _blue_ ) \
  [UIColor colorWithRed:((CGFloat)(_red_))/255.f \
                  green:((CGFloat)(_green_))/255.f \
                   blue:((CGFloat)(_blue_))/255.f \
                  alpha:1.f]

#define RGBAUIColor8bit(_red_, _green_, _blue_, _alpha_ ) \
  [UIColor colorWithRed:((CGFloat)(_red_))/255.f \
                  green:((CGFloat)(_green_))/255.f \
                   blue:((CGFloat)(_blue_))/255.f \
                  alpha:((CGFloat)(_alpha_))/255.f]


typedef struct taguiRGBAColor
{
  CGFloat red;
  CGFloat green;
  CGFloat blue;
  CGFloat alpha;
}uiRGBAColor;

@interface UIColor(RGB)

  + (UIColor *)colorWithRGB:(NSUInteger)value_;

  + (UIColor *)colorWithRGBA:(NSUInteger)value_;

  - (uiRGBAColor)getRGBA;

  - (UIColor *)blend:(UIColor *)overlayColor_;

@end
