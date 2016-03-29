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

#import "urlimagedictionary.h"
#import "downloadmanager.h"
#import "uiimage+resize.h"
#import "iconcontainer.h"
#import "urlimageview.h"


@implementation TURLImageDescriptor
@synthesize alterImageData, obj;

-(id) initWithObject:(id)obj_
      alterImageData:(NSData *)alterData_
{
  self = [super init];
  if ( self )
  {
    self.alterImageData = alterData_;
    self.obj            = obj_;
  }
  return self;
}

-(id) init
{
  self = [super init];
  if ( self )
  {
    self.alterImageData = nil;
    self.obj            = nil;
  }
  return self;
}

-(void)dealloc
{
  self.alterImageData = nil;
  self.obj            = nil;
  [super dealloc];
}

// In the implementation
-(id)copyWithZone:(NSZone *)zone
{
  return [[TURLImageDescriptor alloc] initWithObject:self.obj
                                      alterImageData:self.alterImageData];
}
// Encode an object for an archive
- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeObject:self.alterImageData forKey:@"TURLImageDescriptor::alterImageData" ];
}
// Decode an object from an archive
- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if ( self )
  {
    self.alterImageData = [coder decodeObjectForKey:@"TURLImageDescriptor::alterImageData"];
    self.obj            = nil;
  }
  return self;
}

@end


#define DEFAULT_THUMBNAIL_SIZE_WIDTH  128
#define DEFAULT_THUMBNAIL_SIZE_HEIGHT 128

@implementation TURLImageDictionary
@synthesize thumbnailSize, contentMode, count,
            delegatesList = m_delegatesList;

-(id)init
{
  self = [super init];
  if ( self )
  {
    m_imageDictionary = [[NSMutableDictionary alloc] init];
    m_count = 0;
    m_bBeginRequest  = NO;
    m_bBeginDownload = NO;
    self.contentMode   = UIViewContentModeScaleAspectFill;
    self.thumbnailSize = CGSizeZero;
    m_delegatesList = nil;
  }
  return self;
}

-(id)initWithImageList:(NSArray *)imageList_
{
  self = [super init];
  if ( self )
  {
    m_imageDictionary = [[NSMutableDictionary alloc] init];
    m_count = 0;
    m_bBeginRequest  = NO;
    m_bBeginDownload = NO;
    m_delegatesList = nil;
    self.contentMode   = UIViewContentModeScaleAspectFill;
    self.thumbnailSize = CGSizeMake( -1.f, -1.f );
    
    for( NSString *it in imageList_ )
      [self appendImageLink:it];
  }
  return self;
}

-(void)startDownload
{
  [[TDownloadManager instance] runAll];
}

-(void)dealloc
{
  if ( m_imageDictionary )
    [m_imageDictionary release];
  
  if ( m_delegatesList )
    [m_delegatesList release];
  
  [super dealloc];
}

-(NSMutableArray *)delegatesList
{
  if ( !m_delegatesList )
    m_delegatesList = [[NSMutableArray alloc] init];
  return m_delegatesList;
}

-(BOOL)addDelegate:(id <IURLLoaderDelegate>)delegate
{
  @synchronized(self)
  {
    if ( [self.delegatesList containsObject:delegate] )
      return NO;
    [self.delegatesList addObject:delegate];
    return YES;
  }
}

-(BOOL)removeDelegate:(id <IURLLoaderDelegate>)delegate
{
  @synchronized(self)
  {
    [self.delegatesList removeObject:delegate];
    return YES;
  }
}



-(NSUInteger)getCount
{
  return m_imageDictionary.count;
}

-(NSArray *)allKeys
{
  return [m_imageDictionary allKeys];
}

-(NSArray *)allValues
{
  return [m_imageDictionary allValues];
}

-(TURLImageDescriptor *)valueForKey:(NSString *)key_
{
  return [m_imageDictionary objectForKey:key_];
}

-(void)removeAllObjects
{
  return [m_imageDictionary removeAllObjects];
}


-(void)appendImageLink:(NSString *)imgLink_
{
  [self appendImageLink:imgLink_ withAlterImageData:nil];
}

-(void)appendImageLink:(NSString *)imgLink_
    withAlterImageData:(NSData *)alterImageData_
{
  if ( !imgLink_ || ![imgLink_ length] )
    return;
  
  imgLink_ = [imgLink_ stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  imgLink_ = [imgLink_ stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  
  NSURL *url = [NSURL URLWithString:imgLink_];
  if ( [[url.scheme lowercaseString] isEqualToString:@"file"] &&
      [[url.host lowercaseString] isEqualToString:@"bundle"] )
  {
    NSString *path = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:url.path];
    imgLink_ = [[NSURL fileURLWithPath:path] absoluteString];
  }
  
  id obj = [m_imageDictionary objectForKey:imgLink_];
  if ( obj )
    return;
  
  
  TURLLoader *urlLoader = [[TURLLoader alloc] initWithURL:imgLink_
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:30.f];
  if ( !urlLoader )
    return;
  
  [urlLoader addDelegate:self];
  TURLLoader *pOldLoader = [[TDownloadManager instance] appendTargetWithHiPriority:urlLoader];
  if ( pOldLoader != urlLoader )
  {
    [urlLoader removeDelegate:self];
    [pOldLoader addDelegate:self];
    [m_imageDictionary setObject:[[[TURLImageDescriptor  alloc ] initWithObject:pOldLoader
                                                                 alterImageData:alterImageData_] autorelease]
                          forKey:imgLink_];
  }else{
    [m_imageDictionary setObject:[[[TURLImageDescriptor  alloc ] initWithObject:pOldLoader
                                                                 alterImageData:alterImageData_] autorelease]
                          forKey:imgLink_];
  }
  ++m_count;
  
  [urlLoader release];
}

-(void)setImage:(UIImage *)image_ forKey:(NSString *)key_
{
  if ( !image_ || !key_ )
    return;
  
  key_ = [key_ stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  key_ = [key_ stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  
  [m_imageDictionary setObject:[[[TURLImageDescriptor alloc] initWithObject:image_ alterImageData:nil] autorelease]
                        forKey:key_];
}

-(id)objectForKey:(NSString *)key_
{
  key_ = [key_ stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  key_ = [key_ stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

  NSURL *url = [NSURL URLWithString:key_];
  if ( [[url.scheme lowercaseString] isEqualToString:@"file"] &&
       [[url.host lowercaseString] isEqualToString:@"bundle"] )
  {
    NSString *path = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:url.path];
    key_ = [[NSURL fileURLWithPath:path] absoluteString];
  }
  
  TURLImageDescriptor *imgDesc = [m_imageDictionary objectForKey:key_];
  if ( imgDesc )
  {
    if ( [imgDesc.obj isKindOfClass:[TURLLoader class]] )
    {
      TURLImageView *urlImg = [[[TURLImageView alloc] initWithFrame:CGRectZero] autorelease];
      urlImg.autoresizesSubviews = YES;
      urlImg.autoresizingMask    = UIViewAutoresizingFlexibleWidth |
                                   UIViewAutoresizingFlexibleHeight;
      urlImg.thumbnailSize       = self.thumbnailSize;
      [urlImg generateThumbnail:YES];
      urlImg.mode = (TImageMode)self.contentMode;
      [((TURLLoader *)imgDesc.obj) addDelegate:urlImg];
      return urlImg;
    }
    return imgDesc.obj;
  }
  return nil;
}

#pragma mark IURLLoaderDelegate

- (void)onBeginRequest:(NSURLRequest *)urlRequest
         withURLloader:(TURLLoader *)urlLoader
{
  if ( !m_bBeginRequest )
  {
    m_bBeginRequest = !m_bBeginRequest;

    @synchronized(self)
    {
      for( id<IURLLoaderDelegate> delegate in self.delegatesList )
      {
        if ( [delegate respondsToSelector:@selector(onBeginRequest:withURLloader:)] )
          [delegate onBeginRequest:urlRequest
                     withURLloader:urlLoader];
      }
    }
  }
}

- (void)onBeginDownload:(NSURLResponse *)urlResponse
          withURLloader:(TURLLoader *)urlLoader
{
  if ( !m_bBeginDownload )
  {
    m_bBeginDownload = !m_bBeginDownload;
    @synchronized(self)
    {
      for( id<IURLLoaderDelegate> delegate in self.delegatesList )
      {
        if ( [delegate respondsToSelector:@selector(onBeginDownload:withURLloader:)] )
          [delegate onBeginDownload:urlResponse
                      withURLloader:urlLoader];
      }
    }
  }
}

-(void)checkForEndOfSession:(NSData *)data
              withURLloader:(TURLLoader *)urlLoader
{
  if ( --m_count )
  {
    double percentComplete = (double)(m_imageDictionary.count - m_count) / m_imageDictionary.count;
    @synchronized(self)
    {
      for( id<IURLLoaderDelegate> delegate in self.delegatesList )
      {
        if ( [delegate respondsToSelector:@selector(onProcessDownload:withURLloader:)] )
          [delegate onProcessDownload:percentComplete
                        withURLloader:urlLoader];
      }
    }
  }else{
    @synchronized(self)
    {
      unsigned i;
      NSUInteger cnt = [self.delegatesList count];
      for( i = 0; i < cnt; ++i )
      {
        NSInteger previousCount = [self.delegatesList count];
        id<IURLLoaderDelegate> delegate = [self.delegatesList objectAtIndex:i];
        
        if ( [delegate respondsToSelector:@selector(didFinishLoading:withURLloader:)] )
          [delegate didFinishLoading:data
                       withURLloader:urlLoader];
        if ( [delegate respondsToSelector:@selector(setLoader:)] )
          [delegate setLoader:nil];
        
        [self.delegatesList removeObject:delegate];
        cnt = [self.delegatesList count];
        if ( previousCount != cnt )
          --i;
      }
      [m_delegatesList release];
      m_delegatesList = nil;
    }
  }
}

- (void)didFinishLoading:(NSData *)data
           withURLloader:(TURLLoader *)urlLoader
{
  UIImage *srcImg = [[UIImage alloc] initWithData:data];
  if ( srcImg )
  {
    UIImage *scaledImage = nil;

    if ( self.thumbnailSize.width  > 0.f &&
         self.thumbnailSize.height > 0.f )
    {
      scaledImage = [srcImg resizedImageWithContentMode:self.contentMode
                                                 bounds:self.thumbnailSize
                                   interpolationQuality:kCGInterpolationDefault];
    }
    
    NSString *key = urlLoader.urlRequest.URL.absoluteString;
    
    TURLImageDescriptor *imgDesc = [m_imageDictionary objectForKey:key];
    imgDesc.obj            = ( scaledImage ? scaledImage : srcImg );
    imgDesc.alterImageData = nil;
  }
  [self checkForEndOfSession:data
               withURLloader:urlLoader];
  [srcImg release];
}

- (void)loaderConnection:(NSURLConnection *)connection
        didFailWithError:(NSError *)error
            andURLloader:(TURLLoader *)urlLoader
{
  NSString *key = urlLoader.urlRequest.URL.absoluteString;
  TURLImageDescriptor *imgDesc = [m_imageDictionary objectForKey:key];
  BOOL bNeedPlaceholder = YES;
  
  if ( imgDesc.alterImageData )
  {
    imgDesc.obj = [UIImage imageWithData:imgDesc.alterImageData];
    bNeedPlaceholder = imgDesc.obj == nil;
  }
  
  if ( bNeedPlaceholder )
  {
    NSInteger minSize = MIN(self.thumbnailSize.width, self.thumbnailSize.height);
    UIImage *failToLoadImage = nil;
    if ( minSize < 24 )
    {
      UIImage *img = [TIconContainer embeddedImageNamed:@"UIIconImageMissing24"];
      failToLoadImage = [img resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                                                  bounds:self.thumbnailSize
                                    interpolationQuality:kCGInterpolationDefault];
    }else if ( minSize < 48 )
    {
      failToLoadImage = [TIconContainer embeddedImageNamed:@"UIIconImageMissing24"];
    }else if ( minSize < 128 )
    {
      failToLoadImage = [TIconContainer embeddedImageNamed:@"UIIconImageMissing48"];
    }else {
      failToLoadImage = [TIconContainer embeddedImageNamed:@"UIIconImageMissing128"];
    }

    imgDesc.obj = failToLoadImage;
  }
  imgDesc.alterImageData = nil;

  [self checkForEndOfSession:nil
               withURLloader:urlLoader];
}

@end
