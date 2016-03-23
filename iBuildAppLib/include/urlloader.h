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

@protocol IURLLoaderDelegate;

@interface TURLLoader : NSObject
{
  @private
  
    /** 
     * URL connection object.
     */
    NSURLConnection   *m_urlConnection;
  
    /** 
     * Downloaded data.
     */
    NSMutableData     *m_receivedData;
  
    /** 
     * Elapsed time since download start.
     */
    NSTimeInterval     m_elapsedTime;
  
    /** 
     * URL request.
     */
    NSURLRequest      *m_urlRequest;
  
    /** 
     * Connection start time.
     */
    NSDate            *m_connectionTime;
  
    /** 
     * Expected content length in response.
     */
    long long          m_nContentLength;
    NSMutableArray    *m_delegatesList;
    BOOL               m_bLoading;
    BOOL               m_bLocalhostLoading;
    BOOL               m_bCachedURLResponse;
}

@property (nonatomic, readonly ) BOOL               cachedURLResponse;
@property (nonatomic, readonly ) NSURLConnection   *urlConnection;
@property (nonatomic, readonly ) NSURLRequest      *urlRequest;
@property (nonatomic, readonly ) NSDate            *connectionTime;
@property (nonatomic, readonly ) NSMutableArray    *delegatesList;
@property (nonatomic, readonly ) NSMutableData     *receivedData;
@property (nonatomic, readonly, getter = isLoading) BOOL bLoading;
@property (nonatomic, readonly, getter = isLocalhostLoading ) BOOL bLocalhostLoading;
@property (nonatomic, readonly ) NSTimeInterval  elapsedTime;
@property (nonatomic, readonly ) long long       contentLength;
@property (nonatomic, assign   ) NSUInteger        uid;

- (void)cancel;
-(BOOL)start;

- (id)initWithURL:(NSString *)urlStr_
      cachePolicy:(NSURLRequestCachePolicy)cachePolicy_
  timeoutInterval:(NSTimeInterval)timeoutInterval_;

-(BOOL)loadWithURL:(NSString *)urlStr_
       cachePolicy:(NSURLRequestCachePolicy)cachePolicy_
   timeoutInterval:(NSTimeInterval)timeoutInterval_;

-(BOOL)wasLoaded;
-(BOOL)addDelegate:(id <IURLLoaderDelegate>)delegate;
-(BOOL)setDelegate:(id <IURLLoaderDelegate>)delegate;
-(BOOL)removeDelegate:(id <IURLLoaderDelegate>)delegate;

@end

@protocol IURLLoaderDelegate<NSObject>
@optional

- (void)setLoader:(TURLLoader *)urlLoader_;

- (void)onBeginRequest:(NSURLRequest *)urlRequest
         withURLloader:(TURLLoader *)urlLoader;

- (void)onBeginDownload:(NSURLResponse *)urlResponse
          withURLloader:(TURLLoader *)urlLoader;

- (void)onProcessDownload:(double_t)loadProgress
            withURLloader:(TURLLoader *)urlLoader;

- (void)didFinishLoading:(NSData *)data
           withURLloader:(TURLLoader *)urlLoader;

- (void)loaderConnection:(NSURLConnection *)connection
        didFailWithError:(NSError *)error
            andURLloader:(TURLLoader *)urlLoader;
@end
