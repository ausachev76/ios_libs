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

@class TLabelWidgetData;
@class NRLabel;

/**
 *  TLabelWidget - Single- or multiline text label.
 *                 Inherits all the fields of the TWidget and adds the followings:
 *  labelView.text          - text to be displayed
 *  labelView.font          - font of the text
 *  labelView.textColor     - color of the text
 *  labelView.textAlignment - text alignment
 *  labelView.lineBreakMode - line break mode
 *  labelView.numberOfLines - how many lines of text should be displayed
 *  labelView.shadowColor   - color of the shadow
 *  labelView.shadowOffset  - offset of the shadow
 */
@interface TLabelWidget : TWidget
{
  NRLabel  *m_labelView;
}

@property (nonatomic, readonly) NRLabel  *labelView;

-(id)initWithParams:(TLabelWidgetData *)params_;

@end


@interface TLabelWidgetData : TWidgetData<NSCoding,NSCopying>
  @property (nonatomic, copy  ) NSString       *text;
  @property (nonatomic, retain) UIFont         *font;
  @property (nonatomic, retain) UIColor        *textColor;
  @property (nonatomic, retain) UIColor        *highlightedTextColor;
  @property (nonatomic, assign) NSTextAlignment textAlignment;
  @property (nonatomic, assign) NSTextAlignment textVerticalAlignment;
  @property (nonatomic, assign) NSLineBreakMode lineBreakMode;
  @property (nonatomic, assign) NSUInteger      numberOfLines;
  @property (nonatomic, retain) UIColor        *shadowColor;
  @property (nonatomic, assign) CGSize          shadowOffset;
  -(id)initWithXMLElement:(TBXMLElement *)element
        defaultWidgetData:(TLabelWidgetData *)default_;
  +(TLabelWidgetData *)createWithXMLElement:(TBXMLElement *)element;
  +(TLabelWidgetData *)createWithXMLElement:(TBXMLElement *)element
                          defaultWidgetData:(TLabelWidgetData *)default_;
  -(id)initWithXMLElement:(TBXMLElement *)element;
@end