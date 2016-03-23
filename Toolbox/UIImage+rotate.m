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

#import "UIImage+rotate.h"

static inline CGFloat degreesToRadians(CGFloat degrees)
{
  return M_PI * (degrees / 180.0);
}

static inline CGSize swapWidthAndHeight(CGSize size)
{
  CGFloat  swap = size.width;
  
  size.width  = size.height;
  size.height = swap;
  
  return size;
}


@implementation UIImage (rotate)
// rotate an image to any 90-degree orientation, with or without mirroring.
// original code by kevin lohman, heavily modified by yours truly.
// http://blog.logichigh.com/2008/06/05/uiimage-fix/

-(UIImage*)rotate:(UIImageOrientation)orient
{
  CGRect             bnds = CGRectZero;
  UIImage*           copy = nil;
  CGContextRef       ctxt = nil;
  CGRect             rect = CGRectZero;
  CGAffineTransform  tran = CGAffineTransformIdentity;
  
  bnds.size = self.size;
  rect.size = bnds.size;
  
  switch (orient)
  {
    case UIImageOrientationUp:
      return self;
      
    case UIImageOrientationUpMirrored:
      tran = CGAffineTransformMakeTranslation(rect.size.width, 0.0);
      tran = CGAffineTransformScale(tran, -1.0, 1.0);
      break;
      
    case UIImageOrientationDown:
      tran = CGAffineTransformMakeTranslation(rect.size.width,
                                              rect.size.height);
      tran = CGAffineTransformRotate(tran, degreesToRadians(180.0));
      break;
      
    case UIImageOrientationDownMirrored:
      tran = CGAffineTransformMakeTranslation(0.0, rect.size.height);
      tran = CGAffineTransformScale(tran, 1.0, -1.0);
      break;
      
    case UIImageOrientationLeft:
      bnds.size = swapWidthAndHeight(bnds.size);
      tran = CGAffineTransformMakeTranslation(0.0, rect.size.width);
      tran = CGAffineTransformRotate(tran, degreesToRadians(-90.0));
      break;
      
    case UIImageOrientationLeftMirrored:
      bnds.size = swapWidthAndHeight(bnds.size);
      tran = CGAffineTransformMakeTranslation(rect.size.height,
                                              rect.size.width);
      tran = CGAffineTransformScale(tran, -1.0, 1.0);
      tran = CGAffineTransformRotate(tran, degreesToRadians(-90.0));
      break;
      
    case UIImageOrientationRight:
      bnds.size = swapWidthAndHeight(bnds.size);
      tran = CGAffineTransformMakeTranslation(rect.size.height, 0.0);
      tran = CGAffineTransformRotate(tran, degreesToRadians(90.0));
      break;
      
    case UIImageOrientationRightMirrored:
      bnds.size = swapWidthAndHeight(bnds.size);
      tran = CGAffineTransformMakeScale(-1.0, 1.0);
      tran = CGAffineTransformRotate(tran, degreesToRadians(90.0));
      break;
      
    default:
      // orientation value supplied is invalid
      assert(false);
      return nil;
  }
  
  UIGraphicsBeginImageContextWithOptions( bnds.size, NO, self.scale );
  ctxt = UIGraphicsGetCurrentContext();
  
  switch (orient)
  {
    case UIImageOrientationLeft:
    case UIImageOrientationLeftMirrored:
    case UIImageOrientationRight:
    case UIImageOrientationRightMirrored:
      CGContextScaleCTM(ctxt, -1.0, 1.0);
      CGContextTranslateCTM(ctxt, -rect.size.height, 0.0);
      break;
      
    default:
      CGContextScaleCTM(ctxt, 1.0, -1.0);
      CGContextTranslateCTM(ctxt, 0.0, -rect.size.height);
      break;
  }
  
  CGContextConcatCTM(ctxt, tran);
  CGContextDrawImage(ctxt, rect, self.CGImage);
  
  copy = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
//  copy.scale = self.scale;
  
  return copy;
}

@end
