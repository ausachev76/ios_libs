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

#import "gradientselection.h"
#import "xmlwidgetparser.h"
#import "NSString+colorizer.h"

//------------------------------------------------------------------------------------------------------
@implementation TGradientPoint
@synthesize pos, color;
-(id)init
{
  self = [super init];
  if (self)
  {
    self.pos   = 0.f;
    self.color = [UIColor clearColor];
  }
  return self;
}
-(id)initWithPos:(CGFloat)pos_
           color:(UIColor*)color_
{
  self = [super init];
  if (self)
  {
    self.pos   = pos_;
    self.color = color_;
  }
  return self;
}

-(void)dealloc
{
  self.color = nil;
  [super dealloc];
}
- (NSString *)description {
  CGFloat red = 0.f, green = 0.f, blue = 0.f, alpha = 1.f;
  [self.color getRed:&red green:&green blue:&blue alpha:&alpha ];
  return [NSString stringWithFormat:@"pos = %.2f; color = %.2X%.2X%.2X (%.2f)",
                                      self.pos,
                                      (int)(red * 255.f),
                                      (int)(green * 255.f),
                                      (int)(blue * 255.f),
                                      alpha];
}
@end

//------------------------------------------------------------------------------------------------------
@implementation TElementSelection
@synthesize direction, points, cornerRadius, padding;
-(id)init
{
  self = [super init];
  if (self)
  {
    self.padding   = CGSizeZero;
    self.direction = SelectionGradientVertical;
    self.points    = nil;
    self.cornerRadius = 0.f;
  }
  return self;
}

-(id)initWithDirection:(TSelectionGradientDirection)direction_
                points:(NSArray *)points_
          cornerRadius:(CGFloat)radius_

{
  self = [super init];
  if (self)
  {
    self.direction = direction_;
    self.points    = points_;
    self.cornerRadius = radius_;
  }
  return self;
}

-(void)dealloc
{
  self.points = nil;
  [super dealloc];
}

- (NSString *)description
{
  NSString *str = [NSString stringWithFormat:@"{\ndirection = %@", self.direction == SelectionGradientVertical ? @"vertical" : @"horizontal"];
  str = [str stringByAppendingString:@"\npoints = ( "];
  for(TGradientPoint *gp in self.points )
    str = [str stringByAppendingFormat:@"\n%@", gp ];
  str = [str stringByAppendingString:@" )\n}\n"];
  return str;
}

+(TElementSelection *)defaultSelection
{
  UIColor *colorTop    = [UIColor colorWithRed:108./255. green:178./255. blue:226./255. alpha:1.];
  UIColor *colorBottom = [UIColor colorWithRed:59./255.  green:136./255. blue:206./255. alpha:1.];
  TGradientPoint *pointTop    = [[[TGradientPoint alloc] initWithPos:0.f color:colorTop] autorelease];
  TGradientPoint *pointBottom = [[[TGradientPoint alloc] initWithPos:1.f color:colorBottom] autorelease];
  NSArray *gradientPoints = [NSArray arrayWithObjects:pointTop, pointBottom, nil];
  return [[[TElementSelection alloc] initWithDirection:SelectionGradientVertical
                                                points:gradientPoints
                                          cornerRadius:5.f] autorelease];
}

+(TElementSelection *)selectionFromXMLelement:(TBXMLElement *)element
                               withAttributes:(NSDictionary *)attributes_
{
  TElementSelection *selEl = [TElementSelection defaultSelection];
  if ( !element )
    return selEl;
  

  NSString *directionGradient =  [[attributes_ objectForKey:@"gradient"] lowercaseString];
  selEl.direction = [directionGradient isEqualToString:@"horizontal"] ? 
                            SelectionGradientHorizontal :
                            SelectionGradientVertical;

  NSString *szCornerRadius = [attributes_ objectForKey:@"cornerradius"];
  selEl.cornerRadius = [szCornerRadius floatValue];
  if ( selEl.cornerRadius < 0.f )
    selEl.cornerRadius = 0.f;
  //---------------------------------------------------------------------------------------------
  TBXMLElement *paddingElement = [TBXML childElementNamed:@"padding" parentElement:element];
  if ( paddingElement )
  {
    NSString *szWidth  = [TBXML valueOfAttributeNamed:@"width"  forElement:paddingElement];
    NSString *szHeight = [TBXML valueOfAttributeNamed:@"height" forElement:paddingElement];
    selEl.padding = CGSizeMake( (NSInteger)[szWidth floatValue], (NSInteger)[szHeight floatValue] );
  }
  //---------------------------------------------------------------------------------------------
  TBXMLElement *componentElement = [TBXML childElementNamed:@"component" parentElement:element];
  NSMutableArray *components = [NSMutableArray array];
  CGFloat invalidLocation = -1.f;
  while( componentElement )
  {
    NSString *szColor    = [TBXML valueOfAttributeNamed:@"color"    forElement:componentElement];
    NSString *szAlpha    = [TBXML valueOfAttributeNamed:@"alpha"    forElement:componentElement];
    NSString *szLocation = [TBXML valueOfAttributeNamed:@"location" forElement:componentElement];
    UIColor  *clr        = ((TGradientPoint *)[selEl.points lastObject]).color;
    if ( szColor && szColor.length )
      clr = [szColor asColor];
    if ( szAlpha && szAlpha.length )
      clr = [clr colorWithAlphaComponent:[szAlpha doubleValue]];
    
    CGFloat location = invalidLocation;
    if ( szLocation && szLocation.length )
    {
      location = [szLocation doubleValue];
      // Filtering for interval (0..1)
      // Incorrect values will be recalculated automatically.
      if ( location < 0.f )
        location = invalidLocation;
      if ( location > 1.f )
        location = invalidLocation;
    }
    invalidLocation -= 1.f;
    // add gradient point to array
    [components addObject:[[[TGradientPoint alloc] initWithPos:location color:clr] autorelease]];
    componentElement = [TBXML nextSiblingNamed:@"component" searchFromElement:componentElement];
  }
  if ( components.count < selEl.points.count )
    return selEl;
  
  CGPoint bounds = CGPointMake( 0.f, 1.f );

  TGradientPoint *ptTop    = (TGradientPoint *)[components lastObject];
  TGradientPoint *ptBottom = (TGradientPoint *)[components objectAtIndex:0];
  if (ptBottom.pos < 0.f )
    ptBottom.pos = bounds.x;
  if ( ptTop.pos < 0.f )
    ptTop.pos    = bounds.y;
  
  // Sort the array by location ascending
  NSArray *sortedArray = [components sortedArrayUsingComparator:^NSComparisonResult(id a, id b)
                          {
                            CGFloat posA = [(TGradientPoint*)a pos];
                            CGFloat posB = [(TGradientPoint*)b pos];
                            
                            if ( posA < 0.f && posB < 0.f )
                              return posA < posB;
                            return posA > posB;
                          }];
  // Location for first and last array elements is constant (0..1).
  // For points with negative location do the linear interpolation between points with correct location.
  NSInteger inIndex  = 0;
  NSInteger length   = 0;
  NSInteger ii = 0;
  CGFloat   previousPos = bounds.x;
  for( TGradientPoint *gp in sortedArray )
  {
    if ( gp.pos < 0.f )
    {
      if ( previousPos >= 0.f )
      {
        bounds = CGPointMake( previousPos, bounds.y );
        inIndex = ii;
      }
      ++length;
    }else{
      if ( previousPos < 0.f )
      {
        // mark the end of the interval
        bounds = CGPointMake( bounds.x, gp.pos );
        CGFloat mulCoef = (bounds.y - bounds.x)/(length + 1);
        NSInteger jj = 0;
        NSInteger it = inIndex;
        
        // do the linear interpolation between known points
        for(;jj < length; ++it, ++jj )
          ((TGradientPoint *)[sortedArray objectAtIndex:it]).pos = mulCoef * jj;
        inIndex = 0;
        length  = 0;
      }
    }
    previousPos = gp.pos;
    ++ii;
  }
  selEl.points = sortedArray;
  return selEl;
}

@end

