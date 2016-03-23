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
#import "IBPhotoScrollView.h"

/**
 * Widget which implements a graphical representation of the component
 * allowing to make the horizontal scroll a UIView elements like.
 */
@interface IBSequencePhotoScrollView : UIView<IBPhotoScrollViewEventDelegate>

 /**
  * Area for scrolling images.
  */
  @property(nonatomic, readonly ) IBPhotoScrollView *photoScrollView;

 /**
  * Button to scroll through the contents of the left.
  */
  @property(nonatomic, readonly ) UIButton          *leftButton;

 /**
  * Button to scroll through the contents of the right.
  */
  @property(nonatomic, readonly ) UIButton          *rightButton;

 /**
  * Offset controls on the current View.
  */
  @property(nonatomic, assign   ) UIEdgeInsets       controlsInset;

@end
