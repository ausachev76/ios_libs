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

#import "widget.h"
#import "xmlwidgetparser.h"
#import "widgettaphandler.h"
#import <QuartzCore/QuartzCore.h>
#import "notifications.h"
#import "UIView+corners.h"
#import "UIColor+RGB.h"
#import "NSString+colorizer.h"


typedef struct tagTWidgetAlignmentStrTypes
{
  TWidgetAlignment type;
  NSString         *str;
}TWidgetAlignmentStrTypes;

const TWidgetAlignmentStrTypes g_widgetAlignmentStrTypes[] = 
{
  { WidgetAlignmentCenter, @"center" },
  { WidgetAlignmentLeft  , @"left"   },
  { WidgetAlignmentRight , @"right"  },
  { WidgetAlignmentTop   , @"top"    },
  { WidgetAlignmentBottom, @"bottom" },
};

typedef struct tagTWidgetImageModeStrTypes
{
  TImageMode type;
  NSString  *str;
}TWidgetImageModeStrTypes;

const TWidgetImageModeStrTypes g_widgetImageModeStrTypes[] = 
{
  { ContentModeScaleToFill          , @"scaletofill"           },
  { ContentModeScaleAspectFit       , @"scaleaspectfit"        },
  { ContentModeScaleAspectFill      , @"scaleaspectfill"       },
  { ContentModeCenter               , @"center"                },
  { ContentModeTop                  , @"top"                   },
  { ContentModeBottom               , @"bottom"                },
  { ContentModeLeft                 , @"left"                  }, 
  { ContentModeRight                , @"right"                 },
  { ContentModeTopLeft              , @"topleft"               },
  { ContentModeTopRight             , @"topright"              },
  { ContentModeBottomLeft           , @"bottomleft"            },
  { ContentModeBottomRight          , @"bottomright"           },
  { ContentModePatternTiled         , @"patterntiled"          },
  { ContentModeStretchableFromCenter, @"stretchablefromcenter" },
};

typedef struct tagTWidgetAnimationStrTypes
{
  uiWidgetAnimation  type;
  NSString          *str;
}TWidgetAnimationStrTypes;

const TWidgetAnimationStrTypes g_widgetAnimationStrTypes[] =
{
  { uiWidgetAnimationDefault, @"default"      },
  { uiWidgetAnimationRipple , @"rippleeffect" },
};


@implementation TWidgetData
@synthesize  type = _type,
            align = _align,
          bgColor = _bgColor,
            alpha = _alpha,
              img = _img,
             mode = _mode,
             size = _size,
           margin = _margin,
  imageDictionary = _imageDictionary,
webDataDictionary = _webDataDictionary,
          relSize = _relSize,
           action = _action;

+(TWidgetData *)createWithXMLElement:(TBXMLElement *)element
{
  return [[[TWidgetData alloc] initWithXMLElement:element] autorelease];
}

-(void)initialize
{
  _type              = nil;
  _align             = WidgetAlignmentCenter;
  _bgColor           = nil;
  _alpha             = 1.f;
  _img               = nil;
  _mode              = ContentModeCenter;
  _size              = CGSizeMake( 1.f, 1.f );
  _margin            = MarginMake( 0, 0, 0, 0 );
  _imageDictionary   = nil;
  _webDataDictionary = nil;
  _relSize           = WidgetSizeMake( YES, YES );
  _action            = nil;
}

-(id)initWithXMLElement:(TBXMLElement *)element
{
  self = [super init];
  if ( self )
  {
    [self initialize];
    self.type    = NSStringFromClass([self class]);
    self.align   = WidgetAlignmentCenter;
    self.alpha   = 1.f;
    self.mode    = ContentModeCenter;
    self.relSize = WidgetSizeMake( YES, YES );
    self.size    = CGSizeMake( 1.f, 1.f );
    self.margin  = MarginMake( 0, 0, 0, 0 );
    self.bgColor = [UIColor clearColor];
    self.img     = nil;
    self.action  = [[[TWidgetAction alloc] init] autorelease];
    self.imageDictionary = nil;
    self.webDataDictionary = nil;
    if ( !element )
      return self;

    [self parseXMLitems:element
         withAttributes:[TXMLWidgetParser elementAttributes:element]];
  }
  return self;
}

-(id)init
{
  self = [super init];
  if ( self )
  {
    [self initialize];
    self.type    = NSStringFromClass([self class]);
    self.align   = WidgetAlignmentCenter;
    self.alpha   = 1.f;
    self.mode    = ContentModeCenter;
    self.relSize = WidgetSizeMake( YES, YES );
    self.size    = CGSizeMake( 1.f, 1.f );
    self.margin  = MarginMake( 0, 0, 0, 0 );
    self.bgColor = [UIColor clearColor];
    self.img     = nil;
    self.action  = [[[TWidgetAction alloc] init] autorelease];
    self.imageDictionary = nil;
    self.webDataDictionary = nil;
  }
  return self;
}

-(void)dealloc
{
  self.type    = nil;
  self.img     = nil;
  self.bgColor = nil;
  self.imageDictionary = nil;
  self.webDataDictionary = nil;
  self.action  = nil;
  [super dealloc];
}

// Encode an object for an archive
- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeObject :self.type  forKey:@"type" ];
  [coder encodeInteger:self.align forKey:@"align" ];
  
  if ( self.bgColor )
    [coder encodeObject:self.bgColor forKey:@"bgColor"];
    
  [coder encodeFloat  :self.alpha forKey:@"alpha"];
  [coder encodeObject :self.img   forKey:@"img"];
  [coder encodeInteger:self.mode  forKey:@"mode" ];
  [coder encodeCGSize :self.size  forKey:@"size"];
  [coder encodeCGRect :CGRectMake( self.margin.left, self.margin.right, self.margin.top, self.margin.bottom )
                forKey:@"margin"];
  [coder encodeBool:self.relSize.width  forKey:@"relSize.width"];
  [coder encodeBool:self.relSize.height forKey:@"relSize.height"];
  [coder encodeObject:self.action       forKey:@"action"];
}

// Decode an object from an archive
- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if ( self )
  {
    self.type  = [coder decodeObjectForKey:@"type" ];
    self.align = [coder decodeIntegerForKey:@"align" ];

    self.bgColor = [coder decodeObjectForKey:@"bgColor"];
    
    self.alpha = [coder decodeFloatForKey:@"alpha"];
    self.img   = [coder decodeObjectForKey:@"img"];
    self.mode  = [coder decodeIntegerForKey:@"mode"];
    self.size  = [coder decodeCGSizeForKey:@"size"];
    CGRect rc = [coder decodeCGRectForKey:@"margin"];
    self.margin = MarginMake( rc.origin.x, rc.origin.y, rc.size.width, rc.size.height );
    
    self.relSize = WidgetSizeMake( [coder decodeBoolForKey:@"relSize.width"],
                                   [coder decodeBoolForKey:@"relSize.height"] );
    self.action = [coder decodeObjectForKey:@"action"];
    self.imageDictionary = nil;
  }
  return self;
}

-(id)copyWithZone:(NSZone *)zone
{
  TWidgetData *widgetData = [[[self class] allocWithZone:zone] init];
  if ( widgetData )
  {
    widgetData.type  = [[self.type copy] autorelease];
    widgetData.align = self.align;
    widgetData.bgColor = self.bgColor;
    widgetData.alpha   = self.alpha;
    widgetData.img     = [[self.img copy] autorelease];
    widgetData.mode    = self.mode;
    widgetData.size    = self.size;
    widgetData.margin  = self.margin;
    widgetData.relSize = self.relSize;
    widgetData.action  = [[self.action copy] autorelease];
    widgetData.imageDictionary   = self.imageDictionary;
    widgetData.webDataDictionary = self.webDataDictionary;
  }
  return widgetData;
}


+(TWidgetAlignment)alignFromString:(NSString *)string_
{
  for( unsigned i = 0; i < sizeof(g_widgetAlignmentStrTypes)/sizeof(g_widgetAlignmentStrTypes[0]); ++i )
  {
    if ( [string_ isEqualToString:g_widgetAlignmentStrTypes[i].str] )
      return g_widgetAlignmentStrTypes[i].type;
  }
  return g_widgetAlignmentStrTypes[0].type;
}

+(TImageMode)modeFromString:(NSString *)string_
{
  for( unsigned i = 0; i < sizeof(g_widgetImageModeStrTypes)/sizeof(g_widgetImageModeStrTypes[0]); ++i )
  {
    if ( [string_ isEqualToString:g_widgetImageModeStrTypes[i].str] )
      return g_widgetImageModeStrTypes[i].type;
  }
  return ContentModeCenter;
}

+(uiWidgetAnimation)animationFromString:(NSString *)string_
{
  for( unsigned i = 0; i < sizeof(g_widgetAnimationStrTypes)/sizeof(g_widgetAnimationStrTypes[0]); ++i )
  {
    if ( [string_ isEqualToString:g_widgetAnimationStrTypes[i].str] )
      return g_widgetAnimationStrTypes[i].type;
  }
  return uiWidgetAnimationDefault;
}

-(void)parseXMLitems:(TBXMLElement *)item_
      withAttributes:(NSDictionary *)attributes_
{
  //--------------------------------------------------------------------------------------------
  //  Widget's required attributes (size and margin)
  //-------------------------------------------------------------------------------------------- 
  TBXMLElement *sizeElement = [TBXML childElementNamed:@"size"
                                         parentElement:item_];
  if ( sizeElement )
  {
    NSDictionary *sizeAttrib = [TXMLWidgetParser elementAttributes:sizeElement];
    
    NSString *width  = [sizeAttrib objectForKey:@"width"];
    NSString *height = [sizeAttrib objectForKey:@"height"];
    if ( width )
    {
      NSString *value = [TXMLWidgetParser extractValueWithPercent:width];
      if ( value )
      {
        self.size = CGSizeMake( [TXMLWidgetParser percentValueToRelative:[value floatValue]], self.size.height);
        self.relSize = WidgetSizeMake( YES, self.relSize.height );
      }else{
        self.size = CGSizeMake( [width floatValue], self.size.height );
        self.relSize = WidgetSizeMake( NO, self.relSize.height );
      }
    }
    if ( height )
    {
      NSString *value = [TXMLWidgetParser extractValueWithPercent:height];
      if ( value )
      {
        self.size = CGSizeMake( self.size.width, [TXMLWidgetParser percentValueToRelative:[value floatValue]] );
        self.relSize = WidgetSizeMake( self.relSize.width, YES );
      }else{
        self.size = CGSizeMake( self.size.width, [height floatValue] );
        self.relSize = WidgetSizeMake( self.relSize.width, NO );
      }
    }
  }
  //--------------------------------------------------------------------------------------------
  TBXMLElement *marginElement = [TBXML childElementNamed:@"margin"
                                           parentElement:item_];
  if ( marginElement )
  {
    NSDictionary *marginAttrib = [TXMLWidgetParser elementAttributes:marginElement];
    self.margin = MarginMake([[marginAttrib objectForKey:@"left"]   floatValue],
                             [[marginAttrib objectForKey:@"right"]  floatValue],
                             [[marginAttrib objectForKey:@"top"]    floatValue],
                             [[marginAttrib objectForKey:@"bottom"] floatValue] );
  }
  //--------------------------------------------------------------------------------------------
  TBXMLElement *actionElement = [TBXML childElementNamed:@"action"
                                           parentElement:item_];
  {
    NSDictionary *actionAttrib = [TXMLWidgetParser elementAttributes:actionElement];

    NSString *szActionID = [[actionAttrib objectForKey:@"id"] lowercaseString];
    if ( szActionID && szActionID.length )
    {
      if ( [szActionID isEqualToString:@"home"] )
        self.action.uid = WidgetActionHome;
      else if ( [szActionID isEqualToString:@"back"] )
        self.action.uid = WidgetActionBack;
      else if ( [szActionID isEqualToString:@"menu"] )
        self.action.uid = WidgetActionMenu;
      else if ( [szActionID isEqualToString:@"update"] )
        self.action.uid = WidgetActionUpdate;
      else if ( [szActionID isEqualToString:@"fullscreen"] )
        self.action.uid = WidgetActionFullscreen;
      else if ( [szActionID isEqualToString:@"search"] )
        self.action.uid = WidgetActionSearch;
      else if ( [szActionID isEqualToString:@"searchvariants"] )
        self.action.uid = WidgetActionSearchVariants;
      else
        self.action.uid = [szActionID integerValue];
    }
    
    NSString *szTapAnimation = [actionAttrib objectForKey:@"tapanimation"];
    if ( szTapAnimation && szTapAnimation.length )
      self.action.tapAnimation = WidgetAnimationMake( [TWidgetData animationFromString:szTapAnimation], self.action.tapAnimation.duration );

    NSString *szTapAnimationDuration = [actionAttrib objectForKey:@"tapanimationduration"];
    if ( szTapAnimationDuration )
      self.action.tapAnimation = WidgetAnimationMake( self.action.tapAnimation.style, [szTapAnimationDuration floatValue] );

    NSString *szOpenStrategy = [actionAttrib objectForKey:@"openin"];
    self.action.openStrategy = [szOpenStrategy isEqualToString:@"detail"] ? 
                                  uiWidgetOpenStrategyDetail :
                                  uiWidgetOpenStrategyDefault;
  }
  
  //--------------------------------------------------------------------------------------------
  // Parse attributes
  //--------------------------------------------------------------------------------------------
  NSString *szColor = [attributes_ objectForKey:@"bgcolor"];
  if ( !szColor )
    szColor = [attributes_ objectForKey:@"color"];
  if ( szColor )
  {
    UIColor *srcBgColor = [szColor asColor];
    if ( srcBgColor )
      self.bgColor = srcBgColor;
  }

  NSString *szAlpha = [attributes_ objectForKey:@"alpha"];
  if ( szAlpha )
  {
    CGFloat val = [szAlpha floatValue];
    self.alpha = MAX( MIN( val, 1.f ), 0.f);
  }

  NSString *szAlign = [attributes_ objectForKey:@"align"];
  if ( szAlign )
    self.align = [TWidgetData alignFromString:szAlign];
  
  NSString *szMode = [attributes_ objectForKey:@"mode"];
  if ( szMode )
    self.mode = [TWidgetData modeFromString:szMode];

  self.img = [TBXML valueOfAttributeNamed:@"img" forElement:item_];
  
  TBXMLElement *imgElement = [TBXML childElementNamed:@"img"
                                        parentElement:item_];
  if ( imgElement )
    self.img = [TBXML textForElement:imgElement];
}
@end

@implementation TActionDescriptor
@synthesize title = _title,
      description = _description,
          favIcon = _favIcon,
   disclosureIcon = _disclosureIcon,
             data = _data;

-(id)init
{
  self = [super init];
  if ( self )
  {
    _title          = nil;
    _description    = nil;
    _favIcon        = nil;
    _disclosureIcon = nil;
    _data           = nil;
  }
  return self;
}

-(void)dealloc
{
  self.title          = nil;
  self.description    = nil;
  self.favIcon        = nil;
  self.disclosureIcon = nil;
  self.data           = nil;
  [super dealloc];
}

// In the implementation
-(id)copyWithZone:(NSZone *)zone
{
  // We'll ignore the zone for now
  TActionDescriptor *ad = [[TActionDescriptor alloc] init];
  ad.title          = self.title;
  ad.description    = self.description;
  ad.favIcon        = [[self.favIcon        copy] autorelease];
  ad.disclosureIcon = [[self.disclosureIcon copy] autorelease];
  ad.data           = [[self.data           copy] autorelease];
  return ad;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
  if ( self.title )
    [coder encodeObject:self.title          forKey:@"TActionDescriptor::title"];
  if ( self.description )
    [coder encodeObject:self.description    forKey:@"TActionDescriptor::description"];
  if ( self.favIcon )
    [coder encodeObject:[self.favIcon        absoluteString] forKey:@"TActionDescriptor::favIcon"];
  if ( self.disclosureIcon )
    [coder encodeObject:[self.disclosureIcon absoluteString] forKey:@"TActionDescriptor::disclosureIcon"];
  if ( self.data && [self.data conformsToProtocol:@protocol(NSCoding)] )
    [coder encodeObject:self.data forKey:@"TActionDescriptor::data"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
  self = [super init];
  if ( self )
  {
    _title       = nil;
    _description = nil;
    _favIcon     = nil;
    _disclosureIcon = nil;
    _data           = nil;
    self.title       = [decoder decodeObjectForKey:@"TActionDescriptor::title"];
    self.description = [decoder decodeObjectForKey:@"TActionDescriptor::description"];
    
    NSString *szFavIcon = [decoder decodeObjectForKey:@"TActionDescriptor::favIcon"];
    if ( szFavIcon )
      self.favIcon = [NSURL URLWithString:szFavIcon];

    NSString *szDisclosureIcon = [decoder decodeObjectForKey:@"TActionDescriptor::disclosureIcon"];
    if ( szDisclosureIcon )
      self.disclosureIcon = [NSURL URLWithString:szDisclosureIcon];
    
    self.data = [decoder decodeObjectForKey:@"TActionDescriptor::data"];
  }
  return self;
}


@end

@implementation TWidgetAction
  @synthesize tapAnimation, uid, openStrategy, pushAnimation, descriptor = _descriptor;

-(id)init
{
  self = [super init];
  if ( self )
  {
    _descriptor = nil;
    self.tapAnimation        = WidgetAnimationMake( uiWidgetAnimationDefault, 0.5f );
    self.uid                 = WidgetActionUnknown;
    self.openStrategy        = uiWidgetOpenStrategyDefault;
    self.pushAnimation       = YES;
  }
  return self;
}

-(void)dealloc
{
  self.descriptor = nil;
  [super dealloc];
}

// In the implementation
-(id)copyWithZone:(NSZone *)zone
{
  // We'll ignore the zone for now
  TWidgetAction *waction = [[TWidgetAction alloc] init];
  waction.tapAnimation   = self.tapAnimation;
  waction.uid            = self.uid;
  waction.openStrategy   = self.openStrategy;
  waction.descriptor     = self.descriptor;
  waction.pushAnimation  = self.pushAnimation;
  return waction;
}

- (NSString *)description
{
  return [NSString stringWithFormat:@"\n{\n  uid = %ld\n  %@\n}", (long)self.uid,
                                                                  self.descriptor ];
}
// Encode an object for an archive
- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeInteger:self.tapAnimation.style    forKey:@"tapAnimation.style" ];
  [coder encodeFloat  :self.tapAnimation.duration forKey:@"tapAnimation.duration" ];
  [coder encodeInteger:self.openStrategy          forKey:@"openStrategy"];
  [coder encodeInteger:self.uid                   forKey:@"uid"];
  [coder encodeBool   :self.pushAnimation         forKey:@"pushAnimation"];
  if ( self.descriptor )
    [coder encodeObject :self.descriptor            forKey:@"descriptor"];
}
// Decode an object from an archive
- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if ( self )
  {
    _descriptor = nil;
    self.tapAnimation        = WidgetAnimationMake( [coder decodeIntegerForKey:@"tapAnimation.style"],
                                                    [coder decodeFloatForKey:@"tapAnimation.duration"] );
    self.uid                 = [coder decodeIntegerForKey:@"uid"];
    self.openStrategy        = [coder decodeIntegerForKey:@"openStrategy"];
    self.descriptor          = [coder decodeObjectForKey :@"descriptor"];
    self.pushAnimation       = [coder decodeBoolForKey   :@"pushAnimation"];
  }
  return self;
}

@end


@implementation TWidget
@synthesize size       = size_,
            flexWidth  = flexWidth_,
            flexHeight = flexHeight_,
            margin,
            align,
            action = action_;

- (id)init
{
  self = [super init];
  if (self)
  {
    TMargin mrg = {0,0,0,0};
    self.size   = CGSizeMake(1.f, 1.f);
    self.margin = mrg;
    self.action = nil;
    self.align  = WidgetAlignmentCenter;
    self.autoresizesSubviews = YES;
    self.autoresizingMask    = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  }
  return self;
}

-(id)initWithParams:(TWidgetData *)params_
{
  self = [super init];
  if (self)
  {
    self.size            = params_.size;
    self.align           = params_.align;
    self.margin          = params_.margin;
    self.backgroundColor = params_.bgColor;
    self.mode            = params_.mode;
    self.action          = params_.action;
    self.autoresizesSubviews = YES;
    self.autoresizingMask    = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
  }
  return self;
}

-(void)dealloc
{
  self.action = nil;
  [super dealloc];
}

-(void)setSize:(CGSize)sz
{
  size_ = sz;
  flexWidth_  = sz.width  == 1.f;
  flexHeight_ = sz.height == 1.f;
}

-(void)setSizeOnly:(CGSize)sz
{
  size_ = sz;
}

- (void)handleTap:(UITapGestureRecognizer*)recognizer
{
  if ( recognizer.state == UIGestureRecognizerStateEnded &&
       [recognizer.view isKindOfClass:[TWidget class]] )
  {
    TWidget *widget = (TWidget *)recognizer.view;
    if ( ![TWidgetTapHandler createAnimationForAction:widget.action
                                             withView:widget
                                             delegate:self] )
    {
      [self animationDidStop:nil finished:YES];
    }
  }
}

- (void)animationDidStop:(CAAnimation *)theAnimation
                finished:(BOOL)flag
{
  if ( flag )
    [[NSNotificationCenter defaultCenter] postNotificationName:kAPP_NOTIFICATION_WIDGET_TAP
                                                        object:[[self.action copy] autorelease]];
}

-(void)setAction:(TWidgetAction*)theAction_
{
  if ( action_ != theAction_ )
  {
    [action_ release];
    action_ = [theAction_ retain];
  }
  if ( !action_ )
    return;

  if ( action_.uid < 0 )
    return;

  for (UIGestureRecognizer *recognizer in self.gestureRecognizers )
    [self removeGestureRecognizer:recognizer];
  
  UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(handleTap:)];
  self.userInteractionEnabled = YES;
  [self addGestureRecognizer:tapRecognizer];

  [tapRecognizer release];
}

@end

extern TWidgetAnimation WidgetAnimationMake( uiWidgetAnimation style_, CGFloat duration_ );

extern WidgetSize WidgetSizeMake( BOOL width, BOOL height );

extern TMargin MarginMake(CGFloat left, CGFloat right, CGFloat top, CGFloat bottom);
