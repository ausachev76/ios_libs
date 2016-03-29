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

#import "vboxlayout.h"

@implementation TVBoxLayoutData
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

@implementation TVBoxLayout

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self)
  {
    m_height       = 1.f;
    m_staticHeight = 0.f;
  }
  return self;
}

-(void)addWidget:(TWidget *)widget_
{
  if ( !widget_ )
    return;

  m_staticHeight += widget_.margin.top + widget_.margin.bottom;
  if ( widget_.size.height > 1.f )
  {
    m_staticHeight += widget_.size.height;
  }else{
    
    NSMutableArray *flexWidgetList = [[NSMutableArray alloc] init];
    for(UIView *view in [self subviews] )
    {
      if ( ![view isKindOfClass:[TWidget class]] )
        continue;
      if ( ((TWidget*)view).flexHeight )
        [flexWidgetList addObject:view];
    }
    
    if ( widget_.flexHeight )
      [flexWidgetList addObject:widget_];
    else
    {
      m_height -= widget_.size.height;
      if ( m_height < 0.f )
      {
        widget_.size = CGSizeMake( widget_.size.width, widget_.size.height + m_height );
        m_height = 0.f;
      }
    }

    if ( flexWidgetList.count && m_height != 0.f )
    {
      CGFloat newHeight = m_height / flexWidgetList.count;
      
      for( TWidget *widget in flexWidgetList )
        [widget setSizeOnly:CGSizeMake( widget.size.width, newHeight )];
    }
    [flexWidgetList release];
  }

  [super addWidget:widget_];
}

-(void)removeWidget:(TWidget *)widget_;
{
  if ( !widget_ )
    return;

  [widget_ retain];

  [super removeWidget:widget_];

  m_staticHeight -= widget_.margin.top + widget_.margin.bottom;
  if ( widget_.size.height > 1.f )
  {
    m_staticHeight -= widget_.size.height;
  }else{
    
    NSMutableArray *flexWidgetList = [[NSMutableArray alloc] init];
    for(UIView *view in [self subviews] )
    {
      if ( ![view isKindOfClass:[TWidget class]] )
        continue;
      if ( ((TWidget*)view).flexHeight )
        [flexWidgetList addObject:view];
    }

    if ( !widget_.flexHeight )
    {
      m_height += widget_.size.height;
      if ( m_height > 1.f )
        m_height = 1.f;
    }

    if ( flexWidgetList.count && m_height != 0.f )
    {
      CGFloat newHeight = m_height / flexWidgetList.count;
      
      for( TWidget *widget in flexWidgetList )
        [widget setSizeOnly:CGSizeMake( widget.size.width, newHeight )];
    }
    [flexWidgetList release];
  }

  [widget_ release];
}


-(void)clear
{
  [super clear];
  m_height = 1.f;
  m_staticHeight = 0.f;
}

-(void)layoutSubviews
{
  [super layoutSubviews];
  
  CGSize selfSize = self.bounds.size;
  CGFloat widgetYpos = 0.f;
  
  CGFloat remHeight        = selfSize.height - m_staticHeight;
  CGFloat cumulativeHeight = 0.f;

  for(UIView *view in [self subviews] )
  {
    if ( ![view isKindOfClass:[TWidget class]] )
      continue;
    
    TWidget *pView = (TWidget*)view;
    
    CGRect rcView = pView.frame;
    
    rcView.origin.y   = widgetYpos + pView.margin.top;
    
    if ( pView.size.width > 1.f )
    {
      rcView.size.width = pView.size.width;
    }else{
      rcView.size.width = floorf((selfSize.width - (pView.margin.left + pView.margin.right)) * pView.size.width);
    }
    
    if ( pView.size.height > 1.f )
    {
      rcView.size.height = pView.size.height;
    }else{

      CGFloat widgetHeight = pView.size.height * remHeight;
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
      rcView.origin.x = pView.margin.left;
    }else if ( pView.align == WidgetAlignmentRight )
    {
      rcView.origin.x = selfSize.width - pView.margin.right - rcView.size.width;
    }else{
      rcView.origin.x = floorf( pView.margin.left + (selfSize.width - (pView.margin.left + pView.margin.right)) * 0.5f
                                                                    - rcView.size.width * 0.5f );
    }
    
    widgetYpos += pView.margin.top + rcView.size.height + pView.margin.bottom;
    
    pView.frame = rcView;
  }
}

@end
