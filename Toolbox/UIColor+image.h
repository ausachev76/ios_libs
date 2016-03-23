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

@interface UIColor(image)

-(UIImage *)asImage;

-(UIImage *)stretchableImageWithBorderColor:(UIColor *)borderColor
                                borderWidth:(UIEdgeInsets)borderInsets
                               borderInsets:(UIEdgeInsets)borderInsets;

-(UIImage *)asImageWithSize:(CGSize)size;


@end
