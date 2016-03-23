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

#import "IBURLLoader.h"
#import <UIKit/UIKit.h>

@interface IBURLLoader()
  @property (nonatomic, strong) NSMutableData         *receivedData;
  @property (nonatomic, strong) NSURLConnection       *connection;
  @property (nonatomic, copy  ) URLLoaderSuccessBlock  successBlock;
  @property (nonatomic, copy  ) URLLoaderFailureBlock  failureBlock;
@end


@implementation IBURLLoader
@synthesize   connection = _connection,
            receivedData = _receivedData,
            successBlock = _successBlock,
            failureBlock = _failureBlock;

-(void)initialize
{
  _connection   = nil;
  _receivedData = nil;
  _successBlock = nil;
  _failureBlock = nil;
}

-(id)init
{
  self = [super init];
  if ( self )
  {
    [self initialize];
  }
  return self;
}

-(id)initWithRequest:(NSURLRequest *)request_
             success:(URLLoaderSuccessBlock)success_
             failure:(URLLoaderFailureBlock)failure_
{
  self = [super init];
  if ( self )
  {
    [self initialize];
    if ( !request_ )
      return self;
    
    NSURLConnection *con = [[[NSURLConnection alloc] initWithRequest:request_ delegate:self] autorelease];
    if ( con )
    {
      [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
      self.successBlock = success_;
      self.failureBlock = failure_;
      self.connection = con;
    } else {
      // Inform the user that the connection failed.
      if ( failure_ )
        failure_( [NSError errorWithDomain:@"couldn't create NSURLConnection object." code:1 userInfo:nil] );
    }
  }
  return self;
}

-(void)dealloc
{
  [self cancel];
  [super dealloc];
}

#pragma mark NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  self.receivedData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [self.receivedData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  
  // make copy of block, because inside block this object could be destroyed !
  URLLoaderSuccessBlock theSuccessBlock = [self.successBlock copy];
  NSMutableData *theReceivedData = [self.receivedData retain];
  
  self.successBlock = nil;
  self.failureBlock = nil;
  self.receivedData = nil;
  self.connection   = nil;
  
  if ( theSuccessBlock )
    theSuccessBlock ( theReceivedData );
  
  [theReceivedData release];
  [theSuccessBlock release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
  [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
  
  // make copy of block, because inside block this object could be destroyed !
  URLLoaderFailureBlock theFailureBlock = [self.failureBlock copy];
  
  self.successBlock = nil;
  self.failureBlock = nil;
  self.receivedData = nil;
  self.connection   = nil;
  
  if ( theFailureBlock )
    theFailureBlock(error);
  [theFailureBlock release];
}

-(void)cancel
{
  [self.connection cancel];

  NSError *error = [NSError errorWithDomain:@"connection canceled by user" code:NSURLErrorCancelled userInfo:nil];
  [self connection:self.connection didFailWithError:error];
}

@end
