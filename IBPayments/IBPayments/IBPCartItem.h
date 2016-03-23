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

#import "IBPItem.h"

/**
 * Order item in a cart.
 */
@interface IBPCartItem : NSObject

/**
 * Creates an IBPCartItem item as IBPItem with count specified.
 *
 * @param item - object of type IBPItem.
 * @param count - quantity of that object.
 *
 * @see IBPItem
 */
-(instancetype)initWithItem:(IBPItem *)item
                      count:(NSUInteger)count;

/**
 * A stock item.
 */
@property (nonatomic, strong) IBPItem *item;

/**
 * Quantity of the stock item.
 */
@property (nonatomic, assign) NSUInteger count;

@end
