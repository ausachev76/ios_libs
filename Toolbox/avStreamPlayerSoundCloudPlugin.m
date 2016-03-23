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

#import "avStreamPlayerSoundCloudPlugin.h"
#import <UIKit/UIKit.h>
#import "appbuilderappconfig.h"
#import "SBJson.h"

NSString *const avSCBaseURI = @"https://api.soundcloud.com";

NSString *const avSCOAuth2AuthorizeURI = @"/connect";
NSString *const avSCOAuth2TokenURI     = @"/oauth2/token";

NSString *const avSCResolveURI = @"/resolve";
NSString *const avSCTracksURI  = @"/tracks";



@interface avStreamPlayerSoundCloudToken : NSObject
  @property (nonatomic, strong) NSString        *token;
  @property (nonatomic, assign) NSTimeInterval   tokenTTL;
  @property (nonatomic, readonly) NSDate        *tokenDate;
  +(avStreamPlayerSoundCloudToken *)sharedInstance;
  -(BOOL)isExpire;
@end

static avStreamPlayerSoundCloudToken *avSharedInstance_ = nil;

@implementation avStreamPlayerSoundCloudToken
@synthesize tokenDate = _tokenDate,
                token = _token,
             tokenTTL = _tokenTTL;


static void avStreamPlayer_singleton_remover()
{
  [avSharedInstance_ release];
}

+(avStreamPlayerSoundCloudToken *)sharedInstance
{
  @synchronized(self)
  {
    if ( avSharedInstance_ == nil )
    {
      avSharedInstance_ = [NSAllocateObject([self class], 0, NULL) init];
    }
  }
  return avSharedInstance_;
}

- (id)init
{
  self = [super init];
  if ( self )
  {
    _token     = nil;
    _tokenTTL  = 0.f;
    _tokenDate = nil;
  }
  atexit(avStreamPlayer_singleton_remover);
  return self;
}

-(void)dealloc
{
  self.token     = nil;
  [_tokenDate release];
  [super dealloc];
}

-(void)setTokenTTL:(NSTimeInterval)tokenTTL_
{
  if ( _tokenTTL != tokenTTL_ )
  {
    _tokenTTL = tokenTTL_;
    // ------------------------------------
    [_tokenDate release];
    _tokenDate = [[NSDate date] retain];
  }
}

-(BOOL)isExpire
{
  return !self.tokenTTL ||
         ( self.tokenTTL && ( [[NSDate date] timeIntervalSinceDate:self.tokenDate] > self.tokenTTL ) );
}

@end



@interface avStreamPlayerSoundCloudPlugin()
  @property (nonatomic, strong) NSMutableData   *receivedData;
  @property (nonatomic, strong) NSURLConnection *urlConnection;
  @property (nonatomic, strong) NSURL           *sourceURL;
  @property (nonatomic, assign) avStreamPlayerPluginCompletionHandler  completionBlock;
@end

@implementation avStreamPlayerSoundCloudPlugin
@synthesize receivedData = _receivedData,
           urlConnection = _urlConnection,
               sourceURL = _sourceURL,
         completionBlock = _completionBlock;

-(id)init
{
  self = [super init];
  if ( self )
  {
    _receivedData  = nil;
    _urlConnection = nil;
    _sourceURL     = nil;
    _completionBlock = nil;
  }
  return self;
}

-(void)dealloc
{
  [self.urlConnection cancel];
  self.urlConnection = nil;
  self.receivedData  = nil;
  self.sourceURL     = nil;
  [self.completionBlock release];
  [super dealloc];
}

- (void)requestToken
{
  NSString *requestURL = [avSCBaseURI stringByAppendingString:avSCOAuth2TokenURI];
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL]
                                                         cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                     timeoutInterval:60.0f];
  
  NSString *requestBody = @"grant_type=password";
  requestBody = [requestBody stringByAppendingFormat:@"&client_id=%@"    , SCOAuth2ClientID()];
  requestBody = [requestBody stringByAppendingFormat:@"&client_secret=%@", SCOAuth2ClientSecret()];
  requestBody = [requestBody stringByAppendingFormat:@"&username=%@"     , SCUserName()];
  requestBody = [requestBody stringByAppendingFormat:@"&password=%@"     , SCUserPassword()];
  
  [request setHTTPMethod:@"POST"];
  [request setValue:@"application/x-www-form-urlencoded"
 forHTTPHeaderField:@"Content-Type"];
  [request setValue:@"OAuth"
 forHTTPHeaderField:@"Authorization"];
  [request setValue:@"iBuildApp/iPhone"
 forHTTPHeaderField:@"User-Agent"];
  [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)[requestBody length]]
 forHTTPHeaderField:@"Content-Length"];
  
  [request setHTTPBody:[requestBody dataUsingEncoding:NSUTF8StringEncoding]];
  
  self.urlConnection = [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
  if ( self.urlConnection )
  {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  } else {
    if ( self.completionBlock )
      self.completionBlock( nil, [NSError errorWithDomain:@"coudn't create URL connection" code:1 userInfo:nil] );
    [self.completionBlock release];
    self.completionBlock = nil;
    self.urlConnection = nil;
  }
}

-(void)requestStreamWithURL:(NSURL *)url_
{
  NSString *szURL = [url_ absoluteString];
  if([szURL rangeOfString:@"="].location != NSNotFound)
    szURL = [[szURL componentsSeparatedByString:@"="] objectAtIndex:1];
  
  NSURL *requestURL = [szURL rangeOfString:@"api.soundcloud"].location == NSNotFound ?
  [NSURL URLWithString:[NSString stringWithFormat:@"%@%@.json?url=%@&client_id=%@", avSCBaseURI,
                                                                                          avSCResolveURI,
                                                                                          szURL,
                                                                                          SCOAuth2ClientID()]] :
  [NSURL URLWithString:szURL];
  
  
  NSString *szToken = [avStreamPlayerSoundCloudToken sharedInstance].token;
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:requestURL
                                                         cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                     timeoutInterval:60.0f];
  
  [request setHTTPMethod:@"GET"];
  [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
  [request setValue:[@"OAuth " stringByAppendingString:(szToken == nil ? @"" : szToken)] forHTTPHeaderField:@"Authorization"];
  [request setValue:@"iBuildApp/iPhone" forHTTPHeaderField:@"User-Agent"];

  self.urlConnection = [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
  if ( self.urlConnection )
  {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
  } else {
    if ( self.completionBlock )
      self.completionBlock( nil, [NSError errorWithDomain:@"coudn't create URL connection" code:1 userInfo:nil] );
    [self.completionBlock release];
    self.completionBlock = nil;
    self.urlConnection = nil;
  }
}

-(void)resolveStreamURL:(NSURL *)url_
  withCompletionHandler:(avStreamPlayerPluginCompletionHandler)completionHandler
{
  NSURL *streamURL = [[[NSURL alloc] initWithScheme:@"https"
                                               host:[url_ host]
                                               path:[url_ path]] autorelease];
  
  [self.completionBlock release];
  self.completionBlock = [completionHandler copy];
  
  avStreamPlayerSoundCloudToken *tkn = [avStreamPlayerSoundCloudToken sharedInstance];
  if ( [tkn isExpire] )
  {
    
    tkn.token    = nil;
    tkn.tokenTTL = 0.f;
    self.sourceURL = streamURL;
    [self requestToken];
  }else{
    [self requestStreamWithURL:streamURL];
  }
}

#pragma mark NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  if ( [avStreamPlayerSoundCloudToken sharedInstance].token )
  {
    if ( self.completionBlock )
      self.completionBlock( response.URL, nil );
    [self.completionBlock release];
    self.completionBlock = nil;
  }else{
    self.receivedData = [NSMutableData data];
  }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  if ( ![avStreamPlayerSoundCloudToken sharedInstance].token )
    [self.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  if ( ![avStreamPlayerSoundCloudToken sharedInstance].token )
  {
    NSString *jsonString = [[NSString alloc] initWithData:self.receivedData encoding:NSUTF8StringEncoding];
    
    SBJsonParser *jsonParser = [SBJsonParser new];
    NSDictionary *serverResp = [jsonParser objectWithString:jsonString];
    
    avStreamPlayerSoundCloudToken *token = [avStreamPlayerSoundCloudToken sharedInstance];
    if ([serverResp objectForKey:@"access_token"])
    {
      token.token    = [serverResp objectForKey:@"access_token"];
      token.tokenTTL = [[serverResp objectForKey:@"expires_in"] doubleValue];
      
      NSLog(@"get token: %@", token.token );
    }
    [jsonString release];
    [jsonParser release];

    self.receivedData = nil;
    [self.urlConnection cancel];
    self.urlConnection = nil;
    
    if ( [token.token length] )
    {
      [self requestStreamWithURL:self.sourceURL];
    }else{
      if ( self.completionBlock )
        self.completionBlock( nil, [NSError errorWithDomain:@"coudn't get token" code:1 userInfo:nil] );
      [self.completionBlock release];
      self.completionBlock = nil;
    }
  }else{
    self.receivedData = nil;
    [self.urlConnection cancel];
    self.urlConnection = nil;
    //------- destroy completion handler ---------
    [self.completionBlock release];
    self.completionBlock = nil;
  }
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  if ( self.completionBlock )
    self.completionBlock( nil, error );
  [self.completionBlock release];
  self.completionBlock = nil;
  
  self.receivedData = nil;
  [self.urlConnection cancel];
  self.urlConnection = nil;
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}


@end
