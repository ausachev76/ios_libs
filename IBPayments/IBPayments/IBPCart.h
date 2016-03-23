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

#import "IBPCartItem.h"

/**
 * Entity for a cart.
 */
@interface IBPCart : NSObject<IBPPayable>

/**
 * Creates a cart with cart items.
 *
 * @param items - array of IBCartItems.
 *
 * @see IBPCartItem
 */
-(instancetype)initWithItems:(NSArray *)items;

/**
 * Adds a cart item to cart.
 *
 * @param item - IBPCartItem to add.
 *
 * @see IBPCartItem
 */
-(void)addCartItem:(IBPCartItem *)item;

/**
 * Removes an item from cart.
 *
 * @param item - IBPCartItem to remove.
 *
 * @see IBPCartItem
 */
-(void)removeCartItem:(IBPCartItem *)item;

/**
 * Clears the cart.
 */
-(void)clearCart;

/**
 * Returns cart items as array.
 *
 * @return NSArray of IBPCartItems.
 *
 * @see IBPCartItem
 */
-(NSArray *)allItems;

@end
