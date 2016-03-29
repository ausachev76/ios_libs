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

#import "gridwidget.h"
#import "iconcontainer.h"
#import "widgetbuilder.h"
#import "xmlwidgetparser.h"
#import "iconcontainer.h"
#import "textwidget.h"
#import "labelwidget.h"
#import "customgridcell.h"
#import "widgettaphandler.h"
#import "notifications.h"
#import "uihboxlayout.h"
#import "uivboxlayout.h"

#import "NSString+UrlConvertion.h"
#import "NSString+colorizer.h"
#import "NSString+size.h"
#import "WidgetsInfo.h"
#import <QuartzCore/QuartzCore.h>
#import "UIImageView+WebCache.h"//<SDWebImage/UIImageView+WebCache.h>


TGridScrollLayout GridLayoutMake( NRGridViewLayoutStyle portrait_, NRGridViewLayoutStyle landscape_ )
{
  TGridScrollLayout layout = { portrait_, landscape_ };
  return layout;
}

TGridScrollColumns GridColumnsMake( NSUInteger portrait_, NSUInteger landscape_ )
{
  TGridScrollColumns columns = { portrait_, landscape_ };
  return columns;
}

//------------------------------------------------------------------------------------------------------
@implementation TGridElement
@synthesize title, description, imgLink, action, titleMaxWordWidth, descriptionMaxWordWidth;
-(id)init
{
  self = [super init];
  if (self)
  {
    self.title       = nil;
    self.description = nil;
    self.imgLink     = nil;
    self.action      = nil;
    self.titleMaxWordWidth       = 0.f;
    self.descriptionMaxWordWidth = 0.f;
  }
  return self;
}

-(void)dealloc
{
  self.title       = nil;
  self.description = nil;
  self.imgLink     = nil;
  self.action      = nil;
  [super dealloc];
}

- (BOOL)needToShowBadge
{
  if (!self.action || self.action.uid < 0)
    return NO;
  
  WidgetsInfo *wInfo = [WidgetsInfo sharedInstance];
  return [wInfo contentUpdatedForActionID:self.action.uid];
}


@end


@implementation TGridWidgetData
  @synthesize layout, columns, itemSize, items,
              imageWidgetData = m_imageWidgetData,
              titleWidgetData = _titleWidgetData,
        descriptionWidgetData = m_descriptionWidgetData,
          delimiterWidgetData = m_delimiterWidgetData,
                cellBoxLayout = m_cellBoxLayout,
                    selection = _selection,
               itemWidgetData = m_itemWidgetData,
                 headerLayout = m_headerLayout,
                 footerLayout = m_footerLayout,
         itemsBackgroundColor = _itemsBackgroundColor,
           itemsBackgroundURL = _itemsBackgroundURL,
              cellPadding,
              contentPadding,
              itemsBackgroundMode,
              headerContentSize,
              footerContentSize;
-(id)init
{
  self = [super init];
  if ( self )
  {
    m_imageWidgetData       = nil;
    _titleWidgetData       = nil;
    m_descriptionWidgetData = nil;
    m_delimiterWidgetData   = nil;
    m_itemWidgetData        = nil;
    m_cellBoxLayout         = nil;
    _selection             = nil;
    
    m_headerLayout          = nil;
    m_footerLayout          = nil;
    
    _itemsBackgroundColor    = nil;
    _itemsBackgroundURL      = nil;
    
    self.cellPadding         = CGSizeZero;
    self.contentPadding      = CGSizeZero;
    self.itemsBackgroundMode = ContentModeScaleToFill;
    
    self.type     = NSStringFromClass([self class]);
    self.layout   = GridLayoutMake( NRGridViewLayoutStyleVertical, NRGridViewLayoutStyleHorizontal );
    self.columns  = GridColumnsMake( 1, 1 );
    self.itemSize = CGSizeMake( 100.f, 100.f );
    self.headerContentSize = CGSizeZero;
    self.footerContentSize = CGSizeZero;
    self.items    = nil;
  }
  return self;
}

-(void)destroyWidgetData
{
  self.itemsBackgroundColor   = nil;
  self.itemsBackgroundURL     = nil;
  self.itemsBackgroundMode    = ContentModeScaleToFill;

  if( m_itemWidgetData )
  {
    [m_itemWidgetData release];
    m_itemWidgetData = nil;
  }
  if( m_imageWidgetData )
  {
    [m_imageWidgetData release];
    m_imageWidgetData = nil;
  }
  self.titleWidgetData = nil;
  
  if ( m_descriptionWidgetData )
  {
    [m_descriptionWidgetData release];
    m_descriptionWidgetData = nil;
  }
  if ( m_delimiterWidgetData )
  {
    [m_delimiterWidgetData release];
    m_delimiterWidgetData = nil;
  }
  if ( m_cellBoxLayout )
  {
    [m_cellBoxLayout release];
    m_cellBoxLayout = nil;
  }
  
  self.selection = nil;
  
  if ( m_headerLayout )
  {
    [m_headerLayout release];
    m_headerLayout = nil;
  }
  if ( m_footerLayout )
  {
    [m_footerLayout release];
    m_footerLayout = nil;
  }
}

-(void)dealloc
{
  [self destroyWidgetData];
  self.items = nil;
  [super dealloc];
}

-(uiBoxLayout *)parseCellElements:(TBXMLElement *)item_
                   withAttributes:(NSDictionary *)attributes_
{
  NSString *type = [attributes_ objectForKey:@"type"];
  uiBoxLayout *boxLayout = nil;
  if ( [type isEqualToString:@"hboxlayout"] )
  {
    uiHBoxLayout *hBoxLayout = [[[uiHBoxLayout alloc] init] autorelease];
    boxLayout = hBoxLayout;
  }else if ( [type isEqualToString:@"vboxlayout"] )
  {
    uiVBoxLayout *vBoxLayout = [[[uiVBoxLayout alloc] init] autorelease];
    boxLayout = vBoxLayout;
  }else{
    uiHBoxLayout *hBoxLayout = [[[uiHBoxLayout alloc] init] autorelease];
    boxLayout = hBoxLayout;
  }

  NSString *szAlign = [attributes_ objectForKey:@"align"];
  if ( szAlign )
    boxLayout.align = [TWidgetData alignFromString:szAlign];

  TBXMLElement *sizeElement = [TBXML childElementNamed:@"size"
                                         parentElement:item_];
  if ( sizeElement )
  {
    NSDictionary *sizeAttrib = [TXMLWidgetParser elementAttributes:sizeElement];
    NSString *width  = [sizeAttrib objectForKey:@"width"];
    NSString *height = [sizeAttrib objectForKey:@"height"];
    BOOL      relWidth  = YES;
    BOOL      relHeight = YES;
    if ( width )
    {
      NSString *value = [TXMLWidgetParser extractValueWithPercent:width];
      relWidth = value != nil;
      boxLayout.size  = value ?
                            CGSizeMake( [TXMLWidgetParser percentValueToRelative:[value floatValue]], boxLayout.size.height ) :
                            CGSizeMake( [width floatValue], boxLayout.size.height );
    }
    if ( height )
    {
      NSString *value = [TXMLWidgetParser extractValueWithPercent:height];
      relHeight = value != nil;
      boxLayout.size = value ?
                            CGSizeMake( boxLayout.size.width, [TXMLWidgetParser percentValueToRelative:[value floatValue]] ) :
                            CGSizeMake( boxLayout.size.width, [height floatValue] );
    }
    WidgetSize rSize = {relWidth, relHeight};
    boxLayout.relSize = rSize;
  }
  TBXMLElement *marginElement = [TBXML childElementNamed:@"margin"
                                           parentElement:item_];
  if ( marginElement )
  {
    NSDictionary *marginAttrib = [TXMLWidgetParser elementAttributes:marginElement];

    boxLayout.margin =  MarginMake([[marginAttrib objectForKey:@"left"]   floatValue],
                                   [[marginAttrib objectForKey:@"right"]  floatValue],
                                   [[marginAttrib objectForKey:@"top"]    floatValue],
                                   [[marginAttrib objectForKey:@"bottom"] floatValue] );
  }

  TBXMLElement *elements = item_->firstChild;
  while( elements )
  {
    NSString *elementName = [[TBXML elementName:elements] lowercaseString];

    if ( [elementName isEqualToString:@"image"] )
    {
      if ( m_imageWidgetData )
      {
        [m_imageWidgetData release];
        m_imageWidgetData = nil;
      }
      m_imageWidgetData = [[TWidgetData alloc] init];
      [m_imageWidgetData parseXMLitems:elements
                        withAttributes:[TXMLWidgetParser elementAttributes:elements]];
      uiWidgetData *wd = [[[uiWidgetData alloc] init] autorelease];
      wd.relSize       = m_imageWidgetData.relSize;
      wd.size          = m_imageWidgetData.size;
      wd.margin        = m_imageWidgetData.margin;
      wd.align         = m_imageWidgetData.align;
      wd.type          = @"image";

      wd.boxLayout     = [self parseCellElements:elements
                                  withAttributes:[TXMLWidgetParser elementAttributes:elements]];
      
      [boxLayout addWidget:wd];
    }else if ( [elementName isEqualToString:@"title"] )
    {

      self.titleWidgetData = [[[TLabelWidgetData alloc] init] autorelease];
      [self.titleWidgetData parseXMLitems:elements
                        withAttributes:[TXMLWidgetParser elementAttributes:elements]];
      uiWidgetData *wd = [[[uiWidgetData alloc] init] autorelease];
      wd.relSize       = self.titleWidgetData.relSize;
      wd.size          = self.titleWidgetData.size;
      wd.margin        = self.titleWidgetData.margin;
      wd.align         = self.titleWidgetData.align;
      wd.type          = @"title";
      [boxLayout addWidget:wd];
    }else if ( [elementName isEqualToString:@"description"] )
    {
      if ( m_descriptionWidgetData )
      {
        [m_descriptionWidgetData release];
        m_descriptionWidgetData = nil;
      }

      m_descriptionWidgetData = [[TLabelWidgetData alloc] init];
      [m_descriptionWidgetData parseXMLitems:elements
                              withAttributes:[TXMLWidgetParser elementAttributes:elements]];
      
      uiWidgetData *wd = [[[uiWidgetData alloc] init] autorelease];
      wd.relSize       = m_descriptionWidgetData.relSize;
      wd.size          = m_descriptionWidgetData.size;
      wd.margin        = m_descriptionWidgetData.margin;
      wd.align         = m_descriptionWidgetData.align;
      wd.type          = @"description";
      [boxLayout addWidget:wd];
    }else if ( [elementName isEqualToString:@"delimiter"] )
    {
      if ( m_delimiterWidgetData )
      {
        [m_delimiterWidgetData release];
        m_delimiterWidgetData = nil;
      }

      m_delimiterWidgetData = [[TWidgetData alloc] init];
      [m_delimiterWidgetData parseXMLitems:elements
                            withAttributes:[TXMLWidgetParser elementAttributes:elements]];
      uiWidgetData *wd = [[[uiWidgetData alloc] init] autorelease];

      wd.relSize       = m_delimiterWidgetData.relSize;
      wd.size          = m_delimiterWidgetData.size;
      wd.margin        = m_delimiterWidgetData.margin;
      wd.align         = m_delimiterWidgetData.align;
      wd.type          = @"delimiter";
      [boxLayout addWidget:wd];
    }else if ( [elementName isEqualToString:@"widget"] )
    {
      TWidgetData *widgetData = [[TWidgetData alloc] init];
      [widgetData parseXMLitems:elements
                 withAttributes:[TXMLWidgetParser elementAttributes:elements]];

      uiWidgetData *wd = [[[uiWidgetData alloc] init] autorelease];
      wd.relSize       = widgetData.relSize;
      wd.size          = widgetData.size;
      wd.margin        = widgetData.margin;
      wd.align         = widgetData.align;

      wd.boxLayout     = [self parseCellElements:elements
                                  withAttributes:[TXMLWidgetParser elementAttributes:elements]];
      [widgetData release];
      [boxLayout addWidget:wd];
    }
    elements = elements->nextSibling;
  }
  return boxLayout;
}

+(CGSize)parseContentSizeWithXMLelement:(TBXMLElement *)parent_
{
  CGSize contentSize = CGSizeZero;

  TBXMLElement *contentSizeElement = [TBXML childElementNamed:@"contentSize" parentElement:parent_];
  if ( contentSizeElement )
  {
    NSDictionary *elementAttrib = [TXMLWidgetParser elementAttributes:contentSizeElement];

    NSString *szWidth  = [elementAttrib objectForKey:@"width"];
    if ( szWidth )
      contentSize = CGSizeMake( [szWidth floatValue], contentSize.height );
    
    NSString *szHeight = [elementAttrib objectForKey:@"height"];
    if ( szHeight )
      contentSize = CGSizeMake( contentSize.width, [szHeight floatValue] );
  }
  return contentSize;
}

-(void)parseXMLitems:(TBXMLElement *)item_
      withAttributes:(NSDictionary *)attributes_
{
  [super parseXMLitems:item_
        withAttributes:attributes_];
  
  [self destroyWidgetData];
 
  TBXMLElement *layoutElement = [TBXML childElementNamed:@"layout"
                                           parentElement:item_];
  if ( layoutElement )
  {
    NSDictionary *layoutAttrib = [TXMLWidgetParser elementAttributes:layoutElement];
    NSString *portrait  = [layoutAttrib objectForKey:@"portrait"];
    NSString *landscape = [layoutAttrib objectForKey:@"landscape"];
    if ( portrait )
    {
      self.layout = GridLayoutMake( [portrait isEqualToString:@"horizontal"] ?
                                          NRGridViewLayoutStyleHorizontal :
                                          NRGridViewLayoutStyleVertical,
                                    self.layout.landscape );
    }
    if ( landscape )
    {
      self.layout = GridLayoutMake( self.layout.portrait,
                                    [landscape isEqualToString:@"horizontal"] ?
                                                NRGridViewLayoutStyleHorizontal :
                                                NRGridViewLayoutStyleVertical );
    }
  }

  TBXMLElement *columnsElement = [TBXML childElementNamed:@"columns"
                                            parentElement:item_];
  if ( columnsElement )
  {
    NSDictionary *columnsAttrib = [TXMLWidgetParser elementAttributes:columnsElement];
    NSUInteger portraitColumnCount  = self.columns.portrait;
    NSUInteger landscapeColumnCount = self.columns.landscape;
    NSString *portrait  = [columnsAttrib objectForKey:@"portrait"];
    if ( portrait )
    {
      NSInteger val = [portrait integerValue];
      portraitColumnCount = val < 1 ? 1 : val;
    }

    NSString *landscape = [columnsAttrib objectForKey:@"landscape"];
    if ( landscape )
    {
      NSInteger val = [landscape integerValue];
      landscapeColumnCount = val < 1 ? 1 : val;
    }
    self.columns = GridColumnsMake( portraitColumnCount, landscapeColumnCount );
  }
  
  TBXMLElement *itemsSizeElement = [TBXML childElementNamed:@"itemSize"
                                              parentElement:item_];
  if ( itemsSizeElement )
  {
    NSDictionary *sizeAttrib = [TXMLWidgetParser elementAttributes:itemsSizeElement];

    NSString *width  = [sizeAttrib objectForKey:@"width"];
    NSString *height = [sizeAttrib objectForKey:@"height"];
    if ( width )
    {
      CGFloat val = [width floatValue];
      self.itemSize = CGSizeMake( val < 1.f ? 1.f : val, self.size.height );
    }
    if ( height )
    {
      CGFloat val = [height floatValue];
      self.itemSize = CGSizeMake( self.size.width, val < 1.f ? 1.f : val );
    }
  }
  
  TBXMLElement *headerElement = [TBXML childElementNamed:@"header" parentElement:item_];
  if ( headerElement )
  {
    NSArray *widgets = [TXMLWidgetParser parseXMLforWidgets:headerElement];
    if ( widgets && [widgets count] )
      m_headerLayout = [[widgets lastObject] retain];
    self.headerContentSize = [[self class] parseContentSizeWithXMLelement:headerElement];
  }
  TBXMLElement *fotterElement = [TBXML childElementNamed:@"footer" parentElement:item_];
  if ( fotterElement )
  {
    NSArray *widgets = [TXMLWidgetParser parseXMLforWidgets:fotterElement];
    if ( widgets && [widgets count] )
      m_footerLayout = [[widgets lastObject] retain];

    self.footerContentSize = [[self class] parseContentSizeWithXMLelement:fotterElement];
  }

  uiBoxLayout *boxLayout = nil;
  TBXMLElement *gridItem = [TBXML childElementNamed:@"griditem"
                                      parentElement:item_];
  if ( !gridItem )
    gridItem = [TBXML childElementNamed:@"tabbaritem"
                          parentElement:item_];
  if ( gridItem )
  {
    //----------------------------------------------------------------------------
    TBXMLElement *selectionElement = [TBXML childElementNamed:@"selection"
                                                parentElement:gridItem];
    self.selection = [TElementSelection selectionFromXMLelement:selectionElement
                                                 withAttributes:[TXMLWidgetParser elementAttributes:selectionElement]];
    //----------------------------------------------------------------------------
    TBXMLElement *paddingElement = [TBXML childElementNamed:@"padding" parentElement:gridItem];
    if ( paddingElement )
    {
      NSString *szWidth  = [TBXML valueOfAttributeNamed:@"width"  forElement:paddingElement];
      NSString *szHeight = [TBXML valueOfAttributeNamed:@"height" forElement:paddingElement];
      self.cellPadding = CGSizeMake( (NSInteger)[szWidth floatValue], (NSInteger)[szHeight floatValue] );
    }
    //----------------------------------------------------------------------------
    m_itemWidgetData = [[TWidgetData alloc] init];
    [m_itemWidgetData parseXMLitems:gridItem
                     withAttributes:[TXMLWidgetParser elementAttributes:gridItem]];
    
    TBXMLElement *layoutElement = [TBXML childElementNamed:@"widget"
                                             parentElement:gridItem];
    if ( layoutElement )
    {
      boxLayout = [self parseCellElements:layoutElement
                           withAttributes:[TXMLWidgetParser elementAttributes:layoutElement]];
    }
  }
  
  if ( !boxLayout )
    return;

  m_cellBoxLayout = [boxLayout retain];
  
  // List of items for gridView is described as follws:
  // <items>
  //   <element>
  //     <title>
  //       some text
  //     </title>
  //     <description>
  //       some description
  //     </description>
  //     <img src = "http://url.com"/>
  //   </element>
  // </items>
  // grid view may have widgets inside <items> tags
  // So the recursive search is prescribed.
  TBXMLElement *gridItems = [TBXML childElementNamed:@"items" parentElement:item_];
  if ( !gridItems )
    return;

  TBXMLElement *elementBackground = [TBXML childElementNamed:@"background" parentElement:gridItems];
  if ( elementBackground )
  {
    NSString *szBackgoundImage  = [TBXML valueOfAttributeNamed:@"img"   forElement:elementBackground];
    NSString *szMode            = [TBXML valueOfAttributeNamed:@"mode"  forElement:elementBackground];
    NSString *szBackgroundColor = [TBXML valueOfAttributeNamed:@"color" forElement:elementBackground];
    self.itemsBackgroundURL   = [szBackgoundImage asURL];
    self.itemsBackgroundColor = [szBackgroundColor asColor];
    self.itemsBackgroundMode  = [TWidgetData modeFromString:[szMode lowercaseString]];

    TBXMLElement *imgElement = [TBXML childElementNamed:@"img"
                                          parentElement:elementBackground];
    if ( imgElement )
      self.itemsBackgroundURL = [[TBXML textForElement:imgElement] asURL];
  }

  TBXMLElement *paddingElement = [TBXML childElementNamed:@"padding" parentElement:gridItems];
  if ( paddingElement )
  {
    NSString *szWidth  = [TBXML valueOfAttributeNamed:@"width"  forElement:paddingElement];
    NSString *szHeight = [TBXML valueOfAttributeNamed:@"height" forElement:paddingElement];
    self.contentPadding = CGSizeMake( (NSInteger)[szWidth floatValue], (NSInteger)[szHeight floatValue] );
  }
  NSMutableArray *itemsList = [[NSMutableArray alloc] init];
  
  TBXMLElement *gridElement = [TBXML childElementNamed:@"element"
                                         parentElement:gridItems];
  while( gridElement )
  {
    TBXMLElement *titleElement = [TBXML childElementNamed:@"title"
                                            parentElement:gridElement];
    TBXMLElement *descriptionElement = [TBXML childElementNamed:@"description"
                                                  parentElement:gridElement];
    TBXMLElement *imgElement = [TBXML childElementNamed:@"img"
                                          parentElement:gridElement];
    TBXMLElement *actionElement = [TBXML childElementNamed:@"action"
                                             parentElement:gridElement];
    
    TGridElement *gridItem = [[TGridElement alloc] init];
    
    if ( titleElement )
      gridItem.title = [TBXML textForElement:titleElement];
    
    if ( descriptionElement )
      gridItem.description = [TBXML textForElement:descriptionElement];
    
    if ( imgElement )
    {
      gridItem.imgLink = [TBXML valueOfAttributeNamed:@"src" forElement:imgElement];
      
      NSString *imgSrc = [TBXML textForElement:imgElement];
      if ( imgSrc && [imgSrc length] )
        gridItem.imgLink = imgSrc;
    }
    
    if ( actionElement )
    {
      NSDictionary *actionAttrib = [TXMLWidgetParser elementAttributes:actionElement];
      
      TWidgetAction *wAction = [[TWidgetAction alloc] init];

      NSString *szActionID = [actionAttrib objectForKey:@"id"];
      if ( szActionID )
        wAction.uid = [szActionID integerValue];

      NSString *szTapAnimation = [actionAttrib objectForKey:@"tapanimation"];
      if ( szTapAnimation && szTapAnimation.length )
        wAction.tapAnimation = WidgetAnimationMake( [TWidgetData animationFromString:szTapAnimation], wAction.tapAnimation.duration );

      NSString *szTapAnimationDuration = [actionAttrib objectForKey:@"tapanimationduration"];
      if ( szTapAnimationDuration )
        wAction.tapAnimation = WidgetAnimationMake( wAction.tapAnimation.style, [szTapAnimationDuration floatValue] );
      
      NSString *szOpenStrategy = [[actionAttrib objectForKey:@"openin"] lowercaseString];
        wAction.openStrategy = [szOpenStrategy isEqualToString:@"detail"] ? 
                                    uiWidgetOpenStrategyDetail :
                                    uiWidgetOpenStrategyDefault;
      
      gridItem.action = wAction;
      [wAction release];
      
      
    }
    
    [itemsList addObject:gridItem];
    [gridItem release];

    gridElement = [TBXML nextSiblingNamed:@"element"
                        searchFromElement:gridElement];
  }

  if ( itemsList.count )
    self.items = itemsList;
  
  [itemsList release];
}


@end
//------------------------------------------------------------------------------------------------------

@implementation TGridWidget
@synthesize gridView = m_gridView,
               items = m_items,
        scrollLayout = m_scrollLayout,
       scrollColumns = m_scrollColumns,
            itemSize = m_itemSize,
        headerWidget = _headerWidget,
        footerWidget = _footerWidget,
          headerContentSize,
          footerContentSize,
            cellBoxLayout,
            cellPadding,
            contentPadding,
            selection,
            itemWidgetData,
            imageWidgetData,
            titleWidgetData = _titleWidgetData,
      descriptionWidgetData = _descriptionWidgetData,
            delimiterWidgetData;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self)
  {
    m_widgetRect = frame;
    
    _headerWidget = nil;
    _footerWidget = nil;
    _titleWidgetData       = nil;
    _descriptionWidgetData = nil;
    headerContentSize   = CGSizeZero;
    footerContentSize   = CGSizeZero;
    self.cellPadding    = CGSizeZero;
    self.contentPadding = CGSizeZero;
    self.items = nil;
    self.opaque = YES;
    self.selection = [TElementSelection defaultSelection];
    self.imageWidgetData       = nil;
    self.titleWidgetData       = nil;
    self.descriptionWidgetData = nil;
    self.delimiterWidgetData   = nil;
    self.cellBoxLayout         = nil;
    
    CGSize defaultSize = frame.size;
    m_gridView = [[NRGridView alloc] initWithFrame:CGRectMake( 0.f, 0.f, defaultSize.width, defaultSize.height )];

    m_scrollLayout  = GridLayoutMake( NRGridViewLayoutStyleVertical, NRGridViewLayoutStyleHorizontal );
    m_scrollColumns = GridColumnsMake( 2, 3 );
    m_itemSize      = CGSizeMake( 256.f, 198.f );
    m_scrollPos     = CGPointMake( 0.f, 0.f );
    
    m_bPortraitOrientation = UIInterfaceOrientationIsPortrait( [[UIApplication sharedApplication] statusBarOrientation] );
    m_gridView.layoutStyle         =  m_bPortraitOrientation ?
                                        m_scrollLayout.portrait :
                                        m_scrollLayout.landscape;
    m_gridView.autoresizesSubviews = YES;
    m_gridView.autoresizingMask    = UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight;
    m_gridView.delegate            = self;
    m_gridView.dataSource          = self;
    m_gridView.backgroundColor     = [UIColor clearColor];

    m_gridView.cellSize = m_itemSize;
    [self addSubview:m_gridView];
  }
  return self;
}

-(void)setContentPadding:(CGSize)contentPadding_
{
  m_gridView.contentMargin = UIEdgeInsetsMake(contentPadding_.height,
                                              contentPadding_.width,
                                              contentPadding_.height,
                                              contentPadding_.width );
}

-(void)calcMaxWordWidth
{
#ifdef ADAPTIVE_LABEL_BEHAVIOR
  if ( !self.items ||
       !self.titleWidgetData ||
       !self.descriptionWidgetData )
    return;
  
  for( TGridElement *element in self.items )
  {
    element.titleMaxWordWidth       = [element.title       calcMaxWordWidthWithFont:self.titleWidgetData.font];
    element.descriptionMaxWordWidth = [element.description calcMaxWordWidthWithFont:self.descriptionWidgetData.font];
  }
#endif
}

-(void)setItems:(NSArray *)items_
{
  if ( m_items != items_ )
  {
    [m_items release];
    m_items = [items_ retain];
  }
  [self calcMaxWordWidth];
}

-(void)setTitleWidgetData:(TLabelWidgetData *)titleWidgetData_
{
  if ( _titleWidgetData != titleWidgetData_ )
  {
    [_titleWidgetData release];
    _titleWidgetData = [titleWidgetData_ retain];
  }
  [self calcMaxWordWidth];
}

-(void)setDescriptionWidgetData:(TLabelWidgetData *)descriptionWidgetData_
{
  if ( _descriptionWidgetData != descriptionWidgetData_ )
  {
    [_descriptionWidgetData release];
    _descriptionWidgetData = [descriptionWidgetData_ retain];
  }
  [self calcMaxWordWidth];
}

-(id)initWithParams:(TGridWidgetData *)params_
{
  self = [super initWithParams:params_];
  if (self)
  {
    m_gridView = [[NRGridView alloc] initWithFrame:CGRectMake( 0.f, 0.f, self.frame.size.width, self.frame.size.height )];
    
    _headerWidget = nil;
    _footerWidget = nil;
    
    self.itemWidgetData        = nil;
    self.imageWidgetData       = nil;
    self.titleWidgetData       = nil;
    self.descriptionWidgetData = nil;
    self.delimiterWidgetData   = nil;
    self.cellBoxLayout         = nil;
    
    if ( params_.headerLayout )
    {
      NSArray *wdtList = [TWidgetBuilder createWidgets:[NSArray arrayWithObject:params_.headerLayout]];
      if ( wdtList && wdtList.count )
        self.headerWidget = [wdtList objectAtIndex:0];
    }
    if ( params_.headerLayout )
    {
      NSArray *wdtList = [TWidgetBuilder createWidgets:[NSArray arrayWithObject:params_.footerLayout]];
      if ( wdtList && wdtList.count )
        self.footerWidget = [wdtList objectAtIndex:0];
    }
    
    self.headerContentSize = params_.headerContentSize;
    self.footerContentSize = params_.footerContentSize;

    
    m_scrollLayout  = params_.layout;
    m_scrollColumns = params_.columns;
    m_itemSize      = params_.itemSize;
    self.items      = params_.items;
    m_scrollPos     = CGPointMake( 0.f, 0.f );
    
    BOOL bPortraitOrientation = UIInterfaceOrientationIsPortrait( [[UIApplication sharedApplication] statusBarOrientation] );
    m_gridView.layoutStyle         =  bPortraitOrientation ?
                                        m_scrollLayout.portrait :
                                        m_scrollLayout.landscape;
    m_gridView.autoresizesSubviews = YES;
    m_gridView.autoresizingMask    = UIViewAutoresizingFlexibleWidth |
                                     UIViewAutoresizingFlexibleHeight;
    m_gridView.delegate            = self;
    m_gridView.dataSource          = self;
    m_gridView.backgroundColor     = [UIColor clearColor];
    
    m_gridView.cellSize            = m_gridView.layoutStyle == NRGridViewLayoutStyleVertical ?
    CGSizeMake( self.frame.size.width / ( bPortraitOrientation ? m_scrollColumns.portrait : m_scrollColumns.landscape),
                self.frame.size.height ) :
    CGSizeMake( self.frame.size.width,
                self.frame.size.height / ( bPortraitOrientation ? m_scrollColumns.portrait : m_scrollColumns.landscape) );
    [self addSubview:m_gridView];
  }
  return self;
}

-(void)dealloc
{
  if ( m_gridView )
  {
    [m_gridView release];
    m_gridView = nil;
  }
  
  self.headerWidget          = nil;
  self.footerWidget          = nil;
  
  self.items                 = nil;
  self.itemWidgetData        = nil;
  self.imageWidgetData       = nil;
  self.titleWidgetData       = nil;
  self.descriptionWidgetData = nil;
  self.delimiterWidgetData   = nil;
  self.cellBoxLayout         = nil;
  self.selection             = nil;
  [super dealloc];
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  m_scrollPos = CGPointMake( scrollView.contentSize.width  ? scrollView.contentOffset.x / scrollView.contentSize.width  : 0.f,
                             scrollView.contentSize.height ? scrollView.contentOffset.y / scrollView.contentSize.height : 0.f );
}


-(void)layoutView:(UIView *)view_
  withContentSize:(CGSize )contentSize_
  scrollDirection:(NRGridViewLayoutStyle)layoutStyle_
{
  CGFloat aspectRatio = 0.f;
  CGSize  contentSize = CGSizeZero;
  
  if ( layoutStyle_ == NRGridViewLayoutStyleHorizontal )
  {
    if ( contentSize_.width > 0.f && contentSize_.height > 0.f )
      aspectRatio = contentSize_.width / contentSize_.height;
    if ( aspectRatio > 0.f )
    {
      contentSize.width = self.bounds.size.height * aspectRatio;
    }else{
      contentSize.width = contentSize_.width > 0.f ?
                          contentSize_.width :
                          self.bounds.size.width;
    }
    contentSize.height = self.bounds.size.height;
  }else{
    if ( contentSize_.width > 0.f && contentSize_.height > 0.f )
      aspectRatio = contentSize_.height / contentSize_.width;
    
    if ( aspectRatio > 0.f )
    {
      contentSize.height = self.bounds.size.width * aspectRatio;
    }else{
      contentSize.height = contentSize_.height > 0.f ?
                            contentSize_.height :
                            self.bounds.size.height;
    }
    contentSize.width = self.bounds.size.width;
  }
  CGRect frc = view_.frame;
  frc.size = contentSize;
  view_.frame = frc;
}


-(void)layoutSubviews
{
  BOOL bPortraitOrientation = UIInterfaceOrientationIsPortrait( [[UIApplication sharedApplication] statusBarOrientation] );
  
  if ( CGRectEqualToRect(self.frame, m_widgetRect ) && (m_bPortraitOrientation == bPortraitOrientation ) )
    return;
  NRGridViewLayoutStyle newLayout      = bPortraitOrientation ?
                                            m_scrollLayout.portrait :
                                            m_scrollLayout.landscape;
  
  m_bPortraitOrientation = bPortraitOrientation;
  m_widgetRect = self.frame;
  
  if ( self.gridView.gridHeaderView )
  {
    [self layoutView:self.gridView.gridHeaderView
     withContentSize:self.headerContentSize
     scrollDirection:newLayout];
  }

  if ( self.gridView.gridFooterView )
  {
    [self layoutView:self.gridView.gridFooterView
     withContentSize:self.footerContentSize
     scrollDirection:newLayout];
  }

  CGPoint scrollPos = m_scrollPos;

  [super layoutSubviews];
  
  CGSize frmSize = m_gridView.frame.size;

  NRGridViewLayoutStyle previousLayout = m_gridView.layoutStyle;

  CGSize cellSize = ( newLayout == NRGridViewLayoutStyleVertical ) ?
                            CGSizeMake( (frmSize.width - m_gridView.contentMargin.left - m_gridView.contentMargin.right) /
                                        ( bPortraitOrientation ? m_scrollColumns.portrait : m_scrollColumns.landscape),
                                        m_itemSize.height ) :
                            CGSizeMake( m_itemSize.width,
                                        (frmSize.height - m_gridView.contentMargin.top - m_gridView.contentMargin.bottom) /
                                        ( bPortraitOrientation ? m_scrollColumns.portrait : m_scrollColumns.landscape) );
  m_gridView.layoutStyle    = newLayout;
  m_gridView.cellSize       = cellSize;

  CGPoint contentOffset;

  if ( previousLayout == NRGridViewLayoutStyleVertical )
  {
    if ( newLayout == NRGridViewLayoutStyleVertical )
    {
      contentOffset = CGPointMake( m_gridView.contentOffset.x, scrollPos.y * m_gridView.contentSize.height );
    }else{
      contentOffset = CGPointMake( scrollPos.y * m_gridView.contentSize.width, m_gridView.contentOffset.y );
    }
  }else{
    if ( newLayout == NRGridViewLayoutStyleVertical )
    {
      contentOffset = CGPointMake( m_gridView.contentOffset.x, scrollPos.x * m_gridView.contentSize.height  );
    }else{
      contentOffset = CGPointMake( scrollPos.x * m_gridView.contentSize.width, m_gridView.contentOffset.y );
    }
  }
  m_gridView.contentOffset = contentOffset;
  NSArray *ips = [m_gridView indexPathsForSelectedCells];
  [m_gridView reloadData];
  if ( ips && ips.count )
    [m_gridView selectCellAtIndexPath:[ips lastObject] animated:NO];
}

#pragma mark - NRGridView Data Source
- (NSInteger)numberOfSectionsInGridView:(NRGridView *)gridView
{
  return 1;
}

-  (NSInteger)gridView:(NRGridView *)gridView
numberOfItemsInSection:(NSInteger)section
{
  return self.items.count;
}

+(void)attachCellSubviews:(TCustomGridCell *)cell_
              toBoxLayout:(uiBoxLayout *)boxLayout_
{
  for( uiWidgetData *wData in boxLayout_.subWidgets )
  {
    if ( wData.boxLayout )
      [self attachCellSubviews:cell_ toBoxLayout:wData.boxLayout];
    if ( [wData.type isEqualToString:@"image"] )
    {
      wData.view = cell_.imageView;
    }else if ( [wData.type isEqualToString:@"title"] )
    {
      wData.view = cell_.textLabel;
    }else if ( [wData.type isEqualToString:@"description"] )
    {
      wData.view = cell_.detailedTextLabel;
    }else if ( [wData.type isEqualToString:@"delimiter"] )
    {
      wData.view = cell_.delimiterView;
    }
  }
}

- (NRGridViewCell*)gridView:(NRGridView *)gridView
     cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *MyCellIdentifier = @"MyCellIdentifier";
  
  TCustomGridCell* cell = (TCustomGridCell *)[gridView dequeueReusableCellWithIdentifier:MyCellIdentifier];
  
  if(cell == nil)
  {
    cell = [[[TCustomGridCell alloc] initWithReuseIdentifier:MyCellIdentifier] autorelease];
    cell.backgroundColor = [UIColor clearColor];
    cell.selection   = self.selection;
    cell.cellPadding = self.cellPadding;
    
    cell.layout            = [[self.cellBoxLayout copy] autorelease];
    cell.imageWidget       = self.imageWidgetData;
    cell.titleWidget       = self.titleWidgetData;
    cell.descriptionWidget = self.descriptionWidgetData;
    cell.delimiterWidget   = self.delimiterWidgetData;

    cell.imageView.clipsToBounds   = YES;
    cell.contentView.clipsToBounds = YES;
    
    if ( self.itemWidgetData )
    {
      id obj = [self.itemWidgetData.imageDictionary objectForKey:self.itemWidgetData.img];
      if ( [obj isKindOfClass:[UIImage class]] )
      {
        UIImage *img = (UIImage *)obj;

        UIImageView *pBackgroundView = [[[UIImageView alloc] init] autorelease];
        pBackgroundView.clipsToBounds       = YES;
        pBackgroundView.autoresizesSubviews = YES;
        pBackgroundView.opaque              = YES;
        pBackgroundView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        pBackgroundView.backgroundColor     = [UIColor clearColor];
        pBackgroundView.image               = nil;

        if ( self.itemWidgetData.mode == ContentModeStretchableFromCenter )
        {
          img = [img stretchableImageWithLeftCapWidth:floorf(img.size.width /2)
                                         topCapHeight:floorf(img.size.height/2)];
          pBackgroundView.image = img;
        }else if ( self.itemWidgetData.mode == ContentModePatternTiled )
        {
          pBackgroundView.backgroundColor = [UIColor colorWithPatternImage:img];
        }else{
          pBackgroundView.contentMode  = (UIViewContentMode)self.itemWidgetData.mode;
          pBackgroundView.image = img;
        }
        cell.backgroundView = pBackgroundView;
      }
    }
    if ( cell.delimiterWidget )
    {
      id obj = [cell.delimiterWidget.imageDictionary objectForKey:cell.delimiterWidget.img];
      if ( [obj isKindOfClass:[UIImage class]] )
      {
        UIImageView *delimImg = [[[UIImageView alloc] initWithImage:(UIImage *)obj] autorelease];
        delimImg.autoresizesSubviews = YES;
        delimImg.opaque              = YES;
        delimImg.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        delimImg.contentMode         = UIViewContentModeScaleToFill;
        cell.delimiterView = delimImg;
      }
    }
    cell.imageView.backgroundColor = [UIColor clearColor];
    cell.imageView.clipsToBounds   = YES;
    cell.contentView.opaque = YES;
    cell.contentView.backgroundColor       = [UIColor clearColor];
    
    
    cell.textLabel.backgroundColor         = self.titleWidgetData ? self.titleWidgetData.bgColor : [UIColor clearColor];
    
    cell.detailedTextLabel.backgroundColor = self.descriptionWidgetData ? self.descriptionWidgetData.bgColor : [UIColor clearColor];

    [TGridWidget attachCellSubviews:cell
                        toBoxLayout:cell.layout];
  }

  [[cell.imageView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];

  TGridElement *gridElement = (TGridElement *)[self.items objectAtIndex:indexPath.itemIndex];
  if ( gridElement.imgLink )
  {
    NSURL *imgUrl = [NSURL URLWithString:[[gridElement.imgLink stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                         stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    cell.imageView.contentMode = UIViewContentModeCenter;
    
    [cell.imageView setImageWithURL:imgUrl
                   placeholderImage:[UIImage imageNamed:@"photo_placeholder_small"]
                            success:^(UIImage *image, BOOL cached)
     {
       cell.imageView.contentMode = (UIViewContentMode)self.imageWidgetData.mode;
     }
                          failure:^(NSError *error)
     {
       cell.imageView.contentMode = UIViewContentModeCenter;
     }];
  }else{
    [cell.imageView setImage:nil];
  }
  cell.imageView.clipsToBounds = YES;
  cell.textLabel.text         = gridElement.title;
  cell.detailedTextLabel.text = gridElement.description;
  
  cell.titleMaxWordWidth       = gridElement.titleMaxWordWidth;
  cell.descriptionMaxWordWidth = gridElement.descriptionMaxWordWidth;
  
  return cell;
}

#pragma mark - NRGridView Delegate

- (void)gridView:(NRGridView *)gridView didSelectCellAtIndexPath:(NSIndexPath *)indexPath
{
  TCustomGridCell* cell = (TCustomGridCell *)[gridView cellAtIndexPath:indexPath];

  self.action = ((TGridElement *)[self.items objectAtIndex:indexPath.itemIndex]).action;
  if ( ![TWidgetTapHandler createAnimationForAction:self.action
                                           withView:cell
                                           delegate:self] )
    [self animationDidStop:nil finished:YES];
}

- (void)animationDidStop:(CAAnimation *)theAnimation
                finished:(BOOL)flag
{
  if ( flag )
    [[NSNotificationCenter defaultCenter] postNotificationName:kAPP_NOTIFICATION_WIDGET_TAP
                                                        object:[[self.action copy] autorelease]];
  self.action = nil;
}

@end
