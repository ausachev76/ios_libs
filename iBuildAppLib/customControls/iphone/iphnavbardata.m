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

#import "iphnavbardata.h"
#import "labelwidget.h"
#import "NSString+colorizer.h"
#import "UINavigationBar+backgroundImage.h"

#import "UIColor+HSL.h"


@interface NSMutableDictionary(defaultValue)
-(void)setObject:(id)anObject_
          forKey:(id<NSCopying>)aKey_
widthDefaultDictionary:(NSDictionary *)default_;

@end

@implementation NSMutableDictionary(defaultValue)

-(void)setObject:(id)anObject_
          forKey:(id<NSCopying>)aKey_
widthDefaultDictionary:(NSDictionary *)default_
{
  if ( anObject_ )
    [self setObject:anObject_ forKey:aKey_];
  else if ( [default_ objectForKey:aKey_] )
    [self setObject:[default_ objectForKey:aKey_]
                         forKey:aKey_];
}
@end



@implementation UINavigationController(customNavBar)

-(NSDictionary *)textAttributesWithData:(TLabelWidgetData *)widgetData_
                      defaultAttributes:(NSDictionary *)defaultAttributes_
{
  if ( !widgetData_ )
    return nil;
  NSMutableDictionary *navBarAppearance = [[NSMutableDictionary alloc] init];
  
  // 1. UITextAttributeTextColor
  [navBarAppearance setObject:widgetData_.textColor
                       forKey:UITextAttributeTextColor
       widthDefaultDictionary:defaultAttributes_];
  
  // 2. UITextAttributeTextShadowColor
  [navBarAppearance setObject:widgetData_.shadowColor
                       forKey:UITextAttributeTextShadowColor
       widthDefaultDictionary:defaultAttributes_];
  
  // 3. UITextAttributeTextShadowOffset
  [navBarAppearance setObject:[NSValue valueWithUIOffset:UIOffsetMake(widgetData_.shadowOffset.width, widgetData_.shadowOffset.height)]
                       forKey:UITextAttributeTextShadowOffset
       widthDefaultDictionary:defaultAttributes_];
  
  // 4. UITextAttributeFont
  [navBarAppearance setObject:widgetData_.font
                       forKey:UITextAttributeFont
       widthDefaultDictionary:defaultAttributes_];
  
  if ( [navBarAppearance count] )
  {
    NSDictionary *retValue = [NSDictionary dictionaryWithDictionary:navBarAppearance];
    [navBarAppearance release];
    return retValue;
  }
  [navBarAppearance release];
  
  return nil;
}

-(void)customizeNavBarAppearance:(TIPhoneNavBarData *)navBarData
{
//  if ( navBarData && [self.navigationBar respondsToSelector:@selector(setTintColor:)] )
//  {
//    if ( navBarData.color )
//    {
//#ifdef __IPHONE_7_0
//      // detect if we run under iOS7
//      if ( [self.navigationBar respondsToSelector:@selector(barTintColor)] )
//      {
//        [self.navigationBar setBarTintColor:navBarData.color];
//        [[UIApplication sharedApplication] setStatusBarStyle:([navBarData.color isLight] ?
//                                                              UIStatusBarStyleDefault : UIStatusBarStyleLightContent ) ];
//      }else
//        [self.navigationBar setTintColor:navBarData.color];
//#else
//      [self.navigationBar setTintColor:navBarData.color];
//#endif
//    }
//
//    if ( navBarData.titleData )
//    {
//      NSDictionary *textAttributes = [self textAttributesWithData:navBarData.titleData
//                                                defaultAttributes:[[UINavigationBar appearance] titleTextAttributes]];
//      if ( textAttributes )
//        [self.navigationBar setTitleTextAttributes:textAttributes];
//    }
//    
//    if ( navBarData.barButtonData )
//    {
//      NSDictionary *defaultAppearance = [[UIBarButtonItem appearance] titleTextAttributesForState:UIControlStateNormal];
//      NSDictionary *textAttributes = [self textAttributesWithData:navBarData.barButtonData
//                                                defaultAttributes:defaultAppearance];
//      if ( textAttributes )
//      {
//        [[UIBarButtonItem appearance] setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
//        if ( ![navBarData.barButtonData.bgColor isEqual:[UIColor clearColor]] )
//          [[UIBarButtonItem appearance] setTintColor:navBarData.barButtonData.bgColor];
//#ifdef __IPHONE_7_0
//        if ( [self.navigationBar respondsToSelector:@selector(barTintColor)] )
//          [self.navigationBar setTintColor:navBarData.barButtonData.bgColor];
//#endif
//      }
//    }
//  }else{
//    [self.navigationBar setBarStyle:UIBarStyleBlack];
//
//    if ( ![self.navigationBar respondsToSelector:@selector(barTintColor)] )
//      [self.navigationBar setTintColor:[UIColor blackColor]];
//#ifdef __IPHONE_7_0
//
//    if ( [self.navigationBar respondsToSelector:@selector(barTintColor)] )
//    {
//      [self.navigationBar setTintColor:[@"#1860FF" asColor]];
//      [self.navigationBar setBarTintColor:[UIColor blackColor]];
//      TLabelWidgetData *titleData = [[[TLabelWidgetData alloc] init] autorelease];
//      titleData.bgColor   = [UIColor whiteColor];
//      titleData.textColor = [UIColor whiteColor];
//      titleData.font      = nil;
//      NSDictionary *textAttributes = [self textAttributesWithData:titleData
//                                                defaultAttributes:[[UINavigationBar appearance] titleTextAttributes]];
//      if ( textAttributes )
//        [self.navigationBar setTitleTextAttributes:textAttributes];
//      /*
//      NSDictionary *defaultAppearance = [[UIBarButtonItem appearance] titleTextAttributesForState:UIControlStateNormal];
//      textAttributes = [self textAttributesWithData:titleData
//                                  defaultAttributes:defaultAppearance];
//      if ( textAttributes )
//      {
//        [[UIBarButtonItem appearance] setTitleTextAttributes:textAttributes forState:UIControlStateNormal];
//        [[UIBarButtonItem appearance] setTitleTextAttributes:textAttributes forState:UIControlStateSelected];
//        [[UIBarButtonItem appearance] setTitleTextAttributes:textAttributes forState:UIControlStateDisabled];
//        [[UIBarButtonItem appearance] setTitleTextAttributes:textAttributes forState:UIControlStateHighlighted];
//        
//        UIColor *barColor = [UIColor blueColor];
//        [[UIBarButtonItem appearance] setTintColor:barColor];
//
//        if ( [self.navigationBar respondsToSelector:@selector(barTintColor)] )
//          [self.navigationBar setTintColor:barColor];
//      }
//      */
//      [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
//    }
//#endif
//  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:TIPhoneNavBarDataCustomizeNavBarAppearanceCompleted object:nil];
}

@end



@implementation TIPhoneNavBarData
@synthesize color = _color,
        titleData = _titleData,
    barButtonData = _barButtonData;

+(TIPhoneNavBarData *)createWithXMLElement:(TBXMLElement *)element
{
  return [[[TIPhoneNavBarData alloc] initWithXMLElement:element] autorelease];
}

-(void)initialize
{
  _color         = nil;
  _titleData     = nil;
  _barButtonData = nil;
}

-(id)init
{
  self = [super init];
  if ( self )
  {
    [self initialize];
  }
  return self;
}

-(id)initWithXMLElement:(TBXMLElement *)element
{
  self = [super init];
  if ( self )
  {
    [self initialize];
    if ( !element )
      return self;
    
    NSString *szColor = [TBXML valueOfAttributeNamed:@"color" forElement:element];
    if ( [szColor length] )
      self.color = [szColor asColor];

    TLabelWidgetData *defaultData = [[[TLabelWidgetData alloc] init] autorelease];
    defaultData.textColor   = nil;
    defaultData.shadowColor = nil;
    defaultData.font        = nil;
    
    TBXMLElement *titleElement = [TBXML childElementNamed:@"navBarTitle" parentElement:element];
    if ( titleElement )
      self.titleData = [TLabelWidgetData createWithXMLElement:titleElement defaultWidgetData:defaultData];
    
    TBXMLElement *barItemElement = [TBXML childElementNamed:@"navBarItem" parentElement:element];
    if ( barItemElement )
      self.barButtonData = [TLabelWidgetData createWithXMLElement:barItemElement defaultWidgetData:defaultData];
  }
  return self;
}

-(void)dealloc
{
  self.color         = nil;
  self.titleData     = nil;
  self.barButtonData = nil;
  [super dealloc];
}

#pragma mark NSCoding protocol
// Encode an object for an archive
- (void)encodeWithCoder:(NSCoder *)coder
{
  if ( self.color )
    [coder encodeObject:self.color forKey:@"TIPhoneNavBarData::color" ];
  if ( self.titleData )
    [coder encodeObject:self.titleData forKey:@"TIPhoneNavBarData::titleData" ];
  if ( self.barButtonData )
    [coder encodeObject:self.barButtonData forKey:@"TIPhoneNavBarData::barButtonData" ];
}

-(id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if ( self )
  {
    [self initialize];
    self.color         = [coder decodeObjectForKey:@"TIPhoneNavBarData::color"];
    self.titleData     = [coder decodeObjectForKey:@"TIPhoneNavBarData::titleData"];
    self.barButtonData = [coder decodeObjectForKey:@"TIPhoneNavBarData::barButtonData"];
  }
  return self;
}

-(id)copyWithZone:(NSZone *)zone
{
  TIPhoneNavBarData *navBarData = [[TIPhoneNavBarData alloc] init];
  navBarData.color         = self.color;
  navBarData.titleData     = [[self.titleData     copy] autorelease];
  navBarData.barButtonData = [[self.barButtonData copy] autorelease];
  return navBarData;
}

@end
