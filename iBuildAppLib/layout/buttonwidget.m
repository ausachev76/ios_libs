//
//  buttonwidget.m
//  layoutViewApp
//
//  Created by Mac on 09.11.12.
//  Copyright (c) 2012 Novedia Regions. All rights reserved.
//

// Modified by iBuildApp.

#import "buttonwidget.h"


@implementation TButtonWidgetData
@synthesize imgSel, textSel;
-(id)init
{
  self = [super init];
  if ( self )
  {
    self.imgSel  = nil;
    self.textSel = nil;
  }
  return self;
}

-(void)dealloc
{
  self.imgSel  = nil;
  self.textSel = nil;
  [super dealloc];
}

-(void)parseXMLitems:(TBXMLElement *)item_
      withAttributes:(NSDictionary *)attributes_
{
  [super parseXMLitems:item_ withAttributes:attributes_];
  
  TBXMLElement *imgElement = [TBXML childElementNamed:@"img"
                                        parentElement:item_];
  while( imgElement )
  {
    NSString *szSrc   = [TBXML textForElement:imgElement];
    if ( !(szSrc && [szSrc length]) )
      szSrc   = [TBXML valueOfAttributeNamed:@"src" forElement:imgElement];
    
    
    NSString *szState = [[TBXML valueOfAttributeNamed:@"state" forElement:imgElement] lowercaseString];
    if ( szSrc && szSrc.length )
    {
      if ( [szState isEqualToString:@"pressed"] )
        self.imgSel = szSrc;
      else
        self.img = szSrc;
    }
    imgElement = [TBXML nextSiblingNamed:@"img" searchFromElement:imgElement];
  }
  
  TBXMLElement *textElement = [TBXML childElementNamed:@"text"
                                        parentElement:item_];
  while( textElement )
  {
    if ( [[TBXML valueOfAttributeNamed:@"state" forElement:textElement] isEqualToString:@"pressed"] )
      self.textSel = [TBXML textForElement:textElement];
    textElement = [TBXML nextSiblingNamed:@"text" searchFromElement:textElement];
  }
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  [super encodeWithCoder:coder];
  [coder encodeObject:self.imgSel  forKey:@"TButtonWidgetData::imgSel"];
  [coder encodeObject:self.textSel forKey:@"TButtonWidgetData::textSel"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super initWithCoder:decoder];
  if ( self )
  {
    self.imgSel  = [decoder decodeObjectForKey:@"TButtonWidgetData::imgSel"];
    self.textSel = [decoder decodeObjectForKey:@"TButtonWidgetData::textSel"];
  }
  return self;
}


@end
