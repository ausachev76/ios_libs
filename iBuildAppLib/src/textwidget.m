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

#import "textwidget.h"
#import "xmlwidgetparser.h"
#import "fontregistry.h"
#import "NSString+colorizer.h"

//-----------------------------------------------------------
@implementation TTextWidgetData
@synthesize text,
            font,
            textColor,
            textAlignment,
            scrollEnabled;
-(id)init
{
  self = [super init];
  if( self )
  {
    self.type = NSStringFromClass([self class]);
    self.text = nil;
    self.font = [UIFont systemFontOfSize:10.f];
    self.textColor = [UIColor blackColor];
    self.textAlignment = NSTextAlignmentLeft;
    self.scrollEnabled = YES;
  }
  return self;
}

-(void)dealloc
{
  self.text        = nil;
  self.font        = nil;
  self.textColor   = nil;
  [super dealloc];
}

-(void)parseXMLitems:(TBXMLElement *)item_
      withAttributes:(NSDictionary *)attributes_
{
  [super parseXMLitems:item_
        withAttributes:attributes_];
  
  NSString *szTextColor = [attributes_ objectForKey:@"textcolor"];
  if ( szTextColor )
  {
    UIColor *txtColor = [szTextColor asColor];
    if ( txtColor )
      self.textColor = txtColor;
  }
  NSString *txtAlignment  = [attributes_ objectForKey:@"textalignment"];
  if ( txtAlignment )
  {
    if ( [txtAlignment isEqualToString:@"right"] )
      self.textAlignment = NSTextAlignmentRight;
    else if ( [txtAlignment isEqualToString:@"center"] )
      self.textAlignment = NSTextAlignmentCenter;
  }
  NSString *textScrollable = [attributes_ objectForKey:@"scroll"];
  if ( textScrollable )
    self.scrollEnabled = [textScrollable boolValue];

  TBXMLElement *fontElement = [TBXML childElementNamed:@"font" parentElement:item_];
  if ( fontElement )
  {
    NSDictionary *fontAttrib = [TXMLWidgetParser elementAttributes:fontElement];

    NSString *fontFamily = [fontAttrib objectForKey:@"family"];
    NSString *fontWeight = [fontAttrib objectForKey:@"weight"];
    NSString *fontSize   = [fontAttrib objectForKey:@"size"  ];

    CGFloat fntSize = 0.f;
    if ( fontSize )
      fntSize = [fontSize floatValue];
    
    BOOL isBold   = NO;
    BOOL isItalic = NO;
    if ( fontWeight )
    {
      if ( [fontWeight isEqualToString:@"bold"] )
        isBold = YES;
      if ( [fontWeight isEqualToString:@"italic"] )
        isItalic = YES;
      if ( [fontWeight isEqualToString:@"bold-italic"] )
        isBold = isItalic = YES;
    }
    
    NSString *fontName = [[TFontRegistry instance] fontForFamily:fontFamily
                                                         forBold:isBold
                                                       andItalic:isItalic];
    if ( fntSize <= 0.f )
      fntSize = self.font.pointSize;

    if ( !fontName.length )
      fontName = [[TFontRegistry instance] fontForFamily:@"Helvetica"
                                                 forBold:isBold
                                               andItalic:isItalic];
    self.font = [UIFont fontWithName:fontName
                                size:fntSize];
  }
  TBXMLElement *textElement = [TBXML childElementNamed:@"text" parentElement:item_];
  if ( textElement )
    self.text = [TBXML textForElement:textElement];
}

#pragma mark NSCoding protocol
// Encode an object for an archive
- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject :self.text          forKey:@"textWidget.text" ];
  [coder encodeInteger:self.textAlignment forKey:@"textWidget.alignment" ];

  CGFloat red = 0.f, green = 0.f, blue = 0.f, a = 0.f;
  const CGFloat *components = CGColorGetComponents(self.textColor.CGColor);
  red   = components[0];
  green = components[1];
  blue  = components[2];
  a     = components[3];
  
  
  [coder encodeFloat:red   forKey:@"textWidget.color.red"];
  [coder encodeFloat:green forKey:@"textWidget.color.green"];
  [coder encodeFloat:blue  forKey:@"textWidget.color.blue"];
  [coder encodeFloat:a     forKey:@"textWidget.color.alpha"];
  [coder encodeBool :self.scrollEnabled forKey:@"textWidget.scrollEnabled"];

  [coder encodeObject:[self.font fontName]  forKey:@"textWidget.fontName"];
  [coder encodeFloat :[self.font pointSize] forKey:@"textWidget.fontSize"];
}

// Decode an object from an archive
- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if ( self )
  {
    self.text          = [coder decodeObjectForKey:@"textWidget.text" ];
    self.textAlignment = [coder decodeIntegerForKey:@"textWidget.alignment"];

    CGFloat red        = [coder decodeFloatForKey:@"textWidget.color.red"];
    CGFloat green      = [coder decodeFloatForKey:@"textWidget.color.green"];
    CGFloat blue       = [coder decodeFloatForKey:@"textWidget.color.blue"];
    CGFloat a          = [coder decodeFloatForKey:@"textWidget.color.alpha"];
    self.textColor     = [UIColor colorWithRed:red green:green blue:blue alpha:a];
    self.scrollEnabled = [coder decodeBoolForKey:@"textWidget.scrollEnabled"];
    
    self.font          = [UIFont fontWithName:[coder decodeObjectForKey:@"textWidget.fontName"]
                                         size:[coder decodeFloatForKey :@"textWidget.fontSize"]];
  }
  return self;
}

@end


@implementation TTextWidget
@synthesize  textView = m_textView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
      m_textView = [[UITextView alloc] initWithFrame:CGRectMake(0.f, 0.f, frame.size.width, frame.size.height)];
      m_textView.autoresizingMask    = UIViewAutoresizingFlexibleWidth |
                                       UIViewAutoresizingFlexibleHeight;
      m_textView.autoresizesSubviews    = YES;
      m_textView.backgroundColor        = [UIColor clearColor];
      m_textView.editable               = NO;
      m_textView.scrollEnabled          = YES;
      m_textView.userInteractionEnabled = YES;
      m_textView.textAlignment          = NSTextAlignmentLeft;
      [self addSubview:m_textView];
    }
    return self;
}

-(id)initWithParams:(TTextWidgetData *)params_
{
  self = [super initWithParams:params_];
  if (self)
  {
    m_textView = [[UITextView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.frame.size.width, self.frame.size.height)];
    m_textView.autoresizesSubviews = YES;
    m_textView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    m_textView.editable               = NO;
    m_textView.userInteractionEnabled = YES;

    m_textView.scrollEnabled = params_.scrollEnabled;
    m_textView.text          = params_.text;
    m_textView.textColor     = params_.textColor;
    m_textView.textAlignment = params_.textAlignment;
    m_textView.font          = params_.font;
    [self addSubview:m_textView];
  }
  return self;
}

-(void)dealloc
{
  if ( m_textView )
  {
    [m_textView release];
    m_textView = nil;
  }
  [super dealloc];
}

@end
