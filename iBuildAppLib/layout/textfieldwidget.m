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

#import "textfieldwidget.h"
#import "xmlwidgetparser.h"
#import "fontregistry.h"
#import "notifications.h"
#import "NSString+colorizer.h"
#import "UIView+FindViewController.h"

//-----------------------------------------------------------
@implementation TTextFieldWidgetData
  @synthesize text,
              font,
              textColor,
              textInsets,
              textAlignment,
              placeholder;
-(id)init
{
  self = [super init];
  if( self )
  {
    self.type        = NSStringFromClass([self class]);
    self.text        = nil;
    self.placeholder = nil;
    self.font        = [UIFont systemFontOfSize:10.f];
    self.textColor   = [UIColor blackColor];
    self.textAlignment = NSTextAlignmentCenter;
    self.textInsets    = UIEdgeInsetsZero;
  }
  return self;
}

-(void)dealloc
{
  self.text        = nil;
  self.font        = nil;
  self.textColor   = nil;
  self.placeholder = nil;
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
    else if ( [txtAlignment isEqualToString:@"left"] )
      self.textAlignment = NSTextAlignmentLeft;
  }
  
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
  
  TBXMLElement *placeholderElement = [TBXML childElementNamed:@"placeholder" parentElement:item_];
  if ( placeholderElement )
    self.placeholder = [TBXML textForElement:placeholderElement];
  
  TBXMLElement *insetsElement = [TBXML childElementNamed:@"insets" parentElement:item_];
  if ( insetsElement )
  {
    self.textInsets = UIEdgeInsetsMake([[TBXML valueOfAttributeNamed:@"top"    forElement:insetsElement] integerValue],
                                       [[TBXML valueOfAttributeNamed:@"left"   forElement:insetsElement] integerValue],
                                       [[TBXML valueOfAttributeNamed:@"bottom" forElement:insetsElement] integerValue],
                                       [[TBXML valueOfAttributeNamed:@"right"  forElement:insetsElement] integerValue]);
  }
  
}


@end


@implementation TCustomTextField
@synthesize inset;
-(id)init
{
  self = [super init];
  if ( self )
  {
    self.inset = UIEdgeInsetsMake(0.f, 0.f, 0.f, 0.f);
  }
  return self;
}

// placeholder position
- (CGRect)textRectForBounds:(CGRect)bounds
{
  return CGRectMake( bounds.origin.x + self.inset.left,
                     bounds.origin.y + self.inset.top,
                     bounds.size.width  - self.inset.left - self.inset.right,
                     bounds.size.height - self.inset.top  - self.inset.bottom );
}

// text position
- (CGRect)editingRectForBounds:(CGRect)bounds
{
  return CGRectMake( bounds.origin.x + self.inset.left,
                    bounds.origin.y + self.inset.top,
                    bounds.size.width  - self.inset.left - self.inset.right,
                    bounds.size.height - self.inset.top  - self.inset.bottom );
}
@end

///********************************************************************************************
///********************************************************************************************
///********************************************************************************************

@interface TTextFieldWidget()
  @property (nonatomic, retain) TCustomTextField *textField;
@end

@implementation TTextFieldWidget
@synthesize textField;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self)
  {
    UISearchBar *searchBar = [[[UISearchBar alloc] initWithFrame:CGRectZero] autorelease];
    searchBar.autoresizesSubviews = YES;
    searchBar.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    if ([[[searchBar subviews] objectAtIndex:0] isKindOfClass:[UIImageView class]]){
      [[[searchBar subviews] objectAtIndex:0] removeFromSuperview];
    }
    
    for ( UIView *view in searchBar.subviews )
    {
      if ( [view isKindOfClass:[UITextField class]] )
      {
        self.textField = (TCustomTextField *)view;
        break;
      }
    }
    self.textField.autoresizesSubviews = YES;
    self.textField.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.textField.backgroundColor     = [UIColor clearColor];
    self.textField.textAlignment       = NSTextAlignmentLeft;
    self.textField.contentMode         = UIViewContentModeScaleAspectFit;
    self.textField.clearButtonMode     = UITextFieldViewModeWhileEditing;
    self.textField.returnKeyType       = UIReturnKeySearch;
    self.textField.delegate            = self;
    [self addSubview:searchBar];
  }
  return self;
}

-(void)dealloc
{
  self.textField = nil;
  [super dealloc];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField_
{
  UIViewController *vc = [self firstAvailableUIViewController];
  if ( vc && [vc conformsToProtocol:@protocol(UITextFieldDelegate)] )
  {
    self.textField.delegate = (UIViewController<UITextFieldDelegate> *)vc;
    if ( [self.textField.delegate respondsToSelector:@selector(textFieldShouldBeginEditing:)] )
      return [self.textField.delegate textFieldShouldBeginEditing:textField_];
    return YES;
  }
  return NO;
}

@end
