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

#import "UINavigationController+appearance.h"

@implementation UINavigationController(appearance)
-(void)inheritAppearanceFromNavigationController:(UINavigationController *)navigationController
{
  self.navigationBar.barStyle    = navigationController.navigationBar.barStyle;
  self.navigationBar.translucent = navigationController.navigationBar.translucent;

  if ( [self respondsToSelector:@selector(setTintColor:)] )
  {
#ifdef __IPHONE_7_0
      // detect if we run under iOS7
      if ( [self.navigationBar respondsToSelector:@selector(barTintColor)] )
      {
        [self.navigationBar setBarTintColor:navigationController.navigationBar.barTintColor];
        [self.navigationBar setTintColor:navigationController.navigationBar.tintColor];
      }else
        [self.navigationBar setTintColor:navigationController.navigationBar.tintColor];
#else
      [self.navigationBar setTintColor:navigationController.navigationBar.tintColor];
#endif

    [self.navigationBar setTitleTextAttributes:navigationController.navigationBar.titleTextAttributes];
  }
}
@end
