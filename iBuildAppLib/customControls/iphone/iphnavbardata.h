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
#import "TBXML.h"

#define TIPhoneNavBarDataCustomizeNavBarAppearanceCompleted @"customizeNavBarAppearanceCompleted"

@class TIPhoneNavBarData;
@interface UINavigationController(customNavBar)
  -(void)customizeNavBarAppearance:(TIPhoneNavBarData *)navBarData;
@end

@class TLabelWidgetData;

/**
 * Container to store the settings and configuration of the navigation bar
 */
@interface TIPhoneNavBarData : NSObject<NSCoding, NSCopying>

 /**
  * Background color of the navigation bar
  */
  @property(nonatomic, strong) UIColor          *color;

 /**
  * Decoration field title
  */
  @property(nonatomic, strong) TLabelWidgetData *titleData;

 /**
  * Decorations for other buttons, including backButton
  */
  @property(nonatomic, strong) TLabelWidgetData *barButtonData;

  +(TIPhoneNavBarData *)createWithXMLElement:(TBXMLElement *)element;

  -(id)initWithXMLElement:(TBXMLElement *)element;

@end
