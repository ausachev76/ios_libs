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
#import "auth_Share.h"

/**
 * Class describing an entity of a user, authorized via some social network.
 */
@interface auth_ShareUser : NSObject

/**
 * Type of a social service (auth_ShareServiceType) the user has authorized on.
 */
@property (nonatomic) auth_ShareServiceType authentificatedWith;

/**
 * Type of a social service as NSString.
 */
@property (nonatomic, retain) NSString *type;

/**
 * User Id in terms of a social service.
 */
@property (nonatomic, retain) NSString *ID;

/**
 * User name on a social service.
 */
@property (nonatomic, retain) NSString *name;

/**
 * User avatar url.
 */
@property (nonatomic, retain) NSString *avatar;

/**
 * Convenience method to get a service type from a string representation.
 *
 * @return auth_ShareServiceType - service type of the current user object.
 */
- (auth_ShareServiceType) getCurrentServiceType;

@end
