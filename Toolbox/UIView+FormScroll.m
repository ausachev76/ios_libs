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

#import "UIView+FormScroll.h"

@implementation UIView (FormScroll)


-(void)scrollToY:(float)y
{
  [UIView beginAnimations:@"registerScroll" context:NULL];
  [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
  [UIView setAnimationDuration:0.3];
  self.transform = CGAffineTransformMakeTranslation(0, y);
  [UIView commitAnimations];
}

-(void)scrollToView:(UIView *)view
{
  CGRect theFrame = [self convertRect:view.frame fromView:view];
  float y = theFrame.origin.y - 15;
  y -= ( y / 1.7 );
  [self scrollToY:-y];
}


-(void)scrollElement:(UIView *)view toPoint:(float)y
{
  CGRect theFrame = [self convertRect:view.frame fromView:view];
  float orig_y = theFrame.origin.y;
  float diff = y - orig_y;
  if (diff < 0) {
    [self scrollToY:diff];
  }
  else {
    [self scrollToY:0];
  }
  
}

@end
