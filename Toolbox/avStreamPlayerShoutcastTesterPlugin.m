#import "avStreamPlayerShoutcastTesterPlugin.h"
#import <UIKit/UIKit.h>

@interface avStreamPlayerShoutcastTesterPlugin()
  @property (nonatomic, strong) NSMutableData   *receivedData;
  @property (nonatomic, strong) NSURLConnection *urlConnection;
  @property (nonatomic, strong) NSURL           *sourceURL;
  @property (nonatomic, assign) avStreamPlayerPluginCompletionHandler  completionBlock;
@end

@implementation avStreamPlayerShoutcastTesterPlugin
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

-(void)requestStreamWithURL:(NSURL *)url_
{
  NSString *szURL = [url_ absoluteString];
  
  self.sourceURL = [NSURL URLWithString:szURL];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.sourceURL
                                                         cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                                                     timeoutInterval:60.0f];

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
  [self.completionBlock release];
  self.completionBlock = [completionHandler copy];
  
  [self requestStreamWithURL:url_];
}

#pragma mark NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
  self.receivedData = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
  [self.receivedData appendData:data];
  [self analyzeReceivedData];
}

-(void)analyzeReceivedData
{
  if(self.receivedData.length >= 1024) {
    NSString *testString = [[[NSString alloc] initWithData:self.receivedData encoding:NSASCIIStringEncoding] autorelease];
    
    NSRange pos=[testString rangeOfString:@"ICY 401 Service Unavailable"];
    
    if (pos.location != NSNotFound) {
      if ( self.completionBlock )
        self.completionBlock( [NSURL URLWithString:@"http://ibuildapp.com"], [NSError errorWithDomain:@"ICY 401 Service Unavailable" code:-1 userInfo:[NSDictionary dictionary]] );
    } else {
      if ( self.completionBlock )
        self.completionBlock( self.sourceURL, nil );
    }
    
    [self.urlConnection cancel];
    
    [self.completionBlock release];
    self.completionBlock = nil;
  }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
  self.receivedData = nil;
  [self.urlConnection cancel];
  self.urlConnection = nil;
  //------- destroy completion handler ---------
  [self.completionBlock release];
  self.completionBlock = nil;

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