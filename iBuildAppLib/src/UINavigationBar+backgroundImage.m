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

#import "UINavigationBar+backgroundImage.h"
#import "NSObject+AssociatedObjects.h"

#define kBackgroundImageKey @"backgroundImageKey"

@implementation UINavigationBar (backgroundImage)

-(void)setBackgroundImage:(UIImage *)backgroundImage
{
#if defined(__IPHONE_5_0) && __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_5_0
  if ([self respondsToSelector:@selector( setBackgroundImage:forBarMetrics:)])
    [self setBackgroundImage:backgroundImage forBarMetrics:UIBarMetricsDefault];
#else
  [self associateValue:backgroundImage
               withKey:kBackgroundImageKey];
#endif
  
}

- (void)drawRect:(CGRect)rect
{
  NSObject *obj = [self associatedValueForKey:kBackgroundImageKey];
  if ( [obj isKindOfClass:[UIImage class]] )
    [(UIImage *)obj drawInRect:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
}

@end
