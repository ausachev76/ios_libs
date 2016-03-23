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

#import "toolbar.h"

@implementation TToolBarItem
@synthesize tag  = m_nTag,
            view = m_pView,
            type = m_type;

-(id)init
{
  self = [super init];
  if ( self )
  {
    self.view = nil;
    self.type = ITEM_FIXED;
    self.tag  = -1;
  }
  return self;
}

-(id)initWithView:(UIView *)view_
          andType:(TToolBarItemType)type_
{
  self = [super init];
  if ( self )
  {
    self.view = view_;
    self.type = type_;
    self.tag  = -1;
  }
  return self;
}

-(id)initWithView:(UIView *)view_
             type:(TToolBarItemType)type_
           andTag:(NSInteger)tag_
{
  self = [super init];
  if ( self )
  {
    self.view = view_;
    self.type = type_;
    self.tag  = tag_;
  }
  return self;
}

-(void)dealloc
{
  self.view = nil;
  [super dealloc];
}

@end


@implementation TToolBar
@synthesize viewItems = m_pItemsArray;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
      self.viewItems = nil;
      m_pToolBarImageView = nil;
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
           andImage:(UIImage *)img_
{
  self = [super initWithFrame:frame];
  if (self)
  {
    self.viewItems = nil;
    m_pToolBarImageView = [[UIImageView alloc] initWithFrame:CGRectMake( 0, 0, frame.size.width, frame.size.height)];
    m_pToolBarImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    m_pToolBarImageView.backgroundColor  = [UIColor clearColor];
    m_pToolBarImageView.image            = img_;
    [self addSubview:m_pToolBarImageView];
  }
  return self;
}


-(void)setItems:(NSMutableArray *)items
{
  self.viewItems = items;
  [self setNeedsLayout];
}

-(void)setImage:(UIImage *)img_
{
  if ( m_pToolBarImageView )
  {
    m_pToolBarImageView.image = img_;
  }else{
    m_pToolBarImageView = [[UIImageView alloc] initWithFrame:CGRectMake( 0, 0, self.frame.size.width, self.frame.size.height ) ];
    m_pToolBarImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                           UIViewAutoresizingFlexibleHeight;
    m_pToolBarImageView.backgroundColor  = [UIColor clearColor];
    m_pToolBarImageView.image            = img_;
    [self addSubview:m_pToolBarImageView];
  }
}

-(void)insertItem:(TToolBarItem *)item_
          atIndex:(NSInteger)idx_
{
  [self.viewItems insertObject:item_
                       atIndex:idx_];
  [self setNeedsLayout];
}

-(void)removeItemAtIndex:(NSInteger)idx_
{
  TToolBarItem *it = [self.viewItems objectAtIndex:idx_];
  if ( it )
  {
    [it.view removeFromSuperview];
    [self.viewItems removeObjectAtIndex:idx_];
    [self setNeedsLayout];
  }
}

-(TToolBarItem *)itemWithTag:(NSInteger)tag_
{
  for( TToolBarItem *it in self.viewItems )
    if ( it.tag == tag_ )
      return it;
  return nil;
}

-(void)layoutItems:(NSArray *)items_
{
  CGRect    rc = self.frame;
  CGFloat fixedWidth = 0.f;
  unsigned stretchableItemsCount = 0;

  for( TToolBarItem *it in items_ )
  {
    if ( it.type != ITEM_STRETCHABLE )
      fixedWidth += it.view.frame.size.width;
    else
      ++stretchableItemsCount;
    [it.view removeFromSuperview];
  }
  // calculate size for stretchable items, if present
  CGFloat remWidth = (rc.size.width - fixedWidth);
  CGFloat stretchWidth  = 0.f;
  if ( remWidth > 0.f && stretchableItemsCount )
    stretchWidth = remWidth / stretchableItemsCount;
  else if ( remWidth < 0.f )
    rc = CGRectMake(rc.origin.x, rc.origin.y, fixedWidth, rc.size.height );
  
  CGFloat xPos = 0.f; 
  for( TToolBarItem *it in items_ )
  {
    if ( it.type != ITEM_STRETCHABLE )
    {
      it.view.frame = CGRectMake( xPos, it.view.bounds.origin.y, it.view.bounds.size.width, it.view.bounds.size.height );
      xPos += it.view.bounds.size.width;
    }else{
      it.view.frame = CGRectMake( xPos, it.view.bounds.origin.y, stretchWidth, it.view.bounds.size.height );
      xPos += stretchWidth;
    }
    [self addSubview:it.view];
  }
  self.frame = rc;
}

-(void)dealloc
{
  if ( m_pToolBarImageView )
  {
    [m_pToolBarImageView release];
    m_pToolBarImageView = nil;
  }
  self.items = nil;
  [super dealloc];
}

-(void)layoutSubviews
{
  [self layoutItems:self.viewItems];
}

@end
