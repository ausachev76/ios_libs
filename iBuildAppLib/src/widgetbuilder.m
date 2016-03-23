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

#import "widgetbuilder.h"
#import "widget.h"
#import "labelwidget.h"
#import "textwidget.h"
#import "textfieldwidget.h"
#import "gridwidget.h"
#import "vboxlayout.h"
#import "hboxlayout.h"
#import "scrollwidget.h"
#import "urlimagedictionary.h"
#import "UIImageView+WebCache.h"//<SDWebImage/UIImageView+WebCache.h>
#import "downloadmanager.h"
#import "webdatadictionary.h"
#import "webdataitem+image.h"
#import "NSString+UrlConvertion.h"

@implementation TWidgetBuilder

+(void)setWidget:(TWidget *)widget_
      withParams:(TWidgetData *)params_
{
  widget_.size            = params_.size;
  widget_.align           = params_.align;
  widget_.margin          = params_.margin;
  widget_.backgroundColor = params_.bgColor;
  widget_.mode            = params_.mode;
  widget_.alpha           = params_.alpha;
  widget_.action          = params_.action;

  [widget_ setImage:nil
           withMode:params_.mode];

  if ( params_.img && params_.img.length )
  {
    if ( params_.imageDictionary )
    {
      id obj = [params_.imageDictionary objectForKey:params_.img];
      if ( [obj isKindOfClass:[UIImage class]] )
        [widget_ setImage:(UIImage *)obj
                 withMode:params_.mode];
    }else if ( params_.webDataDictionary )
    {
      [widget_ setImage:[[params_.webDataDictionary itemForURL:[params_.img asURL]] asImage]
               withMode:params_.mode];
    }
  }
}

+(TWidget *)createWidget:(TWidgetData *)params_
{
  TWidget *widget = [[[TWidget alloc] init] autorelease];
  [TWidgetBuilder setWidget:widget
                 withParams:params_];
  return widget;
}

+(void)setLabelWidget:(TLabelWidget *)widget_
      withParams:(TLabelWidgetData *)params_
{
  [TWidgetBuilder setWidget:widget_
                 withParams:params_];
  widget_.labelView.text                 = params_.text;
  widget_.labelView.textColor            = params_.textColor;
  widget_.labelView.highlightedTextColor = params_.highlightedTextColor;
  widget_.labelView.textAlignment = params_.textAlignment;
  widget_.labelView.verticalAlignment = (NRLabelVerticalAlignment)params_.textVerticalAlignment;
  widget_.labelView.font          = params_.font;
  widget_.labelView.lineBreakMode = params_.lineBreakMode;
  widget_.labelView.numberOfLines = params_.numberOfLines;
  widget_.labelView.shadowColor   = params_.shadowColor;
  widget_.labelView.shadowOffset  = params_.shadowOffset;
}

+(TLabelWidget *)createLabelWidget:(TLabelWidgetData *)params_
{
  TLabelWidget *widget = [[[TLabelWidget alloc] init] autorelease];
  [TWidgetBuilder setLabelWidget:widget
                      withParams:params_];
  return widget;
}

+(void)setTextFieldWidget:(TTextFieldWidget *)widget_
               withParams:(TTextFieldWidgetData *)params_
{
  [TWidgetBuilder setWidget:widget_
                 withParams:params_];
  widget_.textField.text          = params_.text;
  widget_.textField.placeholder   = params_.placeholder;
}

+(TTextFieldWidget *)createTextFieldWidget:(TTextFieldWidgetData *)params_
{
  TTextFieldWidget *widget = [[[TTextFieldWidget alloc] init] autorelease];
  [TWidgetBuilder setTextFieldWidget:widget
                          withParams:params_];
  return widget;
}


+(void)setTextWidget:(TTextWidget *)widget_
          withParams:(TTextWidgetData *)params_
{
  [TWidgetBuilder setWidget:widget_
                 withParams:params_];
  widget_.textView.text          = params_.text;
  widget_.textView.textColor     = params_.textColor;
  widget_.textView.textAlignment = params_.textAlignment;
  widget_.textView.font          = params_.font;
  widget_.textView.scrollEnabled = params_.scrollEnabled;
}


+(TTextWidget *)createTextWidget:(TTextWidgetData *)params_
{
  TTextWidget *widget = [[[TTextWidget alloc] init] autorelease];
  [TWidgetBuilder setTextWidget:widget
                     withParams:params_];
  return widget;
}


+(void)setGridWidget:(TGridWidget *)widget_
          withParams:(TGridWidgetData *)params_
{
  [TWidgetBuilder setWidget:widget_
                 withParams:params_];
  widget_.imageWidgetData       = params_.imageWidgetData;
  widget_.delimiterWidgetData   = params_.delimiterWidgetData;
  widget_.titleWidgetData       = params_.titleWidgetData;
  widget_.descriptionWidgetData = params_.descriptionWidgetData;
  widget_.itemWidgetData        = params_.itemWidgetData;
  widget_.cellBoxLayout         = params_.cellBoxLayout;
  widget_.selection             = params_.selection;
  widget_.cellPadding           = params_.cellPadding;
  widget_.contentPadding        = params_.contentPadding;
  widget_.headerContentSize     = params_.headerContentSize;
  widget_.footerContentSize     = params_.footerContentSize;
  
  if ( params_.itemsBackgroundColor || params_.itemsBackgroundURL )
  {
    UIImageView *itemsBackground = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
    widget_.gridView.gridItemsBackgroundView = itemsBackground;
    itemsBackground.userInteractionEnabled = YES;
    itemsBackground.autoresizesSubviews    = YES;
    itemsBackground.backgroundColor        = params_.itemsBackgroundColor ?
                                                     params_.itemsBackgroundColor :
                                                     [UIColor clearColor];
    if ( params_.itemsBackgroundURL )
    {
      [itemsBackground setImageWithURL:params_.itemsBackgroundURL
                                   success:^(UIImage *image, BOOL cached){
                                     if ( params_.itemsBackgroundMode == ContentModePatternTiled )
                                     {
                                       itemsBackground.backgroundColor = [UIColor colorWithPatternImage:image];
                                     }else if ( params_.itemsBackgroundMode == ContentModeStretchableFromCenter )
                                     {
                                       itemsBackground.contentMode = UIViewContentModeScaleToFill;
                                       itemsBackground.image = [image stretchableImageWithLeftCapWidth:floorf(image.size.width/2)
                                                                                          topCapHeight:floorf(image.size.height/2)];
                                     }else{
                                       itemsBackground.contentMode = (UIViewContentMode)params_.itemsBackgroundMode;
                                     }
                                   }
                                   failure:^(NSError *error){ }];
    }
  }
  
  widget_.scrollLayout  = params_.layout;
  widget_.scrollColumns = params_.columns;
  widget_.itemSize      = params_.itemSize;
  widget_.items         = params_.items;

  if ( params_.headerLayout )
  {
    NSArray *wdtList = [TWidgetBuilder createWidgets:[NSArray arrayWithObject:params_.headerLayout]];
    if ( wdtList && wdtList.count )
      widget_.headerWidget = [wdtList objectAtIndex:0];
  }

  if ( params_.footerLayout )
  {
    NSArray *wdtList = [TWidgetBuilder createWidgets:[NSArray arrayWithObject:params_.footerLayout]];
    if ( wdtList && wdtList.count )
      widget_.footerWidget = [wdtList objectAtIndex:0];
  }
  
  if ( widget_.headerWidget )
    widget_.gridView.gridHeaderView = widget_.headerWidget;

  if ( widget_.footerWidget )
    widget_.gridView.gridFooterView = widget_.footerWidget;
}

+(void)setScrollWidget:(TScrollWidget *)widget_
            withParams:(TScrollWidgetData *)params_
{
  [TWidgetBuilder setWidget:widget_
                 withParams:params_];

  widget_.scrollSize      = params_.contentSize;
  widget_.scrollDirection = params_.scrollDirection;
  widget_.widgetList = params_.widgets;
  [widget_ createUI];
}

+(TGridWidget *)createGridWidget:(TGridWidgetData *)params_
{
  TGridWidget *widget = [[[TGridWidget alloc] init] autorelease];
  [TWidgetBuilder setGridWidget:widget
                     withParams:params_];
  return widget;
}

+(TScrollWidget *)createScrollLayoutWidget:(TScrollWidgetData *)params_
{
  TScrollWidget *widget = [[[TScrollWidget alloc] init] autorelease];
  [TWidgetBuilder setScrollWidget:widget
                       withParams:params_];
  return widget;
}

+(TVBoxLayout *)createVBoxLayoutWidget:(TBoxLayoutData *)params_
{
  TVBoxLayout *widget = [[[TVBoxLayout alloc] init] autorelease];
  NSArray *widgetList = [TWidgetBuilder createWidgets:params_.items];
  if ( widgetList )
  {
    for ( TWidget *wit in widgetList )
      [widget addWidget:wit];
  }
  [TWidgetBuilder setWidget:widget
                 withParams:params_];
  return widget;
}

+(THBoxLayout *)createHBoxLayoutWidget:(TBoxLayoutData *)params_
{
  THBoxLayout *widget = [[[THBoxLayout alloc] init] autorelease];
  NSArray *widgetList = [TWidgetBuilder createWidgets:params_.items];
  if ( widgetList )
  {
    for ( TWidget *wit in widgetList )
      [widget addWidget:wit];
  }
  [TWidgetBuilder setWidget:widget
                 withParams:params_];
  return widget;
}

+(NSArray *)createWidgets:(NSArray *)items
{
  NSMutableArray *widgetSet = [NSMutableArray array];
  NSDictionary *widgets = [NSDictionary dictionaryWithObjectsAndKeys:
                           NSStringFromSelector(@selector(createWidget:            )), NSStringFromClass([TWidgetData          class]),
                           NSStringFromSelector(@selector(createLabelWidget:       )), NSStringFromClass([TLabelWidgetData     class]),
                           NSStringFromSelector(@selector(createTextFieldWidget:   )), NSStringFromClass([TTextFieldWidgetData class]),
                           NSStringFromSelector(@selector(createTextWidget:        )), NSStringFromClass([TTextWidgetData   class]),
                           NSStringFromSelector(@selector(createGridWidget:        )), NSStringFromClass([TGridWidgetData   class]),
                           NSStringFromSelector(@selector(createHBoxLayoutWidget:  )), NSStringFromClass([THBoxLayoutData   class]),
                           NSStringFromSelector(@selector(createVBoxLayoutWidget:  )), NSStringFromClass([TVBoxLayoutData   class]),
                           NSStringFromSelector(@selector(createScrollLayoutWidget:)), NSStringFromClass([TScrollWidgetData class]),
                           nil];
  
  for ( NSObject *it in items )
  {
    NSString *selName = [widgets objectForKey:NSStringFromClass([it class])];
    if ( selName )
    {
      SEL fnSelector = NSSelectorFromString( selName );
      if ( [TWidgetBuilder respondsToSelector:fnSelector] )
      {
        TWidget *widget = [TWidgetBuilder performSelector:fnSelector withObject:it ];
        if ( widget )
          [widgetSet addObject:widget];
      }
    }
  }
  return widgetSet.count ?
    widgetSet :
    nil;
}

+(void)setData:(TWidgetData *)item_
     forWidget:(TWidget *)widget_
{
  NSDictionary *widgets = [NSDictionary dictionaryWithObjectsAndKeys:
                           NSStringFromSelector(@selector(setWidget:withParams:          )), NSStringFromClass([TWidget      class]),
                           NSStringFromSelector(@selector(setLabelWidget:withParams:     )), NSStringFromClass([TLabelWidget class]),
                           NSStringFromSelector(@selector(setTextFieldWidget:withParams: )), NSStringFromClass([TTextFieldWidget class]),
                           NSStringFromSelector(@selector(setTextWidget:withParams:      )), NSStringFromClass([TTextWidget  class]),
                           NSStringFromSelector(@selector(setGridWidget:withParams:      )), NSStringFromClass([TGridWidget  class]),
                           NSStringFromSelector(@selector(setWidget:withParams:          )), NSStringFromClass([THBoxLayout  class]),
                           NSStringFromSelector(@selector(setWidget:withParams:          )), NSStringFromClass([TVBoxLayout  class]),
                           nil];

  NSString *selName = [widgets objectForKey:NSStringFromClass([widget_ class])];
  if ( selName )
  {
    SEL fnSelector = NSSelectorFromString( selName );
    if ( [TWidgetBuilder respondsToSelector:fnSelector] )
      [TWidgetBuilder performSelector:fnSelector
                           withObject:widget_
                           withObject:item_];
  }
  
  if ( [ widget_ isKindOfClass:[TBoxLayout class]] &&
       [ item_ isKindOfClass:[TBoxLayoutData class]] )
  {
    TBoxLayoutData *boxData = (TBoxLayoutData *)item_;
    NSUInteger dataItemsCount = [boxData.items count];
    NSUInteger ii = 0;

    for ( UIView *pView in [widget_ subviews] )
    {
      if ( !dataItemsCount )
        break;
      if ( [pView isKindOfClass:[TWidget class]] )
      {
        [TWidgetBuilder setData:[boxData.items objectAtIndex:ii++]
                      forWidget:(TWidget *)pView];
        --dataItemsCount;
      }
    }
  }
}

+(void)fillImageDictionary:(TURLImageDictionary *)imgDictionary_
               withWidgets:(NSArray *)widgets_
{
  for( id obj in widgets_ )
  {
    // search tree in depth
    if ( [obj isKindOfClass:[TBoxLayoutData class]] )
    {
      ((TWidgetData *)obj).imageDictionary = imgDictionary_;
      [imgDictionary_ appendImageLink:((TBoxLayoutData *)obj).img];
      [TWidgetBuilder fillImageDictionary:imgDictionary_
                              withWidgets:((TBoxLayoutData *)obj).items];
    }else if ( [obj isKindOfClass:[TGridWidgetData class]] )
    {
      TGridWidgetData *gridWidget = (TGridWidgetData *)obj;
      if ( gridWidget.headerLayout )
        [TWidgetBuilder fillImageDictionary:imgDictionary_
                                withWidgets:[NSArray arrayWithObject:gridWidget.headerLayout]];
      
      if ( gridWidget.footerLayout )
        [TWidgetBuilder fillImageDictionary:imgDictionary_
                                withWidgets:[NSArray arrayWithObject:gridWidget.footerLayout]];
      //---------------------------------------------------------------------------------
      [imgDictionary_ appendImageLink:gridWidget.img];
      [imgDictionary_ appendImageLink:gridWidget.delimiterWidgetData.img];
      [imgDictionary_ appendImageLink:gridWidget.itemWidgetData.img];
      gridWidget.imageDictionary = imgDictionary_;
      gridWidget.delimiterWidgetData.imageDictionary = imgDictionary_;
      gridWidget.itemWidgetData.imageDictionary      = imgDictionary_;
      //----------------------------------------------------------------
    }else if ( [obj isKindOfClass:[TScrollWidgetData class]] )
    {
      ((TWidgetData *)obj).imageDictionary = imgDictionary_;
      [imgDictionary_ appendImageLink:((TScrollWidgetData *)obj).img];
      [TWidgetBuilder fillImageDictionary:imgDictionary_
                              withWidgets:((TScrollWidgetData *)obj).widgets];
    }else if ( [obj isKindOfClass:[TWidgetData class]] )
    {
      [imgDictionary_ appendImageLink:((TWidgetData *)obj).img];
      ((TWidgetData *)obj).imageDictionary = imgDictionary_;
    }
  }
}

+(BOOL)widgetActions:(NSSet *)actions_
             contain:(TWidgetAction *)act_
{
  if ( act_.uid < 0 )
    return YES;
  
  for ( TWidgetAction *a in actions_ )
  {
    if ( (a.uid == act_.uid) )
      return YES;
  }
  return NO;
}

+(void)fillActionSet:(NSMutableSet *)actions_
         withWidgets:(NSArray *)widgets_
{
  for( id obj in widgets_ )
  {
    // search tree in depth
    if ( [obj isKindOfClass:[TBoxLayoutData class]] )
    {
      TWidgetAction *thisAction = ((TBoxLayoutData *)obj).action;
      if ( thisAction && ![[self class] widgetActions:actions_ contain:thisAction] )
        [actions_ addObject:thisAction];
      
      [TWidgetBuilder fillActionSet:actions_
                        withWidgets:((TBoxLayoutData *)obj).items];
    }else if ( [obj isKindOfClass:[TGridWidgetData class]] )
    {
      TWidgetAction *thisAction = ((TGridWidgetData *)obj).action;
      if ( thisAction && ![[self class] widgetActions:actions_ contain:thisAction] )
        [actions_ addObject:thisAction];
      
      TGridWidgetData *gridWidget = (TGridWidgetData *)obj;
      
      if ( gridWidget.headerLayout )
        [TWidgetBuilder fillActionSet:actions_
                          withWidgets:[NSArray arrayWithObject:gridWidget.headerLayout]];
      
      if ( gridWidget.footerLayout )
        [TWidgetBuilder fillActionSet:actions_
                          withWidgets:[NSArray arrayWithObject:gridWidget.footerLayout]];

      for( TWidgetData *wd in gridWidget.items )
        if ( wd.action && ![[self class] widgetActions:actions_ contain:wd.action] )
          [actions_ addObject:wd.action];
    }else if ( [obj isKindOfClass:[TScrollWidgetData class]] )
    {
      TWidgetAction *thisAction = ((TScrollWidgetData *)obj).action;
      if ( thisAction && ![[self class] widgetActions:actions_ contain:thisAction] )
        [actions_ addObject:thisAction];
      [TWidgetBuilder fillActionSet:actions_
                        withWidgets:((TScrollWidgetData *)obj).widgets];
    }else if ( [obj isKindOfClass:[TWidgetData class]] )
    {
      TWidgetAction *thisAction = ((TWidgetData *)obj).action;
      if ( thisAction && ![[self class] widgetActions:actions_ contain:thisAction] )
        [actions_ addObject:thisAction];
    }
  }
}



@end
