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

#import "NSString+UrlConvertion.h"
#import "NSString+truncation.h"

@implementation NSString (UrlConvertion)


-(NSURL *)asURL
{
  NSString *src = [self truncate];
  NSURL *url = [NSURL URLWithString:[[src stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                             stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  
  if ( [[url.scheme lowercaseString] isEqualToString:@"file"] &&
       [[url.host lowercaseString] isEqualToString:@"bundle"] )
  {
    NSString *path = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:url.path];
    return [NSURL fileURLWithPath:path];
  }
  return url;
}



@end
