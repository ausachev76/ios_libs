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

#import "labelwidget.h"
#import "xmlwidgetparser.h"
#import "fontregistry.h"
#import "NRLabel.h"
#import "NSString+colorizer.h"


@implementation TLabelWidgetData
@synthesize text,
            font,
            textColor,
            highlightedTextColor,
            textAlignment,
            textVerticalAlignment,
            lineBreakMode,
            numberOfLines,
            shadowColor,
            shadowOffset;

+(TLabelWidgetData *)createWithXMLElement:(TBXMLElement *)element
{
  return [[[TLabelWidgetData alloc] initWithXMLElement:element] autorelease];
}

+(TLabelWidgetData *)createWithXMLElement:(TBXMLElement *)element
                        defaultWidgetData:(TLabelWidgetData *)default_;
{
  return [[[TLabelWidgetData alloc] initWithXMLElement:element defaultWidgetData:default_] autorelease];
}

-(id)initWithXMLElement:(TBXMLElement *)element
{
  return [self initWithXMLElement:element defaultWidgetData:nil];
}

-(id)initWithXMLElement:(TBXMLElement *)element
      defaultWidgetData:(TLabelWidgetData *)default_
{
  self = [super init];
  if ( self )
  {
    self.type = NSStringFromClass([self class]);
    if ( default_ )
    {
      self.text          = [[default_.text copy] autorelease];
      self.font          = default_.font;
      self.textColor     = default_.textColor;
      self.highlightedTextColor = default_.highlightedTextColor;
      self.textAlignment = default_.textAlignment;
      self.textVerticalAlignment = default_.textVerticalAlignment;
      self.lineBreakMode         = default_.lineBreakMode;
      self.numberOfLines         = default_.numberOfLines;
      self.shadowColor           = default_.shadowColor;
      self.shadowOffset          = default_.shadowOffset;
    }else{
      self.text = nil;
      self.font = [UIFont systemFontOfSize:10.f];
      self.textColor            = [UIColor blackColor];
      self.highlightedTextColor = nil;
      self.textAlignment = NSTextAlignmentCenter;
      self.textVerticalAlignment = NRLabelVerticalAlignmentMiddle;
      self.lineBreakMode = NSLineBreakByWordWrapping;
      self.numberOfLines = 0;
      self.shadowColor   = [UIColor clearColor];
      self.shadowOffset  = CGSizeZero;
    }

    if ( !element )
      return self;
    [self parseXMLitems:element
         withAttributes:[TXMLWidgetParser elementAttributes:element]];
  }
  return self;
}

-(id)init
{
  self = [super init];
  if( self )
  {
    self.type = NSStringFromClass([self class]);
    self.text = nil;
    self.font = [UIFont systemFontOfSize:10.f];
    self.textColor            = [UIColor blackColor];
    self.highlightedTextColor = nil;
    self.textAlignment = NSTextAlignmentCenter;
    self.textVerticalAlignment = NRLabelVerticalAlignmentMiddle;
    self.lineBreakMode = NSLineBreakByWordWrapping;
    self.numberOfLines = 0;
    self.shadowColor   = [UIColor clearColor];
    self.shadowOffset  = CGSizeZero;
  }
  return self;
}

-(void)dealloc
{
  self.text        = nil;
  self.font        = nil;
  self.textColor   = nil;
  self.highlightedTextColor = nil;
  self.shadowColor = nil;
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

  NSString *szhighlightedTextColor = [attributes_ objectForKey:@"highlightedtextcolor"];
  if ( szhighlightedTextColor )
  {
    UIColor *txtColor =  [szhighlightedTextColor asColor];
    if ( txtColor )
      self.highlightedTextColor = txtColor;
  }

  NSString *txtAlignment  = [attributes_ objectForKey:@"textalignment"];
  if ( txtAlignment )
  {
    if ( [txtAlignment isEqualToString:@"right"] )
      self.textAlignment = NSTextAlignmentRight;
    else if ( [txtAlignment isEqualToString:@"left"] )
      self.textAlignment = NSTextAlignmentLeft;
  }

  NSString *txtValignment  = [attributes_ objectForKey:@"verticalalignment"];
  if ( txtValignment )
  {
    if ( [txtValignment isEqualToString:@"top"] )
      self.textVerticalAlignment = NRLabelVerticalAlignmentTop;
    else if ( [txtValignment isEqualToString:@"bottom"] )
      self.textVerticalAlignment = NRLabelVerticalAlignmentBottom;
  }
  

  NSString *szLineBreakMode  = [attributes_ objectForKey:@"linebreakmode"];
  if ( szLineBreakMode )
  {
    if ( [szLineBreakMode isEqualToString:@"characterwrap"] )
      self.lineBreakMode = NSLineBreakByCharWrapping;       // Wrap at character boundaries
    else if ( [szLineBreakMode isEqualToString:@"clip"] )
      self.lineBreakMode = NSLineBreakByClipping;                // Simply clip when it hits the end of the rect
    else if ( [szLineBreakMode isEqualToString:@"headtruncation"] )
      self.lineBreakMode = NSLineBreakByTruncatingHead;      // Truncate at head of line: "...wxyz". Will truncate multiline text on first line
    else if ( [szLineBreakMode isEqualToString:@"tailtruncation"] )
      self.lineBreakMode = NSLineBreakByTruncatingTail;      // Truncate at tail of line: "abcd...". Will truncate multiline text on last line
    else if ( [szLineBreakMode isEqualToString:@"middletruncation"] )
      self.lineBreakMode = NSLineBreakByTruncatingMiddle;    // Truncate middle of line:  "ab...yz". Will truncate multiline text in the middle
  }

  NSString *szNumberOfLines  = [attributes_ objectForKey:@"numberoflines"];
  if ( szNumberOfLines )
  {
    NSInteger val = [szNumberOfLines integerValue];
    self.numberOfLines = val < 0 ? 0 : val;
  }

  NSString *szShadowColor = [attributes_ objectForKey:@"shadowcolor"];
  if ( szShadowColor )
  {
    UIColor *shadeColor = [szShadowColor asColor];
    if ( shadeColor )
      self.shadowColor = shadeColor;
  }

  NSString *szShadowOffsetX = [attributes_ objectForKey:@"shadowoffset_x"];
  NSString *szShadowOffsetY = [attributes_ objectForKey:@"shadowoffset_y"];
  if ( szShadowOffsetX )
    self.shadowOffset = CGSizeMake( [szShadowOffsetX floatValue], self.shadowOffset.height );
  if ( szShadowOffsetY )
    self.shadowOffset = CGSizeMake( self.shadowOffset.width, [szShadowOffsetY floatValue] );
  
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
  [coder encodeObject :self.text          forKey:@"labelWidget.text" ];
  [coder encodeInteger:self.textAlignment forKey:@"labelWidget.alignment" ];
  [coder encodeInteger:self.textVerticalAlignment forKey:@"labelWidget.valignment" ];
  
  if ( self.highlightedTextColor )
    [coder  encodeObject:self.highlightedTextColor forKey:@"labelWidget.highlightedTextColor"];
  
  CGFloat red = 0.f, green = 0.f, blue = 0.f, a = 0.f;
  
  const CGFloat *components = CGColorGetComponents(self.textColor.CGColor);
  red   = components[0];
  green = components[1];
  blue  = components[2];
  a     = components[3];
 
  
  [coder encodeFloat:red   forKey:@"labelWidget.color.red"];
  [coder encodeFloat:green forKey:@"labelWidget.color.green"];
  [coder encodeFloat:blue  forKey:@"labelWidget.color.blue"];
  [coder encodeFloat:a     forKey:@"labelWidget.color.alpha"];
  
  [coder encodeInteger:self.lineBreakMode forKey:@"labelWidget.lineBreakMode"];
  [coder encodeInteger:self.numberOfLines forKey:@"labelWidget.numberOfLines"];
  
  components = CGColorGetComponents(self.shadowColor.CGColor);
  red   = components[0];
  green = components[1];
  blue  = components[2];
  a     = components[3];
  
  
  [coder encodeFloat:red   forKey:@"labelWidget.shadowColor.red"  ];
  [coder encodeFloat:green forKey:@"labelWidget.shadowColor.green"];
  [coder encodeFloat:blue  forKey:@"labelWidget.shadowColor.blue" ];
  [coder encodeFloat:a     forKey:@"labelWidget.shadowColor.alpha"];
  
  [coder encodeCGSize:self.shadowOffset forKey:@"labelWidget.shadowOffset"];
  
  [coder encodeObject:[self.font fontName]  forKey:@"labelWidget.fontName"];
  [coder encodeFloat :[self.font pointSize] forKey:@"labelWidget.fontSize"];
}

// Decode an object from an archive
- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if ( self )
  {
    self.text          = [coder decodeObjectForKey:@"labelWidget.text" ];
    self.textAlignment = [coder decodeIntegerForKey:@"labelWidget.alignment"];
    self.textVerticalAlignment = [coder decodeIntegerForKey:@"labelWidget.valignment"];

    CGFloat red        = [coder decodeFloatForKey:@"labelWidget.color.red"  ];
    CGFloat green      = [coder decodeFloatForKey:@"labelWidget.color.green"];
    CGFloat blue       = [coder decodeFloatForKey:@"labelWidget.color.blue" ];
    CGFloat a          = [coder decodeFloatForKey:@"labelWidget.color.alpha"];
    self.textColor     = [UIColor colorWithRed:red green:green blue:blue alpha:a];

    self.highlightedTextColor = [coder decodeObjectForKey:@"labelWidget.highlightedTextColor"];

    self.lineBreakMode = [coder decodeIntegerForKey:@"labelWidget.lineBreakMode"];
    self.numberOfLines = [coder decodeIntegerForKey:@"labelWidget.numberOfLines"];

    red        = [coder decodeFloatForKey:@"labelWidget.shadowColor.red"  ];
    green      = [coder decodeFloatForKey:@"labelWidget.shadowColor.green"];
    blue       = [coder decodeFloatForKey:@"labelWidget.shadowColor.blue" ];
    a          = [coder decodeFloatForKey:@"labelWidget.shadowColor.alpha"];
    self.shadowColor     = [UIColor colorWithRed:red green:green blue:blue alpha:a];

    self.shadowOffset = [coder decodeCGSizeForKey:@"labelWidget.shadowOffset"];
    
    self.font          = [UIFont fontWithName:[coder decodeObjectForKey:@"labelWidget.fontName"]
                                         size:[coder decodeFloatForKey :@"labelWidget.fontSize"]];
  }
  return self;
}

-(id)copyWithZone:(NSZone *)zone
{
  TLabelWidgetData *widgetData = [super copyWithZone:zone];
  if ( widgetData )
  {
    widgetData.text                  = [[self.text copy] autorelease];
    widgetData.font                  = self.font;
    widgetData.textColor             = self.textColor;
    widgetData.highlightedTextColor  = self.highlightedTextColor;
    widgetData.textAlignment         = self.textAlignment;
    widgetData.textVerticalAlignment = self.textVerticalAlignment;
    widgetData.lineBreakMode         = self.lineBreakMode;
    widgetData.numberOfLines         = self.numberOfLines;
    widgetData.shadowColor           = self.shadowColor;
    widgetData.shadowOffset          = self.shadowOffset;
  }
  return widgetData;
}

@end


@implementation TLabelWidget
@synthesize  labelView = m_labelView;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
      m_labelView = [[NRLabel alloc] initWithFrame:CGRectMake(0.f, 0.f, frame.size.width, frame.size.height)];
      m_labelView.autoresizesSubviews = YES;
      m_labelView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      m_labelView.backgroundColor     = [UIColor clearColor];
      m_labelView.textAlignment       = NSTextAlignmentCenter;
      m_labelView.lineBreakMode       = NSLineBreakByTruncatingTail;
      m_labelView.contentMode         = UIViewContentModeScaleAspectFit;
      m_labelView.numberOfLines       = 0;
      
      [self addSubview:m_labelView];
    }
    return self;
}

-(id)initWithParams:(TLabelWidgetData *)params_
{
  self = [super initWithParams:params_];
  if (self)
  {
    m_labelView = [[NRLabel alloc] initWithFrame:CGRectMake(0.f, 0.f, self.frame.size.width, self.frame.size.height)];
    m_labelView.autoresizesSubviews = YES;
    m_labelView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    m_labelView.contentMode         = UIViewContentModeScaleAspectFit;
    m_labelView.text          = params_.text;
    m_labelView.textColor     = params_.textColor;
    m_labelView.highlightedTextColor = params_.highlightedTextColor;
    m_labelView.textAlignment = params_.textAlignment;
    m_labelView.verticalAlignment = (NRLabelVerticalAlignment)params_.textVerticalAlignment;
    m_labelView.font          = params_.font;
    m_labelView.lineBreakMode = params_.lineBreakMode;
    m_labelView.numberOfLines = params_.numberOfLines;
    m_labelView.shadowColor   = params_.shadowColor;
    m_labelView.shadowOffset  = params_.shadowOffset;
    
    [self addSubview:m_labelView];
  }
  return self;
}

-(void)dealloc
{
  if ( m_labelView )
  {
    [m_labelView release];
    m_labelView = nil;
  }
  [super dealloc];
}


@end
