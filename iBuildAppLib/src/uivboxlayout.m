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

#import "uivboxlayout.h"


@implementation uiVBoxLayout

- (id)init
{
  self = [super init];
  if (self)
  {
    m_height       = 1.f;
    m_staticHeight = 0.f;
  }
  return self;
}


-(void)addWidget:(uiWidgetData *)widget_
{
  if ( !widget_ )
    return;

  m_staticHeight += widget_.margin.top + widget_.margin.bottom;
  if ( !widget_.relSize.height )
  {
    m_staticHeight += widget_.size.height;
  }else{
    
    NSMutableArray *flexWidgetList = [[NSMutableArray alloc] init];
    for( uiWidgetData *wdData in self.subWidgets )
    {
      if ( wdData.size.height < 1.f ||
          !wdData.relSize.height )
        continue;
      [flexWidgetList addObject:wdData];
    }

    if ( !(widget_.size.height < 1.f) )
      [flexWidgetList addObject:widget_];
    else
    {
      m_height -= widget_.size.height;
      if ( m_height < 0.f )
      {
        widget_.mutableSize = CGSizeMake( widget_.size.width, widget_.size.height + m_height );
        m_height = 0.f;
      }
    }
    
    if ( flexWidgetList.count && m_height != 0.f )
    {
      CGFloat newHeight = m_height / flexWidgetList.count;
      
      for( uiWidgetData *wdData in flexWidgetList )
        wdData.mutableSize = CGSizeMake( wdData.size.width, newHeight );
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
  m_height = 1.f;
  m_staticHeight = 0.f;
}

-(void)layoutWidgets:(CGRect)frame
{
  CGSize selfSize = frame.size;
  CGFloat widgetYpos = frame.origin.y;
  CGFloat remHeight = selfSize.height - m_staticHeight;
  CGFloat cumulativeHeight = 0.f;

  for( uiWidgetData *pView in self.subWidgets )
  {
    CGRect rcView = CGRectZero;
    rcView.origin.y = widgetYpos + pView.margin.top;

    if ( !pView.relSize.width )
    {
      rcView.size.width = pView.size.width;
    }else{
      rcView.size.width = floorf((selfSize.width - (pView.margin.left + pView.margin.right)) * pView.mutableSize.width);
    }
    
    if ( !pView.relSize.height )
    {
      rcView.size.height = pView.size.height;
    }else{
      CGFloat widgetHeight = pView.mutableSize.height * remHeight;
      cumulativeHeight += widgetHeight;
      if ( (cumulativeHeight - floorf(cumulativeHeight)) >= 0.5 )
      {
        rcView.size.height = ceilf( widgetHeight );
        cumulativeHeight = 0.f;
      }else{
        rcView.size.height = floorf( widgetHeight );
      }
    }

    if ( pView.align == WidgetAlignmentLeft )
    {
      rcView.origin.x = frame.origin.x + pView.margin.left;
    }else if ( pView.align == WidgetAlignmentRight )
    {
      rcView.origin.x = frame.origin.x + pView.margin.left + selfSize.width - pView.margin.right - rcView.size.width;
    }else{
      rcView.origin.x = floorf(frame.origin.x + pView.margin.left + (selfSize.width - (pView.margin.left + pView.margin.right)) * 0.5f
                                              - rcView.size.width * 0.5f);
    }

    widgetYpos += pView.margin.top + rcView.size.height + pView.margin.bottom;
    [pView layoutWidget:rcView];
  }
  [super layoutWidgets:frame];
}

-(id)copyWithZone:(NSZone *)zone
{
  uiVBoxLayout *wd = [[uiVBoxLayout alloc] init];
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

@end
