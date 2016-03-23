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

#import <CoreGraphics/CoreGraphics.h>
#import "UIImage+histogram.h"

@implementation THistogramItem
  @synthesize rCount, gCount, bCount, aCount;
+(THistogramItem *)itemWithRcount:(NSUInteger)redCount
                           Gcount:(NSUInteger)greenCount
                           Bcount:(NSUInteger)blueCount
                           Acount:(NSUInteger)alphaCount
{
  THistogramItem *item = [[[THistogramItem alloc] init] autorelease];
  item.rCount = redCount;
  item.gCount = greenCount;
  item.bCount = blueCount;
  item.aCount = alphaCount;
  return item;
}

-(NSString *)description
{
  return [NSString stringWithFormat:@"{  rCount = %u  gCount = %u  bCount = %u  aCount = %u}", self.rCount, self.gCount, self.bCount, self.aCount];
}

@end

@implementation THistogram
@synthesize histogram = _histogram,
            minIdx, maxIdx;
-(id)init
{
  self = [super init];
  if ( self )
  {
    THistogramIndex nullIndex = {0,0,0,0};
    self.minIdx = nullIndex;
    self.maxIdx = nullIndex;
    _histogram = nil;
  }
  return self;
}

-(void)dealloc
{
  self.histogram = nil;
  [super dealloc];
}

-(UIColor *)maxColor
{
  return [UIColor colorWithRed:(CGFloat)maxIdx.r/256.f
                         green:(CGFloat)maxIdx.g/256.f
                          blue:(CGFloat)maxIdx.b/256.f
                         alpha:1.f];
}

-(UIColor *)minColor
{
  return [UIColor colorWithRed:(CGFloat)minIdx.r/256.f
                         green:(CGFloat)minIdx.g/256.f
                          blue:(CGFloat)minIdx.b/256.f
                         alpha:1.f];
}


@end

#define setMinIndex( _cmp_val_, _real_val_, _index_val_, _idx_ )\
{\
  if ( (_real_val_) < (_cmp_val_) )\
  {\
    (_cmp_val_) = (_real_val_);\
    (_index_val_) = (_idx_);\
  }\
}

#define setMaxIndex( _cmp_val_, _real_val_, _index_val_, _idx_ )\
{\
  if ( (_real_val_) > (_cmp_val_) )\
  {\
    (_cmp_val_) = (_real_val_);\
    (_index_val_) = (_idx_);\
  }\
}



@implementation UIImage (histogram)

-(THistogram *)histogram
{
  CGImageRef imageRef = [self CGImage];
  NSUInteger width    = CGImageGetWidth(imageRef);
  NSUInteger height   = CGImageGetHeight(imageRef);
  const NSUInteger bytesPerPixel    = 4;
  const NSUInteger bitsPerComponent = 8;
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  const NSUInteger bytesPerRow = bytesPerPixel * width;
  const NSUInteger totalBytes = bytesPerRow * height;
  NSUInteger totalPixels = width * height;
  unsigned char *rawData = (unsigned char*) calloc(totalBytes, sizeof(unsigned char));
  CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                               bitsPerComponent, bytesPerRow, colorSpace,
                                               kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
  CGColorSpaceRelease(colorSpace);
  CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
  CGContextRelease(context);
  
  unsigned char *ptr = rawData;
  
  NSUInteger *histo = (NSUInteger *)calloc( (1 << bitsPerComponent) * bytesPerPixel, sizeof(NSUInteger));
  NSUInteger *histoR = histo;
  NSUInteger *histoG = histo + (1 << bitsPerComponent);
  NSUInteger *histoB = histo + (1 << bitsPerComponent) * 2;
  NSUInteger *histoA = histo + (1 << bitsPerComponent) * 3;
  // Now your rawData contains the image data in the RGBA8888 pixel format.
  do{
    histoR[*ptr++]++;
    histoG[*ptr++]++;
    histoB[*ptr++]++;
    histoA[*ptr++]++;
  }while(--totalPixels);
  
  free(rawData);

  NSMutableArray *histogramArray = [NSMutableArray array];
  THistogram *result = [[[THistogram alloc] init] autorelease];
  NSUInteger minR = -1, minG = -1, minB = -1, minA = -1,
             maxR =  0, maxG =  0, maxB =  0, maxA =  0;
  THistogramIndex nullIndex = {0,0,0,0};
  THistogramIndex minIndex = nullIndex,
                  maxIndex = nullIndex;
  for(NSUInteger i = 0; i < (1 << bitsPerComponent); ++i )
  {
    [histogramArray addObject:[THistogramItem itemWithRcount:histoR[i]
                                                      Gcount:histoG[i]
                                                      Bcount:histoB[i]
                                                      Acount:histoA[i]]];
    
    setMinIndex( minR, histoR[i], minIndex.r, i );
    setMinIndex( minG, histoG[i], minIndex.g, i );
    setMinIndex( minB, histoB[i], minIndex.b, i );
    setMinIndex( minA, histoA[i], minIndex.a, i );
    
    setMaxIndex( maxR, histoR[i], maxIndex.r, i );
    setMaxIndex( maxG, histoG[i], maxIndex.g, i );
    setMaxIndex( maxB, histoB[i], maxIndex.b, i );
    setMaxIndex( maxA, histoA[i], maxIndex.a, i );
  }
  free(histo);
  
  result.maxIdx = maxIndex;
  result.minIdx = minIndex;
  result.histogram = histogramArray;
  return result;
}

@end
