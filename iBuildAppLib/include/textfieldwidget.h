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

#import "widget.h"

@interface TTextFieldWidgetData : TWidgetData
  @property (nonatomic, copy  ) NSString       *text;
  @property (nonatomic, copy  ) NSString       *placeholder;
  @property (nonatomic, retain) UIFont         *font;
  @property (nonatomic, retain) UIColor        *textColor;
  @property (nonatomic, assign) NSTextAlignment textAlignment;
  @property (nonatomic, assign) UIEdgeInsets    textInsets;
@end

@interface TCustomTextField : UITextField
  @property(nonatomic, assign) UIEdgeInsets inset;
@end

@interface TTextFieldWidget : TWidget <UITextFieldDelegate>
  @property (nonatomic, retain, readonly) TCustomTextField *textField;
@end
