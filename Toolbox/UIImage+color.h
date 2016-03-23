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

@interface UIImage (color)

  /**
   * Creates a new colorized image, color-coding algorithm used by default: kCGBlendModeOverlay.
   */
  -(UIImage *)imageWithColor:(UIColor *)color_;

  /**
   * Creates a new colorized image with the given color-coding algorithm.
   */
  -(UIImage *)imageWithColor:(UIColor *)color_ blendMode:(CGBlendMode)blendMode_;

  /**
   * Desaturates the image, with the given factor bleaching (1.0 - completely bleached image).
   */
  -(UIImage *)desaturate:(CGFloat )saturation_;

@end
