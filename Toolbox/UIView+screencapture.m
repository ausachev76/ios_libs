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

#import "UIView+screencapture.h"

@implementation UIView (screencapture)

- (UIImage *)captureScreenInRect:(CGRect)captureFrame
{
  CALayer *layer;
  layer = self.layer;
  UIGraphicsBeginImageContext(captureFrame.size);
  CGContextClipToRect (UIGraphicsGetCurrentContext(),captureFrame);
  [layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *screenImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return screenImage;
}

@end
