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
#import "labelwidget.h"
#import "NRGridView.h"
#import "thumbnailarray.h"
#import "uiboxlayout.h"
#import "gradientselection.h"
#import "boxlayout.h"

#define kTabBarButtonBadgeViewTag 12345

/**
 * Scrolling direction for portrait and landscape orientations.
 */
typedef struct tagTGridScrollLayout
{
  NRGridViewLayoutStyle portrait;   
  NRGridViewLayoutStyle landscape;
}TGridScrollLayout;

typedef struct tagTGridScrollColumns
{
  NSUInteger portrait;
  NSUInteger landscape;
}TGridScrollColumns;


/**
 * TGridElement - container for storing info about gridView cell to provide fast access.
 */
@interface TGridElement : NSObject
  @property (nonatomic, copy   ) NSString      *title;
  @property (nonatomic, copy   ) NSString      *description;
  @property (nonatomic, copy   ) NSString      *imgLink;
  @property (nonatomic, retain ) TWidgetAction *action;

  /**
   * The length of the longest word in title.
   */
  @property (nonatomic, assign ) CGFloat        titleMaxWordWidth;

  /**
   * The length of the longest word in description.
   */
  @property (nonatomic, assign ) CGFloat        descriptionMaxWordWidth;

- (BOOL)needToShowBadge;

@end

@class TGridWidgetData;
@class TCustomGridCell;

/**
 * TGridWidget - class for displaying scrollable list of elements.
 * Inherits all the properties of the TWidget and adds the following:
 *
 *        scrollLayout - scroll direction for given device orientation
 *       scrollColumns - number of columns for a give orientation
 *            itemSize - width for a column
 *               items - array of dictionaries describing elements inside the scrollable list.
 *
 * Contents of the grid view can be shown only after the template's decorative elements have been loaded.
 * If loading fails, the default decorative elements are used.
 */
@interface TGridWidget : TWidget <NRGridViewDataSource, NRGridViewDelegate, UIScrollViewDelegate>
{
  /**
   * GridView UI component.
   */
  NRGridView        *m_gridView;
  
  /**
   * Array with elements to display.
   */
  NSArray           *m_items;
  
  /**
   * Current scroll position inside the scroll view.
   */
  CGPoint            m_scrollPos;
  
  /**
   * Scrolling direction for given device orientation
   */
  TGridScrollLayout  m_scrollLayout;
  
  /**
   * Number of columns for given device orientation
   */
  TGridScrollColumns m_scrollColumns;
  
  /**
   * Grid view cell size. For horizontal scrolling
   * the width is used, for vertical - the height of the size.
   */
  CGSize             m_itemSize;
  
  /**
   * Position and size of the widget
   */
  CGRect             m_widgetRect;
  
  /**
   * Screen orientation - YES for portrait, NO - for landscape.
   */
  BOOL               m_bPortraitOrientation;
}

@property (nonatomic, retain) TElementSelection *selection;
@property (nonatomic, retain) TWidgetData       *imageWidgetData;
@property (nonatomic, retain) TLabelWidgetData  *titleWidgetData;
@property (nonatomic, retain) TLabelWidgetData  *descriptionWidgetData;
@property (nonatomic, retain) TWidgetData       *delimiterWidgetData;
@property (nonatomic, retain) TWidgetData       *itemWidgetData;
@property (nonatomic, retain) uiBoxLayout       *cellBoxLayout;

@property (nonatomic, readonly) NRGridView          *gridView;
@property (nonatomic, retain  ) NSArray             *items;
@property (nonatomic, assign  ) TGridScrollLayout    scrollLayout;
@property (nonatomic, assign  ) TGridScrollColumns   scrollColumns;
@property (nonatomic, assign  ) CGSize               itemSize;
@property (nonatomic, assign  ) CGSize               cellPadding;
@property (nonatomic, assign  ) CGSize               contentPadding;


@property (nonatomic, retain) TWidget    *headerWidget;
@property (nonatomic, retain) TWidget    *footerWidget;
@property (nonatomic, assign) CGSize      headerContentSize;
@property (nonatomic, assign) CGSize      footerContentSize;

-(id)initWithParams:(TGridWidgetData *)params_;

+(void)attachCellSubviews:(TCustomGridCell *)cell_
              toBoxLayout:(uiBoxLayout *)boxLayout_;

@end

@interface TGridWidgetData : TWidgetData
{
  TWidgetData       *m_imageWidgetData;
  TLabelWidgetData  *m_descriptionWidgetData;
  TWidgetData       *m_delimiterWidgetData;
  TWidgetData       *m_itemWidgetData;
  
  /**
   * Elements layout inside gridView cell.
   */
  uiBoxLayout       *m_cellBoxLayout;
  
  /**
   * Layout for table header.
   */
  TBoxLayout        *m_headerLayout;
  
  /**
   * Layout for table footer.
   */
  TBoxLayout        *m_footerLayout;
}
  @property (nonatomic, strong  ) TElementSelection *selection;
  @property (nonatomic, readonly) TWidgetData       *imageWidgetData;
  @property (nonatomic, strong  ) TLabelWidgetData  *titleWidgetData;
  @property (nonatomic, readonly) TLabelWidgetData  *descriptionWidgetData;
  @property (nonatomic, readonly) TWidgetData       *delimiterWidgetData;
  @property (nonatomic, readonly) TWidgetData       *itemWidgetData;
  @property (nonatomic, readonly) uiBoxLayout       *cellBoxLayout;
  @property (nonatomic, readonly) TBoxLayout        *headerLayout;
  @property (nonatomic, readonly) TBoxLayout        *footerLayout;

  /**
   * Geometry for header and footer, if set.
   */
  @property (nonatomic, assign) CGSize               headerContentSize;
  @property (nonatomic, assign) CGSize               footerContentSize;

  @property (nonatomic, assign) TGridScrollLayout    layout;
  @property (nonatomic, assign) TGridScrollColumns   columns;
  @property (nonatomic, assign) CGSize               itemSize;
  @property (nonatomic, assign) CGSize               cellPadding;
  @property (nonatomic, assign) CGSize               contentPadding;

  /**
   * TWidgetData objects array.
   */
  @property (nonatomic, retain) NSArray             *items;

  // ------------ gridView elemets background settings -----------------------
  @property (nonatomic, strong) UIColor            *itemsBackgroundColor;
  @property (nonatomic, strong) NSURL              *itemsBackgroundURL;
  @property (nonatomic, assign) TImageMode          itemsBackgroundMode;

@end

inline TGridScrollLayout  GridLayoutMake ( NRGridViewLayoutStyle portrait_, NRGridViewLayoutStyle landscape_ );
inline TGridScrollColumns GridColumnsMake( NSUInteger portrait_, NSUInteger landscape_ );
