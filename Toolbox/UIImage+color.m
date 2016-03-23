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

#import "UIImage+color.h"

@implementation UIImage (color)


-(UIImage *)desaturate:(CGFloat )saturation_
{
  UIGraphicsBeginImageContextWithOptions( self.size, NO, self.scale );

  // get a reference to that context we created
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  // translate/flip the graphics context (for transforming from CG* coords to UI* coords
  CGContextTranslateCTM( context, 0, self.size.height );
  CGContextScaleCTM( context, 1.0, -1.0 );
  
  // set the blend mode to color burn, and the original image
  CGRect rect = CGRectMake( 0, 0, self.size.width, self.size.height );
  CGContextDrawImage( context, rect, self.CGImage );
  
  CGContextSetBlendMode( context, kCGBlendModeSaturation );
  
  // set a mask that matches the shape of the image, then draw (color burn) a colored rectangle
  CGContextClipToMask( context, rect, self.CGImage );
  CGContextSetRGBFillColor( context, 0.0, 0.0, 0.0, MAX( MIN( saturation_, 1.f ), 0 ) );
  CGContextFillRect(context, rect);
  
  // generate a new UIImage from the graphics context we drew onto
  UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  //return the color-burned image
  return coloredImg;
}


-(UIImage *)imageWithColor:(UIColor *)color_ blendMode:(CGBlendMode)blendMode_
{
  // begin a new image context, to draw our colored image onto
  UIGraphicsBeginImageContextWithOptions( self.size, NO, self.scale );
  
  // get a reference to that context we created
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  // translate/flip the graphics context (for transforming from CG* coords to UI* coords
  CGContextTranslateCTM( context, 0, self.size.height );
  CGContextScaleCTM( context, 1.0, -1.0 );
  
  // set the blend mode to color burn, and the original image
  CGRect rect = CGRectMake( 0, 0, self.size.width, self.size.height );
  CGContextDrawImage( context, rect, self.CGImage );
  
  CGContextSetBlendMode( context, kCGBlendModeSaturation );
  
  // set a mask that matches the shape of the image, then draw (color burn) a colored rectangle
  CGContextClipToMask( context, rect, self.CGImage );
  CGContextSetRGBFillColor( context, 0.0, 0.0, 0.0, 1.f );
  CGContextFillRect(context, rect);

  // set the fill color
  [color_ setFill];
  
  CGContextSetBlendMode( context, blendMode_ );
  CGContextAddRect( context, rect);
  CGContextDrawPath( context, kCGPathFill );
  
  // generate a new UIImage from the graphics context we drew onto
  UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  //return the color-burned image
  return coloredImg;
}

-(UIImage *)imageWithColor:(UIColor *)color_
{
  return [self imageWithColor:color_ blendMode:kCGBlendModeOverlay];
}

@end
