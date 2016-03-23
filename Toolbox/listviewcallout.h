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

#import "SMCalloutView.h"

@interface TListViewCallout : UIView<UITableViewDataSource, UITableViewDelegate> // SMCalloutView <UITableViewDataSource, UITableViewDelegate>

- (void)presentCalloutFromRect:(CGRect)rect
                        inView:(UIView *)view
             constrainedToView:(UIView *)constrainedView
      permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections
                      animated:(BOOL)animated;
@end
