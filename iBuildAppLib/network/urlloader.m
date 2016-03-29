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

#import "urlloader.h"
#import <UIKit/UIKit.h>


@implementation TURLLoader

@synthesize connectionTime = m_connectionTime;
@synthesize receivedData   = m_receivedData;
@synthesize elapsedTime    = m_elapsedTime;
@synthesize contentLength  = m_nContentLength;
@synthesize urlRequest     = m_urlRequest;
@synthesize delegatesList  = m_delegatesList;
@synthesize urlConnection  = m_urlConnection;
@synthesize bLoading       = m_bLoading;
@synthesize bLocalhostLoading = m_bLocalhostLoading;
@synthesize cachedURLResponse = m_bCachedURLResponse;
@synthesize uid;

-(id)init
{
  self = [super init];
  if ( self )
  {
    self.uid             = -1;
    m_bCachedURLResponse = NO;
    m_urlConnection      = nil;
    m_receivedData       = nil;
    m_elapsedTime        = 0;
    m_urlRequest         = nil;
    m_connectionTime     = nil;
    m_nContentLength     = 0;
    m_delegatesList      = [[NSMutableArray alloc] init];
    m_bLoading           = NO;
    m_bLocalhostLoading  = NO; 
  }
  return self;
}

-(void)destroySession
{
  [self cancel];
  m_bLoading          = NO;
  m_bLocalhostLoading = NO;
  m_nContentLength    = 0;
  m_elapsedTime       = 0;
  if ( m_urlConnection )
  {
    [m_urlConnection cancel];
    [m_urlConnection release];
    m_urlConnection = nil;
  }
  if ( m_urlRequest )
  {
    [m_urlRequest release];
    m_urlRequest = nil;
  }
  if (m_receivedData)
  {
    [m_receivedData release];
    m_receivedData = nil;
  }
  if ( m_connectionTime )
  {
    [m_connectionTime release];
    m_connectionTime = nil;
  }
  if ( m_delegatesList )
  {
    [m_delegatesList release];
    m_delegatesList = nil;
  }
}

-(void)unsubscripeDelegates
{
  if ( m_delegatesList )
  {
    for( id<IURLLoaderDelegate> it in m_delegatesList )
    {
      if ( [it conformsToProtocol:@protocol(IURLLoaderDelegate)] &&
          [it respondsToSelector:@selector(setLoader:)] )
        [it setLoader:nil];
    }
    [m_delegatesList release];
    m_delegatesList = nil;
  }
}

- (void)dealloc
{
  [self destroySession];

  [super dealloc];
}

- (void)cancel
{
  if ( m_urlConnection )
  {
    m_bLoading = NO;
    [m_urlConnection cancel];
    [m_urlConnection release];
    m_urlConnection = nil;
  }
}

-(BOOL)addDelegate:(id <IURLLoaderDelegate>)delegate
{
  if ( !delegate )
    return NO;
  @synchronized(self)
  {
    if ( [m_delegatesList containsObject:delegate] )
      return NO;

    if ( [delegate conformsToProtocol:@protocol(IURLLoaderDelegate)] &&
         [delegate respondsToSelector:@selector(setLoader:)] )
      [delegate setLoader:self];
    [m_delegatesList addObject:delegate];
    return YES;
  }
}

-(BOOL)setDelegate:(id <IURLLoaderDelegate>)delegate
{
  @synchronized(self)
  {
    if ( [m_delegatesList containsObject:delegate] )
      return NO;
    
    if ( [delegate conformsToProtocol:@protocol(IURLLoaderDelegate)] &&
        [delegate respondsToSelector:@selector(setLoader:)] )
      [delegate setLoader:self];
    
    if ( [m_delegatesList count] )
      [m_delegatesList replaceObjectAtIndex:[m_delegatesList count] - 1
                                 withObject:delegate];
    else
      [m_delegatesList addObject:delegate];
    return YES;
  }
}

-(BOOL)removeDelegate:(id <IURLLoaderDelegate>)delegate
{
  @synchronized(self)
  {
    [m_delegatesList removeObject:delegate];

    if ( [delegate conformsToProtocol:@protocol(IURLLoaderDelegate)] &&
         [delegate respondsToSelector:@selector(setLoader:)] )
      [delegate setLoader:nil];
    
    return YES;
  }
}

- (id)initWithURL:(NSString *)urlStr_
      cachePolicy:(NSURLRequestCachePolicy)cachePolicy_
  timeoutInterval:(NSTimeInterval)timeoutInterval_
{
  self = [super init];
  if ( self )
  {
    urlStr_ = [urlStr_ stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    urlStr_ = [urlStr_ stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

    NSURL *downloadURL = [[NSURL alloc] initWithString:urlStr_];
    m_bLocalhostLoading = [[downloadURL scheme] isEqualToString:@"file"] ? YES : NO;
    if ( m_bLocalhostLoading )
    {
      [downloadURL release];
      downloadURL = [[NSURL alloc] initWithString:urlStr_];
    }
    
    m_urlRequest = [[NSURLRequest alloc] initWithURL:downloadURL
                                         cachePolicy:m_bLocalhostLoading ? NSURLRequestReloadIgnoringCacheData : cachePolicy_
                                     timeoutInterval:timeoutInterval_];
    
    m_bCachedURLResponse = m_bLocalhostLoading ||
                           ( [[NSURLCache sharedURLCache] cachedResponseForRequest:m_urlRequest] != nil );
    
   [downloadURL release];

    m_bLoading         = NO;
    m_urlConnection    = nil;
    m_receivedData     = nil;
    m_connectionTime   = nil;
    m_nContentLength   = 0;
    m_delegatesList    = [[NSMutableArray alloc] init];
//    NSLog(@"create URL loader: %p", self );
  }
  return self;
}


-(BOOL)loadWithURL:(NSString *)urlStr_
       cachePolicy:(NSURLRequestCachePolicy)cachePolicy_
   timeoutInterval:(NSTimeInterval)timeoutInterval_
{
  if ( m_bLoading )
    return NO;

  [self destroySession];
  
  NSURL *downloadURL = [[NSURL alloc] initWithString:[urlStr_ stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
  m_bLocalhostLoading = [[downloadURL scheme] isEqualToString:@"file"] ? YES : NO;
  if ( m_bLocalhostLoading )
  {
    [downloadURL release];
    downloadURL = [[NSURL alloc] initWithString:urlStr_];
  }
  
  m_urlRequest = [[NSURLRequest alloc] initWithURL:downloadURL
                                       cachePolicy:cachePolicy_
                                   timeoutInterval:timeoutInterval_];
  [downloadURL release];
  return YES;
}




-(void)beginRequestWithData:(NSData *)pData_
{
  // record the start time of the connection
  if ( m_connectionTime )
  {
    [m_connectionTime release];
    m_connectionTime = nil;
  }
  m_connectionTime = [[NSDate alloc] init];
  // create an object to hold the received data
  if ( m_receivedData )
  {
    [m_receivedData release];
    m_receivedData = nil;
  }
  
  m_receivedData = [[NSMutableData alloc] initWithData:pData_];
  m_elapsedTime = [[NSDate date] timeIntervalSinceDate:m_connectionTime];
  
  @synchronized(self)
  {
    for( id<IURLLoaderDelegate> delegate in m_delegatesList )
    {
      if ( [delegate conformsToProtocol:@protocol(IURLLoaderDelegate)] && 
           [delegate respondsToSelector:@selector(onBeginRequest:withURLloader:)] )
        [delegate onBeginRequest:m_urlRequest
                   withURLloader:self];
    }
  }
}

-(BOOL)start
{
  if ( !m_urlRequest )
    return NO;
  
  if ( m_urlConnection )
  {
    [m_urlConnection release];
    m_urlConnection = nil;
  }
  
  m_urlConnection = [[NSURLConnection alloc] initWithRequest:m_urlRequest
                                                    delegate:self
                                            startImmediately:YES];
  if ( m_urlConnection )
  {
    m_bLoading = YES;
    [self beginRequestWithData:[NSMutableData data]];
    return YES;
  }
  m_bLoading = NO;
  return NO;
}

-(BOOL)wasLoaded
{
  return ( m_connectionTime != nil && !m_bLoading );
}



- (void) connection:(NSURLConnection *)connection
 didReceiveResponse:(NSURLResponse *)response
{
  if ( !m_bCachedURLResponse )
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  /* Called when the server has determined that it has enough  
   information to create the NSURLResponse. It can be called 
   multiple times (for example in the case of a redirect), so 
   each time we reset the data. */
  [m_receivedData setLength:0];
  m_nContentLength = [response expectedContentLength];
  
  @synchronized(self)
  {
    for( id<IURLLoaderDelegate> delegate in m_delegatesList )
    {
      if ( [delegate conformsToProtocol:@protocol(IURLLoaderDelegate)] &&
          [delegate respondsToSelector:@selector(onBeginDownload:withURLloader:)] )
        [delegate onBeginDownload:response
                    withURLloader:self];
    }
  }
}

- (void)connection:(NSURLConnection *)connection
    didReceiveData:(NSData *)data
{
  [m_receivedData appendData:data]; // accumulate data
  m_elapsedTime = [[NSDate date] timeIntervalSinceDate:m_connectionTime];

  @synchronized(self)
  {
    for( id<IURLLoaderDelegate> delegate in m_delegatesList )
    {
      if ( [delegate conformsToProtocol:@protocol(IURLLoaderDelegate)] &&
           [delegate respondsToSelector:@selector(onProcessDownload:withURLloader:)] )
        [delegate onProcessDownload:(double)[m_receivedData length] / (double)m_nContentLength
                      withURLloader:self];
    }
  }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  m_elapsedTime = [[NSDate date] timeIntervalSinceDate:m_connectionTime];
  m_bLoading    = NO;
  
  if ( !m_bCachedURLResponse )
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
  
  @synchronized(self)
  {
    // now we must call delegate to reload data
    unsigned i;
    NSUInteger count = [m_delegatesList count];
    for( i = 0; i < count; ++i )
    {
      NSInteger previousCount = [m_delegatesList count];
      id<IURLLoaderDelegate> delegate = [m_delegatesList objectAtIndex:i];
      if ( [delegate conformsToProtocol:@protocol(IURLLoaderDelegate)] )
      {
        if ( [delegate respondsToSelector:@selector(didFinishLoading:withURLloader:)] )
          [delegate didFinishLoading:m_receivedData
                       withURLloader:self];
        
        if ( [delegate respondsToSelector:@selector(setLoader:)] )
          [delegate setLoader:nil];
      }
      [m_delegatesList removeObject:delegate];
      count = [m_delegatesList count];
      if ( previousCount != count )
        --i;
    }

    [m_delegatesList release];
    m_delegatesList = nil;
  }
  if ( m_urlConnection )
  {
    [m_urlConnection release];
    m_urlConnection = nil;
  }
  if ( m_receivedData )
  {
    [m_receivedData release];
    m_receivedData = nil;
  }
}

- (void)connection:(NSURLConnection *)connection
  didFailWithError:(NSError *)error
{
  m_elapsedTime = [[NSDate date] timeIntervalSinceDate:m_connectionTime];
  m_bLoading    = NO;
  
  if ( !m_bCachedURLResponse )
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

  @synchronized(self)
  {
    
    unsigned i;
    NSUInteger count = [m_delegatesList count];
    for(i = 0; i < count; ++i )
    {
      NSInteger previousCount = [m_delegatesList count];
      id<IURLLoaderDelegate> delegate = [m_delegatesList objectAtIndex:i];
      if ( [delegate conformsToProtocol:@protocol(IURLLoaderDelegate)] )
      {
        if ( [delegate respondsToSelector:@selector(loaderConnection:didFailWithError:andURLloader:)] )
          [delegate loaderConnection:connection
                    didFailWithError:error
                        andURLloader:self];

        if ( [delegate respondsToSelector:@selector(setLoader:)] )
          [delegate setLoader:nil];
      }
      [m_delegatesList removeObject:delegate];
      count = [m_delegatesList count];
      if ( previousCount != count )
        --i;
    }

    [m_delegatesList release];
    m_delegatesList = nil;
  }
  if ( m_urlConnection )
  {
    [m_urlConnection release];
    m_urlConnection = nil;
  }
  if ( m_receivedData )
  {
    [m_receivedData release];
    m_receivedData = nil;
  }
}

@end
