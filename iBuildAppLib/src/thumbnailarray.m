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

#import "thumbnailarray.h"
#import "downloadmanager.h"
#import "imageenhancer.h"
#import "iconcontainer.h"
#import "urlimageview.h"


#define DEFAULT_THUMBNAIL_SIZE_WIDTH  128
#define DEFAULT_THUMBNAIL_SIZE_HEIGHT 128



@implementation TThumbnailArray
@synthesize thumbnailSize, contentMode, count;

-(id)init
{
  self = [super init];
  if ( self )
  {
    m_urlList = [[NSMutableArray alloc] init];
    m_imgList = [[NSMutableArray alloc] init];
    self.contentMode   = UIViewContentModeScaleAspectFill;
    self.thumbnailSize = CGSizeMake( DEFAULT_THUMBNAIL_SIZE_WIDTH, DEFAULT_THUMBNAIL_SIZE_HEIGHT );
  }
  return self;
}

-(id)initWithImageList:(NSArray *)imageList_
{
  self = [super init];
  if ( self )
  {
    self.contentMode   = UIViewContentModeScaleAspectFill;
    self.thumbnailSize = CGSizeMake( DEFAULT_THUMBNAIL_SIZE_WIDTH, DEFAULT_THUMBNAIL_SIZE_HEIGHT );
    m_urlList = [[NSMutableArray alloc] initWithArray:imageList_];
    m_imgList = [[NSMutableArray alloc] init];
    
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
  if ( m_urlList )
    [m_urlList release];
  if ( m_imgList )
    [m_imgList release];
  
  [super dealloc];
}

-(NSUInteger)getCount
{
  return m_imgList.count;
}

-(void)appendImageLink:(NSString *)imgLink_
{
  TURLLoader *urlLoader = [[TURLLoader alloc] initWithURL:imgLink_
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:30.f];
  if ( !urlLoader )
    return;
  
  [urlLoader addDelegate:self];
  TURLLoader *pOldLoader = [[TDownloadManager instance] appendTarget:urlLoader];
  if ( pOldLoader != urlLoader )
  {
    [urlLoader removeDelegate:self];
    [pOldLoader addDelegate:self];
    [m_imgList addObject:pOldLoader];
  }else{
    [m_imgList addObject:urlLoader];
  }

  [urlLoader release];
}

-(id)objectAtIndex:(NSUInteger)index_
{
  if ( index_ < m_imgList.count )
  {
    id obj = [m_imgList objectAtIndex:index_];

    if ( [obj isKindOfClass:[TURLLoader class]] )
    {
      TURLImageView *urlImg = [[[TURLImageView alloc] initWithFrame:CGRectZero] autorelease];
      urlImg.autoresizesSubviews = YES;
      urlImg.autoresizingMask    = UIViewAutoresizingFlexibleWidth |
                                   UIViewAutoresizingFlexibleHeight;
      urlImg.mode = (TImageMode)self.contentMode;
      [((TURLLoader *)obj) addDelegate:urlImg];
      return urlImg;
    }
    return obj;
  }
  return nil;
}

#pragma mark IURLLoaderDelegate
- (void)didFinishLoading:(NSData *)data
           withURLloader:(TURLLoader *)urlLoader
{
  UIImage *srcImg = [[UIImage alloc] initWithData:data];
  UIImage *scaledImage = nil;

  if ( self.thumbnailSize.width  > 0.f && 
       self.thumbnailSize.height > 0.f )
  {
    scaledImage = [srcImg scaleToSize:self.thumbnailSize
                             withMode:self.contentMode];
  }

  NSUInteger idx = 0;
  for( id obj in m_imgList )
  {
    if ( obj == urlLoader )
    {
      [m_imgList replaceObjectAtIndex:idx
                           withObject:( scaledImage ? scaledImage : srcImg )];
      break;
    }
    ++idx;
  }
  [srcImg release];
}

- (void)loaderConnection:(NSURLConnection *)connection
        didFailWithError:(NSError *)error
            andURLloader:(TURLLoader *)urlLoader
{
  NSInteger minSize = MIN(self.thumbnailSize.width, self.thumbnailSize.height);
  UIImage *failToLoadImage = nil;
  if ( minSize < 24 )
  {
    UIImage *img = [TIconContainer embeddedImageNamed:@"UIIconImageMissing24"];
    failToLoadImage = [img scaleToSize:self.thumbnailSize proportional:YES];
  }else if ( minSize < 48 )
  {
    failToLoadImage = [TIconContainer embeddedImageNamed:@"UIIconImageMissing24"];
  }else if ( minSize < 128 )
  {
    failToLoadImage = [TIconContainer embeddedImageNamed:@"UIIconImageMissing48"];
  }else {
    failToLoadImage = [TIconContainer embeddedImageNamed:@"UIIconImageMissing128"];
  }

  NSUInteger idx = 0;
  for( id obj in m_imgList )
  {
    if ( obj == urlLoader )
    {
      [m_imgList replaceObjectAtIndex:idx
                           withObject:failToLoadImage];
    }
    ++idx;
  }
}


@end
