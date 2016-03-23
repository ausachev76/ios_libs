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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 * UIImage - colorization enhansements of the functional of the UIImage class.
 */
@interface UIImage (Colorize)

  /**
   * Provides color-coding the original image with the specified color
   *
   * @param color - the color which is produced colorization
   *        (for example, to transfer the image to sepia, you want to set
   *         the next set of parameters: [UIColor colorWithRed:1.f
   *                                                     green:.95f
   *                                                      blue:.82f
   *                                                     alpha:1.f]];
   * @return new colorized image
   */
-(UIImage*)colorize:(UIColor *)color;

-(UIImage*)alternativeColorize:(UIColor *)color_;


- (UIImage*)scaleToSize:(CGSize)size
               withMode:(UIViewContentMode)mode_;

 /** 
  * Changes the size of the original image to the specified size.
  *
  * @param size - new image size
  * @param bProportion - type of transformation:
  *          YES - proportional transformation preserves the aspect
  *                ratio of the original image
  *          NO  - the output image size will be equal to size
  *
  * @return new image
  */
- (UIImage*)scaleToSize:(CGSize)size
           proportional:(BOOL)bProportion;
@end

