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



@interface THistogramItem : NSObject
  @property (nonatomic, assign) NSUInteger rCount;
  @property (nonatomic, assign) NSUInteger gCount;
  @property (nonatomic, assign) NSUInteger bCount;
  @property (nonatomic, assign) NSUInteger aCount;
+(THistogramItem *)itemWithRcount:(NSUInteger)redCount
                           Gcount:(NSUInteger)greenCount
                           Bcount:(NSUInteger)blueCount
                           Acount:(NSUInteger)alphaCount;
@end

typedef struct tagTHistogramIndex
{
  NSUInteger r;
  NSUInteger g;
  NSUInteger b;
  NSUInteger a;
}THistogramIndex;

@interface THistogram : NSObject
  @property(nonatomic, assign) THistogramIndex minIdx;
  @property(nonatomic, assign) THistogramIndex maxIdx;
  @property(nonatomic, strong) NSArray        *histogram;
  -(UIColor *)minColor;
  -(UIColor *)maxColor;
@end



@interface UIImage (histogram)
  -(THistogram *)histogram;
@end
