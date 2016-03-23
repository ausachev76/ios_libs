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

#ifndef apphostapp_appbuilderappconfig_h
#define apphostapp_appbuilderappconfig_h

//#import <Foundation/Foundation.h>

#define kUserDefinedPatternFacebookAppID         @"__FACEBOOK_USER_APP_ID__"
#define kUserDefinedPatternFacebookAppSecret     @"__FACEBOOK_USER_APP_SECRET__"

#define kUserDefinedPatternOAuthConsumerKey	     @"__TWITTER_USER_CONSUMER_KEY__"
#define kUserDefinedPatternOAuthConsumerSecret   @"__TWITTER_USER_CONSUMER_SECRET__"

#define appXMLConfigTimestampKey                 @"CurrentAppXMLConfigTimestamp"
#define appProjectIDKey                          @"CurrentProjectID"

NSString *appGetUID();

NSString *appFlurryAnalyticsAppID();

NSString *appIBuildAppHostName();

NSString *appProjectID();

NSString *appToken();

NSString *appXMLconfigURL();
NSString *cachePath();
NSString *cachePathXML();
NSString *cachePathData();

// --------------- FACEBOOK APP ID -------------------
// Mainly used in auth_Share and IBLogin
NSString *appIBuildAppFacebookAppID();
NSString *appIBuildAppFacebookAppSecret();
NSString *appIBuildAppFacebookAppToken();

NSString *appUserDefinedFacebookAppID();
NSString *appUserDefinedFacebookAppSecret();
NSString *appUserDefinedFacebookAppToken();

// --------------- TWITTER APP ID --------------------
// App credentails to be able to authorize an app on twitter
NSString *appTwitterOAuthConsumerKeyUser();
NSString *appTwitterOAuthConsumerSecretUser();

NSString *appTwitterOAuthConsumerKeyIB();
NSString *appTwitterOAuthConsumerSecretIB();

// --------------- TWITTER DEFAULT USER --------------
// User credentials to access a feed.
// For usage example, please see plugins/mTwitterer/mTwitterSingleton.m
NSString *twitterDefaultUserAccessToken();
NSString *twitterDefaultUserAccessTokenSecret();
NSString *twitterDefaultUserOwnerName();
NSString *twitterDefaultUserOwnerID();

NSString *twitterDefaultUserOAuthConsumerKey();
NSString *twitterDefaultUserOAuthConsumerSecret();

// --------------- SOUND CLOUD DEFAULT USER -----------
// User credentials to access tracks on Sound Cloud.
// For usage example, please examine plugins/mAudioPlayer/Util/mAPConnection.m
NSString *SCUserName();
NSString *SCUserPassword();

NSString *SCOAuth2ClientID();
NSString *SCOAuth2ClientSecret();

// --------------- GOOGLE ANALYTICS DEFAULT ID --------
// For usage example, please inspect core/appcore/googleAnalytics/googleanalytics.m
NSString *googleAnalyticsDefaultTrackingID();
NSString *googleAnalyticsDefaultTrackerNamePrefix();
#endif
