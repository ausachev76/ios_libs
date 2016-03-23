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
#import <MessageUI/MessageUI.h>
#import "FHSTwitterEngine.h"//"FHSTwitterEngine/FHSTwitterEngine.h"

#define k_auth_Share_LoginState @"loginState"
#define k_auth_Share_AuthentificationFailed @"loginFailed"
#define k_auth_Share_LoggedOutNotificationName @"k_auth_Share_LoggedOutNotification"
#define k_auth_Share_LikedItemsLoadedNotificationName @"k_auth_Share_LikedItemsLoadedNotification"

/**
 * Social network or sharing type to operate with
 */
typedef enum auth_ShareServiceType
{
  auth_ShareServiceTypeNone     =-1,
  auth_ShareServiceTypeEmail    = 0,
  auth_ShareServiceTypeSMS      = 1,
  auth_ShareServiceTypeFacebook = 2,
  auth_ShareServiceTypeTwitter  = 3,
} auth_ShareServiceType;

#import "auth_ShareDelegate.h"
#import "auth_ShareUser.h"

@class auth_ShareUser;

/**
 * Completion block to customize user-entered text after the user have submitted through the sharing dialog.
 *
 * @param textFromReplyVC - text to customize
 */
typedef NSMutableDictionary* (^auth_ShareMessageProcessingBlock)(NSString *textFromReplyVC);

/**
 * Completion block letting handling raw facebook responses.
 *
 * @param data - response that you can treat as NSDictionary
 * @param error - error occured during loading (<code>nil</code> if loading succeeded).
 */
typedef void (^auth_ShareFacebookGenericCompletionBlock)(NSDictionary *data, NSError *error);

/**
 * Completion block to handle the feed loaded from public page on facebook.
 *
 * @param feedItems - array of dictionaries representing feed posts.
 * @param paging - dictionary with urls to previous and next portions of the posts.
 * @param error - error occured during loading (<code>nil</code> if loading succeeded).
 */
typedef void (^auth_ShareFacebookFeedLoadingCompletionBlock)(NSArray *feedItems, NSDictionary *paging, NSError *error);

/**
 * Completion block to handle loading of the comments on some facebook object.
 *
 * @param comments - array of dictionaries representing comments.
 * @param paging - dictionary with urls to previous and next portions of the comments.
 * @param error - error occured during loading (<code>nil</code> if loading succeeded).
 */
typedef void (^auth_ShareFacebookCommentsLoadingCompletionBlock)(NSArray *comments, NSDictionary *paging, NSError *error);

/**
 * Completion block to handle loading of the photos count for public page.
 *
 * @param count - photos count.
 */
typedef void (^auth_ShareFacebookPhotosCountCompletionBlock)(NSUInteger count);

/**
 * Completion block fro the scenario, when we have to get, for example, source URL for an image object by its facebook id.
 *
 * @param url - NSURL for given id.
 * @param error - error occured during loading (<code>nil</code> if loading succeeded).
 */
typedef void (^auth_ShareFacebookURLForIdCompletionBlock)(NSURL *url, NSError *error);




/**
 * Class to perform social actions (sharing, likes, authentication) on social newtorks 
 * or sharing via e-mail and SMS.
 *
 * Intended to be used with iPhone project. For iPad project, please use IBLogin.
 */
@interface auth_Share : NSObject <FHSTwitterEngineAccessTokenDelegate,
                                  MFMailComposeViewControllerDelegate,
                                  MFMessageComposeViewControllerDelegate>

/**
 * Current user logged in the app.
 */
@property (nonatomic, retain) auth_ShareUser *user;

/**
 * View controller to present social dialogs on.
 */
@property (nonatomic, assign) UIViewController *viewController;

/**
 * Completion selector called as callback after certain asynchronous actions.
 */
@property (nonatomic, assign) SEL currentCompletionSelector;

/**
 * Object acting as authShare delegate
 *
 * @see auth_ShareDelegate
 */
@property (nonatomic, assign) id<auth_ShareDelegate> delegate;

/**
 * Block to generate data dictionary for sharing
 * If nil, standard auth_Share's logic is used.
 *
 * Good practice is to nil it in initialization of every module which uses shared instance of auth_Share.
 *
 * At the moment employed in facebook sharing.
 */
@property (nonatomic, copy) auth_ShareMessageProcessingBlock messageProcessingBlock;


/**
 * Shared instance of the auth_Share.
 */
+(auth_Share *)sharedInstance;

/**
 * Authenticates user on service with the credentials provided.
 *
 * If user is not logged in, shows the prompt with an option to cancel authentication.
 */
-(auth_ShareServiceType)authenticatePersonUsingService:(auth_ShareServiceType)service
                                       andCredentials:(NSDictionary *)credentials;

/**
 * Authenticates user on service with the credentials provided.
 * Performs completionSelector with data as the authentication process finishes.
 *
 * If user is not logged in, shows the prompt with an option to cancel authentication.
 */
-(auth_ShareServiceType)authenticatePersonUsingService:(auth_ShareServiceType)service
                                       andCredentials:(NSMutableDictionary *)credentials
                                       withCompletion:(SEL)completionSelector
                                              andData:(NSMutableDictionary *)data;
/**
 * Authenticates user on service with the credentials provided.
 * Performs completionSelector with data as the authentication process finishes.
 *
 * If <code>showLoginRequired</code> set to <code>YES</code> and user is not logged in, 
 * shows the prompt with an option to cancel authentication.
 *
 * If <code>showLoginRequired</code> set to <code>NO</code>, authentication proceeds without the prompt.
 */
-(auth_ShareServiceType)authenticatePersonUsingService:(auth_ShareServiceType)service
                                       andCredentials:(NSMutableDictionary *)credentials
                                       withCompletion:(SEL)completionSelector
                                              andData:(NSMutableDictionary *)data
                        shouldShowLoginRequiredPrompt:(BOOL)showLoginRequired;

/**
 * Shares content on behalf of the specified user.
 * 
 * @param service - auth_Share service type.
 * @param user - user intending to share message.
 * @param data - NSDictionary with the message itself (usually for key "message").
 *
 * Additional keys may be added to fit different social networks sharing requirements.
 * For example, "link", "capture" keys to share on facebook.
 */
-(BOOL)shareContentUsingService:(auth_ShareServiceType)service
                       fromUser:(auth_ShareUser *)user
                       withData:(NSDictionary *)data;

/**
 * Shares content on behalf of the specified user.
 *
 * @param service - auth_Share service type.
 * @param user - user intending to share message.
 * @param data - NSDictionary with the message itself (usually for key "message").
 *
 * Additional keys may be added to fit different social networks sharing requirements.
 * For example, "link", "capture" keys to share on facebook.
 *
 * @param showPrompt - if <code>NO</code>, we do not bother user with please-login-to-service-or-cancel dialog
 * and show login form directly
 */
-(BOOL)shareContentUsingService:(auth_ShareServiceType)service
                       fromUser:(auth_ShareUser *)user
                       withData:(NSDictionary *)data
        showLoginRequiredPrompt:(BOOL)showPrompt;


/**
 * Checks if system twitter account exists and available for the app.
 */
-(BOOL)isAuthenticatedWithTwitter;

/**
 * Checks if app has a valid user session on facebook.
 */
-(BOOL)isAuthenticatedWithFacebook;

/**
 * When authorized on a social network, this convenience method returns user's name on that network.
 * @param service - auth_Share service type.
 */
- (NSString*) userNameForService:(auth_ShareServiceType)service;

/**
 * Posts Facebook like for URL and post named notification.
 * Always shows "Do you want to login to FB" prompt.
 *
 * @param URL - url-string to post like for.
 * @param notificationName - notification name to post when posting a like finishes.
 */
- (void)postLikeForURL:(NSString *)URL
        withNotificationNamed:(NSString *)notificationName;

/**
 * Posts Facebook like for URL and post named notification.
 * Always shows "Do you want to login to FB" prompt.
 *
 * @param URL - url-string to post like for.
 * @param notificationName - notification name to post when posting a like finishes.
 * @param ShowLoginRequired - should we show the user the "Do you want to login to FB" prompt.
 */
- (void)postLikeForURL:(NSString *)URL
        withNotificationNamed:(NSString *)notificationName
        shouldShowLoginRequiredPrompt:(BOOL)showLoginRequired;

/**
 * Post FB like for Facebook Id (e.g. feed post).
 * Does not show the "Do you want to login to FB" prompt.
 *
 * @param Id - NSString id of the facebook object.
 */
- (void)postLikeForId:(NSString *)Id;

/**
 * Post FB like for Facebook Id (e.g. feed post).
 * Does not show the "Do you want to login to FB" prompt.
 * Calls completion block when done.
 *
 * @param completion - completion block.
 *
 * @see auth_ShareFacebookGenericCompletionBlock
 */
- (void)postLikeForPageId:(NSString *)Id
               completion:(auth_ShareFacebookGenericCompletionBlock)completion;

/**
 * Loads likes count for URLs represented as NSSet of NSString*
 * Calls didLoadFacebookLikesCount:error: delegate method when done.
 *
 * @param URLs - URLs to load counts for.
 */
- (void)loadFacebookLikesCountForURLs:(NSSet *)URLs;

/**
 * Loads likes count for Facebook Ids represented as NSString* set
 * Calls didLoadFacebookLikesCount:error: delegate method when done.
 *
 * @param (NSSet *)Ids - Facebook Ids represented as NSString* set
 *
 * @see auth_ShareDelegate
 */
- (void)loadFacebookLikesCountForIds:(NSSet *)Ids;

/**
 * Load URLs liked on facebook by the current user authenicated on facebook.
 * Calls didLoadFacebookLikedURLs when done.
 *
 * @see auth_ShareDelegate
 */
- (void)loadFacebookLikedURLs;

/**
 * Load URLs liked on facebook by the current user authenicated on facebook.
 * Calls didLoadFacebookLikedIds when done.
 *
 * @see auth_ShareDelegate
 */
- (void)loadFacebookLikedIds;

/**
 * Load Facebook public pages liked by the current user authenicated on facebook.
 * Calls completion when done.
 *
 * @param completion - completion block of type auth_ShareFacebookGenericCompletionBlock.
 *
 * @see auth_ShareFacebookGenericCompletionBlock
 */
- (void)loadFacebookLikedPagesWithCompletion:(auth_ShareFacebookGenericCompletionBlock)completion;

/**
 * Load Facebook engagement info. Looks like "You and 3 others like this".
 * Calls completion when done.
 *
 * @param facebookId - facebook id to load engagement for.
 * @param completion - completion block of type auth_ShareFacebookGenericCompletionBlock.
 *
 * @see auth_ShareFacebookGenericCompletionBlock
 */
- (void)loadFacebookEngagementForId:(NSString *)facebookId
                         completion:(auth_ShareFacebookGenericCompletionBlock)completion;

/**
 * Loads facebook feed for given public page id. When proided with a custom graph path, 
 * executes request with this path (useful for paging).
 * Loads 25 posts by default.
 * Calls completion when done.
 *
 * @param facebookId - public page id to load feed from.
 * @param customPath - custom grap path to override the default.
 * @param completion - completion block of type auth_ShareFacebookFeedLoadingCompletionBlock.
 *
 * @see auth_ShareFacebookFeedLoadingCompletionBlock
 */
- (void)loadFacebookFeedForId:(NSString *)facebookId
              customGraphPath:(NSString *)customPath
                   completion:(auth_ShareFacebookFeedLoadingCompletionBlock)completion;

/**
 * Loads facebook comments for ids in set.
 * Calls didLoadFacebookCommentsCount:error: delegate method when done.
 *
 * @param Ids - Facebook Ids to load comments to.
 *
 * @see auth_ShareDelegate
 */
- (void)loadFacebookCommentsCountForIds:(NSSet *)Ids;

/**
 * Loads facebook info for id specified.
 * Calls completion when done.
 *
 * @param facebookId - facebook id as NSString.
 * @param completion - completion block of type auth_ShareFacebookGenericCompletionBlock.
 *
 * @see auth_ShareFacebookGenericCompletionBlock
 */
- (void)loadFacebookInfoForId:(NSString *)facebookId
                   completion:(auth_ShareFacebookGenericCompletionBlock)completion;

/**
 * Loads facebook info for id specified.
 * Calls completion when done.
 *
 * @param facebookId - facebook id as NSString.
 * @param completion - completion block of type auth_ShareFacebookPhotosCountCompletionBlock.
 *
 * @see auth_ShareFacebookPhotosCountCompletionBlock
 */
- (void)loadFacebookPhotosCountForId:(NSString *)facebookId
                          completion:(auth_ShareFacebookPhotosCountCompletionBlock)completion;

/**
 * Assembles an URL for user avatar
 *
 * @param facebookId - user facebook id.
 */
+ (NSURL *)facebookPictureURLForId:(NSString *)facebookId;

/**
 * Assembles an URL for user avatar.
 * Uses timestamp to prevent caching.
 *
 * @param facebookId - user facebook id.
 * @param timestamp - NSTimeInterval to specify in the timestamp.
 */
+ (NSURL *)facebookPictureURLForId:(NSString *)facebookId
                         timestamp:(NSTimeInterval)timestamp;

/**
 * Posts a Facebook comment on Facebook object with given id.
 * Calls completion when done.
 *
 * @param message - comment's text
 * @param objectId - Facebook object id to post comment on
 * @param completion - completion block of type auth_ShareFacebookGenericCompletionBlock.
 *
 * @see auth_ShareFacebookGenericCompletionBlock
 */
- (void)postFacebookComment:(NSString *)message
             parentObjectId:(NSString *)objectId
                 completion:(auth_ShareFacebookGenericCompletionBlock)completion;

/**
 * Loads facebook URL for a given facebook id.
 * Calls completion when done.
 *
 * @param facebookId - id to load URL for
 * @param completion - completion block of type auth_ShareFacebookURLForIdCompletionBlock.
 *
 * @see auth_ShareFacebookGenericCompletionBlock
 */
-(void)loadFacebookImageURLForId:(NSString *)facebookId
                      completion:(auth_ShareFacebookURLForIdCompletionBlock)completion;


/**
 * Exectutes a Facebook request with given graph path.
 * Calls completion when done.
 *
 * @param path - custom graph path.
 * @param completion - completion block of type auth_ShareFacebookGenericCompletionBlock.
 *
 * @see auth_ShareFacebookGenericCompletionBlock
 */
-(void)postFacebookRequestWithGraphPath:(NSString *)path
                             completion:(auth_ShareFacebookGenericCompletionBlock)completion;

/**
 * Loads facebook video descriptions ("videos") meeting the passed constraints.
 * Set since and/or until to 0 if you do not have any requirements
 * Do not use since and until set both, FB returns empty set
 *
 * @param facebookId - public page id to laod videos for.
 * @param customGraphPath - custom graph path. If set, params since, until and limit are ignored.
 * @param since - constraints the earliest post to load a video from.
 * @param until - constraints the latest post to load a video from.
 * @param limit - limit of videos to be loaded.
 * @param completion - completion block of type auth_ShareFacebookGenericCompletionBlock.
 *
 * @see auth_ShareFacebookGenericCompletionBlock
 */
-(void)loadFacebookVideosForId:(NSString *)facebookId
               customGraphPath:(NSString *)customGraphPath
                         since:(long long)since
                         until:(long long)until
                         limit:(NSUInteger)limit
                    completion:(auth_ShareFacebookGenericCompletionBlock)completion;

/**
 * Loads an array of facebook video descriptions for ids specified in the facebookIds set.
 * Calls completion when done.
 *
 * @param facebookIds - set of video ids to load descriptions for.
 * @param completion - completion block of type auth_ShareFacebookGenericCompletionBlock.
 *
 * @see auth_ShareFacebookGenericCompletionBlock
 */
-(void)loadFacebookVideosForIds:(NSSet *)facebookIds
                     completion:(auth_ShareFacebookGenericCompletionBlock)completion;

/**
 * Creates native facebook "Like" button targeted to an Id provided.
 *
 * @param target - string of id to be liked with the button.
 *
 * @return depersonalized representation of the button as UIControl.
 */
-(UIControl *)nativeFacebookLikeControlForId:(NSString *)target;

/**
 * Softer check for isAuthenticatedWithFacebook
 */
- (BOOL)userFacebookTokenExists;

/**
 * Cancels operations in auth_ShareBackroundOperationQueue.
 * Currently loading of liked items and likes count on Facebook
 */
- (void)cancelPendingTasksIfAny;

@end