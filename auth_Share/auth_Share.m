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

#import "auth_Share.h"
#import "auth_ShareReplyVC.h"
#import "twitterid.h"
#import "OAToken.h"//"FHSTwitterEngine/OAuthConsumer/OAToken.h"
#import "UIAlertView+MKBlockAdditions.h"//<MKAdditions/UIAlertView+MKBlockAdditions.h>
#import "MBProgressHUD.h"//<MBProgressHUD/MBProgressHUD.h>
#import <Foundation/Foundation.h>
#import "Reachability.h"
#import "functionLibrary.h"
#import "SBJSON.h"
#import <FacebookSDK/FacebookSDK.h>
#import "appbuilderappconfig.h"//<appconfig.h>

#define twitterInfoPath  @"https://api.twitter.com/1.1/users/show.json"
#define kTwitterMessageLength 140
#define kTwitterMessageWithMediaUrlLength kTwitterMessageLength - 24
#define facebookInfoPath FacebookGraphAPILatestEndpoint @"/me"

#define kFacebookAllInOnePermissionsArray @[@"email", @"publish_actions"]
#define kFacebookBatchLimit 50
#define kauth_ShareFBSessionType @"IBShareFBSessionType"

#define kFacebookLikesEdge @"likes"
#define kFacebookCommentsEdge @"comments"

typedef enum {
  auth_ShareFBSessionTypeNone = 0,
  auth_ShareFBSessionTypeIBA = 1,
  auth_ShareFBSessionTypeUser = 2
} auth_ShareFBSessionType;

/**
 * Enum to differentiate likes loading for 
 * ids and from loading for urls.
 */
typedef enum {
  auth_ShareFBItemTypeURL = 1,
  auth_ShareFBItemTypeId = 2
} auth_ShareFBItemType;


/**
 * Facebook can operate with <=50 ids per request, so we have to
 * track the state of larger logical requests.
 */
@interface auth_ShareFBBatchProcessingState : NSObject

@property (nonatomic) NSUInteger requestsRemaining;
@property (nonatomic) BOOL failedWithError;

@end

@implementation auth_ShareFBBatchProcessingState

-(void)setFailedWithError:(BOOL)failedWithError
{
  if(failedWithError){
    _failedWithError = failedWithError;
    _requestsRemaining = 0;
  }
}

@end

@interface auth_Share() {
  NSUserDefaults *UD;
  BOOL shareOnTwitterWithCustomWindow;
  NSUInteger likeAttemptsRemaining;
}

  @property (nonatomic, retain) FHSTwitterEngine *engine;
  @property (nonatomic, retain) __block NSMutableDictionary *blockData;
  @property (nonatomic, retain) MFMailComposeViewController *mailController;
  @property (nonatomic, retain) MFMessageComposeViewController *messageController;

  @property (nonatomic, strong)  auth_ShareReplyVC *replyVC;

  /**
   * Login-to-facebook-required message depending on usecase;
   * "You must be logged to facebok to *like* this item" for like.
   * "You must be logged to facebok to *share* this item" for share and so on.
   */
  @property (nonatomic, strong) NSString *facebookLoginRequiredPrompt;
  @property (nonatomic, strong) NSOperationQueue *aShaBackroundOperationQueue;
  @property (nonatomic, strong) NSMutableArray *pendingHTTPRequests;

  @property (nonatomic, strong) NSMutableDictionary *urlsFromIdsCache;

  @property (nonatomic, strong) NSString *facebookPhotosCountNextPath;
  @property (nonatomic, assign) NSUInteger facebookPhotosCount;

@end

@implementation auth_Share : NSObject

static auth_Share *auth_ShareSingleton = nil;

@synthesize user = _user;
@synthesize viewController;
@synthesize currentCompletionSelector = _currentCompletionSelector;
@synthesize engine;
@synthesize mailController;
@synthesize delegate;

@synthesize replyVC;

-(auth_ShareUser *)user {
  if(_user == nil) {
    _user = [[auth_ShareUser alloc] init];

    UD = [NSUserDefaults standardUserDefaults];
    
      // Account type "guest" is valid only for widget TableReservation.
      // So, return in this case.
    NSString *accountType = [UD objectForKey: @"mAccountType"];
    if (accountType
        && ([accountType isEqualToString:@"none"] || [accountType isEqualToString:@"guest"]))
    {
      _user.authentificatedWith = auth_ShareServiceTypeNone;
      _user.type                = nil;
      _user.ID                  = nil;
      _user.name                = nil;
      _user.avatar              = nil;
      return _user;
    }
    
    _user.authentificatedWith = (auth_ShareServiceType)([UD integerForKey:@"mAuthentificatedWith"] ? [UD integerForKey:@"mAuthentificatedWith"] : [_user getCurrentServiceType]);
    _user.type                = ([UD objectForKey: @"mAccountType"]         ? [UD objectForKey: @"mAccountType"]         : nil);
    _user.ID                  = ([UD objectForKey: @"mAccountID"]           ? [UD objectForKey: @"mAccountID"]           : nil);
    _user.name                = ([UD objectForKey: @"mUserName"]            ? [UD objectForKey: @"mUserName"]            : nil);
    _user.avatar              = ([UD objectForKey: @"mAvatar"]              ? [UD objectForKey: @"mAvatar"]              : nil);
  }
  return _user;
}

#pragma mark auth_Share Singleton definition

+(auth_Share *)sharedInstance {
  @synchronized(self) {
    if (auth_ShareSingleton == nil) {
      auth_ShareSingleton = [NSAllocateObject([self class], 0, NULL) init];
    }
  }
  
  return auth_ShareSingleton;
}

- (id) copyWithZone:(NSZone*)zone {
  return self;
}

- (id) retain {
  return self;
}

- (NSUInteger) retainCount {
  return NSUIntegerMax;
}

- (oneway void)release {
}

- (id) autorelease {
  return self;
}

#pragma mark auth_Share lifecycle

-(id)init {
  self = [super init];
  if (self) {
    self.user = nil;
    self.viewController = nil;
    self.currentCompletionSelector = nil;
    self.engine = nil;
    self.blockData = nil;
    self.mailController = nil;
    self.messageController = nil;
    self.replyVC = nil;
    
    delegate = nil;
    
    UD = [NSUserDefaults standardUserDefaults];
    shareOnTwitterWithCustomWindow = NO;
    self.facebookLoginRequiredPrompt = nil;
    _aShaBackroundOperationQueue = [[NSOperationQueue alloc] init];
    _pendingHTTPRequests = nil;
    
    likeAttemptsRemaining = 5;
    
    self.messageProcessingBlock = nil;
    
    self.urlsFromIdsCache = [[[NSMutableDictionary alloc] init] autorelease];
    
    [FBSettings setDefaultUrlSchemeSuffix:[self fbURLSchemeSuffix]];
  }
  return self;
}

-(void)dealloc {
  self.user = nil;
  self.viewController = nil;
  self.currentCompletionSelector = nil;
  self.engine = nil;
  self.blockData = nil;
  self.mailController = nil;
  self.messageController = nil;
  self.replyVC = nil;
  
  delegate = nil;
  
  self.facebookLoginRequiredPrompt = nil;
  self.aShaBackroundOperationQueue = nil;
  self.pendingHTTPRequests = nil;
  
  self.messageProcessingBlock = nil;
  
    //maybe it would be nice to store the cache to disk...
  self.urlsFromIdsCache = nil;
  
  self.facebookPhotosCountNextPath = nil;
  
  [super dealloc];
}

#pragma mark auth_Share Global function

- (NSString*) userNameForService:(auth_ShareServiceType)service
{
  __block NSString *userName = nil;

  switch (service) {
    case auth_ShareServiceTypeTwitter: {
      
      dispatch_semaphore_t sema = dispatch_semaphore_create(0);
      
      if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType  *accountType  = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
          if (granted) {
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            if (accounts.count > 0) {
              ACAccount *twitterAccount = [accounts objectAtIndex:0];
              userName = [[twitterAccount.username copy] retain];
            }
          }
          
          dispatch_semaphore_signal(sema);
        }];
      } else {
        userName = @"";
      }
      
      
      dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
      dispatch_release(sema);
    }
      break;
      
    case auth_ShareServiceTypeNone: {
      userName = @"";
    }
      break;
      
    default: {
      if (self.user)
        userName = self.user.name;
      else
        userName =  @"";
    }
      break;
  }
  
  
  return userName;
}


-(auth_ShareServiceType)authenticatePersonUsingService:(auth_ShareServiceType)service
                                  andCredentials:(NSMutableDictionary *)credentials
{
  return [self authenticatePersonUsingService:service
                               andCredentials:credentials
                               withCompletion:nil
                                      andData:nil
                shouldShowLoginRequiredPrompt:YES];
}

-(auth_ShareServiceType)authenticatePersonUsingService:(auth_ShareServiceType)service
                                  andCredentials:(NSMutableDictionary *)credentials
                                  withCompletion:(SEL)completionSelector
                                         andData:(NSMutableDictionary *)data
{
  return [self authenticatePersonUsingService:service
                               andCredentials:credentials
                               withCompletion:completionSelector
                                      andData:data
                shouldShowLoginRequiredPrompt:YES];
}

-(auth_ShareServiceType)authenticatePersonUsingService:(auth_ShareServiceType)service
                                  andCredentials:(NSMutableDictionary *)credentials
                                  withCompletion:(SEL)completionSelector
                                         andData:(NSMutableDictionary *)data
                   shouldShowLoginRequiredPrompt:(BOOL)showLoginRequired {
  
  __block auth_ShareServiceType result = auth_ShareServiceTypeNone;
  
  switch (service) {
    case auth_ShareServiceTypeEmail: {
      result = auth_ShareServiceTypeEmail;
    }
      break;
      
    case auth_ShareServiceTypeSMS: {
      result = auth_ShareServiceTypeSMS;
    }
      break;
      
    case auth_ShareServiceTypeFacebook: {
     
      [self authFacebookWithCompletion:completionSelector
                               andData:data
                        andPermissions:kFacebookAllInOnePermissionsArray
                           publishMode:YES
         shouldShowLoginRequiredPrompt:showLoginRequired];
      
      result = auth_ShareServiceTypeFacebook;
    }
      break;
      
    case auth_ShareServiceTypeTwitter: {
      if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType  *accountType  = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        /*
         * Wait for request to complete. Otherwise we get wrong return result
         */
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
          if (granted)
          {
            NSArray *accounts = [accountStore accountsWithAccountType:accountType];
            if (accounts.count > 0) {
              ACAccount *twitterAccount = [accounts objectAtIndex:0];
              
              result = auth_ShareServiceTypeTwitter;
              
              
              SLRequest *twitterInfoRequest = [SLRequest requestForServiceType:SLServiceTypeTwitter
                                                                 requestMethod:SLRequestMethodGET
                                                                           URL:[NSURL URLWithString:twitterInfoPath]
                                                                    parameters:[NSDictionary dictionaryWithObject:twitterAccount.username forKey:@"screen_name"]];
              [twitterInfoRequest setAccount:twitterAccount];

              [twitterInfoRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                  if (responseData) {
                    NSError *error = nil;
                    NSDictionary *TWData = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingMutableLeaves error:&error];

                    self.user.authentificatedWith =  auth_ShareServiceTypeTwitter;
                    self.user.type                =  @"twitter";
                    self.user.name                =  [TWData objectForKey:@"screen_name"];
                    self.user.ID                  =  [TWData objectForKey:@"id_str"];
                    self.user.avatar              = [[TWData objectForKey:@"profile_image_url"] stringByReplacingOccurrencesOfString:@"_normal" withString:@"_bigger"];
                    
                    [self saveUser:self.user];
                    
                    result = auth_ShareServiceTypeTwitter;
                    
                    if(completionSelector) {
                      [[self targetForSelector:completionSelector] performSelector:completionSelector withObject:data];
                    } else {
                      [[NSNotificationCenter defaultCenter] postNotificationName:k_auth_Share_LoginState object:@"twitter"];
                    }
                  }
                });
              }];
            }

          }
          else {
            dispatch_async(dispatch_get_main_queue(), ^{
              
#ifdef ENABLE_CONNECTION_WITH_BLOCKED_SYSTEM_ACCOUNT
              [self authTwitterWithCompletion:completionSelector andData:data];
#else
              [self informResult:NSBundleLocalizedString(@"asha_cannotAccessTwitterProfile", @"Cannot access Twitter Profile") withTitle:@"" andDismissText:@"OK"];
#endif
            });
          }
          
          dispatch_semaphore_signal(sema);
        }];
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
        
      } else {
        [self authTwitterWithCompletion:completionSelector andData:data];
      }
    }
      break;
      
    case auth_ShareServiceTypeNone: {
      result = auth_ShareServiceTypeNone;
    }
      break;
  }
  
  return result;
}

-(BOOL)shareContentUsingService:(auth_ShareServiceType)service
                       fromUser:(auth_ShareUser *)user
                       withData:(NSMutableDictionary *)data {
  return [self shareContentUsingService:service fromUser:user withData:data showLoginRequiredPrompt:YES];
}


-(BOOL)shareContentUsingService:(auth_ShareServiceType)service
                       fromUser:(auth_ShareUser *)user
                       withData:(NSMutableDictionary *)data
        showLoginRequiredPrompt:(BOOL)showPrompt
{
  __block BOOL result = NO;
  
  switch (service) {
    case auth_ShareServiceTypeEmail: {
      [self shareToEmailWithData:data];
      
      result = YES;
    }
      break;
      
    case auth_ShareServiceTypeSMS: {
      [self shareToSMSWithData:data];
      
      result = YES;
    }
      break;
      
    case auth_ShareServiceTypeFacebook: {
      shareOnTwitterWithCustomWindow = NO;
      
      VoidBlock proceedHandler = ^{
        [self typeMessageWithData:data];
      };
      
      VoidBlock authorizationHandler = ^{
        [self authenticatePersonUsingService:service
                              andCredentials:nil
                              withCompletion:@selector(typeMessageWithData:)
                                     andData:data
               shouldShowLoginRequiredPrompt:showPrompt];
      };
      
      if([self isAuthenticatedWithFacebook]) {
        [self checkIfDeauthorizedWithProceedHandler:proceedHandler
                               authorizationHandler:authorizationHandler];

      } else {
        authorizationHandler();
      }
      
      result = YES;
    }
      break;
      
    case auth_ShareServiceTypeTwitter: {
      //check for system twitter account
      if([self isAuthenticatedWithTwitter]) {
        shareOnTwitterWithCustomWindow = NO;
        [self shareToTwitterWithData:data];
      }
      else if (self.user.authentificatedWith == auth_ShareServiceTypeTwitter)
      {
        shareOnTwitterWithCustomWindow = YES;
        [self typeMessageWithData:data];
      }
      else {
        [self authenticatePersonUsingService:service
                                andCredentials:nil
                                withCompletion:@selector(dispatchToTwitterSharingWithData:)
                                       andData:data
                 shouldShowLoginRequiredPrompt:showPrompt];
      }
      result = YES;
    }
      break;
      
    case auth_ShareServiceTypeNone: {
      result = NO;
    }
      break;
  }
  
  return result;
}

#pragma mark auth_Share Twitter-specific inner function

-(BOOL)isAuthenticatedWithTwitter {
  
  __block BOOL result = NO;
  
  if([SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter]) {
    ACAccountStore *accountStore = [[ACAccountStore alloc] init];
    ACAccountType  *accountType  = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);

    [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
      if (granted) {
        NSArray *accounts = [accountStore accountsWithAccountType:accountType];
        if (accounts.count > 0) {
          result = YES;
        }
      }
      
      dispatch_semaphore_signal(sema);
    }];
    
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    dispatch_release(sema);
  }
  
  return result;
}

- (BOOL) isAuthentificatedWithServiceType:(NSString *)type
{
    __block BOOL result = NO;
    
    if([SLComposeViewController isAvailableForServiceType:type]) {
        ACAccountStore *accountStore = [[ACAccountStore alloc] init];
        ACAccountType  *accountType  = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
        
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        
        [accountStore requestAccessToAccountsWithType:accountType options:nil completion:^(BOOL granted, NSError *error) {
            if (granted) {
                NSArray *accounts = [accountStore accountsWithAccountType:accountType];
                if (accounts.count > 0) {
                    result = YES;
                }
            }
            
            dispatch_semaphore_signal(sema);
        }];
        
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        dispatch_release(sema);
    }
    
    return result;
}


-(void)authTwitterWithCompletion:(SEL)completionSelector andData:(NSMutableDictionary *)data {
  if(completionSelector)
  {
    self.currentCompletionSelector = completionSelector;
  }
  if(!self.blockData)
    self.blockData = [data copy];
  if ( !self.engine )  {
    self.engine = [FHSTwitterEngine sharedEngine];
  }
  
#ifdef TWITTER_DEBUG
  NSLog(@"+++++++++++++permanentlySetConsumerKey: %@ \r\n andSecret: %@", [TwitterID getConsumerKey], [TwitterID getConsumerSecret]);
#endif
  
  [self.engine permanentlySetConsumerKey:[TwitterID getConsumerKey] andSecret:[TwitterID getConsumerSecret]];
  self.engine.delegate = self;
  
  [self.engine loadAccessToken];
  
  NSString *username = self.engine.loggedInUsername;
  if (username.length > 0 && ![username isEqualToString:twitterDefaultUserOwnerName()]
      && [SLComposeViewController isAvailableForServiceType:SLServiceTypeTwitter])
  {
    [self storeAccountWithAccessToken:self.engine.accessToken.key secret:self.engine.accessToken.secret withCompletion:completionSelector andData:self.blockData];
  }
  else {
    
    [self.engine showOAuthLoginControllerFromViewController:self.viewController withCompletion:^(BOOL success) {
      if (success) {
        auth_Share *aShare = self;

          [self storeAccountWithAccessToken:aShare.engine.accessToken.key
                                     secret:aShare.engine.accessToken.secret
                             withCompletion:aShare.currentCompletionSelector
                                    andData:aShare.blockData];
      }
      else {
        NSLog(@"Failed to login to Twitter!");
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

        NSError *error = [NSError errorWithDomain:@"com.ibuildapp.auth_Share.twitter" code:1 userInfo:@{@"message" : @"Failed to login to Twitter!"}];
        [[NSNotificationCenter defaultCenter] postNotificationName:k_auth_Share_LoginState object:@"twitter" userInfo:@{@"error" : error}];
      }
    }];
  }
}

-(void)shareToTwitterWithData:(NSMutableDictionary *)data {
  SLComposeViewController *composeController = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
  
  NSString *link = [data objectForKey:@"link"];
  NSString *message = [data objectForKey:@"message"];
  NSString *additionalText = [data objectForKey:@"additionalText"];
  UIImage *image = [data objectForKey:@"image"];
  
  NSInteger maxMessageLength;
  
  if(image){
    maxMessageLength = kTwitterMessageWithMediaUrlLength;
  } else {
    maxMessageLength = kTwitterMessageLength;
  }
  
  if(message.length && link.length){
    message = [NSString stringWithFormat:@"%@ %@", message, link];
  }
  
  if(message.length && additionalText.length){
    message = [self appendAdditionalText:additionalText toTwitterMessage:message constrainToLength:maxMessageLength];
    
  } else if(additionalText.length){
    message = [self appendAdditionalText:additionalText toTwitterMessage:@"" constrainToLength:maxMessageLength];
  }
  
  [composeController setInitialText:message];
  
  if(image)   [composeController addImage:image];
  
  composeController.completionHandler = ^(SLComposeViewControllerResult result) {
    [composeController dismissViewControllerAnimated:NO completion:nil];
    switch(result) {
      case SLComposeViewControllerResultCancelled: {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        NSLog(@"\n############ [STUB] Sharing via Twitter cancelled.");
      }
        break;
      case SLComposeViewControllerResultDone: {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        NSLog(@"\n############ [STUB] Sharing via Twitter successfully completed.");
        Reachability *hostReachable;
        NetworkStatus hostStatus;
        
        hostReachable = [Reachability reachabilityWithHostName:[functionLibrary hostNameFromString:[@"http://twitter.com" stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        hostStatus = [hostReachable currentReachabilityStatus];
        
        if (hostStatus != NotReachable)
        {
          if (self.delegate && [self.delegate respondsToSelector:@selector(didShareDataForService:error:)])
          {
            [self.delegate didShareDataForService:auth_ShareServiceTypeTwitter error:nil];
          }
        }
      }
        break;
    }
    self.blockData = nil;
  };
  
  [self.viewController presentViewController:composeController animated:YES completion:nil];
}

-(void)storeAccessToken:(NSString *)accessToken {
  [TwitterID storeAccessToken:accessToken];
}

-(NSString *)loadAccessToken {
  return [TwitterID loadAccessToken];
}

-(void)storeAccountWithAccessToken:(NSString *)token secret:(NSString *)secret withCompletion:(SEL)completionSelector andData:(NSMutableDictionary *)data {
  ACAccountCredential *credential = [[ACAccountCredential alloc] initWithOAuthToken:token tokenSecret:secret];
  ACAccountStore *accountStore = [[ACAccountStore alloc] init];
  ACAccount *newTwitterAccount = [[ACAccount alloc] initWithAccountType:[accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter]];
  newTwitterAccount.credential = credential;
  
  [self.engine loadAccessToken];
  
  [self.engine permanentlySetConsumerKey:[TwitterID getConsumerKey]
                        andSecret:[TwitterID getConsumerSecret]];

  [accountStore saveAccount:newTwitterAccount withCompletionHandler:^(BOOL success, NSError *error) {
    if (success) {
      
        // ???
      NSLog(@"accountStore saveAccount: success: YES");
      NSLog(@"Save account withCompletion:%@ andData:%@", NSStringFromSelector(completionSelector), data);
      [self authenticatePersonUsingService:auth_ShareServiceTypeTwitter andCredentials:nil withCompletion:completionSelector andData:data];
    }
    else {
      NSLog(@"\n\n%@", [error localizedDescription]);
      
      if ([error code] == ACErrorPermissionDenied) {
        NSLog(@"Got a ACErrorPermissionDenied, the account was not saved!");
        NSLog(@"accountStore saveAccount: success: NO");
      }
      

//#ifdef ENABLE_CONNECTION_WITH_BLOCKED_SYSTEM_ACCOUNT
      [self fillTwitterUserInfoWithCompletion:completionSelector andData:data];
      
      NSLog(@"the account was not saved! %tu, %@", [error code], error);
      
//#endif
    }
  }];
}

- (void)fillTwitterUserInfoWithCompletion:(SEL)completion andData:(NSMutableDictionary *)data
{
  // run async task to obtain user avatar url
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  dispatch_async(GCDBackgroundThread, ^{
    @autoreleasepool {
      NSError *returnCode = nil;
      NSURL *url = [engine getProfileImageURLForUsername:engine.loggedInUsername
                                                 andSize:FHSTwitterEngineImageSizeBigger
                                                   error:&returnCode];
      dispatch_sync(GCDMainThread, ^{
        if ( url )
        {
          self.user.name = [FHSTwitterEngine sharedEngine].loggedInUsername;
          self.user.ID = [FHSTwitterEngine sharedEngine].loggedInID;
          self.user.authentificatedWith = auth_ShareServiceTypeTwitter;
          self.user.type = @"twitter";
          self.user.avatar = [url absoluteString];
          
          [self saveUser:self.user];
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:k_auth_Share_LoginState object:@"twitter"];
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        
        if(completion){
          [[self targetForSelector:completion] performSelector:completion withObject:data afterDelay:0.5f];
        }
      });
    }
  });
}

#pragma mark auth_Share Facebook-specific inner function
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

-(BOOL)isAuthenticatedWithFacebook {
  if (FBSession.activeSession.state == FBSessionStateOpen ||
      FBSession.activeSession.state == FBSessionStateOpenTokenExtended)
  {
    return ![self isIBAFBSession];
  }
  
  return NO;
}

-(void)authFacebookWithCompletion:(SEL)completionSelector
                          andData:(NSMutableDictionary *)data
                   andPermissions:(NSArray *)permissions
                      publishMode:(BOOL)publishMode
    shouldShowLoginRequiredPrompt:(BOOL)showPrompt{
  
  __block NSArray *fbpermissions = permissions;
  
  if(!fbpermissions){
    fbpermissions = kFacebookAllInOnePermissionsArray;
  }

  if([self isIBAFBSession]){
    //in case we were using default iba fb account, log out from it
    [self closeFBSession];
    
    [self authFacebookWithCompletion:completionSelector
                             andData:data
                      andPermissions:permissions
                         publishMode:publishMode
       shouldShowLoginRequiredPrompt:showPrompt];
    
    return;
  }
  
  [self checkIfSessionIsInTerminalStateAndCloseIfNeeded:[FBSession activeSession]];
  
  if(completionSelector){
    FBSessionStateHandler whatIfWeAreAlreadyLoggedInHandler = ^(FBSession *innerSession,
                                                                FBSessionState status,
                                                                NSError *error) {
      
      if(!error && (status == FBSessionStateOpen || status == FBSessionStateOpen)){
        [[self targetForSelector:completionSelector] performSelector:completionSelector withObject:data];
        return;
      }
    };
    if([self executeHandlerOnUserFBSession:whatIfWeAreAlreadyLoggedInHandler]){
      return;
    }
  }
  
  if(showPrompt){
    
    [fbpermissions retain];
    
    [UIAlertView alertViewWithTitle:NSBundleLocalizedString(@"asha_loginFBRequiredTitle", @"Log In Required")
                            message:self.facebookLoginRequiredPrompt
                  cancelButtonTitle:NSBundleLocalizedString(@"asha_loginFBRequiredCancel", @"Cancel")
                  otherButtonTitles:[NSArray arrayWithObjects:NSBundleLocalizedString(@"asha_loginFBRequiredLogIn", @"Log In"), nil]
                          onDismiss:^(int buttonIndex) {
                            [self openFacebookSessionWithPermissions:fbpermissions
                                                  completionSelector:completionSelector
                                                  withCompletionData:data];
                          }
                           onCancel:^() {
                             NSLog(@"Facebook Login Cancelled");
                           }];
  } else {
    [self openFacebookSessionWithPermissions:fbpermissions
                          completionSelector:completionSelector
                          withCompletionData:data];
  }
}

- (void)openFacebookSessionWithPermissions:(NSArray *)fbpermissions
                        completionSelector:(SEL)completionSelector
                        withCompletionData:(NSDictionary *)data {
  
  FBSessionStateHandler handler = ^(FBSession *session, FBSessionState status, NSError *error)
  {
    if (!error) {
      [[FBRequest requestForMe] startWithCompletionHandler:
       ^(FBRequestConnection *connection, NSDictionary<FBGraphUser> *user, NSError *error) {
         if (!error)
         {
           //fbv22 user.id -> user.objectID
           self.user.authentificatedWith =  auth_ShareServiceTypeFacebook;
           self.user.type                =  @"facebook";
           self.user.name                =  [NSString stringWithFormat:@"%@ %@", user.first_name, user.last_name];
           self.user.ID                  =  user.objectID;
           self.user.avatar              =  [NSString stringWithFormat:@"%@/%@/picture?type=large", FacebookGraphAPILatestEndpoint, user.objectID];
           
           [self saveUser:self.user];
           
           [self storeFBSessionType:auth_ShareFBSessionTypeUser];
           
           if(completionSelector)
           {
             [[self targetForSelector:completionSelector] performSelector:completionSelector
                                                               withObject:data];
           }
           
         }
         [self notifyFacebookAuthorizationResultWithError:error];
       }];
    } else {
      [self notifyFacebookAuthorizationResultWithError:error];
    }
  };
  
  if([self isIBAFBSession])
  {
    [self closeFBSession];
  }

  NSString *urlSchemeSuffix = [self fbURLSchemeSuffix];
  FBSession *activeSession = [[[FBSession alloc] initWithAppID:[self facebookAppId]
                                                   permissions:kFacebookAllInOnePermissionsArray
                                               defaultAudience:FBSessionDefaultAudienceFriends
                                               urlSchemeSuffix:urlSchemeSuffix
                                            tokenCacheStrategy:nil] autorelease];
  
  [FBSession setActiveSession:activeSession];
  
  [activeSession openWithBehavior:FBSessionLoginBehaviorForcingSafari
                completionHandler:handler];
}

-(NSString *)fbURLSchemeSuffix
{
  NSString *urlSchemeSuffix = [NSString stringWithFormat:@"iba%@", appProjectID()];
  
  return urlSchemeSuffix;
}

-(void)notifyFacebookAuthorizationResultWithError:(NSError *)error
{
  if(error)
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:k_auth_Share_LoginState
                                                        object:@"facebook"
                                                      userInfo:@{@"error" : error}];
  } else
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:k_auth_Share_LoginState
                                                        object:@"facebook"];
  }
  
  
  if([self.delegate respondsToSelector:@selector(didAuthorizeOnService:error:)]){
    [self.delegate didAuthorizeOnService:auth_ShareServiceTypeFacebook error:error];
  }
  
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

-(void)typeMessageWithData:(NSMutableDictionary *)data {
  
  SEL actionToPerform;
  NSString *screenTitle;
  
  self.replyVC = [[[auth_ShareReplyVC alloc] init] autorelease];
  
  if (shareOnTwitterWithCustomWindow){
    actionToPerform = @selector(postTweetWithData:);
    screenTitle = NSBundleLocalizedString(@"asha_sharingMessageTwitterTitle", @"Share on Twitter");
    
    if([data objectForKey:@"image"]){
      replyVC.maxMessageLength = kTwitterMessageWithMediaUrlLength;
    } else {
      replyVC.maxMessageLength = kTwitterMessageLength;
    }
  } else {
      //let's try to post to facebook
    if(![FBSession.activeSession hasGranted:@"publish_actions"]){
      NSLog(@"aSha -- WARNING sharing to facebook with no publish_actions permission");
    }
    
    actionToPerform = @selector(shareToFacebookWithData:);
    screenTitle = NSBundleLocalizedString(@"asha_sharingMessageFacebookTitle", @"Share on Facebook");
    replyVC.maxMessageLength = NSIntegerMax;
  }
  
  self.replyVC.data = data;
  
  //let's handle abscence of navigationController, if it is the case.
  BOOL navigationControllerAbscent = self.viewController.navigationController == nil;
  
  UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:self.replyVC] autorelease];
  navController.modalPresentationStyle = UIModalPresentationFormSheet;
  
  navController.navigationBar.barStyle = navigationControllerAbscent ? UIBarStyleBlackOpaque : self.viewController.navigationController.navigationBar.barStyle;
  navController.navigationBar.translucent = navigationControllerAbscent ? NO : self.viewController.navigationController.navigationBar.translucent;
  navController.navigationBar.tintColor = navigationControllerAbscent ? [UIColor blackColor] : self.viewController.navigationController.navigationBar.tintColor;
  
#ifdef __IPHONE_7_0
  if([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
    navController.navigationBar.barTintColor = navigationControllerAbscent ? [UIColor blackColor] : self.viewController.navigationController.navigationBar.barTintColor;
  navController.navigationBar.titleTextAttributes = self.viewController.navigationController.navigationBar.titleTextAttributes;
#endif
  
  UIBarButtonItem *cancelBtn = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                              target:self.viewController
                                                                              action:@selector(dismissModalViewControllerAnimated:)] autorelease];
  UIBarButtonItem *sendBtn = [[[UIBarButtonItem alloc] init] autorelease];
  sendBtn.style  = UIBarButtonItemStyleBordered;
  sendBtn.target = self;
  
  if(navigationControllerAbscent){
    UIColor *cancelTintColor;
    
    if(SYSTEM_VERSION_LESS_THAN(@"7.0")){
      cancelTintColor = [UIColor blackColor];
    } else {
      cancelTintColor = [UIColor whiteColor];
    }
    cancelBtn.tintColor = cancelTintColor;
    sendBtn.tintColor = [UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]; //light blue
  }
  
  sendBtn.action = actionToPerform;
  sendBtn.title  = NSBundleLocalizedString(@"asha_postPostButtonTitle", @"Post");
  
  self.replyVC.navigationItem.title = screenTitle;
  self.replyVC.navigationItem.leftBarButtonItem  = cancelBtn;
  self.replyVC.navigationItem.rightBarButtonItem = sendBtn;
  
  if (!navigationControllerAbscent)
    [self.viewController.navigationController presentViewController:navController animated:YES completion:nil];
  else {
    [self.viewController presentModalViewController:navController animated:YES];
  }
}

-(void)shareToFacebookWithData:(id)sender {
  
  if([sender isKindOfClass:[UIBarButtonItem class]]){
    [sender setEnabled:NO];
  }
  
  NSMutableDictionary *data = nil;
  NSString *userEnteredDescription = [self.replyVC.textView.text copy];
  
  if(self.messageProcessingBlock){
    
    data = self.messageProcessingBlock(userEnteredDescription);
    
  } else {
    data = [self.replyVC.data mutableCopy];
    
    NSString *message = [data objectForKey:@"message"];
    if(message.length){
      [data setObject:[NSString stringWithFormat:@"%@\n%@", userEnteredDescription, message] forKey:@"message"];
    } else{
      [data setObject:userEnteredDescription forKey:@"message"];
    }
  }
  
  [self checkIfSessionIsInTerminalStateAndCloseIfNeeded:FBSession.activeSession];
  
  if (FBSession.activeSession.isOpen) {
    if (FBSession.activeSession.accessTokenData.accessToken) {
        
      [self doActualShareToFacebookWithData:data];
        
    } else {
      NSLog(@"FBSession.activeSession.accessToken IS NULL");
    }
  } else {
    SEL shareCompletionSelector = @selector(doActualShareToFacebookWithData:);
    self.facebookLoginRequiredPrompt = NSBundleLocalizedString(@"asha_loginFBRequiredMessage_share", @"You must be logged in to Facebook to share this item");
    
    [self authFacebookWithCompletion:shareCompletionSelector
                             andData:data
                      andPermissions:kFacebookAllInOnePermissionsArray
                         publishMode:YES
       shouldShowLoginRequiredPrompt:NO];
  };
}

- (void)doActualShareToFacebookWithData:(NSMutableDictionary*)data{
  
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [MBProgressHUD showHUDAddedTo:self.replyVC.textView animated:YES];
  
    static  NSString *graphPathKey = @"graphPath";
  
    NSString *graphPath = [data objectForKey:graphPathKey];
  
    if(!graphPath){
      graphPath = @"/me/feed";
    } else {
      [data removeObjectForKey:graphPathKey];
    }
  
    [FBRequestConnection startWithGraphPath:graphPath
                                 parameters:data
                                 HTTPMethod:@"POST"
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                            
                            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                            [MBProgressHUD hideAllHUDsForView:self.replyVC.view animated:YES];
                            [self.viewController dismissModalViewControllerAnimated:NO];
                            
                              if (!error)
                              {
                                  NSLog(@"\n\nresult: %@\n\n", result);
                                
                                  [self informResult:NSBundleLocalizedString(@"asha_shareFB&TSuccessAlertMessage", @"The message has been posted to your Facebook wall.")
                                           withTitle:@""
                                      andDismissText:NSBundleLocalizedString(@"asha_shareFB&TSuccessAlertTitle", @"OK")];
                              }
                              else
                              {
                                  NSLog(@"\n\n%@\n\n", error.description);
                                
                                  [self informResult:NSBundleLocalizedString(@"asha_FBHasNotBeenPosted", @"The message has not been posted to your Facebook wall.")
                                           withTitle:@""
                                      andDismissText:NSBundleLocalizedString(@"asha_postMessageFailedAlertOkButtonTitle", @"OK")];
                              }
                            
                            if (self.delegate && [self.delegate respondsToSelector:@selector(didShareDataForService:error:)])
                            {
                              [self.delegate didShareDataForService:auth_ShareServiceTypeFacebook error:error];
                            }
                          }];
}

// === LIKE ===
-(void)postLikeForURL:(NSString *)URL
withNotificationNamed:(NSString *)notificationName
{
  [self postLikeForFacebookItem:URL
                         ofType:auth_ShareFBItemTypeURL
          withNotificationNamed:notificationName
  shouldShowLoginRequiredPrompt:YES];
  
}

- (void)postLikeForURL:(NSString *)URL
 withNotificationNamed:(NSString *)notificationName
shouldShowLoginRequiredPrompt:(BOOL)showLoginRequired
{
  [self postLikeForFacebookItem:URL
                         ofType:auth_ShareFBItemTypeURL
          withNotificationNamed:notificationName
  shouldShowLoginRequiredPrompt:showLoginRequired];
}

-(void)postLikeForId:(NSString *)Id
{
  [self postLikeForFacebookItem:Id
                         ofType:auth_ShareFBItemTypeId
          withNotificationNamed:nil
  shouldShowLoginRequiredPrompt:NO];
}

- (void)postLikeForFacebookItem:(NSString *)item
                         ofType:(auth_ShareFBItemType)type
          withNotificationNamed:(NSString *)notificationName
  shouldShowLoginRequiredPrompt:(BOOL)showLoginRequired
{
  likeAttemptsRemaining = 5;
  
  dispatch_async(GCDMainThread, ^{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  });

  //We can not like when under iBuildApp Facebook app session.
  //Let's log out and try again
  if([self isIBAFBSession]){
    [self closeFBSession];
    
    [self postLikeForFacebookItem:item
                           ofType:type
            withNotificationNamed:notificationName
    shouldShowLoginRequiredPrompt:showLoginRequired];
    
    return;
  }
  
  NSMutableDictionary *params = [[@{
                                   @"object" : item,
                                   @"itemType" : @(type)
                                   } mutableCopy] autorelease];
  
  if(notificationName.length)
  {
    [params setObject:notificationName forKey:@"notificationName"];
  }
  
  [self checkIfSessionIsInTerminalStateAndCloseIfNeeded:[FBSession activeSession]];
  
  FBSessionState sessionState = [[FBSession activeSession] state];
  //There is no active session
  if (sessionState != FBSessionStateOpen &&
      sessionState != FBSessionStateOpenTokenExtended) {
    
    if (sessionState == FBSessionStateCreatedTokenLoaded) {
      // even though we had a cached token, we need to login to make the session usable
      [FBSession.activeSession openWithCompletionHandler:^(FBSession *innerSession,
                                                           FBSessionState status,
                                                           NSError *error) {
        if(!error){
          
          [self doActualLikeWithParameters:params];
          
        } else {
          NSLog(@"Facebook login error for cached token in post like method");
          
          dispatch_async(GCDMainThread, ^{
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
          });
        }
      }];
      
      return;
      
    } else {
      
      SEL likeCompletionSelector = @selector(doActualLikeWithParameters:);
      
      self.facebookLoginRequiredPrompt = NSBundleLocalizedString(@"asha_loginFBRequiredMessage_like", @"You must be logged in to Facebook to like this item");
      
      [self authFacebookWithCompletion:likeCompletionSelector
                               andData:params
                        andPermissions:kFacebookAllInOnePermissionsArray
                           publishMode:YES
         shouldShowLoginRequiredPrompt:showLoginRequired];
    }
  } else {
    //Unsufficient permissions in sessions
    if(![FBSession.activeSession hasGranted:@"publish_actions"])
    {
      dispatch_async(GCDMainThread, ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
      });
      
      NSLog(@"Error posting likes, no publish_actions permission");
      
      if(self.delegate)
      {
        NSError *error = [NSError errorWithDomain:@"com.facebook.sdk"
                                             code:5
                                         userInfo:@{@"code":@200, @"message":@"(#200) Requires extended permission: publish_actions"}];
        
        if(type == auth_ShareFBItemTypeURL){
          if([self.delegate respondsToSelector:@selector(didFacebookLikeForURL:error:)]){
            [self.delegate didFacebookLikeForURL:item error:error];
          }
        } else if(type == auth_ShareFBItemTypeId){
          if([self.delegate respondsToSelector:@selector(didFacebookLikeForId:error:)]){
            [self.delegate didFacebookLikeForId:item error:error];
          }
        }
      }
      return;
      
    } else {
      [self doActualLikeWithParameters:params];
    }
  }
}

-(void)doActualLikeWithParameters:(NSMutableDictionary *)params
{
  NSString *item = [params objectForKey:@"object"];
  NSString *notificationName = [params objectForKey:@"notificationName"];
  
  auth_ShareFBItemType itemType = [[params objectForKey:@"itemType"] intValue];
  
  NSString *graphPath = nil;
  NSDictionary *parameters = @{};
  
  switch (itemType) {
      
    case auth_ShareFBItemTypeId:
      graphPath = [NSString stringWithFormat:@"/%@/likes", item];
      break;
      
    case auth_ShareFBItemTypeURL:
    {
      parameters = params;
      graphPath = @"/me/og.likes";
    }
      break;
      
    default:
      break;
  }
  
  [FBRequestConnection startWithGraphPath:graphPath
                               parameters:parameters
                               HTTPMethod:@"POST"
                        completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                          
                          NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:@"like", @"type", item, @"URL", nil];
                          
                          if(error){
                            NSLog(@"ERROR in %@ didFacebookLikeForURL:error: %@", NSStringFromClass([self.delegate class]), [error description]);
                            if([self isLikeOnlyOnSecondAttemptGlitch:error]){
                              if(--likeAttemptsRemaining > 0){
                                NSLog(@"authShare -- looks like we need second attempt to like on facebook");
                                [self doActualLikeWithParameters:params];
                                return;
                              }
                            }

                            [userInfo setObject:error forKey:@"error"];
                          }
                          
                          if(self.delegate){
                            switch (itemType) {
                                
                              case auth_ShareFBItemTypeId:
                              {
                                if([self.delegate respondsToSelector:@selector(didFacebookLikeForId:error:)]){
                                  [self.delegate didFacebookLikeForId:item error:error];
                                }
                              }
                              break;
                                
                              case auth_ShareFBItemTypeURL:
                              {
                                if([self.delegate respondsToSelector:@selector(didFacebookLikeForURL:error:)]){
                                  [self.delegate didFacebookLikeForURL:item error:error];
                                }
                                if(notificationName.length)
                                {
                                  NSNotification *notification = [NSNotification notificationWithName:notificationName
                                                                                               object:nil
                                                                                             userInfo:userInfo];
                                  
                                  [[NSNotificationCenter defaultCenter] postNotification:notification];
                                }
                              }
                              break;
                                
                              default:
                              break;
                            }
                          }
                          
                          [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                        }];
}

- (void)postLikeForPageId:(NSString *)Id
               completion:(auth_ShareFacebookGenericCompletionBlock)completion
{
  
}

-(void)checkIfDeauthorizedWithProceedHandler:(VoidBlock)proceedHandler
                      authorizationHandler:(VoidBlock)authorizationHandler
{
  [FBRequestConnection startWithGraphPath:@"/me/permissions"
                        completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                          
                          if(!error){
                            proceedHandler();
                          } else {
                            authorizationHandler();
                          }
                        }];
}

-(void)loadFacebookLikesCountForURLs:(NSSet *)urls
{
  [self loadFacebookSummaryForItems:urls
                             ofType:auth_ShareFBItemTypeURL
                           fromEdge:kFacebookLikesEdge];
}

- (void)loadFacebookLikesCountForIds:(NSSet *)Ids
{
  [self loadFacebookSummaryForItems:Ids
                             ofType:auth_ShareFBItemTypeId
                           fromEdge:kFacebookLikesEdge];
}


- (void)loadFacebookSummaryForItems:(NSSet *)items ofType:(auth_ShareFBItemType)type fromEdge:(NSString *)edge
{
  if(!items.count){
    NSLog(@"%@ loadFacebookSummaryForItems: empty items set, do nothing", NSStringFromClass([self class]));
    return;
  }
  
  VoidBlock workBlock = ^{
    [self loadActualFacebookSummaryForItems:items
                                     ofType:type
                                   fromEdge:(NSString *)edge];
  };
  
  [self checkSessionAndAccessFacebookWithWorkBlock:workBlock];
}

-(void)loadActualFacebookSummaryForItems:(NSSet *)items
                                  ofType:(auth_ShareFBItemType)type
                                fromEdge:(NSString *)edge
{
  auth_ShareFBBatchProcessingState *processingState = [[auth_ShareFBBatchProcessingState new] autorelease];
  
  NSInteger itemsRemaining = [items count];
  processingState.failedWithError = NO;
  
  if(itemsRemaining){
    
    NSMutableDictionary *resultingLikesDictionary = [NSMutableDictionary dictionary];
    
    //facebook refused to operate with more than 50 ids in single request
    NSMutableArray *itemsSplitInFacebookAcceptableSubsets = [NSMutableArray array];
    
    if(itemsRemaining <= kFacebookBatchLimit){
      [itemsSplitInFacebookAcceptableSubsets addObject:items];
    } else {
      NSArray *itemsObjects = items.allObjects;
      
      NSInteger integerPart = itemsRemaining / kFacebookBatchLimit;
      NSInteger residue = itemsRemaining % kFacebookBatchLimit;
      
      for(NSInteger i = 0; i < integerPart; i++){
        NSUInteger loc = i * kFacebookBatchLimit;
        
        NSSet *acceptableSubset = [[NSSet alloc] initWithArray:[itemsObjects subarrayWithRange:NSMakeRange(loc, kFacebookBatchLimit)]];
        [itemsSplitInFacebookAcceptableSubsets addObject:acceptableSubset];
      }
      
      NSUInteger loc = integerPart * kFacebookBatchLimit;
      
      NSSet *residualSubset = [[NSSet alloc] initWithArray:[itemsObjects subarrayWithRange:NSMakeRange(loc, residue)]];
      [itemsSplitInFacebookAcceptableSubsets addObject:residualSubset];
    }
    
    processingState.requestsRemaining = itemsSplitInFacebookAcceptableSubsets.count;
    
    //if urls...
    for(NSSet *acceptableSubset in itemsSplitInFacebookAcceptableSubsets){
      
      NSMutableString *urlsString = [NSMutableString string];
      NSEnumerator *urlsEnumerator = acceptableSubset.objectEnumerator;
      NSString *url = urlsEnumerator.nextObject;
      
      while(url){
        [urlsString appendString:[url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        url = urlsEnumerator.nextObject;
        
        if(url){
          [urlsString appendString:@","];
        }
      }
      
      if(type == auth_ShareFBItemTypeURL)
      {
        NSString *graphPath = [NSString stringWithFormat:@"/?ids=%@", urlsString];
        
        [FBRequestConnection startWithGraphPath:graphPath
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error)  {
                                if (!error) {
                                  NSLog(@"got ids");
                                  NSMutableDictionary *urlsToIDs = [self getIDsFromResult:result];
                                  
                                  [self doLoadSummaryForIds:urlsToIDs
                                                   fromEdge:edge
                                     batchProcessingState:processingState
                                 targetDictionary:resultingLikesDictionary];
                                  
                                } else {
                                  
                                  dispatch_async(GCDMainThread, ^{
                                    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                                  });
                                  
                                  NSLog(@"error getting ids");
                                  
                                  if([edge isEqualToString:kFacebookLikesEdge]){
                                    if([self.delegate respondsToSelector:@selector(didLoadFacebookLikesCount:error:)]){
                                      [self.delegate didLoadFacebookLikesCount:nil error:error];
                                    }
                                  } else if([edge isEqualToString:kFacebookCommentsEdge]){
                                    if([self.delegate respondsToSelector:@selector(didLoadFacebookCommentsCount:error:)]){
                                      [self.delegate didLoadFacebookCommentsCount:nil error:error];
                                    }
                                  }
                                  
                                  processingState.failedWithError = YES;
                                }
                              }];
      }
      else if(type == auth_ShareFBItemTypeId)
      {
        /*
         * Initially there was not a possibility to load likes for Ids, only for URLs
         * So let's make a fake dict for compatibility with old method
         */
        NSMutableDictionary *idsToIDs = [self makeFakeDictForIds:acceptableSubset];
        
        /*
         * Attention!
         * Ids are not split into 50-sized chunks.
         * If your needs exceed 50 items, modify this code.
         */
        [self doLoadSummaryForIds:idsToIDs
                         fromEdge:edge
             batchProcessingState:processingState
                 targetDictionary:resultingLikesDictionary];
      }
    }
  }
}

-(void)doLoadSummaryForIds:(NSMutableDictionary *)urlsToIDs
                  fromEdge:(NSString *)edge
      batchProcessingState:(auth_ShareFBBatchProcessingState *)processingState
          targetDictionary:(NSMutableDictionary *)targetDictionary
{
    //purpose of auth_ShareFBBatchProcessingState is the follows.
    //we may get several FB responses (by 50 items) for single logical request (say, 100 items)
    //and we do not want to call delegate until all items are successfully collected
    //ie call it every time FB response for chunk of 50 arrives.
  
    //when we set processingState.failedWithError to YES, we tell the system that any incoming
    //responses from FB for this logical request are unrelevant from now and let's skip them
  if([urlsToIDs count] && !processingState.failedWithError){
    
    static NSString *summaryGraphPathTemplate = @"/%@/?ids=%@&summary=1&limit=0";
    NSMutableString *summaryGraphPath = [NSMutableString string];
    
    NSEnumerator *keyEnumerator = [urlsToIDs keyEnumerator];
    NSString *url = [keyEnumerator nextObject];
    
    while(url){
      NSString *idString = [urlsToIDs objectForKey:url];
      
      [summaryGraphPath appendString:idString];
      
      url = [keyEnumerator nextObject];
      
      if(url){
        [summaryGraphPath appendString:@","];
      }
    }
    
    summaryGraphPath = [NSMutableString stringWithFormat:summaryGraphPathTemplate, edge, summaryGraphPath];
    
    [FBRequestConnection startWithGraphPath:summaryGraphPath
                          completionHandler:^(FBRequestConnection *connection, id result, NSError *error)  {
                            
                            if (!error) {
                              
                              NSLog(@"got actual likes (or comments) count");
                              
                              [self assignToURLsFromDictionary:urlsToIDs likesFromResult:result];
                              
                              [targetDictionary addEntriesFromDictionary:urlsToIDs];
                              processingState.requestsRemaining--;
                              
                            } else {
                              
                              processingState.failedWithError = YES;
                              
                              dispatch_async(GCDMainThread, ^{
                                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                              });
                              
                              if([edge isEqualToString:kFacebookLikesEdge]){
                                if([self.delegate respondsToSelector:@selector(didLoadFacebookLikesCount:error:)]){
                                  dispatch_async(GCDMainThread, ^{
                                    [self.delegate didLoadFacebookLikesCount:nil error:error];
                                  });
                                }
                              } else if([edge isEqualToString:kFacebookCommentsEdge]){
                                if([self.delegate respondsToSelector:@selector(didLoadFacebookCommentsCount:error:)]){
                                  [self.delegate didLoadFacebookCommentsCount:nil error:error];
                                }
                              }

                              NSLog(@"error getting likes (or comments) count");
                            }
                            
                            if(processingState.requestsRemaining == 0 && !processingState.failedWithError){
                              
                              if([edge isEqualToString:kFacebookLikesEdge]){
                                if(self.delegate){
                                  if([self.delegate respondsToSelector:@selector(didLoadFacebookLikesCount:error:)]){
                                    dispatch_async(GCDMainThread, ^{
                                      [self.delegate didLoadFacebookLikesCount:targetDictionary error:error];
                                    });
                                  }
                                }
                              } else if([edge isEqualToString:kFacebookCommentsEdge]){
                                if([self.delegate respondsToSelector:@selector(didLoadFacebookCommentsCount:error:)]){
                                  [self.delegate didLoadFacebookCommentsCount:targetDictionary error:error];
                                }
                              }
                              
                              dispatch_async(GCDMainThread, ^{
                                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                              });
                            }
                          }];
    
  } else {
    dispatch_async(GCDMainThread, ^{
      [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    });
  }
}

-(NSMutableDictionary *)getIDsFromResult:(FBGraphObject *)result
{
  NSMutableDictionary *urlsToIDs = [NSMutableDictionary dictionary];
  
  for(NSString *urlKey in result.keyEnumerator) {
    
    FBGraphObject *ogObject = [[result objectForKey:urlKey] objectForKey:@"og_object"];
    
    NSString *ogObjectId =  [ogObject objectForKey:@"id"];
    
    if(ogObjectId){
      [urlsToIDs setObject:ogObjectId forKey:urlKey];
    }
  }
  return urlsToIDs;
}

-(NSMutableDictionary *)makeFakeDictForIds:(NSSet *)Ids
{
  NSMutableDictionary *idsToIDs = [NSMutableDictionary dictionary];
  
  for(NSString *fbId in Ids) {
    [idsToIDs setObject:fbId forKey:fbId];
  }
  return idsToIDs;
}

-(void)assignToURLsFromDictionary:(NSMutableDictionary *)urlsToIDs likesFromResult:(FBGraphObject *)result
{
  NSUInteger countOfIdsWithLikes = 0;
  
  for(NSString *idKey in result.keyEnumerator){
    NSDictionary *summaryDictionary = [result objectForKey:idKey];
    NSString *likesCountString = [[summaryDictionary objectForKey:@"summary"] objectForKey:@"total_count"];
    
    if(likesCountString){
      long likesCountLong = [[[summaryDictionary objectForKey:@"summary"] objectForKey:@"total_count"] longValue];
      NSNumber *likesCountNumber = [NSNumber numberWithLong:likesCountLong];
      
      NSArray *URLs = [urlsToIDs allKeysForObject:idKey];
      
      for(NSString *urlForLike in URLs){
        if(urlForLike){
          [urlsToIDs setObject:likesCountNumber forKey:urlForLike];
          countOfIdsWithLikes++;
        }
      }
    }
  }
  
  //Just for hypothetical case when we get less entries from FB than there were URLs
  if([urlsToIDs count] != countOfIdsWithLikes){
    
    for(NSString* key in urlsToIDs.keyEnumerator){
      
      if([[urlsToIDs valueForKey:key] isKindOfClass:[NSString class]]){
        [urlsToIDs removeObjectForKey:key];
      }
      
    }
  }
}

- (void)loadFacebookLikedPagesWithCompletion:(auth_ShareFacebookGenericCompletionBlock)completion
{
  NSLog(@"aSha Request for liked FB pages");
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  FBSessionStateHandler loadLikedFacebookPagesHandler = ^(FBSession *session, FBSessionState state, NSError *error)
  {
    if(!error && (state == FBSessionStateOpen || state == FBSessionStateOpenTokenExtended)){
      [self doActualLoadFacebookLikedPagesWithCompletion:[completion copy]];
    } else {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
  };
  
  [self executeHandlerOnUserFBSession:loadLikedFacebookPagesHandler];
}

-(void)doActualLoadFacebookLikedPagesWithCompletion:(auth_ShareFacebookGenericCompletionBlock)completion
{
  NSString *feedGraphPath = [NSString stringWithFormat:@"me/likes?limit=%tu", INT_MAX];
  
  FBRequest *feedRequest = [FBRequest requestForGraphPath:feedGraphPath];
  
  [feedRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
  {
    completion(result, error);
    [completion release];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  }];
}

- (void)loadFacebookEngagementForId:(NSString *)facebookId
                         completion:(auth_ShareFacebookGenericCompletionBlock)completion
{
  NSLog(@"aSha Request for engagement for id: %@", facebookId);
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  FBSessionStateHandler loadLikedFacebookEngagementHandler = ^(FBSession *session, FBSessionState state, NSError *error)
  {
    if(!error && (state == FBSessionStateOpen || state == FBSessionStateOpenTokenExtended)){
      [self doActualLoadFacebookEngagementForId:facebookId
                                     completion:[completion copy]];
    } else {
      [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
  };
  
  [self executeHandlerOnUserFBSession:loadLikedFacebookEngagementHandler];
}

-(void)doActualLoadFacebookEngagementForId:(NSString *)facebookId
                                completion:(auth_ShareFacebookGenericCompletionBlock)completion
{
  NSString *engagementGraphPath = [NSString stringWithFormat:@"%@?fields=engagement", facebookId];
  
  FBRequest *engagementRequest = [FBRequest requestForGraphPath:engagementGraphPath];
  
  [engagementRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error)
   {
     NSDictionary *engagement = [result objectForKey:@"engagement"];
     completion(engagement, error);
     [completion release];
     
     [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
   }];
}

-(void)loadFacebookLikedURLs
{
  [self loadLikedFacebookItemsOfType:auth_ShareFBItemTypeURL];
}

-(void)loadFacebookLikedIds
{
  [self loadLikedFacebookItemsOfType:auth_ShareFBItemTypeId];
}

-(void)loadLikedFacebookItemsOfType:(auth_ShareFBItemType)type
{
  NSLog(@"aSha Request for all Liked on facebook");
  
  FBSessionStateHandler loadLikedFacebookItemsHadler = ^(FBSession *session, FBSessionState state, NSError *error)
  {
    if(!error && (state == FBSessionStateOpen || state == FBSessionStateOpenTokenExtended)){
      [self loadActualFacebookLikedItemsOfType:type];
    } else {
      dispatch_async(GCDMainThread, ^{
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
      });
    }
  };
  
  [self executeHandlerOnUserFBSession:loadLikedFacebookItemsHadler];
}

-(void)loadActualFacebookLikedItemsOfType:(auth_ShareFBItemType)type
{
  dispatch_async(GCDMainThread, ^{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  });
  
  NSString *graphPath = [NSString stringWithFormat:@"/me/og.likes?fields=data&limit=%tu", INT_MAX];
  
  [FBRequestConnection startWithGraphPath:graphPath
                        completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                          
                          dispatch_async(GCDMainThread, ^{
                            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                          });
                          
                          NSSet *likedItems = nil;
                          
                          if (!error) {
                            NSLog(@"got actual liked items");
                            
                            likedItems = [self getLikedItemsOfType:type
                                                        fromResult:result];
                            
                            if(type == auth_ShareFBItemTypeURL)
                            {
                              [[NSNotificationCenter defaultCenter] postNotificationName:k_auth_Share_LikedItemsLoadedNotificationName
                                                                                  object:likedItems];
                            }
                            
                          } else {
                            NSLog(@"error getting actual liked items");
                          }
                          
                          if(type == auth_ShareFBItemTypeURL)
                          {
                            if([self.delegate respondsToSelector:@selector(didLoadFacebookLikedURLs:error:)]){
                              dispatch_async(GCDMainThread, ^{
                                [self.delegate didLoadFacebookLikedURLs:[[likedItems mutableCopy] autorelease]
                                                                  error:error];
                              });
                            }
                          }
                          
                          if(type == auth_ShareFBItemTypeId)
                          {
                            if([self.delegate respondsToSelector:@selector(didLoadFacebookLikedIds:error:)]){
                              dispatch_async(GCDMainThread, ^{
                                [self.delegate didLoadFacebookLikedIds:[[likedItems mutableCopy] autorelease]
                                                                 error:error];
                              });
                            }
                          }
                          
                        }];
}
  
-(NSMutableSet *)getLikedItemsOfType:(auth_ShareFBItemType)type
                   fromResult:(FBGraphObject *)result
  {
    NSMutableSet *likedItemsSet = [NSMutableSet set];
    
    NSArray *likedItems = [result objectForKey:@"data"];
    
    NSString *key = nil;
    
    if(type == auth_ShareFBItemTypeId)
    {
      key = @"id";
    } else
    {
      key = @"url";
    }
    
    for(NSDictionary *likedItem in likedItems){
      [likedItemsSet addObject:[[[likedItem objectForKey:@"data"] objectForKey:@"object"] objectForKey:key]];
    }

    return likedItemsSet;
  }
  

-(BOOL)userFacebookTokenExists
{
  return FBSession.activeSession.accessTokenData.accessToken != nil;
}

#pragma mark auth_Share Email-specific inner function

- (void)shareToEmailWithData:(NSMutableDictionary *)data {
  NSString *messageText = @"";
  
  if([[data objectForKey:@"message"] length]) messageText = [data objectForKey:@"message"];
 
  Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
  if (mailClass != nil) {
    if ([MFMailComposeViewController canSendMail]) {

      self.mailController = [[[MFMailComposeViewController alloc] init] autorelease];
      self.mailController.mailComposeDelegate = self;
      self.mailController.navigationBar.barStyle = UIBarStyleBlack;
      
      NSString *userName = nil;
      
      if (self.user && self.user.name)
        userName = self.user.name;
      else
        userName = NSBundleLocalizedString(@"asha_shareEMailMessageSubjectPersonPlaceholder", @"Some");
        
      NSString *subject = [NSString stringWithFormat:NSBundleLocalizedString(@"asha_shareEMailMessageSubject", @"%@ wants to share with you"), userName];
      [self.mailController setSubject:subject];

      [self.mailController setMessageBody:messageText isHTML:YES];
      
      [self.viewController presentViewController:self.mailController animated:YES completion:nil];

    } else {
      NSLog(@"Device not configured to send mail.");
      
      [self informResult:NSBundleLocalizedString(@"asha_cannotSendEmailAlertMessage", @"This device not configured to send mail")
               withTitle:NSBundleLocalizedString(@"asha_cannotSendEmailAlertTitle", @"Mail cannot be sent")
          andDismissText:NSBundleLocalizedString(@"asha_cannotSendEmailAlertOkButtonTitle", @"OK")];

    }
  } else {
    NSLog(@"Device not configured to send mail.");
    [self informResult:NSBundleLocalizedString(@"asha_cannotSendEmailAlertMessage", @"This device not configured to send mail")
             withTitle:NSBundleLocalizedString(@"asha_cannotSendEmailAlertTitle", @"Mail cannot be sent")
        andDismissText:NSBundleLocalizedString(@"asha_cannotSendEmailAlertOkButtonTitle", @"OK")];
  }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)composeResult error:(NSError *)error {
  switch (composeResult) {
    case MFMailComposeResultCancelled:
      NSLog(@"\n\nResult: Mail sending canceled\n\n");
      break;
      
    case MFMailComposeResultSaved:
      NSLog(@"\n\nResult: Mail saved\n\n");
      break;
      
    case MFMailComposeResultSent:
      NSLog(@"\n\nResult: Mail sent\n\n");
      break;
      
    case MFMailComposeResultFailed:
      NSLog(@"\n\nResult: Mail sending failed\n\n");
      
      [self informResult:NSBundleLocalizedString(@"asha_sendingEmailFailedAlertMessage", @"Error sending email")
               withTitle:NSBundleLocalizedString(@"asha_sendingEmailFailedAlertTitle", @"Error sending email")
          andDismissText:NSBundleLocalizedString(@"asha_sendingEmailFailedAlertOkButtonTitle", @"OK")];

      break;
      
    default:
      NSLog(@"Result: Mail not sent");
      break;
  }

  [self.mailController dismissViewControllerAnimated:NO completion:nil];
}

#pragma mark auth_Share SMS-specific inner function

- (void)shareToSMSWithData:(NSMutableDictionary *)data
{
  NSString *messageText = @"";
  
  if([[data objectForKey:@"message"] length]) messageText = [data objectForKey:@"message"];
  
  Class messageController = (NSClassFromString(@"MFMessageComposeViewController"));
  if (messageController != nil){
    if ([MFMessageComposeViewController canSendText]) {
      
      self.messageController = [[MFMessageComposeViewController alloc] init];
      self.messageController.messageComposeDelegate = self;
      self.messageController.navigationBar.barStyle = UIBarStyleBlack;
      
      [self.messageController setBody:messageText];
      
      [self.viewController presentViewController:self.messageController animated:YES completion:nil];
      
    } else {
      NSLog(@"Device not configured to send SMS.");
      
      [self informResult:NSBundleLocalizedString(@"asha_cannotSendSMSAlertMessage", @"This device not configured to send SMS")
               withTitle:NSBundleLocalizedString(@"asha_cannotSendSMSAlertTitle", @"SMS cannot be sent")
          andDismissText:NSBundleLocalizedString(@"asha_cannotSendSMSAlertOkButtonTitle", @"OK")];
    }
  } else {
    NSLog(@"Device not configured to send SMS.");
    
    [self informResult:NSBundleLocalizedString(@"asha_cannotSendSMSAlertMessage", @"This device not configured to send SMS")
             withTitle:NSBundleLocalizedString(@"asha_cannotSendSMSAlertTitle", @"SMS cannot be sent")
        andDismissText:NSBundleLocalizedString(@"asha_cannotSendSMSAlertOkButtonTitle", @"OK")];
  }
}


- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)composeResult {
  switch (composeResult) {
    case MessageComposeResultCancelled:
      NSLog(@"\n\nResult: SMS sending canceled\n\n");
      break;
      
    case MessageComposeResultSent:
      NSLog(@"\n\nResult: SMS sent\n\n");
      
      if (self.delegate && [self.delegate respondsToSelector:@selector(didShareDataForService:error:)])
      {
        [self.delegate didShareDataForService:auth_ShareServiceTypeEmail error:nil];
      }
      
      break;
      
    case MessageComposeResultFailed:
      NSLog(@"\n\nResult: SMS sending failed\n\n");
      
      [self informResult:NSBundleLocalizedString(@"asha_cannotSendSMSAlertMessage", @"This device not configured to send SMS")
               withTitle:NSBundleLocalizedString(@"asha_cannotSendSMSAlertTitle", @"SMS cannot be sent")
          andDismissText:NSBundleLocalizedString(@"asha_cannotSendSMSAlertOkButtonTitle", @"OK")];
      
      break;
      
    default:
      NSLog(@"\n\nResult: SMS not sent\n\n");
      break;
  }
  [self.messageController dismissViewControllerAnimated:NO completion:nil];
  [self.messageController release];
}

-(NSString *)appendAdditionalText:(NSString *)additionalText toTwitterMessage:(NSString *)message constrainToLength:(NSUInteger)maxMessageLength{
  
  NSMutableString *mutableMessage = [[message mutableCopy] autorelease];
  
  if(additionalText && [additionalText isKindOfClass:[NSString class]]){
    
    if(mutableMessage.length < maxMessageLength - 1){// -1 to ensure space for additional \n
      
      if(mutableMessage.length && additionalText.length){
        [mutableMessage appendString:@"\n"];
      }
      
      NSUInteger additionalTextChunkLength = maxMessageLength - mutableMessage.length;
      
      if(additionalText.length > additionalTextChunkLength){
        NSString *additionalTextChunk = [additionalText substringToIndex:additionalTextChunkLength];
        
        if([additionalTextChunk rangeOfString:@"\n"].location == additionalTextChunkLength){
          additionalTextChunk = [additionalTextChunk substringToIndex:additionalTextChunkLength-1];
        }
        
        [mutableMessage appendString:additionalTextChunk];
      } else {
        [mutableMessage appendString:additionalText];
      }
    }
  }
  
  return mutableMessage;
}

- (void)postTweetWithData:(id)sender
{
  [self.replyVC.textView resignFirstResponder];
  
  if([sender isKindOfClass:[UIBarButtonItem class]]){
    [sender setEnabled:NO];
  }
  
  [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  
  [MBProgressHUD showHUDAddedTo:self.replyVC.textView animated:YES];
  dispatch_async(GCDBackgroundThread, ^{
    if(!self.engine){
      self.engine = [FHSTwitterEngine sharedEngine];
    }
    
    [self.engine loadAccessToken];
    [self.engine permanentlySetConsumerKey:[TwitterID getConsumerKey] andSecret:[TwitterID getConsumerSecret]];
    self.engine.delegate = self;
    
    @autoreleasepool {
      NSDictionary *data = self.replyVC.data;
      NSError *returnCode = nil;
      
      NSString *message = [[self.replyVC.textView.text copy] autorelease];
      
      // Text to be displayed in twitter post, but not visible in editor window
      // Contains item name + item description
      NSString *additionalText = [data objectForKey:@"additionalText"];
      
      if(additionalText){
        message = [self appendAdditionalText:additionalText toTwitterMessage:message constrainToLength:replyVC.maxMessageLength];
      }
 
      NSData *imageData = [data objectForKey:@"imageData"];
      
      if(!imageData){
        UIImage *image = [data objectForKey:@"image"];
        if(image){
          imageData = UIImageJPEGRepresentation(image, 0.9f);
        }
      }
      
      if(imageData){
        returnCode = [self.engine postTweet:message withImageData:imageData];
      } else {
        returnCode = [self.engine postTweet:message];
      }
      
      dispatch_sync(GCDMainThread, ^{
        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
        [MBProgressHUD hideHUDForView:self.replyVC.view animated:YES];
        
        @autoreleasepool {
          if (!returnCode) {
            NSLog(@"\n\nresult: %@\n\n", returnCode);
            
            [self.viewController dismissViewControllerAnimated:NO completion:^{
              [self informResult:NSBundleLocalizedString(@"asha_twitterPosted", @"The message has been posted to your Twitter account.")
                       withTitle:@""
                  andDismissText:@"OK"];
              
              if (self.delegate && [self.delegate respondsToSelector:@selector(didShareDataForService:error:)])
              {
                [self.delegate didShareDataForService:auth_ShareServiceTypeTwitter error:nil];
              }
            }];
            
          }
          else
          {
            NSLog(@"\n\n%@\n\n", returnCode.description);
            NSString *failResult = @"";
            
            switch(returnCode.code){
              case FHSTwitterEngineDuplicateStatusCode:
                {
                  NSString *tweet = self.replyVC.textView.text;
                  
                  if(!tweet.length){
                    tweet = @"";
                  }
                  
                  NSString *additionalText = [data objectForKey:@"additionalText"];
                  
                  if(additionalText){
                    tweet = [self appendAdditionalText:additionalText toTwitterMessage:tweet constrainToLength:replyVC.maxMessageLength];
                  }
                  
                  tweet = [tweet stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
                  
                  failResult = [NSString stringWithFormat:NSBundleLocalizedString(@"asha_twitterDuplicateStatusMessage", @"Duplicate message «%@» could not be posted."), tweet];
                }
                break;
              default:
                failResult = NSBundleLocalizedString(@"asha_twitterHasNotBeenPosted", @"The message hasn't been posted to your Twitter account.");
                break;
            }
            
            [self.viewController dismissViewControllerAnimated:NO completion:^{
              [self informResult:failResult
                       withTitle:@""
                  andDismissText:@"OK"];
              
              if (self.delegate && [self.delegate respondsToSelector:@selector(didShareDataForService:error:)])
              {
                [self.delegate didShareDataForService:auth_ShareServiceTypeTwitter error:returnCode];
              }
            }];
          }
        }
      });
    }
  });
}

- (void)informResult:(NSString *)result withTitle:(NSString *)title andDismissText:(NSString *)dismissText
{
  if(SYSTEM_VERSION_LESS_THAN(@"8.0"))
  {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:result
                                                       delegate:nil
                                              cancelButtonTitle:dismissText
                                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];
  }
  else
  {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title
                                                                             message:result
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *okAction = [UIAlertAction
                               actionWithTitle:dismissText
                               style:UIAlertActionStyleDefault
                               handler:nil];
    
    [alertController addAction:okAction];
    [self.viewController presentViewController:alertController animated:NO completion:nil];
  }
  
}

- (void) dispatchToTwitterSharingWithData:(NSMutableDictionary *)data
{
  if([self isAuthenticatedWithTwitter]) {
    shareOnTwitterWithCustomWindow = NO;
    [self shareToTwitterWithData:data];
  }
  else if (self.user.authentificatedWith == auth_ShareServiceTypeTwitter)
  {
    shareOnTwitterWithCustomWindow = YES;
    [self typeMessageWithData:data];
  }
}

- (void)cancelPendingTasksIfAny{
  [self.aShaBackroundOperationQueue cancelAllOperations];
}
/**
 * Methods like authentificatePersonUsingService:andCredentials:withCompletion:...
 * are public, but there is no way to specify a target for selector.
 *
 * This method finds the appropriate target.
 */
-(id)targetForSelector:(SEL)selector
{
  if([self respondsToSelector:selector]){
    return self;
  }
  if([self.viewController respondsToSelector:selector]){
    return self.viewController;
  }
  if([self.delegate respondsToSelector:selector]){
    return self.delegate;
  }
  return nil;
}

-(void)performHandlerOnExistentOrIBAFBDefaultSession:(FBSessionStateHandler)sessionHandler
{
  FBSessionState state = [[FBSession activeSession] state];
  
  if (state != FBSessionStateOpen && state != FBSessionStateOpenTokenExtended) {
    
    if (state == FBSessionStateCreatedTokenLoaded) {
      
      [FBSession.activeSession openWithCompletionHandler:sessionHandler];
      
    } else {
        if(!FB_ISSESSIONSTATETERMINAL(state))
        {
          [self authorizeWithIBAFBAccountWithCompletionHandler:sessionHandler];
          
        } else {
          
          [[FBSession activeSession] closeAndClearTokenInformation];
          [self closeFBSession];
          [self performHandlerOnExistentOrIBAFBDefaultSession:sessionHandler];
          
          return;
        }
    }
    
  } else {
    sessionHandler([FBSession activeSession], state, nil);
  }
}

-(void)authorizeWithIBAFBAccountWithCompletionHandler:(FBSessionStateHandler)completionHadler
{
  FBAccessTokenData *accessTokenData = [FBAccessTokenData createTokenFromString:[self facebookAppToken]
                                                                    permissions:@[@"email"]
                                                                 expirationDate:nil
                                                                      loginType:FBSessionLoginTypeWebView
                                                                    refreshDate:nil];
  [self closeFBSession];
  
  FBSession *activeSession = [FBSession activeSession];
  
  FBSessionStateHandler encapsulatingHandler = ^(FBSession *session, FBSessionState status, NSError *error){
    if(!error){
      if(status == FBSessionStateOpen || status == FBSessionStateOpenTokenExtended){
        [self storeFBSessionType:auth_ShareFBSessionTypeIBA];
      }
    }
    completionHadler(session, status, error);
  };
  
  [activeSession openFromAccessTokenData:accessTokenData
                       completionHandler:encapsulatingHandler];
}

-(BOOL)isIBAFBSession
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  NSInteger type = [[userDefaults objectForKey:kauth_ShareFBSessionType] integerValue];
  
  return type == auth_ShareFBSessionTypeIBA;
}

-(void)storeFBSessionType:(auth_ShareFBSessionType)sessionType
{
  NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
  [userDefaults setObject:[NSNumber numberWithInteger:sessionType] forKey:kauth_ShareFBSessionType];
  [userDefaults synchronize];
}

-(void)closeFBSession
{
  FBSession* session = [FBSession activeSession];
  [session closeAndClearTokenInformation];
  [session close];
  [FBSession setActiveSession:nil];
  [self storeFBSessionType:auth_ShareFBSessionTypeNone];
}

-(BOOL)checkIfSessionIsInTerminalStateAndCloseIfNeeded:(FBSession *)session
{
  if(session){
    FBSessionState state = session.state;
    
    NSLog(@"FB session token state %tu, is open %@, is terminal: %@", state,
          FB_ISSESSIONOPENWITHSTATE(state) ? @"YES" : @"NO",
          FB_ISSESSIONSTATETERMINAL(state) ? @"YES" : @"NO");
    
    if(FB_ISSESSIONSTATETERMINAL(state)){
      [self closeFBSession];
      
      return YES;
    }
  }
  
  return NO;
}

-(BOOL)executeHandlerOnUserFBSession:(FBSessionStateHandler)completionHandler
{
  if(![self isIBAFBSession]){
    
    FBSessionState state = [FBSession activeSession].state;
    
    if(state == FBSessionStateOpen || state == FBSessionStateOpenTokenExtended) {
      
      completionHandler([FBSession activeSession], state, nil);
      
      return YES;
      
    } else if(state == FBSessionStateCreatedTokenLoaded){
      
      FBSessionStateHandler encapsulatingHandler = ^(FBSession *session, FBSessionState status, NSError *error){
        if(!error){
          if(status == FBSessionStateOpen || status == FBSessionStateOpenTokenExtended){
            [self storeFBSessionType:auth_ShareFBSessionTypeUser];
            completionHandler(session, status, error);
          }
        }
      };
      
      [FBSession.activeSession openWithCompletionHandler:encapsulatingHandler];
      return YES;
    }
  }
  
  return NO;
}

-(void)saveUser:(auth_ShareUser *)user
{
  [UD setInteger:user.authentificatedWith forKey:@"mAuthentificatedWith"];
  [UD setObject :user.type                forKey:@"mAccountType"];
  [UD setObject :user.ID                  forKey:@"mAccountID"];
  [UD setObject :user.name                forKey:@"mUserName"];
  [UD setObject :user.avatar              forKey:@"mAvatar"];
  [UD synchronize];
}

-(BOOL)isLikeOnlyOnSecondAttemptGlitch:(NSError *)error
{
  NSNumber *errorSubcode = @0;
  
  id parsedResponceKey = error.userInfo[@"com.facebook.sdk:ParsedJSONResponseKey"];
  
  if([parsedResponceKey isKindOfClass:[NSDictionary class]]){
    id body = parsedResponceKey[@"body"];
    
    if([body isKindOfClass:[NSDictionary class]]){
      //errorSubcode = body[@"error_subcode"];
      id errorDict = body[@"error"];
      
      if([errorDict isKindOfClass:[NSDictionary class]]){
        errorSubcode = errorDict[@"error_subcode"];
      }
    }
  }
  
  return [errorSubcode integerValue] == 1660002;
}

-(void)checkSessionAndAccessFacebookWithWorkBlock:(VoidBlock)workBlock
{
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  FBSessionStateHandler handler = ^(FBSession *session, FBSessionState status, NSError* error)
  {
    if(!error)
    {
      if(session && (status == FBSessionStateOpen || status == FBSessionStateOpenTokenExtended))
      {
        workBlock();
      }
    } else {
      NSLog(@"Facebook login error for cached token");
      
      [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }
  };
  
  [self performHandlerOnExistentOrIBAFBDefaultSession:handler];
}

- (void)loadFacebookFeedForId:(NSString *)facebookId
              customGraphPath:(NSString *)customGraphPath
                   completion:(auth_ShareFacebookFeedLoadingCompletionBlock)completion
{
  if(!facebookId.length){
    NSLog(@"%@ loadFacebookFeedForId: empty facebookId, do nothing", NSStringFromClass([self class]));
    return;
  }
  
  VoidBlock workBlock = ^{
     [self doActualLoadFacebookFeedForId:facebookId
                         customGraphPath:customGraphPath
                              completion:[completion copy]];
  };
  
  [self checkSessionAndAccessFacebookWithWorkBlock:workBlock];
}

-(void)doActualLoadFacebookFeedForId:(NSString *)facebookId
                     customGraphPath:(NSString *)customGraphPath
                          completion:(auth_ShareFacebookFeedLoadingCompletionBlock)completion;
{
  NSString *feedGraphPath = nil;
  
  if(customGraphPath.length)
  {
    feedGraphPath = [self prepareGraphPath:customGraphPath];
  } else {
    feedGraphPath = [NSString stringWithFormat:
                     @"/%@/posts?fields=id,from,message,object_id,"\
                     "attachments,type,link,actions,created_time,"\
                     "comments.limit(1).summary(true),"\
                     "likes.limit(1).summary(true)"\
                     "&limit=25", facebookId];
  }
  
  FBRequest *feedRequest = [FBRequest requestForGraphPath:feedGraphPath];
  
  [feedRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
    
    NSArray *feedItems = nil;
    NSDictionary *paging = nil;
    
    if(!error)
    {
      feedItems = [result objectForKey:@"data"];
      paging = [result objectForKey:@"paging"];
    }
    
    completion(feedItems, paging, error);
    [completion release];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  }];
}

-(NSString *)prepareGraphPath:(NSString *)originalPagePath
{
  NSRange accessTokenRange = [originalPagePath rangeOfString:@"&access_token=[^&]+" options:NSRegularExpressionSearch];
  if (accessTokenRange.location != NSNotFound)
    originalPagePath = [originalPagePath stringByReplacingCharactersInRange:accessTokenRange withString:@""];
    
  if([originalPagePath hasPrefix:FacebookGraphAPILatestEndpoint])
    originalPagePath = [originalPagePath stringByReplacingOccurrencesOfString:FacebookGraphAPILatestEndpoint withString:@""];
  
  return originalPagePath;
}

- (void)postFacebookComment:(NSString *)message parentObjectId:(NSString *)objectId completion:(auth_ShareFacebookGenericCompletionBlock)completion
{
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  NSDictionary *params = @{ @"message": message };
  
  FBRequest *request = [[[FBRequest alloc] initWithSession:[FBSession activeSession] graphPath:[NSString stringWithFormat:@"/%@/comments", objectId] parameters:params HTTPMethod:@"POST"] autorelease];
  
  [request startWithCompletionHandler:^(FBRequestConnection *connection,
                                        id result,
                                        NSError *error) {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    completion(nil, error);
  }];
}

- (void)loadFacebookInfoForId:(NSString *)facebookId
                   completion:(auth_ShareFacebookGenericCompletionBlock)completion
{
  if(!facebookId.length){
    NSLog(@"%@ facebookInfoForId: empty facebookId, do nothing", NSStringFromClass([self class]));
    return;
  }
  
  VoidBlock workBlock = ^{
    [self doActualLoadFacebookInfoForId:facebookId completion:[completion copy]];
  };
  
  [self checkSessionAndAccessFacebookWithWorkBlock:workBlock];
}

- (void)doActualLoadFacebookInfoForId:(NSString *)facebookId
                           completion:(auth_ShareFacebookGenericCompletionBlock)completion
{
  NSString *infoGraphPath = [NSString stringWithFormat:@"/%@?fields=id,name,cover,category,link,likes,videos.fields(id).limit(1).summary(true)", facebookId];
  
  NSString *local = [[NSLocale preferredLanguages] objectAtIndex:0];
  
  if ([local rangeOfString:@"ru"].location != NSNotFound) {
    infoGraphPath = [infoGraphPath stringByAppendingString:@"&locale=ru_RU"];
  }
  
  FBRequest *infoRequest = [FBRequest requestForGraphPath:infoGraphPath];
  
  [infoRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
    
    completion(result, error);
    [completion release];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  }];
}

+ (NSURL *)facebookPictureURLForId:(NSString *)facebookId
{
  return [[self class] facebookPictureURLForId:facebookId
                                     timestamp:0.0f];
}

+ (NSURL *)facebookPictureURLForId:(NSString *)facebookId
                         timestamp:(NSTimeInterval)timestamp
{
  NSMutableString *avatarURLString = [NSMutableString stringWithFormat:@"%@/%@/picture?type=normal",
                                      FacebookGraphAPILatestEndpoint, facebookId];
  
  if(timestamp)
  {
    [avatarURLString appendFormat:@"&ibatimestamp=%ld", (long)timestamp];
  }
  
  return [NSURL URLWithString:avatarURLString];
}


- (void)loadFacebookCommentsCountForIds:(NSSet *)Ids
{
  [self loadFacebookSummaryForItems:Ids
                             ofType:auth_ShareFBItemTypeId
                           fromEdge:kFacebookCommentsEdge];
}

-(void)loadFacebookImageURLForId:(NSString *)facebookId
                      completion:(auth_ShareFacebookURLForIdCompletionBlock)completion
{
  NSURL *cachedURLForId = [self.urlsFromIdsCache objectForKey:facebookId];
  
  if(cachedURLForId)
  {
    completion(cachedURLForId, nil);
    return;
  }
  
  auth_ShareFacebookGenericCompletionBlock infoCompletionBlock = ^(NSDictionary *data, NSError *error) {
    
    NSURL *resolvedURL = nil;
    
    if(!error){
      NSString *imageURLString = [data objectForKey:@"source"];
      
      resolvedURL = [NSURL URLWithString:imageURLString];
      
      if(resolvedURL)
      {
        [self.urlsFromIdsCache setObject:resolvedURL forKey:facebookId];
      }
    }
    
    completion(resolvedURL, error);
  };
  
  [self loadFacebookInfoForId:facebookId
                   completion:infoCompletionBlock];
}

-(void)postFacebookRequestWithGraphPath:(NSString *)path completion:(auth_ShareFacebookGenericCompletionBlock)completion
{
  VoidBlock workBlock = ^{
    [self doActualPostFacebookRequestWithGraphPath:path completion:[completion copy]];
  };
  
  [self checkSessionAndAccessFacebookWithWorkBlock:workBlock];
}

-(void)doActualPostFacebookRequestWithGraphPath:(NSString *)path completion:(auth_ShareFacebookGenericCompletionBlock)completion
{
  FBRequest *infoRequest = [FBRequest requestForGraphPath:[self prepareGraphPath:path]];
  
  [infoRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
    
    completion(result, error);
    [completion release];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  }];
  
}

-(void)loadFacebookVideosForId:(NSString *)facebookId
               customGraphPath:(NSString *)customGraphPath
                         since:(long long)since
                         until:(long long)until
                         limit:(NSUInteger)limit
                    completion:(auth_ShareFacebookGenericCompletionBlock)completion
{
  if(!facebookId.length){
    NSLog(@"%@: loadFacebookVideosForId:completion: empty facebookId, do nothing", NSStringFromClass([self class]));
    return;
  }
  
  VoidBlock workBlock = ^{
    [self doActualLoadFacebookVideosForId:facebookId
                          customGraphPath:customGraphPath
                                    since:since
                                    until:until
                                    limit:limit
                               completion:[completion copy]];
  };
  
  [self checkSessionAndAccessFacebookWithWorkBlock:workBlock];
}

-(void)doActualLoadFacebookVideosForId:(NSString *)facebookId
                       customGraphPath:customGraphPath
                                 since:(long long)since
                                 until:(long long)until
                                 limit:(NSUInteger)limit
                            completion:(auth_ShareFacebookGenericCompletionBlock)completion
{
  NSString *graphPath = nil;
  
  if(customGraphPath)
  {
    graphPath = [self prepareGraphPath:customGraphPath];
  } else {
    graphPath = [NSString stringWithFormat:@"/%@/videos?fields=id,picture,source,description,embed_html,length,"\
                 "comments.limit(1).summary(true),likes.limit(1).summary(true)&limit=%lu", facebookId, (unsigned long)limit];
    
    if(since > 0)
    {
      graphPath = [graphPath stringByAppendingString:[NSString stringWithFormat:@"&since=%lld", since]];
    }
    
    if(until > 0)
    {
      graphPath = [graphPath stringByAppendingString:[NSString stringWithFormat:@"&until=%lld", until]];
    }
  }
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  FBRequest *feedRequest = [FBRequest requestForGraphPath:graphPath];
  
  [feedRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
    
    completion(result, error);
    [completion release];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  }];
}


-(void)loadFacebookVideosForIds:(NSSet *)facebookIds
                     completion:(auth_ShareFacebookGenericCompletionBlock)completion
{
  if(!facebookIds.count){
    NSLog(@"%@: loadFacebookVideosForIds:completion: empty facebookId, do nothing", NSStringFromClass([self class]));
    return;
  }
  
  VoidBlock workBlock = ^{
    [self doActualLoadFacebookVideosForIds:facebookIds
                               completion:[completion copy]];
  };
  
  [self checkSessionAndAccessFacebookWithWorkBlock:workBlock];
}

-(void)doActualLoadFacebookVideosForIds:(NSSet *)facebookIds
                             completion:(auth_ShareFacebookGenericCompletionBlock)completion
{
  NSArray *facebookIdsArray =[facebookIds allObjects];
  
  NSMutableString *graphPath = [NSMutableString stringWithFormat:@"?ids=%@",[facebookIdsArray firstObject]];
  
  for(NSUInteger idIndex = 1; idIndex < facebookIdsArray.count; idIndex++)
  {
    NSString *videoId = [facebookIdsArray objectAtIndex:idIndex];
    
    [graphPath appendFormat:@",%@", videoId];
  }
  
  [graphPath appendString:@"&fields=id,picture,source,description,embed_html,length,"\
   "comments.limit(1).summary(true),likes.limit(1).summary(true)"];
  
  FBRequest *feedRequest = [FBRequest requestForGraphPath:graphPath];
  
  [feedRequest startWithCompletionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
    
    completion(result, error);
    [completion release];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  }];
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

-(void)loadFacebookPhotosCountForId:(NSString *)facebookId
                         completion:(auth_ShareFacebookPhotosCountCompletionBlock)completion
{
  self.facebookPhotosCount = 0;
  self.facebookPhotosCountNextPath = 0;
  
  [self doActualLoadFacebookPhotosCountForId:facebookId completion:completion];
}

-(void)doActualLoadFacebookPhotosCountForId:(NSString *)facebookId
                                 completion:(auth_ShareFacebookPhotosCountCompletionBlock)completion
{
  NSString *graphPath;
  
  if (self.facebookPhotosCountNextPath)
    graphPath = self.facebookPhotosCountNextPath;
  else
    graphPath = [NSString stringWithFormat:@"%@/albums?fields=count", facebookId];
  
  [self postFacebookRequestWithGraphPath:graphPath
                                   completion:^(NSDictionary *data, NSError *error) {
                                     if (!error)
                                     {
                                       self.facebookPhotosCountNextPath = [[data objectForKey:@"paging"] objectForKey:@"next"];
                                       
                                       NSArray *albums = [data objectForKey:@"data"];
                                       
                                       for (NSDictionary *album in albums)
                                         self.facebookPhotosCount += [[album objectForKey:@"count"] integerValue];
                                       
                                       if (!self.facebookPhotosCountNextPath && completion)
                                         completion(self.facebookPhotosCount);
                                       else
                                         [self doActualLoadFacebookPhotosCountForId:facebookId completion:completion];
                                     }
                                     else
                                     {
                                       if (completion)
                                         completion(self.facebookPhotosCount);
                                     }
                                   }];

}

-(UIControl *)nativeFacebookLikeControlForId:(NSString *)target
{
  FBLikeControl *likeControl = [[[FBLikeControl alloc] init] autorelease];
  likeControl.objectID = target;
  likeControl.objectType = FBLikeControlObjectTypePage;
  
  return likeControl;
}

#pragma mark - Improved, reseller-aware FB token retreival mechanism
-(NSString *)facebookAppId
{
  NSString *fbAppId = [[NSUserDefaults standardUserDefaults] objectForKey:@"FacebookAppID"];
  
  return fbAppId;
}

-(NSString *)facebookAppSecret
{
  NSString *fbAppSecret = [[NSUserDefaults standardUserDefaults] objectForKey:@"FacebookAppSecret"];
  
  return fbAppSecret;
}

-(NSString *)facebookAppToken
{
  NSString *fbAppID = [self facebookAppId];
  NSString *fbAppSecret = [self facebookAppSecret];
  
  NSString *fbAppToken = [NSString stringWithFormat:@"%@|%@", fbAppID, fbAppSecret];
  
  return fbAppToken;
}

@end