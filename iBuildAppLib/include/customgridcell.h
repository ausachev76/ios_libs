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

#import "NRGridViewCell.h"

@class TWidgetData;
@class TLabelWidgetData;
@class uiBoxLayout;

#define ADAPTIVE_LABEL_BEHAVIOR

@interface TCustomGridCell : NRGridViewCell

@property (nonatomic, retain) UIImageView       *delimiterView;
@property (nonatomic, retain) TWidgetData       *delimiterWidget;
@property (nonatomic, retain) TWidgetData       *imageWidget;
@property (nonatomic, retain) TLabelWidgetData  *titleWidget;
@property (nonatomic, retain) TLabelWidgetData  *descriptionWidget;
@property (nonatomic, retain) uiBoxLayout       *layout;

/**
 * The length of the longest word in title.
 */
@property (nonatomic, assign ) CGFloat           titleMaxWordWidth;

/**
 * The length of the longest word in description.
 */
@property (nonatomic, assign ) CGFloat           descriptionMaxWordWidth;
@property (nonatomic, retain) UIImageView       *badge;

- (void)removeBadgeFromTab;

@end

