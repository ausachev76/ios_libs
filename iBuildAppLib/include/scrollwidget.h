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
#import "uiwidgets.h"

@interface TScrollWidgetData : TWidgetData
  @property (nonatomic,assign) CGSize                     contentSize;
  @property (nonatomic,assign) RootWidgetScrollDirection  scrollDirection;
  @property (nonatomic,strong) NSArray                   *widgets;
@end

@interface TScrollWidget : TWidget
 /**
  * Width and height of the content to be scrolled
  */
  @property (nonatomic, assign) CGSize                    scrollSize;

 /**
  * Scrolling direction
  */
  @property (nonatomic, assign) RootWidgetScrollDirection scrollDirection;
  @property (nonatomic, strong) NSArray                  *widgetList;
  @property (nonatomic, strong) UIScrollView             *scrollView;

  -(void)createUI;
@end