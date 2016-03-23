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

#import "UIColor+image.h"

@implementation UIColor (image)
-(UIImage *)asImage
{
  UIGraphicsBeginImageContext( CGSizeMake(1.0f, 1.0f) );
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGContextSetFillColorWithColor( context, self.CGColor );
  CGContextFillRect( context, CGRectMake( 0, 0, 1, 1 ) );
  
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return image;
}


-(UIImage *)asImageWithSize:(CGSize)size
{
  if ( !((size.width > 0) && (size.height > 0)) )
    return nil;
  
  UIGraphicsBeginImageContext( size );
  CGContextRef context = UIGraphicsGetCurrentContext();
  
  CGContextSetFillColorWithColor( context, self.CGColor );
  CGContextFillRect( context, CGRectMake( 0.f, 0.f, size.width, size.height ) );
  
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return image;
}

-(UIImage *)stretchableImageWithBorderColor:(UIColor *)borderColor
                                borderWidth:(UIEdgeInsets)borderWidth
                               borderInsets:(UIEdgeInsets)borderInsets
{
  CGFloat scale = [[UIScreen mainScreen] scale];
  
  CGSize imageSize = CGSizeMake(borderWidth.left + borderWidth.right + 2.f + borderInsets.left + borderInsets.right,
                                borderWidth.top  + borderWidth.bottom + 2.f + borderInsets.top + borderInsets.bottom );
  UIGraphicsBeginImageContextWithOptions( imageSize, NO, scale );
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGRect frm = CGRectMake( 0.f, 0.f, imageSize.width, imageSize.height );
  // disable antialiasing
  CGContextSetAllowsAntialiasing( context, NO );
  
  CGContextSetFillColorWithColor( context, self.CGColor );
  CGContextFillRect( context, frm );
  
  if ( borderWidth.left )
  {
    CGContextSetFillColorWithColor( context, borderColor.CGColor );
    // Add Filled Rectangle,
    CGContextFillRect(context, CGRectMake(CGRectGetMinX(frm) + borderInsets.left,
                                          CGRectGetMinY(frm) + borderWidth.top + borderInsets.top,
                                          borderWidth.left,
                                          CGRectGetHeight(frm) - borderWidth.top - borderWidth.bottom -
                                                                 borderInsets.top - borderInsets.bottom ));
  }
  
  if ( borderWidth.right )
  {
    CGContextSetFillColorWithColor( context, borderColor.CGColor );
    // Add Filled Rectangle,
    CGContextFillRect(context, CGRectMake(CGRectGetMaxX(frm) - borderWidth.right - borderInsets.right,
                                          CGRectGetMinY(frm) + borderWidth.top + borderInsets.top,
                                          borderWidth.right,
                                          CGRectGetHeight(frm) - borderWidth.top - borderWidth.bottom -
                                                                 borderInsets.top - borderInsets.bottom ));
  }
  
  if ( borderWidth.top )
  {
    CGContextSetFillColorWithColor( context, borderColor.CGColor );
    // Add Filled Rectangle,
    CGContextFillRect(context, CGRectMake(CGRectGetMinX(frm) + borderInsets.left,
                                          CGRectGetMinY(frm) + borderInsets.top,
                                          CGRectGetWidth(frm) - borderInsets.left - borderInsets.right,
                                          borderWidth.top));
  }
  
  if ( borderWidth.bottom )
  {
    CGContextSetFillColorWithColor( context, borderColor.CGColor );
    // Add Filled Rectangle,
    CGContextFillRect(context, CGRectMake(CGRectGetMinX(frm) + borderInsets.left,
                                          CGRectGetMaxY(frm) - borderWidth.bottom - borderInsets.bottom,
                                          CGRectGetWidth(frm) - borderInsets.left - borderInsets.right,
                                          borderWidth.bottom));
  }
  
  UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  return [image stretchableImageWithLeftCapWidth:floorf(imageSize.width / 2.f)
                                    topCapHeight:floorf(imageSize.height / 2.f)];
}


@end
