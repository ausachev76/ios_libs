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

#import "NSString+truncation.h"

@implementation NSString (truncation)
-(NSString *)truncate
{
  NSString *szString = self;
  szString = [szString stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
  NSRange range = [szString rangeOfString:@"^\\s*" options:NSRegularExpressionSearch];
  szString = [szString stringByReplacingCharactersInRange:range withString:@""];
  range = [szString rangeOfString:@"\\s*$" options:NSRegularExpressionSearch];
  szString = [szString stringByReplacingCharactersInRange:range withString:@""];
  return szString;
}

- (NSString *)stringByReplaceCharacterSet:(NSCharacterSet *)characterset
                               withString:(NSString *)string
{
  NSString *result = self;
  NSRange range = [result rangeOfCharacterFromSet:characterset];
  
  while (range.location != NSNotFound)
  {
    result = [result stringByReplacingCharactersInRange:range withString:string];
    range = [result rangeOfCharacterFromSet:characterset];
  }
  return result;
}
@end
