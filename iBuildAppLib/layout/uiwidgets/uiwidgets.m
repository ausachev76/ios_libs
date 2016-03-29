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

//#import <objc/objc-class.h>
#import "uiwidgets.h"
#import "uiboxlayout.h"

@implementation uiRootWidget
@synthesize layout = _layout,
    layoutPortrait = _layoutPortrait,
   layoutLandscape = _layoutLandscape;


-(id)init
{
  self = [super init];
  if ( self )
  {
    _layout          = nil;
    _layoutPortrait  = nil;
    _layoutLandscape = nil;

  }
  return self;
}

-(void)dealloc
{
  self.layout          = nil;
  self.layoutPortrait  = nil;
  self.layoutLandscape = nil;
  [super dealloc];
}

-(void)layoutSubviews
{
  [super layoutSubviews];
  
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if ( self.layoutPortrait && UIInterfaceOrientationIsPortrait( orientation ) )
  {
    [self.layoutPortrait layoutWidgets:self.bounds];
  }else if ( self.layoutLandscape && UIInterfaceOrientationIsLandscape( orientation ) )
  {
    [self.layoutLandscape layoutWidgets:self.bounds];
  }else{
    [self.layout layoutWidgets:self.bounds];
  }
}
@end

@implementation uiRootImageWidget
@synthesize layout = _layout,
    layoutPortrait = _layoutPortrait,
   layoutLandscape = _layoutLandscape;

-(id)init
{
  self = [super init];
  if ( self )
  {
    _layout          = nil;
    _layoutPortrait  = nil;
    _layoutLandscape = nil;
  }
  return self;
}

-(void)dealloc
{
  self.layout          = nil;
  self.layoutPortrait  = nil;
  self.layoutLandscape = nil;
  [super dealloc];
}

-(void)layoutSubviews
{
  [super layoutSubviews];

  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  if ( self.layoutPortrait && UIInterfaceOrientationIsPortrait( orientation ) )
  {
    [self.layoutPortrait layoutWidgets:self.bounds];
  }else if ( self.layoutLandscape && UIInterfaceOrientationIsLandscape( orientation ) )
  {
    [self.layoutLandscape layoutWidgets:self.bounds];
  }else{
    [self.layout layoutWidgets:self.bounds];
  }
}
@end


@implementation uiRootScrollWidget
@synthesize layout = _layout,
    layoutPortrait = _layoutPortrait,
   layoutLandscape = _layoutLandscape,
            scrollDirection,scrollSize;

-(id)init
{
  self = [super init];
  if ( self )
  {
    _layout          = nil;
    _layoutPortrait  = nil;
    _layoutLandscape = nil;
    self.scrollDirection = RootWidgetScrollHorizontal;
    self.scrollSize      = CGSizeZero;
  }
  return self;
}

-(void)dealloc
{
  self.layout          = nil;
  self.layoutPortrait  = nil;
  self.layoutLandscape = nil;
  [super dealloc];
}

-(void)layoutSubviews
{
  [super layoutSubviews];
  CGFloat aspectRatio = 0.f;
  CGSize  scrollContentSize = CGSizeZero;

  if ( self.scrollDirection == RootWidgetScrollHorizontal )
  {
    if ( self.scrollSize.width > 0.f && self.scrollSize.height > 0.f )
      aspectRatio = self.scrollSize.width / self.scrollSize.height;
    
    if ( aspectRatio > 0.f )
    {
      scrollContentSize.width = self.bounds.size.height * aspectRatio;
    }else{

      scrollContentSize.width = self.scrollSize.width > 0.f ?
                                  self.scrollSize.width :
                                  self.bounds.size.width;
    }
    scrollContentSize.height = self.bounds.size.height;
  }else{

    if ( self.scrollSize.width > 0.f && self.scrollSize.height > 0.f )
      aspectRatio = self.scrollSize.height / self.scrollSize.width;

    if ( aspectRatio > 0.f )
    {
      scrollContentSize.height = self.bounds.size.width * aspectRatio;
    }else{

      scrollContentSize.height = self.scrollSize.height > 0.f ?
                                  self.scrollSize.height :
                                  self.bounds.size.height;
    }
    scrollContentSize.width = self.bounds.size.width;
  }
  self.contentSize = scrollContentSize;
  
  UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
  CGRect frm = CGRectMake( 0.f, 0.f, scrollContentSize.width, scrollContentSize.height );
  if ( self.layoutPortrait && UIInterfaceOrientationIsPortrait( orientation ) )
  {
    [self.layoutPortrait layoutWidgets:frm];
  }else if ( self.layoutLandscape && UIInterfaceOrientationIsLandscape( orientation ) )
  {
    [self.layoutLandscape layoutWidgets:frm];
  }else{
    [self.layout layoutWidgets:frm ];
  }
}

@end



@implementation uiWidgetData
@synthesize size = size_, relSize, margin, align, boxLayout, mutableSize, data, type, view;
-(id)init
{
  self = [super init];
  if ( self )
  {
    self.type        = nil;
    self.data        = nil;
    self.size        = CGSizeMake( 1.f, 1.f );
    self.mutableSize = self.size;
    WidgetSize rSize = {YES,YES};
    self.relSize     = rSize;
    self.margin      = MarginMake(0,0,0,0);
    self.align       = WidgetAlignmentCenter;
    self.boxLayout   = nil;
    self.view        = nil;
  }
  return self;
}

-(void)setSize:(CGSize)sz_
{
  size_       = sz_;
  mutableSize = sz_;
}

-(void)dealloc
{
  self.boxLayout = nil;
  self.view      = nil;
  self.data      = nil;
  self.type      = nil;
  [super dealloc];
}

-(void)layoutWidget:(CGRect)frame
{
  [self.view setFrame:frame];
  [self.boxLayout layoutWidgets:frame];
}

-(id)copyWithZone:(NSZone *)zone
{
  uiWidgetData *wd = [[uiWidgetData alloc] init];
  wd.type        = self.type;
  wd.data        = self.data;
  wd.size        = self.size;
  wd.mutableSize = self.mutableSize;
  wd.relSize     = self.relSize;
  wd.margin      = self.margin;
  wd.align       = self.align;
  wd.boxLayout   = [[self.boxLayout copy] autorelease];
  wd.view        = self.view;
  return wd;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeObject:self.type         forKey:@"uiWidgetData.type"];
  [coder encodeCGSize:self.size         forKey:@"uiWidgetData.size"];
  [coder encodeCGSize:self.mutableSize  forKey:@"uiWidgetData.mutableSize"];
  [coder encodeBool:self.relSize.width  forKey:@"uiWidgetData.relSize.width"];
  [coder encodeBool:self.relSize.height forKey:@"uiWidgetData.relSize.height"];
  // serialize margins
  [coder encodeFloat:self.margin.left   forKey:@"uiWidgetData.margin.left"];
  [coder encodeFloat:self.margin.right  forKey:@"uiWidgetData.margin.right"];
  [coder encodeFloat:self.margin.top    forKey:@"uiWidgetData.margin.top"];
  [coder encodeFloat:self.margin.bottom forKey:@"uiWidgetData.margin.bottom"];
  // serialize align
  [coder encodeInteger:self.align forKey:@"uiWidgetData.align"];
  
  if ( self.data && [self.data conformsToProtocol:@protocol(NSCoding)] )
    [coder encodeObject:self.data forKey:@"uiWidgetData.data"];
  
  // serialize boxLayout
  if ( self.boxLayout )
    [coder encodeObject:self.boxLayout forKey:@"uiWidgetData.boxLayout"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if ( self )
  {
    self.boxLayout = [decoder decodeObjectForKey:@"uiWidgetData.boxLayout"];
    self.data      = [decoder decodeObjectForKey:@"uiWidgetData.data"];
    self.type      = [decoder decodeObjectForKey:@"uiWidgetData.type"];
    self.size      = [decoder decodeCGSizeForKey:@"uiWidgetData.size"];
    self.mutableSize = [decoder decodeCGSizeForKey:@"uiWidgetData.mutableSize"];
    
    self.relSize = WidgetSizeMake( [decoder decodeBoolForKey:@"uiWidgetData.relSize.width"],
                                   [decoder decodeBoolForKey:@"uiWidgetData.relSize.height"] );
    
    self.margin = MarginMake([decoder decodeFloatForKey:@"uiWidgetData.margin.left"],
                             [decoder decodeFloatForKey:@"uiWidgetData.margin.right"],
                             [decoder decodeFloatForKey:@"uiWidgetData.margin.top"],
                             [decoder decodeFloatForKey:@"uiWidgetData.margin.bottom"] );
    
    self.align = (TWidgetAlignment)[decoder decodeIntegerForKey:@"uiWidgetData.align"];
  }
  return self;
}




- (NSString *)description
{
  return [NSString stringWithFormat:@"\n(\
                                      \n  type: %@\
                                      \n  size: %@\
                                      \n  relSize: {width = %@, height = %@}\
                                      \n  margin:  { %.2f, %.2f, %.2f, %.2f }\
                                      \n  align:  %d\
                                      \n  boxLayout: %@\
                                      \n  view     : %@\
                                      \n  data     : %@\
                                      \n);",
          self.type,
          NSStringFromCGSize(self.size),
          self.relSize.width ? @"YES" : @"NO", self.relSize.height ? @"YES" : @"NO",
          self.margin.left, self.margin.right, self.margin.top, self.margin.bottom,
          self.align,
          self.boxLayout,
          self.view,
          self.data ];
}


@end
