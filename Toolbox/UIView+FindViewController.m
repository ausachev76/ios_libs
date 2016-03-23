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

#import "UIView+FindViewController.h"

@implementation UIView (FindUIViewController)
- (UIViewController *) firstAvailableUIViewController {
  // convenience function for casting and to "mask" the recursive function
  return (UIViewController *)[self traverseResponderChainForUIViewController];
}

- (id) traverseResponderChainForUIViewController {
  id nextResponder = [self nextResponder];
  if ([nextResponder isKindOfClass:[UIViewController class]]) {
    return nextResponder;
  } else if ([nextResponder isKindOfClass:[UIView class]]) {
    return [nextResponder traverseResponderChainForUIViewController];
  } else {
    return nil;
  }
}
@end

