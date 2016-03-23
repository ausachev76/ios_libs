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

#import "UIColor+RGB.h"

@implementation UIColor (RGB)

+ (UIColor *)colorWithRGB:(NSUInteger)value_
{
  return [UIColor colorWithRed:((CGFloat)((value_ >> 16) & 0xFF) ) / 255.f
                         green:((CGFloat)((value_ >> 8 ) & 0xFF) ) / 255.f
                          blue:((CGFloat)(value_ & 0xFF) )         / 255.f
                         alpha:1.f];
}

+ (UIColor *)colorWithRGBA:(NSUInteger)value_
{
  return [UIColor colorWithRed:((CGFloat)((value_ >> 24 ) & 0xFF) ) / 255.f
                         green:((CGFloat)((value_ >> 16 ) & 0xFF) ) / 255.f
                          blue:((CGFloat)((value_ >> 8  ) & 0xFF) ) / 255.f
                         alpha:((CGFloat)(value_ & 0xFF)) / 255.f ];
}

- (uiRGBAColor)getRGBA
{
  CGColorRef color = [self CGColor];
  uiRGBAColor rgbaColor = {0.f,0.f,0.f,1.f};

  CGColorSpaceModel model = CGColorSpaceGetModel( CGColorGetColorSpace(color) );
  if ( model == kCGColorSpaceModelRGB)
  {
    int numComponents = CGColorGetNumberOfComponents(color);
    const CGFloat *components = CGColorGetComponents(color);
    if ( numComponents == 4 )
    {
      rgbaColor.red   = components[0];
      rgbaColor.green = components[1];
      rgbaColor.blue  = components[2];
      rgbaColor.alpha = components[3];
    }
  }else if ( model == kCGColorSpaceModelMonochrome )
  {
    int numComponents = CGColorGetNumberOfComponents(color);
    const CGFloat *components = CGColorGetComponents(color);
    if ( numComponents == 2 )
    {
      rgbaColor.red   = components[0];
      rgbaColor.green = components[0];
      rgbaColor.blue  = components[0];
      rgbaColor.alpha = components[1];
    }
  }
  return rgbaColor;
}

- (UIColor *)blend:(UIColor *)overlayColor_
{
  uiRGBAColor bg = [self getRGBA];
  uiRGBAColor fg = [overlayColor_ getRGBA];
  
  CGFloat alpha = 1.f - (1.f - fg.alpha) * (1 - bg.alpha);
  if (alpha < 1.0e-6)
    return [UIColor clearColor];  // fully transparent color

  // precalc alpha for background and foreground
  CGFloat fgAlphaPrecalc = fg.alpha / alpha;
  CGFloat bgAlphaPrecalc = bg.alpha * (1.f - fg.alpha) / alpha;
  
  // blend two colors...
  CGFloat red   = fg.red   * fgAlphaPrecalc + bg.red   * bgAlphaPrecalc;
  CGFloat green = fg.green * fgAlphaPrecalc + bg.green * bgAlphaPrecalc;
  CGFloat blue  = fg.blue  * fgAlphaPrecalc + bg.blue  * bgAlphaPrecalc;
  
  return [UIColor colorWithRed:red green:green blue:blue alpha:1.f];
}

@end
