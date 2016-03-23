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

#import "NSString+size.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)


@implementation NSString (size)

-(CGFloat)calcMaxWordWidthWithFont:(UIFont *)font
{
  NSMutableCharacterSet *separators = [NSMutableCharacterSet punctuationCharacterSet];
  [separators formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  NSArray *words = [self componentsSeparatedByCharactersInSet:separators];
  CGFloat maxLenght = 0;
  for( NSString *str in words )
  {
    CGFloat currentLength = [str sizeWithFont:font].width;
    maxLenght = MAX(currentLength, maxLenght );
  }
  return maxLenght;
}

- (NSString *)stringReducedToWidth:(CGFloat)width_
                          withFont:(UIFont *)font_
                     lineBreakMode:(NSLineBreakMode)lineBreakeMode_
{
  if ([self sizeWithFont:font_].width <= width_)
    return self;
  
  CGFloat dotFieldWidth = 0.f;
  if ( lineBreakeMode_ == NSLineBreakByTruncatingTail ||
       lineBreakeMode_ == NSLineBreakByTruncatingHead ||
       lineBreakeMode_ == NSLineBreakByTruncatingMiddle )
    dotFieldWidth = [@"..." sizeWithFont:font_].width;
  
  width_ -= dotFieldWidth;
  
  NSMutableString *string = [NSMutableString string];
  
  for (NSInteger i = 0; i < [self length]; i++)
  {
    [string appendString:[self substringWithRange:NSMakeRange(i, 1)]];
    
    if ( [string sizeWithFont:font_].width > width_ )
    {
      if ([string length] == 1)
        return nil;
      
      [string deleteCharactersInRange:NSMakeRange(i, 1)];
      break;
    }
  }
  if ( lineBreakeMode_ == NSLineBreakByTruncatingTail ||
       lineBreakeMode_ == NSLineBreakByTruncatingHead ||
       lineBreakeMode_ == NSLineBreakByTruncatingMiddle )
    return [string stringByAppendingString:@"..."];
  return string;
}



- (CGSize) sizeForFont:(UIFont *)font_
             limitSize:(CGSize)size_
         lineBreakMode:(NSLineBreakMode)lineBreakeMode_
{
  // http://stackoverflow.com/questions/18897896/replacement-for-deprecated-sizewithfont-in-ios-7
  
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
  {
    NSAttributedString *attributedText = [[[NSAttributedString alloc] initWithString:self
                                                                          attributes:@{ NSFontAttributeName: font_ }] autorelease];
    CGRect rect = [attributedText boundingRectWithSize:size_
                                               options:(NSStringDrawingUsesLineFragmentOrigin)
                                                        //(NSStringDrawingUsesLineFragmentOrigin|NSStringDrawingUsesFontLeading)
                                               context:nil];
    rect.size.height = truncf(rect.size.height + 1.5);
    rect.size.width = truncf(rect.size.width + 1.5);
    
    if (rect.size.height >= size_.height && rect.size.width >= size_.width)
      return size_;
    
    
    if (rect.size.height >= size_.height && rect.size.width <= size_.width)
      rect.size.height = size_.height;
    
    if (rect.size.width >= size_.width && rect.size.height <= size_.height)
      rect.size.width = size_.width;
  
    
    return rect.size;

  }
  else
    return [self sizeWithFont:font_ constrainedToSize:size_ lineBreakMode:(NSLineBreakMode)lineBreakeMode_];
}


- (CGSize) sizeForFont:(UIFont *)font_
             limitSize:(CGSize)size_
       nslineBreakMode:(NSLineBreakMode)lineBreakeMode_
{
  return [self sizeForFont:font_
                 limitSize:size_
             lineBreakMode:lineBreakeMode_];
}


- (CGSize) sizeForFont:(UIFont *)font_
             limitSize:(CGSize)size_
{
  return [self sizeForFont:font_
                limitSize:size_
             lineBreakMode:NSLineBreakByWordWrapping];
}


@end
