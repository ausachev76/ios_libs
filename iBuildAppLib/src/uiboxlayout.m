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

#import "uiboxlayout.h"
@implementation uiLayoutItem
@synthesize pos, widget = _widget;
-(id)init
{
  self = [super init];
  if ( self )
  {
    self.pos = 0;
    _widget = nil;
  }
  return self;
}

-(void)dealloc
{
  self.widget = nil;
  [super dealloc];
}

-(id)copyWithZone:(NSZone *)zone
{
  uiLayoutItem *li = [[uiLayoutItem alloc] init];
  li.pos = self.pos;
  li.widget = [[self.widget copy] autorelease];
  return li;
}

- (NSComparisonResult)compare:(uiLayoutItem *)otherObject
{
  return [[NSNumber numberWithInteger:self.pos] compare:[NSNumber numberWithInteger:otherObject.pos]];
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeInteger:self.pos   forKey:@"uiLayoutItem.pos"];
  [coder encodeObject:self.widget forKey:@"uiLayoutItem.widget"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if ( self )
  {
    self.pos    = [decoder decodeIntegerForKey:@"uiLayoutItem.pos"];
    self.widget = [decoder decodeObjectForKey :@"uiLayoutItem.widget"];
  }
  return self;
}

@end


@implementation uiBoxLayout
@synthesize subWidgets;
- (id)init
{
  self = [super init];
  if (self)
  {
    m_subWidgets = nil;
  }
  return self;
}

-(void)dealloc
{
  if ( m_subWidgets )
  {
    [m_subWidgets release];
    m_subWidgets = nil;
  }
  [super dealloc];
}

-(NSMutableArray *)subWidgets
{
  if ( !m_subWidgets )
    m_subWidgets = [[NSMutableArray alloc] init];
  return m_subWidgets;
}


-(void)addWidget:(uiWidgetData *)widget_
{
  [self.subWidgets addObject:widget_];
}


-(void)removeWidget:(uiWidgetData *)widget_;
{
  for (  uiWidgetData *wd in self.subWidgets )
  {
    if ( wd == widget_ )
    {
      NSMutableArray *widgetList = [[NSMutableArray alloc] initWithArray:self.subWidgets];
      [widgetList removeObject:widget_];
      [self clear];
      for ( uiWidgetData *wdNew in widgetList )
        [self addWidget:wdNew];
      [widgetList release];
      return;
    }else if ( [wd isKindOfClass:[uiBoxLayout class]] )
    {
      [((uiBoxLayout *)wd) removeWidget:widget_];
    }
  }
}

-(void)removeWidgets:(NSArray *)widgetList_
{
  for ( uiWidgetData *wd in widgetList_ )
    [self removeWidget:wd];
}


-(void)removeWidgetAtIndex:(NSInteger)index;
{
  [self.subWidgets removeObjectAtIndex:index];
}


-(void)clear
{
  [self.subWidgets removeAllObjects];
}


-(uiWidgetData *)widgetAtIndex:(NSUInteger)index
{
  return [self.subWidgets objectAtIndex:index];
}

-(void)layoutWidgets:(CGRect)frame
{
  [self layoutWidget:frame];
}


-(void)insertWidgets:(NSArray *)widgetList;
{
  if ( !widgetList ||
       ![widgetList count] )
    return;

  NSMutableArray *widgetSourceList = [[[NSMutableArray alloc] initWithArray:self.subWidgets copyItems:YES] autorelease];
  [self clear];

  NSMutableIndexSet *indexSet = [[[NSMutableIndexSet alloc] init] autorelease];
  NSMutableArray    *widgetsToInsert = [NSMutableArray array];
  NSMutableArray    *widgetsToAppend = [NSMutableArray array];
  for( uiLayoutItem *li in widgetList )
  {
    if ( li.pos < 0 )
    {
      [widgetsToAppend addObject:li.widget];
    }else
    {
      [widgetsToInsert addObject:li.widget];
      [indexSet addIndex:li.pos];
    }
  }
  
  @try
  {
    [widgetSourceList insertObjects:widgetsToInsert atIndexes:indexSet];
  }@catch (NSException* exception)
  {
    // Handle
  }
  if ( [widgetsToAppend count] )
    [widgetSourceList addObjectsFromArray:widgetsToAppend];
  
  [self.subWidgets addObjectsFromArray:widgetSourceList];
}


-(id)copyWithZone:(NSZone *)zone
{
  uiBoxLayout *wd = [[uiBoxLayout alloc] init];
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

- (NSString *)description
{
  NSString *str = [NSString stringWithFormat:@"\n(\%@\n);", [super description]];

  for( uiWidgetData *wi in self.subWidgets )
    [str stringByAppendingFormat:@"%@",wi];

  return str;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeObject:self.subWidgets forKey:@"uiBoxLayout.subWidgets"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if ( self )
  {
    m_subWidgets = [[decoder decodeObjectForKey:@"uiBoxLayout.subWidgets"] retain];
  }
  return self;
}


@end
