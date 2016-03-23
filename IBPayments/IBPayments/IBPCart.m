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

#import "IBPCart.h"

@interface IBPCart()

@property (nonatomic, retain) NSMutableArray *cartItems;

@end


@implementation IBPCart

-(instancetype)init{
  
  self = [super init];
  
  if(self){
    self.cartItems = [NSMutableArray array];
  }
  
  return self;
}

-(instancetype)initWithItems:(NSArray *)items
{
  self = [super init];
  
  if(self){
    self.cartItems = [[items mutableCopy] autorelease];
  }
  
  return self;
}

-(void)dealloc
{
  self.cartItems = nil;
  
  [super dealloc];
}

-(void)addCartItem:(IBPCartItem *)item
{
  [self.cartItems addObject:item];
}

-(void)removeCartItem:(IBPCartItem *)item
{
  [self.cartItems removeObject:item];
}

-(void)clearCart
{
  [self.cartItems removeAllObjects];
}

-(NSArray *)allItems
{
  return self.cartItems;
}

@end
