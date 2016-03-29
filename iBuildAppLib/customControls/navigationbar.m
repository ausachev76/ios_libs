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

#import "navigationbar.h"
#import "uiwidgets.h"
#import "uiboxlayout.h"
#import "uiwidgets.h"
#import "buttonwidget.h"

#define NAV_BAR_DEFAULT_HEIGHT 44.f

#define kNavBarButtonAnimationDuration 0.3f


@interface TNavigationBar()
  -(void)setNavigationBarTranslucent:(BOOL)translucent;

  @property (nonatomic, strong) uiWidgetData *homeButtonWidgetData;
  @property (nonatomic, strong) uiWidgetData *backButtonWidgetData;

  @property (nonatomic, strong) NSMutableDictionary *hiddenItems;
@end

@implementation TNavigationBar
@synthesize   height = height_,
             toolBar = m_toolBar,
        sourceLayout = _sourceLayout,
         hiddenItems = _hiddenItems,
homeButtonWidgetData = _homeButtonWidgetData,
backButtonWidgetData = _backButtonWidgetData;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self)
  {
    _homeButtonWidgetData = nil;
    _backButtonWidgetData = nil;
    _sourceLayout         = nil;
    _hiddenItems          = nil;
    // Initialization code
    self.opaque          = YES;
    self.backgroundColor = [UIColor clearColor];
    self.height          = NAV_BAR_DEFAULT_HEIGHT;
    self.hiddenItems     = [[[NSMutableDictionary alloc] init] autorelease];

    [[self subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    m_toolBar = nil;
  }
  return self;
}


-(void)dealloc
{
  if ( m_toolBar )
  {
    [m_toolBar release];
    m_toolBar = nil;
  }
  self.sourceLayout         = nil;
  self.homeButtonWidgetData = nil;
  self.backButtonWidgetData = nil;
  self.hiddenItems          = nil;
  
  [super dealloc];
}

-(TToolBar *)toolBar
{
  if ( !m_toolBar )
  {
    m_toolBar = [[TToolBar alloc] initWithFrame:[self bounds]];
    m_toolBar.autoresizesSubviews = YES;
    m_toolBar.autoresizingMask    = UIViewAutoresizingFlexibleWidth |
                                    UIViewAutoresizingFlexibleHeight;
    m_toolBar.opaque              = YES;
    m_toolBar.clipsToBounds       = YES;
    [self addSubview:m_toolBar];
  }
  return m_toolBar;
}

-(void)setSourceLayout:(uiBoxLayout *)sourceLayout_
{
  if ( _sourceLayout != sourceLayout_ )
  {
    [_sourceLayout release];
    _sourceLayout = [sourceLayout_ retain];
  }
}

-(void)setNavigationBarTranslucent:(BOOL)translucent
{
  UIView *rootView = [self.subviews objectAtIndex:0];
  CGFloat alpha = translucent ? 0.8 : 1.f;
  
  [rootView setOpaque:!translucent];
  [rootView setAlpha:alpha];
}


-(void)setBarStyle:(UIBarStyle)barStyle
{
  [super setBarStyle:barStyle];
  [self setNavigationBarTranslucent:barStyle == UIBarStyleBlackTranslucent];
}

-(void)setTranslucent:(BOOL)translucent
{
  [super setTranslucent:translucent];
  [self setNavigationBarTranslucent:translucent];
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CGSize newSize = [super sizeThatFits:size];
  return CGSizeMake( newSize.width, self.height );
}


-(uiRootImageWidget *)rootWidget
{
  UIView *view = [[self subviews] objectAtIndex:0];
  if ( ![view isKindOfClass:[uiRootImageWidget class]] )
    return nil;
  
  return (uiRootImageWidget *)view;
}

-(void)setHidden:(BOOL)bHidden_
     withIndexes:(NSIndexSet *)indexes_
        animated:(BOOL)animated_
{
  if ( ![indexes_ count] )
    return;
  //--------------------
  uiRootImageWidget *pRootWidget = [self rootWidget];

  if ( bHidden_ )
  {
    NSMutableIndexSet *indexSet = [[[NSMutableIndexSet alloc] initWithIndexSet:indexes_] autorelease];
    [self.hiddenItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
      NSInteger idx = [((NSNumber *)key) integerValue];
      if ( [indexes_ containsIndex:idx] )
      {
        [indexSet removeIndex:idx];
      }
    }];
    
    if ( ![indexSet count] )
      return;
    
    NSMutableDictionary *hiddenItemsDC = [[[NSMutableDictionary alloc] initWithDictionary:self.hiddenItems] autorelease];
    NSMutableArray *widgets = [[[NSMutableArray alloc] initWithArray:pRootWidget.layout.subWidgets copyItems:YES] autorelease];
    [widgets removeObjectsAtIndexes:indexSet];
    
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
      id obj = [pRootWidget.layout.subWidgets objectAtIndex:idx];
      if ( obj )
        [hiddenItemsDC setObject:obj forKey:[NSNumber numberWithInteger:idx]];
    }];
    
    [pRootWidget.layout clear];
    
    for( uiWidgetData *wd in widgets )
      [pRootWidget.layout addWidget:wd];
    
    self.hiddenItems = hiddenItemsDC;
    
    if ( animated_ )
    {
      [UIView animateWithDuration:kNavBarButtonAnimationDuration
                       animations:^{
                         [hiddenItemsDC enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                           ((uiWidgetData *)obj).view.alpha = 0.f;
                         }];
                         [pRootWidget layoutSubviews];
                       } completion:^(BOOL finished) {

                         [hiddenItemsDC enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                           [((uiWidgetData *)obj).view removeFromSuperview];
                         }];
                       }];
    }else{
      [hiddenItemsDC enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        [((uiWidgetData *)obj).view removeFromSuperview];
      }];
      [pRootWidget setNeedsLayout];
    }
  }else{
    NSMutableArray *widgets = [[[NSMutableArray alloc] initWithArray:pRootWidget.layout.subWidgets copyItems:YES] autorelease];
    
    NSMutableArray    *objList      = [[NSMutableArray alloc] init];
    NSMutableArray    *keysToRemove = [[NSMutableArray alloc] init];
    NSMutableIndexSet *indexSet     = [[NSMutableIndexSet alloc] init];
    
    [self.hiddenItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
      NSInteger idx = [((NSNumber *)key) integerValue];
      if ( [indexes_ containsIndex:idx] )
      {
        [objList addObject:obj];
        [keysToRemove addObject:key];
        [indexSet addIndex:[((NSNumber *)key) integerValue]];
      }
    }];
    
    [widgets insertObjects:objList atIndexes:indexSet];
    [indexSet release];

    [objList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
      [pRootWidget addSubview:((uiWidgetData *)obj).view];
    }];

    [self.hiddenItems removeObjectsForKeys:keysToRemove];
    [keysToRemove release];
    
    
    //----------------------------------------------------------------
    [pRootWidget.layout clear];
    for( uiWidgetData *wd in widgets )
      [pRootWidget.layout addWidget:wd];
    //----------------------------------------------------------------
    if ( animated_ )
    {
      [UIView animateWithDuration:kNavBarButtonAnimationDuration
                       animations:^{
                         [objList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                           ((uiWidgetData *)obj).view.alpha = 1.f;
                         }];
                         [pRootWidget layoutSubviews];
                       } completion:^(BOOL finished) {
                       }];
    }else{
      [objList enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ((uiWidgetData *)obj).view.alpha = 1.f;
      }];
      [pRootWidget setNeedsLayout];
    }
    [objList release];
  }
}


-(NSInteger)findWidgetIndexWithActionUID:(NSInteger)uid_
{
  __block NSInteger index = -1;

  uiRootImageWidget *pRootWidget = [self rootWidget];
  [pRootWidget.layout.subWidgets enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
    uiWidgetData *wd = (uiWidgetData *)obj;
    if ( [wd.data isKindOfClass:[TButtonWidgetData class]] )
    {
      TButtonWidgetData *buttonData = (TButtonWidgetData *)wd.data;
      if ( buttonData.action.uid == uid_ )
      {
        index = idx;
        *stop = YES;
      }
    }
  }];
  if ( index < 0 )
  {
    [self.hiddenItems enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop)
    {
      uiWidgetData *wd = (uiWidgetData *)obj;
      if ( [wd.data isKindOfClass:[TButtonWidgetData class]] )
      {
        TButtonWidgetData *buttonData = (TButtonWidgetData *)wd.data;
        if ( buttonData.action.uid == uid_ )
        {
          index = [((NSNumber *)key) integerValue];
          *stop = YES;
        }
      }
    }];
  }
  return index;
}

-(uiWidgetData *)findWidgetWithActionUID:(NSInteger)uid_
                              widgetList:(NSMutableArray **)widgetList_
                              rootWidget:(uiRootImageWidget **)rootWidget_
{
  uiRootImageWidget *pRootWidget = [self rootWidget];
  NSMutableArray *widgets = [[[NSMutableArray alloc] initWithArray:pRootWidget.layout.subWidgets copyItems:YES] autorelease];
  
  *widgetList_ = widgets;
  *rootWidget_ = pRootWidget;
  
  for ( uiWidgetData *wd in widgets )
  {
    if ( ![wd.data isKindOfClass:[TButtonWidgetData class]] )
      continue;
    
    TButtonWidgetData *buttonData = (TButtonWidgetData *)wd.data;
    if ( buttonData.action.uid == uid_ )
    {
      return wd;
    }
  }
  return nil;
}

-(uiWidgetData *)setButtonHidden:(BOOL)bHidden_
                         atIndex:(NSInteger)index_
                  withWidgetData:(uiWidgetData *)widget_
                 storeWidgetData:(uiWidgetData *)storeWidget_
                      rootWidget:(uiRootImageWidget *)pRootWidget_
                      widgetList:(NSMutableArray *)widgetList_
                        animated:(BOOL)animated_
{
  if ( bHidden_ )
  {
    if ( !widget_ )
      return nil;

    storeWidget_ = widget_;
    [[storeWidget_ retain] autorelease];
    
    [widgetList_ removeObject:widget_];
    
    [pRootWidget_.layout clear];
    
    for( uiWidgetData *wd in widgetList_ )
      [pRootWidget_.layout addWidget:wd];
    
    if ( animated_ )
    {
      [UIView animateWithDuration:kNavBarButtonAnimationDuration
                       animations:^{
                         storeWidget_.view.alpha = 0.f;
                         [pRootWidget_ layoutSubviews];
                       } completion:^(BOOL finished) {
                         [storeWidget_.view removeFromSuperview];
                       }];
    }else{
      [storeWidget_.view removeFromSuperview];
      [pRootWidget_ setNeedsLayout];
    }
  }else{
    if ( !storeWidget_ )
      return nil;
    
    [pRootWidget_ addSubview:storeWidget_.view];
    [widgetList_ insertObject:storeWidget_ atIndex:index_];
    
    [pRootWidget_.layout clear];
    for( uiWidgetData *wd in widgetList_ )
      [pRootWidget_.layout addWidget:wd];
    
    if ( animated_ )
    {
      [UIView animateWithDuration:kNavBarButtonAnimationDuration
                       animations:^{
                         storeWidget_.view.alpha = 1.f;
                         [pRootWidget_ layoutSubviews];
                       } completion:^(BOOL finished) {
                       }];
    }else{
      storeWidget_.view.alpha  = 1.f;
      [pRootWidget_ setNeedsLayout];
    }
  }
  return storeWidget_;
}

-(void)setBackButtonHidden:(BOOL)bHidden animated:(BOOL)animated
{
  NSInteger idx = [self findWidgetIndexWithActionUID:WidgetActionBack];
  if ( idx < 0 )
    return;
  
  [self setHidden:bHidden withIndexes:[NSIndexSet indexSetWithIndex:idx] animated:animated];
  
  /*
  NSMutableArray *pWidgetList = nil;
  uiRootImageWidget *pRootWidget = nil;
  uiWidgetData *wdHome = [self findWidgetWithActionUID:WidgetActionHome widgetList:&pWidgetList rootWidget:&pRootWidget];
  uiWidgetData *wdBack = [self findWidgetWithActionUID:WidgetActionBack widgetList:&pWidgetList rootWidget:&pRootWidget];
  if ( !pRootWidget )
    return;
  
  self.backButtonWidgetData = [self setButtonHidden:bHidden
                                            atIndex:(wdHome ? 1 : 0)
                                     withWidgetData:wdBack
                                    storeWidgetData:self.backButtonWidgetData
                                         rootWidget:pRootWidget
                                         widgetList:pWidgetList
                                           animated:animated];
  */
}

-(void)setHomeButtonHidden:(BOOL)bHidden animated:(BOOL)animated
{
  NSInteger idx = [self findWidgetIndexWithActionUID:WidgetActionHome];
  if ( idx < 0 )
    return;
  [self setHidden:bHidden withIndexes:[NSIndexSet indexSetWithIndex:idx] animated:animated];
  
  
  /*
  NSMutableArray *pWidgetList = nil;
  uiRootImageWidget *pRootWidget = nil;
  uiWidgetData *wd = [self findWidgetWithActionUID:WidgetActionHome widgetList:&pWidgetList rootWidget:&pRootWidget];
  if ( !pRootWidget )
    return;

  self.homeButtonWidgetData = [self setButtonHidden:bHidden
                                            atIndex:0
                                     withWidgetData:wd
                                    storeWidgetData:self.homeButtonWidgetData
                                         rootWidget:pRootWidget
                                         widgetList:pWidgetList
                                           animated:animated];
   */
}



@end
