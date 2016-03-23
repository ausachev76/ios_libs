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

#import "urlimageview.h"
#import "httpurlresponse_extesion.h"
#import "thumbnailcache.h"
#import "iconcontainer.h"
#import "uiimage+resize.h"

#define IMAGE_FADE_IN_ANIMATION_DURATION 1.f

@implementation TURLImageView
@synthesize imageView = m_imageView,
            bThumbnail,
            mode = m_mode,
            thumbnailSize = m_thumbSize,
            description   = m_description,
         showDefaultImage = m_bShowDefaultImage,
            bSaveThumbs;

-(void)setupDefaultImageWithSize:(CGSize)size_
{
  NSInteger minSize = MIN(size_.width, size_.height);
  m_imageView.contentMode = UIViewContentModeCenter;
  if ( minSize < 48 )
  {
    UIImage *img = [TIconContainer embeddedImageNamed:@"UIIconImage48"];
    m_imageView.image = [img resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                                                  bounds:size_
                                    interpolationQuality:kCGInterpolationDefault];
  }else if ( minSize < 64 )
  {
    m_imageView.image = [TIconContainer embeddedImageNamed:@"UIIconImage48"];
  }else if ( minSize < 128 )
  {
    m_imageView.image = [TIconContainer embeddedImageNamed:@"UIIconImage64"];
  }else {
    m_imageView.image = [TIconContainer embeddedImageNamed:@"UIIconImage128"];
  }
}

-(void)setupMissingImageWithSize:(CGSize)size_
{
  m_imageView.contentMode = UIViewContentModeCenter;
  NSInteger minSize = MIN(size_.width, size_.height);
  if ( minSize < 24 )
  {
    UIImage *img = [TIconContainer embeddedImageNamed:@"UIIconImageMissing24"];
    m_imageView.image = [img resizedImageWithContentMode:UIViewContentModeScaleAspectFit
                                                  bounds:size_
                                    interpolationQuality:kCGInterpolationDefault];
  }else if ( minSize < 48 )
  {
    m_imageView.image = [TIconContainer embeddedImageNamed:@"UIIconImageMissing24"];
  }else if ( minSize < 128 )
  {
    m_imageView.image = [TIconContainer embeddedImageNamed:@"UIIconImageMissing48"];
  }else {
    m_imageView.image = [TIconContainer embeddedImageNamed:@"UIIconImageMissing128"];
  }
}


-(UIImageView *)imageView
{
  if ( !m_imageView )
  {
    m_imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    m_imageView.autoresizesSubviews = YES;
    m_imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    m_imageView.contentMode   = (UIViewContentMode)m_mode;            // center the content
    m_imageView.clipsToBounds = YES;                                  // enable cliping the content
    [self addSubview:m_imageView];                                    // append view into the stack of view
    [self sendSubviewToBack:m_imageView];
  }
  return m_imageView;
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self)
  {
    m_bShowDefaultImage = NO;
    bThumbnail    = NO;                                              // don't generate thumbnails by default
    bSaveThumbs   = NO;                                              // don't save thumbnails by default
    m_thumbSize   = CGSizeMake( -1.f, -1.f );
    m_mode        = ContentModeCenter;
    m_imageView   = nil;
    self.description = nil;
    m_imgType        = nil;
  }
  return self;
}


-(void)setMode:(TImageMode)mode_
{
  m_mode = mode_;
  if ( !m_imageView )
    return;
  
  if ( mode_ == ContentModePatternTiled )
  {
    if ( self.imageView.image )
    {
      self.backgroundColor = [UIColor colorWithPatternImage:self.imageView.image];
      self.imageView.image = nil;
      [self setOpaque:YES];
      [[self layer] setOpaque:YES];
    }
  }else if ( mode_ == ContentModeStretchableFromCenter )
  {
    if ( self.imageView.image )
    {
      UIImage *img = self.imageView.image;
      self.imageView.contentMode = UIViewContentModeScaleToFill;
      self.imageView.image = [img stretchableImageWithLeftCapWidth:floorf(img.size.width/2)
                                                      topCapHeight:floorf(img.size.height/2)];
    }
  }else
    self.imageView.contentMode = (UIViewContentMode)mode_;
}

-(void)setImage:(UIImage *)image_
       withMode:(TImageMode)mode_
{
  if ( !image_ )
  {
    if ( m_imageView )
    {
      [m_imageView removeFromSuperview];
      [m_imageView release];
      m_imageView = nil;
    }
    return;
  }

  m_mode = mode_;
  
  if ( mode_ == ContentModePatternTiled )
  {
    self.backgroundColor = [UIColor colorWithPatternImage:image_];
    if ( m_imageView )
    {
      [m_imageView removeFromSuperview];
      [m_imageView release];
      m_imageView = nil;
    }
  }else if ( mode_ == ContentModeStretchableFromCenter )
  {
    self.imageView.contentMode = UIViewContentModeScaleToFill;
    self.imageView.image = [image_ stretchableImageWithLeftCapWidth:floorf(image_.size.width/2)
                                                       topCapHeight:floorf(image_.size.height/2)];
  }else{
    self.imageView.contentMode = (UIViewContentMode)mode_;
    self.imageView.image       = image_;
  }
}

-(id)initWithFrame:(CGRect)frame
    andDescription:(NSString *)description_;
{
  self = [self initWithFrame:frame];
  if ( self )
  {
    self.description = description_;
  }
  return self;
}

-(void)dealloc
{
  if ( m_imageView )
  {
    [m_imageView release];
    m_imageView = nil;
  }
  if ( m_imgType )
  {
    [m_imgType release];
    m_imgType = nil;
  }
  self.description = nil;
  
  [super dealloc];
}

-(void)showDefaultImage:(BOOL)bShow_
{
  if ( bShow_ )
    [self setupDefaultImageWithSize:self.frame.size];
  else
  {
    if ( m_imageView )
    {
      [m_imageView removeFromSuperview];
      [m_imageView release];
      m_imageView = nil;
    }
  }
}

/**
 * IURLLoaderDelegate callbacks override
 */
- (void)onBeginRequest:(NSURLRequest *)urlRequest
         withURLloader:(TURLLoader *)urlLoader
{
  if ( m_imageView )
  {
    [m_imageView removeFromSuperview];
    [m_imageView release];
    m_imageView = nil;
  }
  [super onBeginRequest:urlRequest
          withURLloader:urlLoader];
}


- (void)onBeginDownload:(NSURLResponse *)urlResponse
          withURLloader:(TURLLoader *)urlLoader
{
  if ( m_imageView )
  {
    [m_imageView removeFromSuperview];
    [m_imageView release];
    m_imageView = nil;
  }

  if ( m_imgType )
  {
    [m_imgType release];
    m_imgType = nil;
  }
  
  [super onBeginDownload:urlResponse
           withURLloader:urlLoader];
  
  if ([urlResponse isKindOfClass:[NSHTTPURLResponse class]])
  {
    NSHTTPURLResponse *httpResponse = (id)urlResponse;
    NSString *mimeType = [httpResponse MIMEType];
    if (![mimeType hasPrefix:@"image"])
    {
      [urlLoader cancel];
      return;
    }
    m_imgType = [[[mimeType componentsSeparatedByString:@"/"] lastObject] retain];
  }
}

- (void)onProcessDownload:(double_t)loadProgress
            withURLloader:(TURLLoader *)urlLoader
{
  if ( m_imageView )
  {
    [m_imageView removeFromSuperview];
    [m_imageView release];
    m_imageView = nil;
  }
  [super onProcessDownload:loadProgress
             withURLloader:urlLoader];
}

- (void)didFinishLoading:(NSData *)data
           withURLloader:(TURLLoader *)urlLoader
{
  @synchronized(self)
  {
    [super didFinishLoading:data
              withURLloader:urlLoader];
    
    @autoreleasepool
    {
      UIImage *img   = [UIImage imageWithData:data];
      if ( m_mode == ContentModePatternTiled )
      {
        if ( m_imageView )
        {
          [m_imageView removeFromSuperview];
          [m_imageView release];
          m_imageView = nil;
        }

        self.backgroundColor = [UIColor colorWithPatternImage:img];
        [self setOpaque:NO];
        [[self layer] setOpaque:NO];
      }else if ( m_mode == ContentModeStretchableFromCenter )
      {
        self.imageView.contentMode = UIViewContentModeScaleToFill;
        self.imageView.image = [img stretchableImageWithLeftCapWidth:floorf(img.size.width/2.f)
                                                        topCapHeight:floorf(img.size.height/2.f)];
      }else{
        UIImage *thumb = nil;
        CGSize   thumbSize = CGSizeMake( m_thumbSize.width  < 0 ? self.imageView.bounds.size.width  : m_thumbSize.width,
                                         m_thumbSize.height < 0 ? self.imageView.bounds.size.height : m_thumbSize.height );
        
        if ( bThumbnail && ( img.size.width  > thumbSize.width ||
                             img.size.height > thumbSize.height ) )
        {
          thumb = [img resizedImageWithContentMode:(UIViewContentMode)m_mode
                                            bounds:thumbSize
                                       interpolationQuality:kCGInterpolationDefault];

          [self.imageView setImage:thumb];
          if ( thumb == img )
            thumb = nil;
        }else{
          [self.imageView setImage:img];
        }
        
#ifdef IMAGE_FADE_IN_ANIMATION_DURATION
        self.imageView.alpha = 0.f;
        CGContextRef context = UIGraphicsGetCurrentContext();
        [UIView beginAnimations:nil context:context];
        [UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
        [UIView setAnimationDuration: IMAGE_FADE_IN_ANIMATION_DURATION ];
        self.imageView.alpha = 1.f;
        [UIView commitAnimations];
#endif
        
        if ( bSaveThumbs && thumb )
        {
          TThumbnailCache *thumbCache = [TThumbnailCache instance];
          [thumbCache saveThumbnail:thumb
                            withURL:urlLoader.urlRequest.URL
                               type:m_imgType];
        }
      }
    }
    
    if ( m_imgType )
    {
      [m_imgType release];
      m_imgType = nil;
    }
  }
}

- (void)loaderConnection:(NSURLConnection *)connection
        didFailWithError:(NSError *)error
            andURLloader:(TURLLoader *)urlLoader
{
  if ( m_imgType )
  {
    [m_imgType release];
    m_imgType = nil;
  }
  
  [self setupMissingImageWithSize:self.frame.size];
  [self.imageView setHidden:NO];

  [super loaderConnection:connection
         didFailWithError:error
             andURLloader:urlLoader];
}



@end
