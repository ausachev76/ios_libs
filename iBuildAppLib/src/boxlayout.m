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

#import "boxlayout.h"
#import "widgetbuilder.h"
#import "xmlwidgetparser.h"

@implementation TBoxLayoutData
@synthesize items;
-(id)init
{
  self = [super init];
  if ( self )
  {
    self.type = NSStringFromClass([self class]);
    self.items = nil;
  }
  return self;
}

-(void)dealloc
{
  self.items = nil;
  [super dealloc];
}

-(void)parseXMLitems:(TBXMLElement *)item_
      withAttributes:(NSDictionary *)attributes_
{
  [super parseXMLitems:item_
        withAttributes:attributes_];

  self.items = [TXMLWidgetParser parseXMLforWidgets:item_];
}

// Encode an object for an archive
- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:self.items forKey:@"boxLayoutItems"];
}
// Decode an object from an archive
- (id)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if ( self )
  {
    self.items = [coder decodeObjectForKey:@"boxLayoutItems"];
  }
  return self;
}

@end

@implementation TBoxLayout

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
      self.opaque = YES;
    }
    return self;
}

-(id)initWithParams:(TBoxLayoutData *)params_
{
  self = [super initWithParams:params_];
  if (self)
  {
    NSArray *widgetList = [TWidgetBuilder createWidgets:params_.items];
    if ( widgetList )
    {
      for ( TWidget *wit in widgetList )
        [self addWidget:wit];
    }
  }
  return self;
}

-(void)addWidget:(TWidget *)widget_
{
  [self addSubview:widget_];
}

-(void)removeWidget:(TWidget *)widget_;
{
  [widget_ removeFromSuperview];
}

-(void)clear
{
  UIView *view = [self subviews].lastObject;
  while( view )
  {
    if ( ![view isKindOfClass:[TWidget class]] )
      continue;
    [view removeFromSuperview];
    view = [self subviews].lastObject;
  }
}

-(TWidget *)widgetAtIndex:(NSUInteger)index
{
  for(UIView *view in [self subviews] )
  {
    if ( ![view isKindOfClass:[TWidget class]] )
      continue;
    if ( !index-- )
      return (TWidget *)view;
  }
  return nil;
}

@end
