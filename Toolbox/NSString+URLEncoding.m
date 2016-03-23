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

#import "NSString+URLEncoding.h"

#import <Foundation/Foundation.h>

@implementation NSString (URLEncoding)
-(NSString *)urlEncodeUsingEncoding:(NSStringEncoding)encoding
{
	return [((NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                               (CFStringRef)self,
                                                               NULL,
                                                               (CFStringRef)@"!*'\"();:@&=+$,/?%#[]% ",
                                                               CFStringConvertNSStringEncodingToEncoding((unsigned long)encoding))) autorelease];
}

- (NSString *)urlEncodeUsingEncodingEx:(NSStringEncoding)encoding
{
  // exclusion character set could be found at http://tools.ietf.org/html/rfc3986#section-2
	return [((NSString *)CFURLCreateStringByAddingPercentEscapes(NULL,
                                                               (CFStringRef)self,
                                                               (CFStringRef)@"-._~:/?#[]@!$&'()*+,;=",
                                                               NULL,
                                                               CFStringConvertNSStringEncodingToEncoding((unsigned long)encoding))) autorelease];
}

- (NSURL *)convertToURL
{
  // first - remove any % encoded symbols is exists
  NSString *strSource = [self stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  // convert all non URL symbols to % encoded
  strSource = [strSource urlEncodeUsingEncodingEx:NSUTF8StringEncoding];
  return strSource ? [NSURL URLWithString:strSource] : nil;
}

@end
