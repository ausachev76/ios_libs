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

#import "uihboxlayout.h"

@implementation uiHBoxLayout

- (id)init
{
  self = [super init];
  if (self)
  {
    m_width       = 1.f;
    m_staticWidth = 0.f;
  }
  return self;
}

-(void)addWidget:(uiWidgetData *)widget_
{
  if ( !widget_ )
    return;

  m_staticWidth += widget_.margin.left + widget_.margin.right;
  if ( !widget_.relSize.width )
  {
    m_staticWidth += widget_.size.width;
  }else{
    NSMutableArray *flexWidgetList = [[NSMutableArray alloc] init];
    for( uiWidgetData *wdData in self.subWidgets )
    {
      if ( wdData.size.width < 1.f ||
          !wdData.relSize.width )
        continue;
      [flexWidgetList addObject:wdData];
    }

    if ( !(widget_.size.width < 1.f) )
      [flexWidgetList addObject:widget_];
    else
    {
      m_width -= widget_.size.width;
      if ( m_width < 0.f )
      {
        widget_.mutableSize = CGSizeMake( widget_.size.width + m_width, widget_.size.height );
        m_width = 0.f;
      }
    }
    
    if ( flexWidgetList.count && m_width != 0.f )
    {
      CGFloat newWidth = m_width / flexWidgetList.count;
      for( uiWidgetData *wdData in flexWidgetList )
        wdData.mutableSize = CGSizeMake( newWidth, wdData.size.height );
    }
    [flexWidgetList release];
  }
  [super addWidget:widget_];
}

-(void)insertWidgets:(NSArray *)widgetList
{
  [super insertWidgets:widgetList];
  NSMutableArray *widgetSourceList = [[[NSMutableArray alloc] initWithArray:self.subWidgets copyItems:YES] autorelease];
  [self clear];
  for ( uiWidgetData *wd in widgetSourceList )
    [self addWidget:wd];
}

-(void)clear
{
  [super clear];
  m_width       = 1.f;
  m_staticWidth = 0.f;
}

-(void)layoutWidgets:(CGRect)frame
{
  CGSize selfSize = frame.size;
  CGFloat widgetXpos = frame.origin.x;
  
  CGFloat remWidth = selfSize.width - m_staticWidth;
  CGFloat cumulativeWidth = 0.f;

  for(uiWidgetData *wdData in self.subWidgets )
  {
    CGRect rcView = CGRectZero;
      
    if ( !wdData.relSize.width )
    {
      rcView.size.width = wdData.size.width;
    }else{
      CGFloat widgetWidth = wdData.mutableSize.width * remWidth;
      cumulativeWidth += widgetWidth;
      if ( (cumulativeWidth - floorf(cumulativeWidth)) >= 0.5 )
      {
        rcView.size.width = ceilf( widgetWidth );
        cumulativeWidth = 0.f;
      }else{
        rcView.size.width = floorf( widgetWidth );
      }
    }

    if ( !wdData.relSize.height )
    {
      rcView.size.height = wdData.size.height;
    }else{
      rcView.size.height = floorf((selfSize.height - (wdData.margin.top + wdData.margin.bottom)) * wdData.mutableSize.height);
    }
    
    if ( wdData.align == WidgetAlignmentTop )
    {
      rcView.origin.y = frame.origin.y + wdData.margin.top;
    }else if ( wdData.align == WidgetAlignmentBottom )
    {
      rcView.origin.y = frame.origin.y + wdData.margin.top + selfSize.height - wdData.margin.bottom - rcView.size.height;
    }else
    {
      rcView.origin.y = floorf(frame.origin.y + wdData.margin.top + (selfSize.height - (wdData.margin.top + wdData.margin.bottom)) * 0.5f
                                              - rcView.size.height * 0.5f);
    }

      CGFloat expectedOriginX = widgetXpos + wdData.margin.left;
      widgetXpos += wdData.margin.left + rcView.size.width + wdData.margin.right;
      CGFloat originX = 0.0f;
    
      if ( [wdData.type isEqualToString:@"title"] && wdData.align == WidgetAlignmentCenter) {
          CGFloat originDelta = 0.0f;
          originX = [self calculateOriginXForCeneteredView:wdData.view withRect:rcView];
          
          originDelta = originX - expectedOriginX;
        
          rcView.size.width -= originDelta;

          originX = [self calculateOriginXForCeneteredView:wdData.view withRect:rcView];
      } else {
          originX  = expectedOriginX;
      }
      rcView.origin.x = originX;
      
      [wdData layoutWidget:rcView];
  }
    [super layoutWidgets:frame];
}

-(CGFloat)calculateOriginXForCeneteredView:(UIView *)view withRect:(CGRect)rcView
{
    CGFloat originX = (view.superview.frame.size.width - rcView.size.width) / 2;
    
    return originX;
}

-(id)copyWithZone:(NSZone *)zone
{
  uiHBoxLayout *wd = [[uiHBoxLayout alloc] init];
  wd.type        = self.type;
  wd.size        = self.size;
  wd.mutableSize = self.mutableSize;
  wd.relSize     = self.relSize;
  wd.margin      = self.margin;
  wd.align       = self.align;
  wd.boxLayout   = [[self.boxLayout copy] autorelease];
  wd.view        = self.view;
  wd.data        = self.data;
  
  for( uiWidgetData *wi in self.subWidgets )
    [wd addWidget:[[wi copy] autorelease]];
  
  return wd;
}


- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeFloat:m_width       forKey:@"uiHBoxLayout.width"];
  [coder encodeFloat:m_staticWidth forKey:@"uiHBoxLayout.staticWidth"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super initWithCoder:decoder];
  if ( self )
  {
    m_width       = [decoder decodeFloatForKey:@"uiHBoxLayout.width"];
    m_staticWidth = [decoder decodeFloatForKey:@"uiHBoxLayout.staticWidth"];
  }
  return self;
}


@end
