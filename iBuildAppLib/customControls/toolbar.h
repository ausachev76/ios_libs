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

typedef enum 
{
  ITEM_FIXED = 0,
  ITEM_STRETCHABLE,
}TToolBarItemType;


@interface TToolBarItem : NSObject
{
  UIView            *m_pView;
  NSInteger          m_nTag;  // Element id inside the tab bar.
  TToolBarItemType   m_type;
}

@property (nonatomic, retain) UIView          *view;
@property (nonatomic, assign) TToolBarItemType type;
@property (nonatomic, assign) NSInteger        tag;

-(id)initWithView:(UIView *)view_
          andType:(TToolBarItemType)type_;

-(id)initWithView:(UIView *)view_
             type:(TToolBarItemType)type_
           andTag:(NSInteger)tag_;
@end

@interface TToolBar : UIView
{
  @private UIImageView    *m_pToolBarImageView;
  @private NSMutableArray *m_pItemsArray;
}

@property (nonatomic, retain) NSMutableArray *viewItems;

- (id)initWithFrame:(CGRect)frame
           andImage:(UIImage *)img_;

-(TToolBarItem *)itemWithTag:(NSInteger)tag_;

-(void)setItems:(NSMutableArray *)items;

-(void)removeItemAtIndex:(NSInteger)idx_;

-(void)insertItem:(TToolBarItem *)item_
          atIndex:(NSInteger)idx_;

-(void)setImage:(UIImage *)img_;

@end
