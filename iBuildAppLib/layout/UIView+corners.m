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

#import "UIView+corners.h"
#import <QuartzCore/QuartzCore.h>


static inline UIImage* MTDContextCreateRoundedMask( CGRect rect, CGFloat radius_tl, CGFloat radius_tr, CGFloat radius_bl, CGFloat radius_br ) {
  
  CGContextRef context;
  CGColorSpaceRef colorSpace;
  
  colorSpace = CGColorSpaceCreateDeviceRGB();
  
  // create a bitmap graphics context the size of the image
  context = CGBitmapContextCreate(NULL,
                                  rect.size.width,
                                  rect.size.height,
                                  8,
                                  0,
                                  colorSpace,
                                  (CGBitmapInfo)kCGImageAlphaPremultipliedLast );
  
  // free the rgb colorspace
  CGColorSpaceRelease(colorSpace);
  
  if ( context == NULL ) {
    return NULL;
  }
  
  // cerate mask
  
  CGFloat minx = CGRectGetMinX( rect ), midx = CGRectGetMidX( rect ), maxx = CGRectGetMaxX( rect );
  CGFloat miny = CGRectGetMinY( rect ), midy = CGRectGetMidY( rect ), maxy = CGRectGetMaxY( rect );
  
  CGContextBeginPath( context );
  CGContextSetGrayFillColor( context, 1.0, 0.0 );
  CGContextAddRect( context, rect );
  CGContextClosePath( context );
  CGContextDrawPath( context, kCGPathFill );
  
  CGContextSetGrayFillColor( context, 1.0, 1.0 );
  CGContextBeginPath( context );
  CGContextMoveToPoint( context, minx, midy );
  CGContextAddArcToPoint( context, minx, miny, midx, miny, radius_bl );
  CGContextAddArcToPoint( context, maxx, miny, maxx, midy, radius_br );
  CGContextAddArcToPoint( context, maxx, maxy, midx, maxy, radius_tr );
  CGContextAddArcToPoint( context, minx, maxy, minx, midy, radius_tl );
  CGContextClosePath( context );
  CGContextDrawPath( context, kCGPathFill );
  
  // Create CGImageRef of the main view bitmap content, and then
  // release that bitmap context
  CGImageRef bitmapContext = CGBitmapContextCreateImage( context );
  CGContextRelease( context );
  
  // convert the finished resized image to a UIImage
  UIImage *theImage = [UIImage imageWithCGImage:bitmapContext];
  // image is retained by the property setting above, so we can
  // release the original
  CGImageRelease(bitmapContext);
  
  // return the image
  return theImage;
}

@interface CALayer (corners)
+ (id)maskLayerWithCorners:(UIRectCorner)corners radii:(CGSize)radii frame:(CGRect)frame;

+ (id)maskLayerWithBottomEdgeFrame:(CGRect)frame;

@end

@implementation CALayer (corners)

+ (id)maskLayerWithCorners:(UIRectCorner)corners radii:(CGSize)radii frame:(CGRect)frame
{
  // Create a CAShapeLayer
  CAShapeLayer *mask = [CAShapeLayer layer];
  
  // Set the frame
  mask.frame = frame;
  
  // Set the CGPath from a UIBezierPath
  mask.path = [UIBezierPath bezierPathWithRoundedRect:mask.bounds byRoundingCorners:corners cornerRadii:radii].CGPath;
  
  // Set the fill color
  mask.fillColor = [UIColor whiteColor].CGColor;
  return mask;
}

+ (id)maskLayerWithBottomEdgeFrame:(CGRect)frame
{
  CAGradientLayer *maskLayer = [CAGradientLayer layer];
  
  CGColorRef outerColor = [UIColor colorWithWhite:1.0 alpha:0.0].CGColor;
  CGColorRef innerColor = [UIColor colorWithWhite:1.0 alpha:1.0].CGColor;
  
  maskLayer.colors = [NSArray arrayWithObjects:(id)outerColor,
                      (id)innerColor, (id)innerColor, (id)outerColor, nil];
  maskLayer.locations = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],
                         [NSNumber numberWithFloat:0.2],
                         [NSNumber numberWithFloat:0.8],
                         [NSNumber numberWithFloat:1.0], nil];
  
  maskLayer.bounds = frame;
  
  maskLayer.anchorPoint = CGPointZero;
  
  return maskLayer;
}


@end


@implementation UIView (corners)

- (void)maskRoundCorners:(UIRectCorner)corners radius:(CGFloat)radius {
  // To round all corners, we can just set the radius on the layer
  if ( corners == UIRectCornerAllCorners )
  {
    self.layer.cornerRadius = radius;
    self.layer.masksToBounds = YES;
  } else {
    // If we want to choose which corners we want to mask then
    // it is necessary to create a mask layer.
    self.layer.mask = [CALayer maskLayerWithCorners:corners radii:CGSizeMake(radius, radius) frame:self.bounds];
  }
  self.layer.shouldRasterize = YES;
  self.layer.rasterizationScale = [[UIScreen mainScreen] scale];
}

- (void)maskBottomEdge
{
  // If we want to choose which corners we want to mask then
  // it is necessary to create a mask layer.
  [self.layer insertSublayer:[CALayer maskLayerWithBottomEdgeFrame:self.bounds] atIndex:0];
  self.layer.shouldRasterize = YES;
  self.layer.rasterizationScale = [[UIScreen mainScreen] scale];

}

@end
