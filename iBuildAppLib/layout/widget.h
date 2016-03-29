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

#import <UIKit/UIKit.h>
#import "urlimageview.h"
#import "TBXML.h"

@class TWidgetData;
@class TWidgetAction;

/** 
 *  TWidget - Base class in interface hierarchy. A window providing the following properties:
 *             size    - size of an interface component. When size > 1 it's considered to be in absolute values, whem <= 1 - in relative.
 *           margin    - component margins inside a container (absolute values)
 *            align    - widget alignment inside a container
 *  backgroundColor    - component's background color (transparent by default)
 *            alpha    - alpha value (default - 1.f)
 *             mode    - display mode of the background image
 *
 *  background image can be set directly by setting imageView.image property or
 *  by means of async images loader.


 Example of component's xml description:
 <widget type    = "window"
         align   = "center"
         bgColor = "#FFAA55"
         alpha   = "0.75"
         img     = "http://ibuildapp.com/sampleimage.png"
         mode    = "PatternTiled" >
  <size width  = "100%"
        height = "100%" />
  <margin left   = "0"
          right  = "0"
          top    = "0"
          bottom = "0" />
 </widget>
 
 */
@interface TWidget : TURLImageView

/**
 * Component's margins inside a container.
 */
typedef struct tagTMargin
{
  /** 
   *  Left margin.
   */
  CGFloat left;
  
  /** 
   *  Right margin.
   */
  CGFloat right;
  
  /** 
   *  Top margin.
   */
   CGFloat top;
  
  /** 
   *  Bottom margin.
   */
   CGFloat bottom;
  
}TMargin;

typedef enum tagTWidgetAlignment
{
  WidgetAlignmentCenter,
  WidgetAlignmentLeft,
  WidgetAlignmentRight,
  WidgetAlignmentTop,
  WidgetAlignmentBottom,
}TWidgetAlignment;

typedef struct tagWidgetSize
{
  BOOL width;
  BOOL height;
}WidgetSize;

typedef enum taguiWidgetAnimation
{
  /** 
   *  No animation.
   */
  uiWidgetAnimationDefault = 0,
  
  /** 
   * Ripple animation.
   */
  uiWidgetAnimationRipple,
}uiWidgetAnimation;

typedef enum tagTWidgetOpenStrategy
{
  /** 
   * Open a new module from current view controller.
   */
  uiWidgetOpenStrategyDefault = 0,
  
  uiWidgetOpenStrategyMaster  = uiWidgetOpenStrategyDefault,
  
  /** 
   * Open a new module in detail view controller (the split view case).
   */
  uiWidgetOpenStrategyDetail  = 1,
}uiWidgetOpenStrategy;

typedef struct tagTWidgetAnimation
{
  /** 
   * Animation duration.
   */
  CGFloat           duration;
  
  /** 
   * Transition style.
   */
  uiWidgetAnimation style;
}TWidgetAnimation;


/**
 * Size of an interface component. When size > 1 it's considered to be in absolute values, whem <= 1 - in relative.
 */
@property (nonatomic, assign)   CGSize           size;

/**
 * Component margins inside a container (absolute values).
 */
@property (nonatomic, assign)   TMargin          margin;

/** 
 * Widget alignment inside a container.
 */
@property (nonatomic, assign)   TWidgetAlignment align;

/**
 * Flag, telling whether the component has flexible width.
 * Set for all components with size.width == 1.0.
 */
@property (nonatomic, readonly) BOOL             flexWidth;

/**
 * Flag, telling whether the component has flexible height.
 * Set for all components with size.height == 1.0.
 */
@property (nonatomic, readonly) BOOL             flexHeight;

@property (nonatomic, retain) TWidgetAction     *action;

-(void)setSizeOnly:(CGSize)sz;

-(id)initWithParams:(TWidgetData *)params_;

@end

@protocol IWidgetXMLDelegate<NSObject>
@optional
-(void)parseXMLitems:(TBXMLElement *)item_
      withAttributes:(NSDictionary *)attributes_;
@end

typedef enum tagTWidgetActionTypes
{
  WidgetActionHome        = -1000,
  WidgetActionBack        = -1001,
  WidgetActionMenu        = -1002,
  WidgetActionUpdate      = -1003,
  WidgetActionFullscreen  = -1004,
  
  /** 
   * Conduct a search.
   */
  WidgetActionSearch      = -1005,
  
  /**
   * Present iBuildApp add.
   */
  WidgetActioniBuildAppAD = -1006,
  
  /** 
   * Present a list with lastest search queries.
   */
  WidgetActionSearchVariants = -1006,
  WidgetActionUnknown    = -1,
  WidgetActionUser       =  0,
}TWidgetActionTypes;


/**
 * Info about a module.
 */
@interface TActionDescriptor : NSObject <NSCopying, NSCoding>
  @property (nonatomic, copy  ) NSString *title;
  @property (nonatomic, copy  ) NSString *description;
  @property (nonatomic, strong) NSURL    *favIcon;
  @property (nonatomic, strong) NSURL    *disclosureIcon;

  /** 
   * Any user-defiend data.
   */
  @property (nonatomic, strong) id        data;
@end


/**
 * Info about a tap on a widget.
 */
@interface TWidgetAction : NSObject <NSCopying, NSCoding >
 /**
  * Tap animation
  */
  @property (nonatomic) TWidgetAnimation     tapAnimation;

 /**
  * id of an action to be performed in responce for a tap.
  */
  @property (nonatomic, assign) NSInteger             uid;

  /** 
   * New module presentation startegy.
   */
  @property (nonatomic, assign) uiWidgetOpenStrategy  openStrategy;

  /** 
   * Container for brief description of a module.
   */
  @property (nonatomic, strong) TActionDescriptor    *descriptor;

  /** 
   * Whether pushViewController should use animation (default - YES).
   */
  @property (nonatomic, assign) BOOL                  pushAnimation;
@end

@class TURLImageDictionary;
@class TWebDataDictionary;

/**
 * Data describing a widget. 
 * Describes fields to access data from dictionaries.
 */
@interface TWidgetData : NSObject<IWidgetXMLDelegate,NSCoding, NSCopying>
  @property (nonatomic, copy  ) NSString            *type;
  @property (nonatomic, assign) TWidgetAlignment     align;
  @property (nonatomic, retain) UIColor             *bgColor;
  @property (nonatomic, assign) CGFloat              alpha;
  @property (nonatomic, copy  ) NSString            *img;
  @property (nonatomic, assign) TImageMode           mode;
  @property (nonatomic, assign) CGSize               size;
  @property (nonatomic, assign) TMargin              margin;

  /** 
   * Component size (realtive or absolute)
   */
  @property (nonatomic, assign) WidgetSize           relSize;

  //Widget animation properties
  @property (nonatomic, retain) TWidgetAction       *action;
  @property (nonatomic, retain) TURLImageDictionary *imageDictionary;
  @property (nonatomic, retain) TWebDataDictionary  *webDataDictionary;

+(TImageMode)modeFromString:(NSString *)string_;
+(TWidgetAlignment)alignFromString:(NSString *)string_;
+(uiWidgetAnimation)animationFromString:(NSString *)string_;

+(TWidgetData *)createWithXMLElement:(TBXMLElement *)element;
-(id)initWithXMLElement:(TBXMLElement *)element;

@end

inline WidgetSize WidgetSizeMake( BOOL width, BOOL height )
{
  WidgetSize wSize = { width, height };
  return wSize;
}

inline TMargin          MarginMake(CGFloat left, CGFloat right, CGFloat top, CGFloat bottom)
{
  TMargin margin = { left, right, top, bottom };
  return margin;
}

inline TWidgetAnimation WidgetAnimationMake( uiWidgetAnimation style_, CGFloat duration_ )
{
  TWidgetAnimation wAnimation = { duration_, style_ };
  return wAnimation;
}

