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

#import "UIImage+resource.h"

@implementation UIImage (resource)

+(UIImage *)imageNamed:(NSString *)imageName_
            fromBundle:(NSBundle *)bundle_
{
  CGFloat scale = [[UIScreen mainScreen] scale];
  
  if ( scale > 1.f )
    imageName_ = [imageName_ stringByAppendingString:@"@2x"];
  
  NSString *szFilePath = [[bundle_ bundlePath] stringByAppendingPathComponent:imageName_];
  
  
  NSData *data = [NSData dataWithContentsOfFile:szFilePath];
  
  return data ? [UIImage imageWithData:data
                                 scale:scale] : nil;
}

+(UIImage *)imageNamed:(NSString *)imageName_
            withSuffix:(NSString *)suffix
{
  if ( !imageName_ )
    return nil;
  return suffix ?
          [UIImage imageNamed:[[imageName_ stringByDeletingPathExtension] stringByAppendingString:suffix]] :
          [UIImage imageNamed:imageName_];
}

@end
