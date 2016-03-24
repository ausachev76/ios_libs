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

#import "MWDescriptionView.h"

@interface MWDescriptionViewController()
  @property (nonatomic, strong) UITextView *descriptionText;
@end

@implementation MWDescriptionViewController
@synthesize description = _description,
        descriptionText = _descriptionText,
            infoButton;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
      _descriptionText = nil;
      self.description = nil;
      self.infoButton  = nil;
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
  [super viewWillAppear:animated];

  const CGFloat infoMargin = 8.f;
  const CGFloat xPos = self.view.frame.size.width  * 0.35f;
  const CGFloat yPos = self.view.frame.size.height * 0.6f;

  self.descriptionText.frame = CGRectMake( xPos, yPos,
                                           self.view.frame.size.width  - xPos - self.infoButton.frame.size.width - infoMargin * 2,
                                           self.view.frame.size.height - yPos - infoMargin);
}

- (void)viewDidLoad
{
  [super viewDidLoad];

  self.view.backgroundColor = [UIColor underPageBackgroundColor];
  
  const CGFloat infoMargin = 8.f;

  self.infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
  self.infoButton.frame = CGRectMake( self.view.frame.size.width  - self.infoButton.frame.size.width  - infoMargin,
                                      self.view.frame.size.height - self.infoButton.frame.size.height - infoMargin,
                                      self.infoButton.frame.size.width,
                                      self.infoButton.frame.size.height );
  [self.infoButton addTarget:self
                      action:@selector(goBack)
            forControlEvents:UIControlEventTouchUpInside];
  self.infoButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin;

  self.descriptionText = [[[UITextView alloc] initWithFrame:CGRectZero] autorelease];
  self.descriptionText.autoresizingMask = UIViewAutoresizingFlexibleWidth |
                                          UIViewAutoresizingFlexibleHeight;
  self.descriptionText.opaque           = YES;
  self.descriptionText.backgroundColor  = [UIColor clearColor];
  self.descriptionText.textAlignment    = NSTextAlignmentLeft;
  self.descriptionText.textColor        = [UIColor darkTextColor];
  self.descriptionText.editable         = NO;
  self.descriptionText.font             = [UIFont systemFontOfSize:17];
  
  [self.view addSubview:self.descriptionText];
  ///-------------------------------------------------------------
  [self.view addSubview:self.infoButton];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return NO;
}

-(BOOL)shouldAutorotate
{
  return NO;
}

- (void)goBack
{

}

-(void)setDescription:(NSString *)desc
{
  if ( _description != desc )
  {
    [_description release];
    _description = [desc retain];
    [self.descriptionText setText:_description ? _description : @""];
  }
}

#pragma mark    ///////////////////////////////////////    WEBVIEW EVENTS
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
  return YES;
}

- (void)dealloc
{
  self.descriptionText = nil;
  self.description     = nil;
  self.infoButton      = nil;
  [super dealloc];
}


@end
