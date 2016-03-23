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

#import "downloadmanager.h"
#import <objc/objc-sync.h>


#define MAX_HTTP_REQUEST 4

@implementation NSURL (IsEqualTesting)
- (BOOL) isEqualToURL:(NSURL*)otherURL;
{
	return ( ([[self absoluteURL] isEqual:[otherURL absoluteURL]]) || 
                  ( [self isFileURL] &&
                    [otherURL isFileURL] &&
                    [[self path] isEqual:[otherURL path]] ) );
}
@end


@implementation TDownloadManager

@synthesize targetList              = m_targetList;
@synthesize timeout                 = m_timeout;
@synthesize cachePolicy             = m_cachePolicy;
@synthesize bRunning                = m_bRunning;
@synthesize bRunAll                 = m_bRunAll;
@synthesize currentLoader           = m_currentLoader;
@synthesize downloadCompleteUrlList = m_downloadCompleteUrlList;
@synthesize downloadFailureUrlList  = m_downloadFailureUrlList;
@synthesize currentDownloadList     = m_currentDownloadList;

static TDownloadManager *instance_;

static void singleton_remover()
{
  [instance_ release];
}


+ (TDownloadManager *)instance
{
  @synchronized(self)
  {
    if( instance_ == nil )
    {
      instance_ = [[self alloc] init];
    }
  }
  return instance_;
}

-(id)init
{
  self = [super init];
  if (self)
  {
    instance_ = self;

    m_downloadCompleteUrlList    = [[NSMutableArray alloc] init];
    m_downloadFailureUrlList     = [[NSMutableArray alloc] init];
    m_currentDownloadList        = [[NSMutableArray alloc] init];
    m_targetList                 = [[NSMutableArray alloc] init];
    m_bRunning                   = NO;
    m_timeout                    = 60.f;    // default response timeout
    m_cachePolicy                = NSURLRequestReturnCacheDataElseLoad;
    
    atexit(singleton_remover);
  }
  return self;
}

-(void)dealloc
{
  if ( m_downloadCompleteUrlList )
  {
    [m_downloadCompleteUrlList release];
    m_downloadCompleteUrlList = nil;
  }
  if ( m_downloadFailureUrlList )
  {
    [m_downloadFailureUrlList release];
    m_downloadFailureUrlList = nil;
  }
  if ( m_currentDownloadList )
  {
    [m_currentDownloadList release];
    m_currentDownloadList = nil;
  }
  if ( m_targetList )
  {
    [m_targetList release];
    m_targetList = nil;
  }
  [super dealloc];
}

-(TURLLoader *)appendTarget:(TURLLoader *)loader_
{
  @synchronized(self)
  {
    NSURL *url = loader_.urlRequest.URL;
    for ( TURLLoader *target in m_targetList )
    {
      if ( [target.urlRequest.URL isEqualToURL:url] )
      {
        return target;
      }
    }
    for( TURLLoader *target in m_currentDownloadList )
    {
      if ( [target.urlRequest.URL isEqualToURL:url] )
      {
        return target;
      }
    }
    if ( m_currentDownloadList.count < (MAX_HTTP_REQUEST - 1) )
    {
      [m_currentDownloadList insertObject:loader_ atIndex:0];
      // append self as delegate to handle download events
      [loader_ addDelegate:self];
      [loader_ start];
    }else{
      [m_targetList insertObject:loader_ atIndex:0];
    }
    return loader_;
  }
}

-(TURLLoader *)appendTargetWithHiPriority:(TURLLoader *)loader_
{
  @synchronized(self)
  {
    NSURL *url = loader_.urlRequest.URL;
    for ( TURLLoader *target in m_targetList )
    {
      if ( [target.urlRequest.URL isEqualToURL:url] )
      {
        return target;
      }
    }
    for( TURLLoader *target in m_currentDownloadList )
    {
      if ( [target.urlRequest.URL isEqualToURL:url] )
      {
        return target;
      }
    }
    if ( m_currentDownloadList.count < MAX_HTTP_REQUEST )
    {
      [m_currentDownloadList insertObject:loader_ atIndex:0];
      // append self as delegate to handle download events
      [loader_ addDelegate:self];
      [loader_ start];
    }else{
      [m_targetList addObject:loader_];
    }
    return loader_;
  }
}



-(void)removeTarget:(TURLLoader *)loader_
{
  @synchronized(self)
  {
    [m_targetList removeObject:loader_];
  }
}

// start all tasks in queue order
-(BOOL)run
{
  if ( ![self isRunning] )
  {
    // pop last object from queue
    TURLLoader *pLoader = [self.targetList lastObject];
    // and start download
    if ( m_currentLoader != pLoader )
    {
      [m_currentLoader release];
      m_currentLoader = [pLoader retain];
    }
    if ( pLoader )
    {
      [m_targetList removeLastObject];
      // append self as delegate to handle download events
      [m_currentLoader addDelegate:self];
      [m_currentLoader start];
      m_bRunning = YES;
      return YES;
    }
  }
  return NO;
}

// start all tasks all together
-(BOOL)runAll
{
  if ( ![self isRunning] )
  {
    m_bRunning = [m_targetList count] != 0;

    TURLLoader *loader = nil;
    unsigned i = MAX_HTTP_REQUEST;
    while( i && ( ( loader = [m_targetList lastObject] ) != nil ) )
    {
      [m_currentDownloadList insertObject:loader
                                  atIndex:0];
      
      [m_targetList removeLastObject];

      [loader addDelegate:self];
      [loader start];
      --i;
    }
    return m_bRunning;
  }
  return NO;
}

-(BOOL)stop
{
  if ( [self isRunning] && ![self isRunAll] )
  {
    m_bRunning = NO;
    return YES;
  }
  return NO;
}


-(BOOL)loadNextTarget
{
  if ( [self isRunAll] )
    return NO;

  TURLLoader *pLoader = [self.targetList lastObject];
  // and start download
  if ( m_currentLoader != pLoader )
  {
    [m_currentLoader release];
    m_currentLoader = [pLoader retain];
  }
  if ( pLoader )
  {
    [m_targetList removeLastObject];
    [m_currentDownloadList insertObject:pLoader atIndex:0];
    // append self as delegate to handle download events
    [pLoader addDelegate:self];
    BOOL bRes = [pLoader start];
    NSLog(@"start new request: %@, res = %d", [pLoader.urlRequest URL], bRes );
    return YES;
  }
  m_bRunning = NO;
  return NO;
}

-(void)clearDownloadList:(TDownloadListType)listType;
{
  if ( listType & DM_COMPLETE_DOWNLOAD_LIST )
    [m_downloadCompleteUrlList removeAllObjects];
  if ( listType & DM_FAILURE_DOWNLOAD_LIST )
    [m_downloadFailureUrlList removeAllObjects];
}


- (void)didFinishLoading:(NSData *)data
           withURLloader:(TURLLoader *)urlLoader
{
  [urlLoader removeDelegate:self];

  [m_downloadCompleteUrlList addObject:urlLoader.urlRequest.URL];
  
  [m_currentDownloadList removeObject:urlLoader];
  
  [self loadNextTarget];
}

- (void)loaderConnection:(NSURLConnection *)connection
        didFailWithError:(NSError *)error
            andURLloader:(TURLLoader *)urlLoader
{
  [urlLoader removeDelegate:self];
  
  [m_downloadFailureUrlList addObject:urlLoader.urlRequest.URL];
  
  [m_currentDownloadList removeObject:urlLoader];
  
  [self loadNextTarget];
}

@end
