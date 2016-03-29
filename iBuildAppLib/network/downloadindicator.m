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

#import "downloadIndicator.h"
#import <QuartzCore/QuartzCore.h>

#define SMALL_LOCK_VIEW_SCALE 2.0 

@implementation TDownloadIndicator
@synthesize urlLoader = m_pLoader,
             enabled  = m_bEnabled,
          bigLockView = m_bigLockView,
        smallLockView = m_smallLockView;

-(void)createViews
{
  /////////////////////////////////////////////////////////////////////////
  // create Big lock View
  /////////////////////////////////////////////////////////////////////////
  if ( !m_bigLockView )
  {
    m_bigLockView = [[UIView alloc] initWithFrame:self.bounds];
    [m_bigLockView setAutoresizingMask: UIViewAutoresizingFlexibleWidth |
                                        UIViewAutoresizingFlexibleHeight];
    [m_bigLockView setBackgroundColor:[UIColor darkTextColor]];
    [m_bigLockView setOpaque:YES];
    [m_bigLockView setUserInteractionEnabled:YES];
    [m_bigLockView setAlpha:2.f/3.f];
    [m_bigLockView setHidden:YES];                  // hide by default
    [self addSubview:m_bigLockView];

    [self sendSubviewToBack:m_bigLockView];
  }
  /////////////////////////////////////////////////////////////////////////
  // create activity indicator
  /////////////////////////////////////////////////////////////////////////
  if ( !m_activityIndicator )
  {
    m_activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [m_activityIndicator setUserInteractionEnabled:YES];
    [m_activityIndicator setOpaque:NO];
    [m_activityIndicator setBackgroundColor:[UIColor clearColor]];
  }
  
  /////////////////////////////////////////////////////////////////////////
  // create small lock View
  /////////////////////////////////////////////////////////////////////////
  if ( !m_smallLockView )
  {
    m_smallLockView = [[UIView alloc] initWithFrame:CGRectMake( 0, 0,
                                                                m_activityIndicator.bounds.size.width  * SMALL_LOCK_VIEW_SCALE,
                                                                m_activityIndicator.bounds.size.height * SMALL_LOCK_VIEW_SCALE)];
    [m_smallLockView setUserInteractionEnabled:YES];
    [m_smallLockView setAlpha:1.f];
    [m_smallLockView setOpaque:YES];
    [m_smallLockView setBackgroundColor:[UIColor darkTextColor]];
    m_smallLockView.center = m_bigLockView.center;
    m_smallLockView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin  |
                                       UIViewAutoresizingFlexibleRightMargin |
                                       UIViewAutoresizingFlexibleTopMargin   |
                                       UIViewAutoresizingFlexibleBottomMargin;
    m_smallLockView.layer.cornerRadius = 5.0f;

    [m_bigLockView addSubview:m_smallLockView];
    m_activityIndicator.frame = CGRectMake( (m_smallLockView.bounds.size.width - m_activityIndicator.bounds.size.width) * 0.5f,
                                            (m_smallLockView.bounds.size.height - m_activityIndicator.bounds.size.height) * 0.5f,
                                            m_activityIndicator.bounds.size.width,
                                            m_activityIndicator.bounds.size.height);
  }

  if ( ![m_activityIndicator superview] )
    [m_smallLockView addSubview:m_activityIndicator];
}

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self)
  {
    m_pLoader           = nil;
    m_bigLockView       = nil;
    m_smallLockView     = nil;
    m_progressVolume    = nil;
    m_progressIndicator = nil;
    m_activityIndicator = nil;
    m_bEnabled          = YES;
    m_progressCounter   = 0;
    self.autoresizesSubviews = YES;
  }
  return self;
}

-(void)setLoader:(TURLLoader *)urlLoader_
{
  if ( m_pLoader != urlLoader_ )
  {
    [m_pLoader release];
    m_pLoader = [urlLoader_ retain];
  }
}

-(void)destroyViews
{
  if ( m_progressVolume )
  {
    [m_progressVolume removeFromSuperview];
    [m_progressVolume release];
    m_progressVolume  = nil;
  }
  if ( m_progressIndicator )
  {
    [m_progressIndicator removeFromSuperview];
    [m_progressIndicator release];
    m_progressIndicator = nil;
  }
  if ( m_activityIndicator )
  {
    [m_activityIndicator removeFromSuperview];
    [m_activityIndicator release];
    m_activityIndicator = nil;
  }
  if ( m_smallLockView )
  {
    [m_smallLockView removeFromSuperview];
    [m_smallLockView release];
    m_smallLockView = nil;
  }
  if ( m_bigLockView )
  {
    [m_bigLockView removeFromSuperview];
    [m_bigLockView release];
    m_bigLockView = nil;
  }
}

-(void)removeFromURLloader
{
  if ( m_pLoader )
    [m_pLoader removeDelegate:self];
}

-(void)dealloc
{
  if ( m_pLoader )
  {
    [m_pLoader release];
    m_pLoader = nil;
  }
  [self destroyViews];
  /////////////////////////////////
  [super dealloc];
}

-(void)setProgressValue:(double_t)loadProgress
{
  if ( !m_smallLockView     ||
      !m_activityIndicator )
    return;
  if ( !m_progressVolume )
  {
    m_progressVolume = [[UILabel alloc] initWithFrame:CGRectMake( 0,
                                                                 m_smallLockView.bounds.size.height -
                                                                 (m_smallLockView.bounds.size.height - m_activityIndicator.bounds.size.height) * 0.5f,
                                                                 m_smallLockView.bounds.size.width,
                                                                 (m_smallLockView.bounds.size.height - m_activityIndicator.bounds.size.height) * 0.5f )];
    [m_progressVolume setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin |
     UIViewAutoresizingFlexibleWidth ];
    [m_progressVolume setFont:[UIFont boldSystemFontOfSize:12]];
    [m_progressVolume setTextColor:[UIColor whiteColor]];
    [m_progressVolume setBackgroundColor:[UIColor clearColor]];
    [m_progressVolume setAdjustsFontSizeToFitWidth:YES];
    [m_progressVolume setTextAlignment:NSTextAlignmentCenter];
    m_progressCounter = 0;
    [m_smallLockView addSubview:m_progressVolume];
  }
  if ( m_progressVolume )
  {
    // if content length specified... create download progress bar
    if ( loadProgress > 0 )
    {
      [m_progressVolume setText: [NSString stringWithFormat:@"Loading %.1f%%", loadProgress * 100.f ] ];
    }else{
      [m_progressVolume setText: NSLocalizedString(@"core_loadingMessage", @"Loading...")];
    }
  }
}

-(void) createIndicatorWithLoader:(TURLLoader *)urlLoader
                 andProgressValue:(double_t)loadProgress
{
  
  [self setProgressValue:[urlLoader contentLength] > 0 ? loadProgress : -1.0 ];
}


-(void)layoutSubviews
{
  [super layoutSubviews];
}


-(void)startLockViewAnimating:(BOOL)bStart_
{
  if ( [m_bigLockView isHidden] && bStart_ )
  {
    [m_bigLockView setHidden:!bStart_];
    [m_activityIndicator startAnimating];
  }else if ( ![m_bigLockView isHidden] && !bStart_ )
  {
    [m_bigLockView setHidden:!bStart_];
    [m_activityIndicator stopAnimating];
  }
}

// IURLLoaderDelegate implementation
- (void)onBeginRequest:(NSURLRequest *)urlRequest
         withURLloader:(TURLLoader *)urlLoader
{
  [self createViews];
  [self startLockViewAnimating:YES];
}

- (void)onBeginDownload:(NSURLResponse *)urlResponse
          withURLloader:(TURLLoader *)urlLoader
{
  [self createViews];
  [self startLockViewAnimating:YES];
  [self createIndicatorWithLoader:urlLoader
                 andProgressValue:0.f];
}

- (void)onProcessDownload:(double_t)loadProgress
            withURLloader:(TURLLoader *)urlLoader
{
  [self createViews];
  [self startLockViewAnimating:YES];
  [self createIndicatorWithLoader:urlLoader
                 andProgressValue:loadProgress];
  
}

- (void)didFinishLoading:(NSData *)data
           withURLloader:(TURLLoader *)urlLoader
{
  [self startLockViewAnimating:NO];

  [self destroyViews];
}

- (void)loaderConnection:(NSURLConnection *)connection
        didFailWithError:(NSError *)error
            andURLloader:(TURLLoader *)urlLoader
{
  [self startLockViewAnimating:NO];
  [self destroyViews];
}

@end
