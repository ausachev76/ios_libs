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

#import "scrollWidget.h"
#import "xmlwidgetparser.h"
#import "widgetbuilder.h"

@implementation TScrollWidgetData
@synthesize contentSize, scrollDirection, widgets = _widgets;

- (id)init
{
    self = [super init];
    if (self)
    {
      self.type = NSStringFromClass([self class]);
      _widgets = nil;
      self.contentSize     = CGSizeZero;
      self.scrollDirection = RootWidgetScrollVertical;
    }
    return self;
}

-(void)dealloc
{
  self.widgets = nil;
  [super dealloc];
}

-(void)parseXMLitems:(TBXMLElement *)item_
      withAttributes:(NSDictionary *)attributes_
{
  [super parseXMLitems:item_ withAttributes:attributes_];
  
  NSString *objType = [attributes_ objectForKey:@"type"];
  if ( [objType isEqualToString:@"vscroll"] )
    self.scrollDirection = RootWidgetScrollVertical;
  else if ( [objType isEqualToString:@"hscroll"] )
    self.scrollDirection = RootWidgetScrollHorizontal;

  TBXMLElement *contentSizeElement = [TBXML childElementNamed:@"contentSize" parentElement:item_];
  if ( contentSizeElement )
  {
    NSDictionary *elementAttrib = [TXMLWidgetParser elementAttributes:contentSizeElement];

    NSString *szWidth  = [elementAttrib objectForKey:@"width"];
    if ( szWidth )
      self.contentSize = CGSizeMake( [szWidth floatValue], self.contentSize.height );
    
    NSString *szHeight = [elementAttrib objectForKey:@"height"];
    if ( szHeight )
      self.contentSize = CGSizeMake( self.contentSize.width, [szHeight floatValue] );
  }
  
  self.widgets = [TXMLWidgetParser parseXMLforWidgets:item_];
}

@end


@implementation TScrollWidget

@synthesize widgetList = _widgetList,
            scrollView = _scrollView,
            scrollDirection,
            scrollSize;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self)
  {
    _widgetList = nil;
    _scrollView = nil;
    self.scrollDirection = RootWidgetScrollHorizontal;
    self.scrollSize      = CGSizeZero;
    
    self.scrollView = [[[UIScrollView alloc] initWithFrame:CGRectMake(0.f, 0.f, frame.size.width, frame.size.height)] autorelease];
    self.scrollView.autoresizesSubviews = YES;
    self.scrollView.autoresizingMask    = UIViewAutoresizingFlexibleWidth |
                                          UIViewAutoresizingFlexibleHeight;
    self.scrollView.backgroundColor     = [UIColor clearColor];
    self.scrollView.contentMode         = UIViewContentModeScaleAspectFit;
    
    [self addSubview:self.scrollView];
  }
  return self;
}

-(void)dealloc
{
  self.widgetList = nil;
  self.scrollView = nil;
  [super dealloc];
}

-(void)layoutSubviews
{
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
  
  NSArray *subviews = [self.scrollView subviews];
  if ( [subviews count] )
    [[subviews objectAtIndex:0] setFrame:CGRectMake( 0.f, 0.f, scrollContentSize.width, scrollContentSize.height )];
  
  self.scrollView.contentSize = scrollContentSize;
  [super layoutSubviews];
}

-(void)createUI
{
  if ( self.widgetList )
  {
    NSArray *wdtList = [TWidgetBuilder createWidgets:self.widgetList];
    if ( wdtList && wdtList.count )
    {
      TWidget *pWidget = [wdtList objectAtIndex:0];
      pWidget.frame = CGRectMake( 0,
                                  0,
                                  self.scrollView.contentSize.width,
                                  self.scrollView.contentSize.height );
      [self.scrollView addSubview:pWidget];
    }
  }
}


@end
