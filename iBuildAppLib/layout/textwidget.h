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

/**
 * Component for text label, either singleline or multiline. Inherits all the fields
 * of the TWidget and adds the following:
 *
 *  textView.text          - text to display
 *  textView.font          - font
 *  textView.textColor     - color of text
 *  textView.textAlignment - alighment of text
 *  textView.scrollEnabled - whether scrolling of the text is enabled / disabled.
 */
@class TTextWidgetData;
@interface TTextWidget : TWidget
{
  UITextView  *m_textView;
}

@property (nonatomic, readonly) UITextView  *textView;

-(id)initWithParams:(TTextWidgetData *)params_;

@end

@interface TTextWidgetData : TWidgetData<NSCoding>
  @property (nonatomic, copy  ) NSString       *text;
  @property (nonatomic, retain) UIFont         *font;
  @property (nonatomic, retain) UIColor        *textColor;
  @property (nonatomic, assign) NSTextAlignment textAlignment;
  @property (nonatomic, assign) BOOL            scrollEnabled;
@end