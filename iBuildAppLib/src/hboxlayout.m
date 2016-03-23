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

#import "hboxlayout.h"

@implementation THBoxLayoutData
-(id)init
{
  self = [super init];
  if ( self )
  {
    self.type = NSStringFromClass([self class]);
  }
  return self;
}

-(void)parseXMLitems:(TBXMLElement *)item_
      withAttributes:(NSDictionary *)attributes_
{
  [super parseXMLitems:item_ withAttributes:attributes_];
}

@end


@implementation THBoxLayout

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self)
  {
    m_width = 1.f;
    m_staticWidth = 0.f;
  }
  return self;
}

-(void)addWidget:(TWidget *)widget_
{
  if ( !widget_ )
    return;
  
  m_staticWidth += widget_.margin.left + widget_.margin.right;
  if ( widget_.size.width > 1.f )
  {
    m_staticWidth += widget_.size.width;
  }else{
    NSMutableArray *flexWidgetList = [[NSMutableArray alloc] init];
    
    for(UIView *view in [self subviews] )
    {
      if ( ![view isKindOfClass:[TWidget class]] )
        continue;
      if ( ((TWidget*)view).flexWidth )
        [flexWidgetList addObject:view];
    }
    
    if ( widget_.flexWidth )
      [flexWidgetList addObject:widget_];
    else
    {
      m_width -= widget_.size.width;
      if ( m_width < 0.f )
      {
        widget_.size = CGSizeMake( widget_.size.width + m_width, widget_.size.height );
        m_width = 0.f;
      }
    }

    if ( flexWidgetList.count && m_width != 0.f )
    {
      CGFloat newWidth = m_width / flexWidgetList.count;

      for( TWidget *widget in flexWidgetList )
        [widget setSizeOnly:CGSizeMake( newWidth, widget.size.height )];
    }
    [flexWidgetList release];
  }

  [self addSubview:widget_];
}

-(void)removeWidget:(TWidget *)widget_;
{
  if ( !widget_ )
    return;
  
  [widget_ retain];
  
  [widget_ removeFromSuperview];

  m_staticWidth -= widget_.margin.left + widget_.margin.right;
  if ( widget_.size.width > 1.f )
  {
    m_staticWidth -= widget_.size.width;
  }else{
    NSMutableArray *flexWidgetList = [[NSMutableArray alloc] init];
    for(UIView *view in [self subviews] )
    {
      if ( ![view isKindOfClass:[TWidget class]] )
        continue;
      if ( ((TWidget*)view).flexWidth )
        [flexWidgetList addObject:view];
    }

    if ( !widget_.flexWidth )
    {
      m_width += widget_.size.width;
      if ( m_width > 1.f )
        m_width = 1.f;
    }

    if ( flexWidgetList.count && m_width != 0.f )
    {
      CGFloat newWidth = m_width / flexWidgetList.count;
      
      for( TWidget *widget in flexWidgetList )
        [widget setSizeOnly:CGSizeMake( newWidth, widget.size.height )];
    }
    [flexWidgetList release];
  }

  [widget_ release];
}

-(void)clear
{
  [super clear];
  m_width       = 1.f;
  m_staticWidth = 0.f;
}

-(void)layoutSubviews
{
  [super layoutSubviews];
  
  CGSize selfSize = self.bounds.size;
  CGFloat widgetXpos = 0.f;
  
  CGFloat remWidth = selfSize.width - m_staticWidth;
  CGFloat cumulativeWidth = 0.f;

  for(UIView *view in [self subviews] )
  {
    if ( ![view isKindOfClass:[TWidget class]] )
      continue;
    
    TWidget *pView = (TWidget*)view;
    
    CGRect rcView = pView.frame;
    
    rcView.origin.x   = widgetXpos + pView.margin.left;

    if ( pView.size.width > 1.f )
    {
      rcView.size.width = pView.size.width;
    }else{
      CGFloat widgetWidth = pView.size.width * remWidth;
      cumulativeWidth += widgetWidth;
      if ( (cumulativeWidth - floorf(cumulativeWidth)) >= 0.5 )
      {
        rcView.size.width = ceilf( widgetWidth );
        cumulativeWidth = 0.f;
      }else{
        rcView.size.width = floorf( widgetWidth );
      }
    }

    if ( pView.size.height > 1.f )
    {
      rcView.size.height = pView.size.height;
    }else{
      rcView.size.height = floorf((selfSize.height - (pView.margin.top + pView.margin.bottom)) * pView.size.height);
    }

    if ( pView.align == WidgetAlignmentTop )
    {
      rcView.origin.y = pView.margin.top;
    }else if ( pView.align == WidgetAlignmentBottom )
    {
      rcView.origin.y = selfSize.height - pView.margin.bottom - rcView.size.height;
    }else{
      rcView.origin.y = floorf(pView.margin.top + (selfSize.height - (pView.margin.top + pView.margin.bottom)) * 0.5f
                                                                   - rcView.size.height * 0.5f);
    }
    
    widgetXpos += pView.margin.left + rcView.size.width + pView.margin.right;
    pView.frame = rcView;
  }
}



@end
