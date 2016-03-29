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

#import "appbuilderappconfig.h"
#import "userconfig.h"

//--------------- FACEBOOK APP ID ------------------------
#define kIBuildAppFacebookAppID        @"207296122640913" // iBuildApp (default) facebook app ID
#define kIBuildAppFacebookAppSecret    @"8GKTRW57eH_2t5hVgtioNPWvecE" // iBuildApp (default) facebook app secret

#define kIBuildAppFacebookAppToken    kIBuildAppFacebookAppID @"|" kIBuildAppFacebookAppSecret// iBuildApp (default) facebook app token

#define kUserDefinedFacebookAppID  @"__FACEBOOK_USER_APP_ID__"   // user facebook app ID
#define kUserDefinedFacebookAppSecret  @"__FACEBOOK_USER_APP_SECRET__"   // user facebook app secret

#define kUserDefinedFacebookAppToken  kUserDefinedFacebookAppID @"|" kUserDefinedFacebookAppSecret // user facebook app token

//--------------- TWITTER APP ID -------------------------
#define kIBuildAppOAuthConsumerKey	   @"p48aBftV8vXXfG6UWo0BcQ"		      // keys for ibuildapp (default) app
#define kIBuildAppOAuthConsumerSecret  @"YYkHCKtSD7uYhSC3jtPL1H2b6NaX2u6x5kOLLgRUA"

#define kUserDefinedOAuthConsumerKey	    @"p48aBftV8vXXfG6UWo0BcQ"       // keys for the mobile (custom) app
#define kUserDefinedOAuthConsumerSecret   @"YYkHCKtSD7uYhSC3jtPL1H2b6NaX2u6x5kOLLgRUA"

//--------------- TWITTER DEFAULT USER --------------------
#define kTwitterDefaultUserAccessToken           @"1032182184-s15a4zo13gySjJPCrRHfQaBIemxCis9uWPQYJJ0"
#define kTwitterDefaultUserAccessTokenSecret     @"cEXSataNiK3PwMWhDMSIcuFnuQ9t6M6EUcfELhA29ZUnG"
#define kTwitterDefaultUserOwnerName             @"vasopupyakin"
#define kTwitterDefaultUserOwnerID               @"1032182184"

#define kTwitterDefaultUserOAuthConsumerKey      @"szTSJaoSHMviPwfdb1PDCg"
#define kTwitterDefaultUserOAuthConsumerSecret   @"nv4PGlEDLKVgxzGoPJ7uumWzYW2eMYuxo9XtLWNbM"


// --------------- SOUND CLOUD DEFAULT USER ---------------
#define kSCUserName           @"support@ibuildapp.com"
#define kSCUserPassword       @"SCIbuiDPP43@"

#define kSCOAuth2ClientID     @"a8a2acc83c83ed22496520cad824d2ba"
#define kSCOAuth2ClientSecret @"2ed5aa730942f010c5afd49f90242b74"


// iBuildApp FlurryAnalytics ID
#define kFlurryAnalyticsAppID    @"247K9ZXRQ2Z46XNWFCP8"

// --------------- GOOGLE ANALYTICS DEFAULT ID ------------
#define kGoogleAnalyticsDefaultTrackingID        @"UA-20239101-6"
#define kGoogleAnalyticsDefaultTrackerNamePrefix @"iBuildApp."
//---------------------------------------------------------


//Key to save/restore deviceID
#define kDeviceUID               @"DeviceID"

#define kAppToken                @"TTooKKeeNN"

#define kAppPlatformType         @"iphone"

// You may use platform type @"tablet" instead to get the config of the same app for iPad
//#define kAppPlatformType       @"tablet"

// Host name to fetch the config from
#define kiBuildAppHostName  @"uuRRLL"
#define kProjectID          @"RReePPLLaaCCee"

#define kBaseXMLconfigURL  @"http://" kiBuildAppHostName @"/xml/"

#define kXMLconfigURL     kBaseXMLconfigURL kAppPlatformType

#define kCachePath @"configCache"
#define kCacheXML  @"xml.cache"
#define kCacheData @"data.cache"

NSString *appFlurryAnalyticsAppID()
{
  return kFlurryAnalyticsAppID;
}

NSString *appIBuildAppHostName()
{
  return kiBuildAppHostName;
}

NSString *appProjectID()
{
  return kProjectID;
}

NSString *appToken()
{
  return kAppToken;
}

NSString *appGetUID()
{
  NSUserDefaults *udefaults = [NSUserDefaults standardUserDefaults];
  NSString *szUID = [udefaults objectForKey: kDeviceUID];
  if(!szUID || szUID.length == 0)
  {
    CFUUIDRef uidRef = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef uidStr = CFUUIDCreateString(kCFAllocatorDefault, uidRef);
    [udefaults setObject:(NSString *)uidStr
                  forKey:kDeviceUID];
    
    CFRelease(uidRef);
    CFRelease(uidStr);
    return [udefaults objectForKey:kDeviceUID];
  }else{
    return szUID;
  }
}

NSString* timestampForAppXMLConfig()
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *appId = [defaults objectForKey:appProjectIDKey];
  
  if (!appId)
    appId = @"";
  
  if (![appId isEqualToString:appProjectID()])
  {
    [defaults setObject:appProjectID() forKey:appProjectIDKey];
    return @"0";
  }
  
  NSString *timestampForAppXMLConfigString = [defaults objectForKey:appXMLConfigTimestampKey];
  if(timestampForAppXMLConfigString == nil)
  {
    timestampForAppXMLConfigString = @"0";
  }
  return timestampForAppXMLConfigString;
}

NSString *appXMLconfigURL()
{
  if (kUseCustomConfigXMLurl && kUserConfigXMLurl && [kUserConfigXMLurl length])
  {
    return kUserConfigXMLurl;
  }

  NSURL *url = [NSURL URLWithString:kXMLconfigURL];
  
  if ( [[url.scheme lowercaseString] isEqualToString:@"file"] &&
       [[url.host lowercaseString] isEqualToString:@"bundle"] )
  {
    return kXMLconfigURL;
  }
  else
  {
    NSMutableString *URLString = [NSMutableString stringWithString:kXMLconfigURL];
    
    [URLString appendFormat:@"/%@", appGetUID()]; // UID
    [URLString appendFormat:@":%@", appToken()]; // token
    [URLString appendFormat:@":%@", appProjectID()]; // app id
    [URLString appendFormat:@":%@", timestampForAppXMLConfig()]; // timestamp

    return URLString;
  }
}

NSString *cachePath()
{
  NSError *error = nil;
  NSArray *paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES);
  NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent: kCachePath];
  
  // --- create cache folder if not exist
  if ( ![[NSFileManager defaultManager] fileExistsAtPath: path] ){
    [[NSFileManager defaultManager] createDirectoryAtPath: path
                              withIntermediateDirectories: NO
                                               attributes: nil
                                                    error: &error];
  }
  return path;
}

NSString *cachePathXML()
{
  return [cachePath() stringByAppendingPathComponent: kCacheXML];
}

NSString *cachePathData()
{
  return [cachePath() stringByAppendingPathComponent: kCacheData];
}


//--------------- FACEBOOK APP ID -------------------------
NSString *appIBuildAppFacebookAppID()        { return kIBuildAppFacebookAppID; }
NSString *appIBuildAppFacebookAppSecret()    { return kIBuildAppFacebookAppSecret; }
NSString *appIBuildAppFacebookAppToken()     { return kIBuildAppFacebookAppToken; }

NSString *appUserDefinedFacebookAppID()      { return kUserDefinedFacebookAppID; }
NSString *appUserDefinedFacebookAppSecret()  { return kUserDefinedFacebookAppSecret; }
NSString *appUserDefinedFacebookAppToken()   { return kUserDefinedFacebookAppToken; }

//--------------- TWITTER APP ID --------------------------
NSString *appTwitterOAuthConsumerKeyUser()    { return kUserDefinedOAuthConsumerKey;   }
NSString *appTwitterOAuthConsumerSecretUser() { return kUserDefinedOAuthConsumerSecret;}

NSString *appTwitterOAuthConsumerKeyIB()      { return kIBuildAppOAuthConsumerKey;     }
NSString *appTwitterOAuthConsumerSecretIB()   { return kIBuildAppOAuthConsumerSecret;  }

//--------------- TWITTER DEFAULT USER --------------------
NSString *twitterDefaultUserAccessToken()         { return kTwitterDefaultUserAccessToken;  }
NSString *twitterDefaultUserAccessTokenSecret()   { return kTwitterDefaultUserAccessTokenSecret;  }
NSString *twitterDefaultUserOwnerName()           { return kTwitterDefaultUserOwnerName;  }
NSString *twitterDefaultUserOwnerID()             { return kTwitterDefaultUserOwnerID;  }

NSString *twitterDefaultUserOAuthConsumerKey()	  { return kTwitterDefaultUserOAuthConsumerKey;  }
NSString *twitterDefaultUserOAuthConsumerSecret() { return kTwitterDefaultUserOAuthConsumerSecret;  }

// --------------- SOUND CLOUD DEFAULT USER ---------------
NSString *SCUserName()           { return kSCUserName; }
NSString *SCUserPassword()       { return kSCUserPassword; }

NSString *SCOAuth2ClientID()     { return kSCOAuth2ClientID; }
NSString *SCOAuth2ClientSecret() { return kSCOAuth2ClientSecret; }

// --------------- GOOGLE ANALYTICS DEFAULT ID ------------
NSString *googleAnalyticsDefaultTrackingID()        { return kGoogleAnalyticsDefaultTrackingID; }
NSString *googleAnalyticsDefaultTrackerNamePrefix() { return kGoogleAnalyticsDefaultTrackerNamePrefix; }