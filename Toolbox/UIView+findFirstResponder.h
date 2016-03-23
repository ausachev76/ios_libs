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

#import <UIKit/UIKit.h>

@interface UIView (findFirstResponder)
  - (UIView *)findFirstResponder;

  - (void)lockSubviewsExceptViews:(NSArray *)exclusionList_;

  - (void)lockSubviewsExceptView:(UIView *)firstResponderView_;

  - (void)unlockSubviews;

@end
