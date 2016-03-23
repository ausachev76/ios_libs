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

#import "NSString+colorizer.h"
#import "UIImageView+WebCache.h"

#define HEX_VALUE_REGEXP @"[\\da-fA-F]{2}"

@implementation NSString (colorizer)

-(UIColor *)checkStringWithRGBAPattern
{
  NSError* error = nil;
  NSString *szPattern = @"^\\s*rgba\\s*\\(\\s*(\\d{1,3})\\s*,\\s*(\\d{1,3})\\s*,\\s*(\\d{1,3})\\s*,\\s*([0-9]*[.]?[0-9]*)\\s*\\)";
  NSRegularExpression* regexp = [NSRegularExpression regularExpressionWithPattern:szPattern
                                                                          options:0
                                                                            error:&error];
  if ( error )
    return nil;
  
  NSTextCheckingResult *textCheckingResult = [regexp firstMatchInString:self
                                                                options:0
                                                                  range:NSMakeRange(0, [self length])];
  if (textCheckingResult && [textCheckingResult numberOfRanges] >= 5 )
  {
    NSUInteger red = 0, green = 0, blue = 0;
    CGFloat    alpha = 1.f;
    red   = [[self substringWithRange:[textCheckingResult rangeAtIndex:1]] integerValue];
    green = [[self substringWithRange:[textCheckingResult rangeAtIndex:2]] integerValue];
    blue  = [[self substringWithRange:[textCheckingResult rangeAtIndex:3]] integerValue];
    alpha = [[self substringWithRange:[textCheckingResult rangeAtIndex:4]] floatValue];  // alpha must be in range [0..1]
    
    red   = MAX( MIN(red  , 255), 0);
    green = MAX( MIN(green, 255), 0);
    blue  = MAX( MIN(blue , 255), 0);
    
    alpha = MAX( MIN(alpha,1.f), 0.f);
    
    return [UIColor colorWithRed:(CGFloat)red   / 255.f
                           green:(CGFloat)green / 255.f
                            blue:(CGFloat)blue  / 255.f
                           alpha:alpha];
  }
  return nil;
}

-(UIColor *)checkStringWithRGBPattern
{
  NSError* error = nil;
  NSString *szPattern = @"^\\s*rgb\\s*\\(\\s*(\\d{1,3})\\s*,\\s*(\\d{1,3})\\s*,\\s*(\\d{1,3})\\s*\\)";
  NSRegularExpression* regexp = [NSRegularExpression regularExpressionWithPattern:szPattern
                                                                          options:0
                                                                            error:&error];
  if ( error )
    return nil;
  
  NSTextCheckingResult *textCheckingResult = [regexp firstMatchInString:self
                                                                options:0
                                                                  range:NSMakeRange(0, [self length])];
  if ( !textCheckingResult )
  {
    return [self checkStringWithRGBAPattern];
  }else if ( [textCheckingResult numberOfRanges] >= 4 )
  {
    NSUInteger red = 0, green = 0, blue = 0;
    red   = [[self substringWithRange:[textCheckingResult rangeAtIndex:1]] integerValue];
    green = [[self substringWithRange:[textCheckingResult rangeAtIndex:2]] integerValue];
    blue  = [[self substringWithRange:[textCheckingResult rangeAtIndex:3]] integerValue];
    
    red   = MAX( MIN(red  , 255), 0);
    green = MAX( MIN(green, 255), 0);
    blue  = MAX( MIN(blue , 255), 0);
    
    return [UIColor colorWithRed:(CGFloat)red   / 255.f
                           green:(CGFloat)green / 255.f
                            blue:(CGFloat)blue  / 255.f
                           alpha:1.f];
  }
  return nil;
}


-(UIColor *)asColor
{
  if ( ![self length] )
    return nil;
  
  NSError* error = nil;
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*#("HEX_VALUE_REGEXP")("HEX_VALUE_REGEXP")("HEX_VALUE_REGEXP")\\s*"
                                                                         options:0
                                                                           error:&error];
  if ( error )
    return nil;
  
  NSTextCheckingResult *textCheckingResult = [regex firstMatchInString:self
                                                               options:0
                                                                 range:NSMakeRange(0, [self length])];
  
  if ( !textCheckingResult )
  {
    return [self checkStringWithRGBPattern];
  }else if ( [textCheckingResult numberOfRanges] >= 4 )
  {
    NSScanner *scanner;
    unsigned int red = 0, green = 0, blue = 0;
    scanner = [NSScanner scannerWithString: [self substringWithRange:[textCheckingResult rangeAtIndex:1]]];
    [scanner scanHexInt:&red];
    scanner = [NSScanner scannerWithString: [self substringWithRange:[textCheckingResult rangeAtIndex:2]]];
    [scanner scanHexInt:&green];
    scanner = [NSScanner scannerWithString: [self substringWithRange:[textCheckingResult rangeAtIndex:3]]];
    [scanner scanHexInt:&blue];
    
    return [UIColor colorWithRed:(CGFloat)red   / 256.f
                           green:(CGFloat)green / 256.f
                            blue:(CGFloat)blue  / 256.f
                           alpha:1.f];
  }
  return nil;
}


-(UIImage *)asImage
{
  if ( ![self length] )
    return nil;
  
  UIColor *color = [self asColor];
  if ( color )
  {
    UIGraphicsBeginImageContext( CGSizeMake(1.0f, 1.0f) );
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor( context, color.CGColor );
    CGContextFillRect( context, CGRectMake( 0, 0, 1, 1) );
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
  }else{
    NSString *correctedUrlStr = [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    correctedUrlStr = [correctedUrlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSURL *correctedUrl = [NSURL URLWithString:correctedUrlStr];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:correctedUrl
                                             cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                         timeoutInterval:15.f];
    NSURLResponse *response = nil;
    NSError       *error    = nil;
    
    //Capturing server response
    NSData* result = [NSURLConnection sendSynchronousRequest:request
                                           returningResponse:&response
                                                       error:&error];
    return [UIImage imageWithData:result];
  }
}

-(UIImageView *)asImageView:(UIImage *)placeholder
{
  if ( ![self length] )
    return nil;
  
  UIColor *color = [self asColor];
  if ( color )
  {
    UIGraphicsBeginImageContext( CGSizeMake(1.0f, 1.0f) );
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetFillColorWithColor( context, color.CGColor );
    CGContextFillRect( context, CGRectMake( 0, 0, 1, 1) );
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIImageView *imageView = [[[UIImageView alloc] initWithImage:image] autorelease];
    imageView.autoresizesSubviews = YES;
    imageView.autoresizingMask    = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    return imageView;
  }else{
    NSString *correctedUrlStr = [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    correctedUrlStr = [correctedUrlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    UIImageView *imageView = [[[UIImageView alloc] init] autorelease];
    imageView.contentMode = UIViewContentModeCenter;
    
    [imageView setImageWithURL:[NSURL URLWithString:correctedUrlStr]
        placeholderImage:placeholder
                 success:^(UIImage *image, BOOL cached)
                          {
                            if ( CGSizeEqualToSize( image.size, CGSizeZero ) )
                            {
                              imageView.contentMode = UIViewContentModeCenter;
                            }else
                              imageView.contentMode = UIViewContentModeScaleAspectFill;
                          }
                 failure:^(NSError *error)
                          {
                            imageView.contentMode = UIViewContentModeScaleAspectFill;
                          }];
    imageView.autoresizesSubviews = YES;
    imageView.autoresizingMask    = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    return imageView;
  }
}




@end
