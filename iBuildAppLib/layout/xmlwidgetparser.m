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

#import "xmlwidgetparser.h"
#import "widget.h"
#import "labelwidget.h"
#import "textwidget.h"
#import "gridwidget.h"
#import "vboxlayout.h"
#import "hboxlayout.h"

@implementation TXMLWidgetParser


typedef struct tagTWidgetType
{
  NSString *type;
  NSString *className;
}TWidgetType;

// List of class names for UI elements descriptions
static const TWidgetType g_widgetTypeList[] = 
{
  { @"window"    , @"TWidgetData"      },
  { @"text"      , @"TTextWidgetData"  },
  { @"label"     , @"TLabelWidgetData" },
  { @"textfield" , @"TTextFieldWidgetData" },
  { @"grid"      , @"TGridWidgetData"  },
  { @"vboxlayout", @"TVBoxLayoutData"  },
  { @"hboxlayout", @"THBoxLayoutData"  },
  { @"hscroll"   , @"TScrollWidgetData"},
  { @"vscroll"   , @"TScrollWidgetData"},
};

+(NSString *)widgetByType:(NSString *)type_
{
  for ( unsigned i = 0; i < sizeof(g_widgetTypeList)/sizeof(g_widgetTypeList[0]); ++i )
  {
    if ( [g_widgetTypeList[i].type isEqualToString:type_] )
      return g_widgetTypeList[i].className;
  }
  return nil;
}

+(NSDictionary *)elementAttributes:(TBXMLElement *)element_
{
  if ( !element_ )
    return nil;

  NSMutableDictionary *widgetAttrib = [NSMutableDictionary dictionary];
  TBXMLAttribute *itemAttribute = element_->firstAttribute;
  while( itemAttribute )
  {
    NSString *attributeName  = [[TBXML attributeName:itemAttribute] lowercaseString];
    NSString *attributeValue = [TBXML attributeValue:itemAttribute];
    
    [widgetAttrib setObject: ( ( [attributeName isEqualToString:@"img"] ||
                                 [attributeName isEqualToString:@"src"] ) ? attributeValue : [attributeValue lowercaseString] )
                     forKey:attributeName];
    itemAttribute = itemAttribute->next;
  }
  return widgetAttrib;
}

+(NSString *)extractValueWithPercent:(NSString *)inputString_
{
  if ( !inputString_ )
    return nil;
  
  NSError* error = nil;
  NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*(\\d*\\.??\\d*)\\s*%"
                                                                         options:0
                                                                           error:&error];
  if ( error )
    return nil;
  
  NSTextCheckingResult *textCheckingResult = [regex firstMatchInString:inputString_
                                                               options:0
                                                                 range:NSMakeRange(0, inputString_.length)];
  if ( textCheckingResult )
    return [inputString_ substringWithRange:[textCheckingResult rangeAtIndex:1]];
  return nil;
}

+(CGFloat)percentValueToRelative:(CGFloat)value_
{
  if ( value_ <= 0.f )
    return 1.f;
  if ( value_ > 100.f )
    return 1.f;
  return value_ / 100.f;
}

+(NSArray *)parseXMLforWidgets:(TBXMLElement *)parent_
{
  if ( !parent_ )
    return nil;
  
  NSMutableArray *dataSet = [NSMutableArray array];
  
  TBXMLElement *rootItemElem = [TBXML childElementNamed:@"widget"
                                          parentElement:parent_];
  while (rootItemElem != nil)
  {
    NSDictionary *widgetAttrib = [TXMLWidgetParser elementAttributes:rootItemElem];
    
    NSString *widgetClassName =  [[self class] widgetByType:[widgetAttrib objectForKey:@"type"]];
    if ( !widgetClassName )
      widgetClassName = @"TWidgetData";
    
    Class clsType = NSClassFromString(widgetClassName);
    if ( clsType )
    {
      id theClass = [[clsType alloc] init];
      if ( [theClass conformsToProtocol:@protocol(IWidgetXMLDelegate) ] && 
           [theClass respondsToSelector:@selector(parseXMLitems:withAttributes:)] )
      {
        [theClass parseXMLitems:rootItemElem
                 withAttributes:widgetAttrib];
      }
      [dataSet addObject:theClass];
      [theClass release];
    }
    rootItemElem = [TBXML nextSiblingNamed:@"widget" searchFromElement:rootItemElem];
  }
  
  return dataSet;
}


@end
