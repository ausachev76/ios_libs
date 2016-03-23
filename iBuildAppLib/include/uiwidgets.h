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
#import "widget.h"

@class uiBoxLayout;
@interface uiWidgetData : NSObject<NSCopying, NSCoding>

/**
 * Mutable component's size (its values duplicate the size property),
 * used in calculations of the relative size of the components,
 * where width or height values set as 100%.
 */
@property (nonatomic, assign)   CGSize           mutableSize;

/** 
 * Component's size.
 */
@property (nonatomic, assign)   CGSize           size;

/** 
 * Component's size (relative or absolute values).
 */
@property (nonatomic, assign)   WidgetSize       relSize;

/** 
 * Component's margins in the conatiner (absolute values).
 */
@property (nonatomic, assign)   TMargin          margin;

/** 
 * Widget alignment inside the container.
 */
@property (nonatomic, assign)   TWidgetAlignment align;

/** 
 * Link to the underlying boxLayout.
 */
@property (nonatomic, retain)   uiBoxLayout     *boxLayout;

/** 
 * Link to the associated view.
 */
@property (nonatomic, retain)   UIView          *view;

/** 
 * Data associated with the object.
 */
@property (nonatomic, retain)   id               data;

/** 
 * String id of the object.
 */
@property (nonatomic, copy  )   NSString        *type;


-(void)layoutWidget:(CGRect)frame;

@end

/**
 * Supported scrolling directions
 */
typedef enum tagRootWidgetScrollDirection
{
  RootWidgetScrollHorizontal = 0,
  RootWidgetScrollVertical,
}RootWidgetScrollDirection;

@interface uiRootImageWidget : UIImageView
  @property (nonatomic, strong) uiBoxLayout *layout;
  @property (nonatomic, strong) uiBoxLayout *layoutPortrait;
  @property (nonatomic, strong) uiBoxLayout *layoutLandscape;
@end

@interface uiRootWidget : UIView
  @property (nonatomic, strong) uiBoxLayout *layout;
  @property (nonatomic, strong) uiBoxLayout *layoutPortrait;
  @property (nonatomic, strong) uiBoxLayout *layoutLandscape;
@end

@interface uiRootScrollWidget : UIScrollView
  @property (nonatomic, strong) uiBoxLayout              *layout;
  @property (nonatomic, strong) uiBoxLayout              *layoutPortrait;
  @property (nonatomic, strong) uiBoxLayout              *layoutLandscape;

  /** 
   * Size of the content in scrollable area.
   */
  @property (nonatomic, assign) CGSize                    scrollSize;

  /** 
   * Scrolling direction.
   */
  @property (nonatomic, assign) RootWidgetScrollDirection scrollDirection;
@end

