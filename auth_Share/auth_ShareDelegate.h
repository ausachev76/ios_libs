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
 * Protocol to define an object capable of handling auth_Share callbacks.
 */
@protocol auth_ShareDelegate<NSObject>

@optional

/**
 * Called when sharing routine has finished.
 *
 * @param serviceType - auth_Share service used to share.
 * @param error - nil if sharing succeeded.
 */
- (void)didShareDataForService:(auth_ShareServiceType)serviceType
                         error:(NSError *)error;

/**
 * Called when auth_Share finishes loading likes count for Ids specified.
 *
 * @param likes - dictionary of NSString* - NSNumber*,
 * representing likes count for URL or for facebook Id
 * @param error - nil if loading succeeded.
 */
- (void)didLoadFacebookLikesCount:(NSDictionary *)likes
                            error:(NSError *)error;

/**
 * Called when auth_Share finishes loading comments count for Ids specified.
 *
 * @param commentsCount - dictionary of NSString* - NSNumber*, matching comments count with facebook Ids
 * @param error - nil if loading succeeded.
 */
- (void)didLoadFacebookCommentsCount:(NSDictionary *)commentsCount
                               error:(NSError *)error;

/**
 * Called when auth_Share finishes loading URLs liked by the user on Facebook
 *
 * @param commentsCount - dictionary of NSString* - NSNumber*, matching likes count with facebook URLs
 * @param error - nil if loading succeeded.
 */
- (void)didLoadFacebookLikedURLs:(NSMutableSet *)likedItems
                           error:(NSError *)error;

/**
 * Called when auth_Share finishes loading Ids liked by the user on Facebook
 *
 * @param commentsCount - dictionary of NSString* - NSNumber*, matching likes count with facebook Ids
 * @param error - nil if loading succeeded.
 */
- (void)didLoadFacebookLikedIds:(NSMutableSet *)likedIds
                          error:(NSError *)error;

/**
 * Called after fb like request ended.
 *
 * @param NSString URL specified for like request.
 * @param error - nil if like succeeded.
 */
- (void)didFacebookLikeForURL:(NSString*)URL
                        error:(NSError *)error;

/**
 * Called after fb like request ended.
 *
 * @param NSString Facebook Id specified for like request.
 * @param error - nil if like succeeded.
 */
- (void)didFacebookLikeForId:(NSString*)URL
                       error:(NSError *)error;

/**
 * Called when user has just authorized on serviceType.
 *
 * @param serviceType - auth_Share service used to authorize.
 * @param error - nil if authorization request succeeded.
 */
- (void)didAuthorizeOnService:(auth_ShareServiceType)serviceType
                        error:(NSError *)error;

@end
