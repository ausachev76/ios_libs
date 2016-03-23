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

#import <Foundation/Foundation.h>
#import "IBPPayable.h"

/**
 * Entity describing a stock item.
 */
@interface IBPItem : NSObject<IBPPayable>

/**
 * Unique identifier of an item.
 */
 @property (nonatomic) NSInteger pid;

/**
 * Name of an item.
 */
 @property(nonatomic, strong) NSString *name;

/**
 * Currency code like USD, EUR and so on.
 */
 @property(nonatomic, strong) NSString *currencyCode;

/**
 * Item's price.
 */
 @property(nonatomic, strong) NSDecimalNumber *price;

/**
 * Description of an item.
 */
 @property(nonatomic, strong) NSString *shortDescription;

@end
