//
//  MWPhotoBrowser.m
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

// Modified by iBuildApp

#import <QuartzCore/QuartzCore.h>
#import "MWPhotoBrowser.h"
#import "MWZoomingScrollView.h"
#import "MBProgressHUD.h"
#import "SDImageCache.h"
#import "MWDescriptionView.h"
#import "MWPhotoTitle.h"
#import "IBSideBarModuleAction.h"
#import "IBSideBarVC.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

#define PADDING                 10
#define PAGE_INDEX_TAG_OFFSET   1000
#define PAGE_INDEX(page)        ([(page) tag] - PAGE_INDEX_TAG_OFFSET)

#define PAGE_DESCRIPTION_CURL_OFFSET 0.58f

// Private
@interface MWPhotoBrowser () {
    
	// Data
    id <MWPhotoBrowserDelegate> _delegate;
    NSUInteger _photoCount;
    NSMutableArray *_photos;
	NSArray *_depreciatedPhotoData; // Depreciated
	
	// Views
	UIScrollView *_pagingScrollView;
	
	// Paging
	NSMutableSet *_visiblePages, *_recycledPages;
	NSUInteger _pageIndexBeforeRotation;
	
	// Navigation & controls
	UIToolbar *_toolbar;
	NSTimer *_controlVisibilityTimer;
//  UILabel *_uiTitleLabel;
  MWPhotoTitle *_uiTitleScroll;
	UIBarButtonItem *_previousButton, *_nextButton, *_actionButton, *_titleLabel;
    UIActionSheet *_actionsSheet;
    MBProgressHUD *_progressHUD;
    
    // Appearance
    UIImage *_navigationBarBackgroundImageDefault, 
    *_navigationBarBackgroundImageLandscapePhone;
    UIColor *_previousNavBarTintColor;
    UIBarStyle _previousNavBarStyle;
//    UIStatusBarStyle _previousStatusBarStyle;
    UIBarButtonItem *_previousViewControllerBackButton;
  
    UIView  *_descriptionBackground;
    // Misc
    BOOL _displayActionButton;
	BOOL _performingLayout;
	BOOL _rotating;
    BOOL _viewIsActive; // active as in it's in the view heirarchy
    BOOL _didSavePreviousStateOfNavBar;
    
}

// Private Properties
@property (nonatomic, retain) UIImage *navigationBarBackgroundImageDefault, *navigationBarBackgroundImageLandscapePhone;
@property (nonatomic, retain) UIActionSheet *actionsSheet;
@property (nonatomic, retain) MBProgressHUD *progressHUD;
@property (nonatomic, retain) MWDescriptionViewController *descriptionViewController;

// Private Methods

// Layout
- (void)performLayout;

// Paging
- (void)tilePages;
- (BOOL)isDisplayingPageForIndex:(NSUInteger)index;
- (MWZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index;
- (MWZoomingScrollView *)pageDisplayingPhoto:(id<MWPhoto>)photo;
- (MWZoomingScrollView *)dequeueRecycledPage;
- (void)configurePage:(MWZoomingScrollView *)page forIndex:(NSUInteger)index;
- (void)didStartViewingPageAtIndex:(NSUInteger)index;

// Frames
- (CGRect)frameForPagingScrollView;
- (CGRect)frameForPageAtIndex:(NSUInteger)index;
- (CGSize)contentSizeForPagingScrollView;
- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index;
- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation;
- (CGRect)frameForCaptionView:(MWCaptionView *)captionView atIndex:(NSUInteger)index;

// Navigation
- (void)updateNavigation;
- (void)jumpToPageAtIndex:(NSUInteger)index;
- (void)gotoPreviousPage;
- (void)gotoNextPage;

// Controls
- (void)cancelControlHiding;
- (void)hideControlsAfterDelay;
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent;
- (void)toggleControls;
- (BOOL)areControlsHidden;

// Data
- (NSUInteger)numberOfPhotos;
- (id<MWPhoto>)photoAtIndex:(NSUInteger)index;
- (UIImage *)imageForPhoto:(id<MWPhoto>)photo;
- (void)loadAdjacentPhotosIfNecessary:(id<MWPhoto>)photo;
- (void)releaseAllUnderlyingPhotos;

// Actions
- (void)savePhoto;
- (void)copyPhoto;
- (void)emailPhoto;

@end

// Handle depreciations and supress hide warnings
@interface UIApplication (DepreciationWarningSuppresion)
- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated;
@end

// MWPhotoBrowser
@implementation MWPhotoBrowser

// Properties
@synthesize navigationBarBackgroundImageDefault = _navigationBarBackgroundImageDefault,
navigationBarBackgroundImageLandscapePhone = _navigationBarBackgroundImageLandscapePhone;
@synthesize displayActionButton = _displayActionButton,
                   actionsSheet = _actionsSheet;
@synthesize progressHUD = _progressHUD;
@synthesize bSavePicture;
@synthesize leftBarButtonCaption = _leftBarButtonCaption;
@synthesize descriptionViewController = _descriptionViewController;

#pragma mark - NSObject

- (id)init {
    if ((self = [super init])) {
        
        // Defaults
        self.wantsFullScreenLayout    = YES;
        self.bSavePicture             = NO;
        _leftBarButtonCaption = nil;
        _photoCount = NSNotFound;
        _currentPageIndex = 0;
        _performingLayout = NO; // Reset on view did appear
        _rotating = NO;
        _viewIsActive = NO;
        _visiblePages = [[NSMutableSet alloc] init];
        _recycledPages = [[NSMutableSet alloc] init];
        _photos = [[NSMutableArray alloc] init];
        _displayActionButton = NO;
      
        // Listen for MWPhoto notifications
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleMWPhotoLoadingDidEndNotification:)
                                                     name:MWPHOTO_LOADING_DID_END_NOTIFICATION
                                                   object:nil];
      
        /// Add a handler for entering background. When going to background we need to
        /// remove descriptionViewController -- iBuildApp
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
      
        _descriptionViewController = nil;
    }
    return self;
}

- (id)initWithDelegate:(id <MWPhotoBrowserDelegate>)delegate {
    if ((self = [self init])) {
      self.descriptionViewController = nil;
        _delegate = delegate;
	}
	return self;
}

- (id)initWithPhotos:(NSArray *)photosArray {
	if ((self = [self init])) {
		_depreciatedPhotoData = [photosArray retain];
    self.descriptionViewController = nil;
	}
	return self;
}

- (void)dealloc {
  
  ///------------------------------------------------------------------
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [_previousNavBarTintColor release];
  [_navigationBarBackgroundImageDefault release];
  [_navigationBarBackgroundImageLandscapePhone release];
  [_previousViewControllerBackButton release];
  [_descriptionBackground release];
	[_pagingScrollView release];
	[_visiblePages release];
	[_recycledPages release];
	[_toolbar release];
  [_uiTitleScroll release];
  [_titleLabel release];
	[_previousButton release];
	[_nextButton release];
  [_actionButton release];
	[_depreciatedPhotoData release];
  [self releaseAllUnderlyingPhotos];
  [[SDImageCache sharedImageCache] clearMemory]; // clear memory
  [_photos release];
  [_progressHUD release];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIApplicationDidEnterBackgroundNotification
                                                object:nil];
  
  self.leftBarButtonCaption = nil;
  [self.descriptionViewController viewWillDisappear:NO];
  [[self.descriptionViewController view] removeFromSuperview];
  [self.descriptionViewController viewDidDisappear:NO];
  self.descriptionViewController = nil;
  [super dealloc];
}

- (void)releaseAllUnderlyingPhotos {
    for (id p in _photos) { if (p != [NSNull null]) [p unloadUnderlyingImage]; } // Release photos
}

- (void)didReceiveMemoryWarning {
	
	// Release any cached data, images, etc that aren't in use.
    [self releaseAllUnderlyingPhotos];
	[_recycledPages removeAllObjects];
	
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
}

#pragma mark - View Loading

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
		// View
	self.view.backgroundColor = [UIColor blackColor];
  
  self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
  self.navigationController.navigationBar.alpha = 0.85f;
  self.navigationController.navigationBar.hidden = YES;
  
	// Setup paging scrolling view
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
	_pagingScrollView = [[UIScrollView alloc] initWithFrame:pagingScrollViewFrame];
	_pagingScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	_pagingScrollView.pagingEnabled = YES;
	_pagingScrollView.delegate = self;
	_pagingScrollView.showsHorizontalScrollIndicator = NO;
	_pagingScrollView.showsVerticalScrollIndicator = NO;
	_pagingScrollView.backgroundColor = [UIColor blackColor];
  _pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	[self.view addSubview:_pagingScrollView];
	
    // Toolbar
    _toolbar = [[UIToolbar alloc] initWithFrame:[self frameForToolbarAtOrientation:self.interfaceOrientation]];
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0")) _toolbar.barTintColor = [UIColor blackColor];
    if ([[UIToolbar class] respondsToSelector:@selector(appearance)]) {
        [_toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];
        [_toolbar setBackgroundImage:nil forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsLandscapePhone];
    }
  
  _toolbar.barStyle = UIBarStyleBlack;
  _toolbar.alpha = 0.85f;
  _toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
  
    // Toolbar Items

    _uiTitleScroll = [[MWPhotoTitle alloc]initWithFrame:CGRectZero];
    [_uiTitleScroll setShowsHorizontalScrollIndicator:NO];
    [_uiTitleScroll setShowsVerticalScrollIndicator:NO];
    _uiTitleScroll.autoresizingMask     = UIViewAutoresizingFlexibleWidth;
    _uiTitleScroll.autoresizesSubviews  = YES;
    _uiTitleScroll.contentSize          = CGSizeZero;
    _uiTitleScroll.alwaysBounceVertical = NO;
    _uiTitleScroll.backgroundColor      = [UIColor clearColor];
  
    _uiTitleScroll.title.backgroundColor      = [UIColor clearColor];
    _uiTitleScroll.title.textColor            = [UIColor lightTextColor];
    _uiTitleScroll.title.text                 = @"";
    _uiTitleScroll.title.autoresizesSubviews  = YES;
    _uiTitleScroll.title.autoresizingMask     = UIViewAutoresizingNone;
    _uiTitleScroll.title.font                 = [UIFont systemFontOfSize:16];
    _uiTitleScroll.title.textAlignment        = NSTextAlignmentCenter;
    _uiTitleScroll.title.adjustsFontSizeToFitWidth = NO;
  
    _titleLabel = [[UIBarButtonItem alloc] initWithCustomView:_uiTitleScroll];

    /// add "Save picture" button only if allowed in settings -- iBuildApp
    if ( self.bSavePicture )
    {
      UIBarButtonItem *actionButton = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                                                     target:self
                                                                                     action:@selector(showActionSelector)] autorelease];
      self.navigationItem.rightBarButtonItem = actionButton;
    }

    UIButton *infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    [infoButton addTarget:self
                   action:@selector(actionButtonPressed:)
         forControlEvents:UIControlEventTouchUpInside];
    _actionButton = [[UIBarButtonItem alloc] initWithCustomView:infoButton];
    [_actionButton setTarget:self];
    [_actionButton setAction:@selector(actionButtonPressed:)];
  
    _uiTitleScroll.frame = CGRectMake( 0.f, 5.f, _toolbar.frame.size.width - 44.f,
                                                 _toolbar.frame.size.height - 5.f * 2);
  
    self.navigationController.navigationBar.translucent = YES;
  
    // Update
    [self reloadData];
    
	// Super
    [super viewDidLoad];
}

- (void)showActionSelector
{
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                           delegate:self
                                                  cancelButtonTitle:nil
                                             destructiveButtonTitle:nil
                                                  otherButtonTitles:nil];
  [actionSheet addButtonWithTitle:NSLocalizedString(@"core_photoBrowserSavePictureButton", @"Save picture")];
	
  if ( actionSheet.numberOfButtons > 0 )
  {
    actionSheet.destructiveButtonIndex = [actionSheet addButtonWithTitle:NSLocalizedString(@"core_photoBrowserCancelButtonTitle", @"Cancel")];
    [actionSheet showInView:( self.tabBarController ? self.tabBarController.view : self.navigationController.view )];
  }
  [actionSheet release];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
  if ( buttonIndex == 0 )
  {
    id <MWPhoto>photo = [self photoAtIndex:_currentPageIndex];
    if ( photo.underlyingImage )
    {
      UIImageWriteToSavedPhotosAlbum( photo.underlyingImage,
                                      self,
                                      @selector(thisImage:hasBeenSavedInPhotoAlbumWithError:usingContextInfo:),
                                      NULL );
    }
  }
}


- (void)thisImage:(UIImage *)image hasBeenSavedInPhotoAlbumWithError:(NSError *)error usingContextInfo:(void*)ctxInfo
{
  if (error){
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"core_photoBrowserErrorSavingPhotoAlertTitle", @"Error!") //@"Error!"
                                                      message:NSLocalizedString(@"core_photoBrowserErrorSavingPhotoAlertMessage", @"Can't save the image!") //@"Can't save the image!"
                                                     delegate:nil
                                            cancelButtonTitle:NSLocalizedString(@"core_photoBrowserErrorSavingPhotoAlertOKButtonTitle", @"OK") //@"OK"
                                            otherButtonTitles:nil];
      [alert show];
      [alert release];
  } else {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                      message:NSLocalizedString(@"core_photoBrowserSuccessSavingPhotoAlertMessabe", @"The picture has been saved to your iPhone.") //@"The picture has been saved to your iPhone."
                                                     delegate:nil
                                            cancelButtonTitle:NSLocalizedString(@"core_photoBrowserSuccessSavingPhotoAlertOKButtonTitle", @"OK") //@"OK"
                                            otherButtonTitles:nil];
    [alert show];
    [alert release];
  }
}




- (void)performLayout {
  
    // Setup
    _performingLayout = YES;
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    
	// Setup pages
    [_visiblePages removeAllObjects];
    [_recycledPages removeAllObjects];
    
    // Toolbar
    if (numberOfPhotos > 1 || _displayActionButton) {
      [self.view addSubview:_toolbar];
      _toolbar.alpha = 0.85f;
    } else {
      [_toolbar removeFromSuperview];
    }
  
    // Toolbar items & navigation
    UIBarButtonItem *fixedLeftSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                                     target:self
                                                                                     action:nil] autorelease];
    fixedLeftSpace.width = 5.f; // To balance action button
    UIBarButtonItem *flexSpace = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                                                target:self
                                                                                action:nil] autorelease];
    NSMutableArray *items = [[NSMutableArray alloc] init];
    if (_displayActionButton)
      [items addObject:fixedLeftSpace];
    [items addObject:flexSpace];
    [items addObject:_titleLabel];
    if (_displayActionButton)
      [items addObject:_actionButton];
    [_toolbar setItems:items];
    [items release];
	[self updateNavigation];
  
    // Content offset
	_pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:_currentPageIndex];
    [self tilePages];
    _performingLayout = NO;
    
}

// Release any retained subviews of the main view.
- (void)viewDidUnload {
	_currentPageIndex = 0;
    [_pagingScrollView release], _pagingScrollView = nil;
    [_visiblePages release], _visiblePages = nil;
    [_recycledPages release], _recycledPages = nil;
    [_toolbar release], _toolbar = nil;
    [_previousButton release], _previousButton = nil;
    [_nextButton release], _nextButton = nil;
    self.progressHUD = nil;
    [super viewDidUnload];
}

#pragma mark - Appearance

- (void)viewWillAppear:(BOOL)animated {
  
  [[self.tabBarController tabBar] setHidden:YES];
  
    // Super
	[super viewWillAppear:animated];
  
  self.navigationController.navigationBar.hidden = YES;
  
  [[[self.navigationController.viewControllers objectAtIndex:(self.navigationController.viewControllers.count - 2)] navigationItem] setTitle:self.leftBarButtonCaption];

  [self updateNavigation];
  
  self.navigationController.navigationBar.translucent = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    
    // Check that we're being popped for good
    if ([self.navigationController.viewControllers objectAtIndex:0] != self &&
        ![self.navigationController.viewControllers containsObject:self]) {
        
        // State
        _viewIsActive = NO;
        
        // Bar state / appearance
        
    }
    
    // Controls
    [self.navigationController.navigationBar.layer removeAllAnimations]; // Stop all animations on nav bar
    [NSObject cancelPreviousPerformRequestsWithTarget:self]; // Cancel any pending toggles from taps
    [self setControlsHidden:NO animated:NO permanent:YES];
  
  
  [self.view.layer removeAllAnimations];
  
	// Super
	[super viewWillDisappear:animated];
  
  self.navigationController.navigationBar.translucent = NO;
}

- (void)viewDidAppear:(BOOL)animated {
  [super viewDidAppear:animated];
  _viewIsActive = YES;
  self.navigationController.navigationBar.hidden = NO;
  self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
}

#pragma mark - Layout

- (void)viewWillLayoutSubviews
{
    // Super
  if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"5")) [super viewWillLayoutSubviews];
	
	// Flag
	_performingLayout = YES;
	
	// Toolbar
	_toolbar.frame = [self frameForToolbarAtOrientation:self.interfaceOrientation];
	
	// Remember index
	NSUInteger indexPriorToLayout = _currentPageIndex;
	
	// Get paging scroll view frame to determine if anything needs changing
	CGRect pagingScrollViewFrame = [self frameForPagingScrollView];
    
	// Frame needs changing
	_pagingScrollView.frame = pagingScrollViewFrame;
	
	// Recalculate contentSize based on current orientation
	_pagingScrollView.contentSize = [self contentSizeForPagingScrollView];
	
	// Adjust frames and configuration of each visible page
	for (MWZoomingScrollView *page in _visiblePages) {
        NSUInteger index = PAGE_INDEX(page);
		page.frame = [self frameForPageAtIndex:index];
//        page.captionView.frame = [self frameForCaptionView:page.captionView atIndex:index];
		[page setMaxMinZoomScalesForCurrentBounds];
	}
	
	// Adjust contentOffset to preserve page location based on values collected prior to location
	_pagingScrollView.contentOffset = [self contentOffsetForPageAtIndex:indexPriorToLayout];
	[self didStartViewingPageAtIndex:_currentPageIndex]; // initial
    
	// Reset
	_currentPageIndex = indexPriorToLayout;
	_performingLayout = NO;
    
}

#pragma mark - Rotation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  if ( !self.descriptionViewController )
    return YES;
  else
    return [self.descriptionViewController shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

- (BOOL)shouldAutorotate
{
  if ( !self.descriptionViewController )
    return YES;
  else
    return [self.descriptionViewController shouldAutorotate];
}

- (NSUInteger)supportedInterfaceOrientations
{
  if ( !self.descriptionViewController )
    return UIInterfaceOrientationMaskAll;
  else
    return 0;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
  return UIInterfaceOrientationPortrait;
}



- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    
	// Remember page index before rotation
	_pageIndexBeforeRotation = _currentPageIndex;
	_rotating = YES;
	
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	// Perform layout
	_currentPageIndex = _pageIndexBeforeRotation;
    
	// Layout manually (iOS < 5)
    if (SYSTEM_VERSION_LESS_THAN(@"5")) [self viewWillLayoutSubviews];
	
	// Delay control holding
	[self hideControlsAfterDelay];
	
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	_rotating = NO;
}

#pragma mark - Data

- (void)reloadData {
    
    // Reset
    _photoCount = NSNotFound;
    
    // Get data
    NSUInteger numberOfPhotos = [self numberOfPhotos];
    [self releaseAllUnderlyingPhotos];
    [_photos removeAllObjects];
    for (int i = 0; i < numberOfPhotos; i++) [_photos addObject:[NSNull null]];
    
    // Update
    [self performLayout];
    
    // Layout
    [self.view setNeedsLayout];
    
}

- (NSUInteger)numberOfPhotos {
    if (_photoCount == NSNotFound) {
        if ([_delegate respondsToSelector:@selector(numberOfPhotosInPhotoBrowser:)]) {
            _photoCount = [_delegate numberOfPhotosInPhotoBrowser:self];
        } else if (_depreciatedPhotoData) {
            _photoCount = _depreciatedPhotoData.count;
        }
    }
    if (_photoCount == NSNotFound) _photoCount = 0;
    return _photoCount;
}

- (id<MWPhoto>)photoAtIndex:(NSUInteger)index {
    id <MWPhoto> photo = nil;
    if (index < _photos.count) {
        if ([_photos objectAtIndex:index] == [NSNull null]) {
            if ([_delegate respondsToSelector:@selector(photoBrowser:photoAtIndex:)]) {
                photo = [_delegate photoBrowser:self photoAtIndex:index];
            } else if (_depreciatedPhotoData && index < _depreciatedPhotoData.count) {
                photo = [_depreciatedPhotoData objectAtIndex:index];
            }
            if (photo) [_photos replaceObjectAtIndex:index withObject:photo];
        } else {
            photo = [_photos objectAtIndex:index];
        }
    }
    return photo;
}

- (MWCaptionView *)captionViewForPhotoAtIndex:(NSUInteger)index
{
  id <MWPhoto> photo = [self photoAtIndex:index];
  NSString *title = [[((MWPhoto *)photo).caption componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]] componentsJoinedByString:@" "];
  _uiTitleScroll.contentOffset = CGPointZero;
  _uiTitleScroll.title.text = title;
  [_uiTitleScroll setNeedsLayout];
  
  /// check whether we have description field -- iBuildApp
  NSString *szDescription = ((MWPhoto *)photo).description;
  if ( szDescription && [szDescription length] )
  {
    // if description... add info button if button doesn't exists
    if ( ![[_toolbar items] containsObject:_actionButton] )
    {
      NSMutableArray *items = [NSMutableArray arrayWithArray:[_toolbar items]];
      [items addObject:_actionButton];
      [_toolbar setItems:items animated:YES];
    }
  }else{
    // if no description... remove info button if button exists
    if ( [[_toolbar items] containsObject:_actionButton] )
    {
      NSMutableArray *items = [NSMutableArray arrayWithArray:[_toolbar items]];
      [items removeObject:_actionButton];
      [_toolbar setItems:items animated:YES];
    }
  }
  return nil;
}

- (UIImage *)imageForPhoto:(id<MWPhoto>)photo {
	if (photo) {
		// Get image or obtain in background
		if ([photo underlyingImage]) {
			return [photo underlyingImage];
		} else {
            [photo loadUnderlyingImageAndNotify];
		}
	}
	return nil;
}


- (void)loadAdjacentPhotosIfNecessary:(id<MWPhoto>)photo {
    MWZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        // If page is current page then initiate loading of previous and next pages
        NSUInteger pageIndex = PAGE_INDEX(page);
        if (_currentPageIndex == pageIndex) {
            if (pageIndex > 0) {
                // Preload index - 1
                id <MWPhoto> photo = [self photoAtIndex:pageIndex-1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                    MWLog(@"Pre-loading image at index %i", pageIndex-1);
                }
            }
            if (pageIndex < [self numberOfPhotos] - 1) {
                // Preload index + 1
                id <MWPhoto> photo = [self photoAtIndex:pageIndex+1];
                if (![photo underlyingImage]) {
                    [photo loadUnderlyingImageAndNotify];
                    MWLog(@"Pre-loading image at index %i", pageIndex+1);
                }
            }
        }
    }
}

#pragma mark - MWPhoto Loading Notification

- (void)handleMWPhotoLoadingDidEndNotification:(NSNotification *)notification {
    id <MWPhoto> photo = [notification object];
    MWZoomingScrollView *page = [self pageDisplayingPhoto:photo];
    if (page) {
        if ([photo underlyingImage]) {
            // Successful load
            [page displayImage];
            [self loadAdjacentPhotosIfNecessary:photo];
        } else {
            // Failed to load
            [page displayImageFailure];
        }
    }
}

#pragma mark - Paging

- (void)tilePages {
	
	// Calculate which pages should be visible
	// Ignore padding as paging bounces encroach on that
	// and lead to false page loads
	CGRect visibleBounds = _pagingScrollView.bounds;
	int iFirstIndex = (int)floorf((CGRectGetMinX(visibleBounds)+PADDING*2) / CGRectGetWidth(visibleBounds));
	int iLastIndex  = (int)floorf((CGRectGetMaxX(visibleBounds)-PADDING*2-1) / CGRectGetWidth(visibleBounds));
    if (iFirstIndex < 0) iFirstIndex = 0;
    if (iFirstIndex > [self numberOfPhotos] - 1) iFirstIndex = [self numberOfPhotos] - 1;
    if (iLastIndex < 0) iLastIndex = 0;
    if (iLastIndex > [self numberOfPhotos] - 1) iLastIndex = [self numberOfPhotos] - 1;
	
	// Recycle no longer needed pages
    NSInteger pageIndex;
	for (MWZoomingScrollView *page in _visiblePages) {
        pageIndex = PAGE_INDEX(page);
		if (pageIndex < (NSUInteger)iFirstIndex || pageIndex > (NSUInteger)iLastIndex) {
			[_recycledPages addObject:page];
            [page prepareForReuse];
			[page removeFromSuperview];
			MWLog(@"Removed page at index %i", PAGE_INDEX(page));
		}
	}
	[_visiblePages minusSet:_recycledPages];
    while (_recycledPages.count > 2) // Only keep 2 recycled pages
        [_recycledPages removeObject:[_recycledPages anyObject]];
	
	// Add missing pages
	for (NSUInteger index = (NSUInteger)iFirstIndex; index <= (NSUInteger)iLastIndex; index++) {
		if (![self isDisplayingPageForIndex:index]) {
            
            // Add new page
			MWZoomingScrollView *page = [self dequeueRecycledPage];
			if (!page) {
				page = [[[MWZoomingScrollView alloc] initWithPhotoBrowser:self] autorelease];
			}
      
			[self configurePage:page forIndex:index];
			[_visiblePages addObject:page];
			[_pagingScrollView addSubview:page];
			MWLog(@"Added page at index %i", index);
      
      [self captionViewForPhotoAtIndex:index];
		}
	}
	
}

- (BOOL)isDisplayingPageForIndex:(NSUInteger)index {
	for (MWZoomingScrollView *page in _visiblePages)
		if (PAGE_INDEX(page) == index) return YES;
	return NO;
}

- (MWZoomingScrollView *)pageDisplayedAtIndex:(NSUInteger)index {
	MWZoomingScrollView *thePage = nil;
	for (MWZoomingScrollView *page in _visiblePages) {
		if (PAGE_INDEX(page) == index) {
			thePage = page;
        //      thePage.bgColor = PGConnection.mPGColorOfBackground;
      thePage.bgColor = [UIColor blackColor];
      break;
		}
	}
	return thePage;
}

- (MWZoomingScrollView *)pageDisplayingPhoto:(id<MWPhoto>)photo {
	MWZoomingScrollView *thePage = nil;
	for (MWZoomingScrollView *page in _visiblePages) {
		if (page.photo == photo) {
			thePage = page;
        //      thePage.bgColor = PGConnection.mPGColorOfBackground;
      thePage.bgColor = [UIColor blackColor];
      break;
		}
	}
	return thePage;
}

- (void)configurePage:(MWZoomingScrollView *)page forIndex:(NSUInteger)index {
	page.frame = [self frameForPageAtIndex:index];
    page.tag = PAGE_INDEX_TAG_OFFSET + index;
    page.photo = [self photoAtIndex:index];
}

- (MWZoomingScrollView *)dequeueRecycledPage {
	MWZoomingScrollView *page = [_recycledPages anyObject];
	if (page) {
		[[page retain] autorelease];
		[_recycledPages removeObject:page];
	}
	return page;
}

// Handle page changes
- (void)didStartViewingPageAtIndex:(NSUInteger)index {
    
    // Release images further away than +/-1
    NSUInteger i;
    if (index > 0) {
        // Release anything < index - 1
        for (i = 0; i < index-1; i++) { 
            id photo = [_photos objectAtIndex:i];
            if (photo != [NSNull null]) {
                [photo unloadUnderlyingImage];
                [_photos replaceObjectAtIndex:i withObject:[NSNull null]];
                MWLog(@"Released underlying image at index %i", i);
            }
        }
    }
    if (index < [self numberOfPhotos] - 1) {
        // Release anything > index + 1
        for (i = index + 2; i < _photos.count; i++) {
            id photo = [_photos objectAtIndex:i];
            if (photo != [NSNull null]) {
                [photo unloadUnderlyingImage];
                [_photos replaceObjectAtIndex:i withObject:[NSNull null]];
                MWLog(@"Released underlying image at index %i", i);
            }
        }
    }
    
    // Load adjacent images if needed and the photo is already
    // loaded. Also called after photo has been loaded in background
    id <MWPhoto> currentPhoto = [self photoAtIndex:index];
  
    [self pageChangedWithPhoto:currentPhoto];
  
    if ([currentPhoto underlyingImage]) {
        // photo loaded so load ajacent now
        [self loadAdjacentPhotosIfNecessary:currentPhoto];
    }
    
}

#pragma mark - Frame Calculations

- (CGRect)frameForPagingScrollView {
  CGRect frame = [[UIScreen mainScreen] bounds];
  
  frame.origin.x -= PADDING;
  frame.size.width += (2 * PADDING);
  
  return frame;
}

- (CGRect)frameForPageAtIndex:(NSUInteger)index {
    // We have to use our paging scroll view's bounds, not frame, to calculate the page placement. When the device is in
    // landscape orientation, the frame will still be in portrait because the pagingScrollView is the root view controller's
    // view, so its frame is in window coordinate space, which is never rotated. Its bounds, however, will be in landscape
    // because it has a rotation transform applied.
    CGRect bounds = _pagingScrollView.bounds;
    CGRect pageFrame = bounds;
    pageFrame.size.width -= (2 * PADDING);
    pageFrame.origin.x = (bounds.size.width * index) + PADDING;
    return pageFrame;
}

- (CGSize)contentSizeForPagingScrollView {
    // We have to use the paging scroll view's bounds to calculate the contentSize, for the same reason outlined above.
    CGRect bounds = _pagingScrollView.bounds;
    return CGSizeMake(bounds.size.width * [self numberOfPhotos], bounds.size.height);
}

- (CGPoint)contentOffsetForPageAtIndex:(NSUInteger)index {
	CGFloat pageWidth = _pagingScrollView.bounds.size.width;
	CGFloat newOffset = index * pageWidth;
	return CGPointMake(newOffset, 0);
}

- (CGRect)frameForToolbarAtOrientation:(UIInterfaceOrientation)orientation {
    CGFloat height = 44;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone &&
        UIInterfaceOrientationIsLandscape(orientation)) height = 32;
	return CGRectMake(0, self.view.bounds.size.height - height, self.view.bounds.size.width, height);
}

- (CGRect)frameForCaptionView:(MWCaptionView *)captionView atIndex:(NSUInteger)index {
    CGRect pageFrame = [self frameForPageAtIndex:index];
    captionView.frame = CGRectMake(0, 0, pageFrame.size.width, 44); // set initial frame
    CGSize captionSize = [captionView sizeThatFits:CGSizeMake(pageFrame.size.width, 0)];
    CGRect captionFrame = CGRectMake(pageFrame.origin.x, pageFrame.size.height - captionSize.height - (_toolbar.superview?_toolbar.frame.size.height:0), pageFrame.size.width, captionSize.height);
    return captionFrame;
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
	
    // Checks
	if (!_viewIsActive || _performingLayout || _rotating) return;
	
	// Tile pages
	[self tilePages];
	
	// Calculate current page
	CGRect visibleBounds = _pagingScrollView.bounds;
	int index = (int)(floorf(CGRectGetMidX(visibleBounds) / CGRectGetWidth(visibleBounds)));
    if (index < 0) index = 0;
	if (index > [self numberOfPhotos] - 1) index = [self numberOfPhotos] - 1;
	NSUInteger previousCurrentPage = _currentPageIndex;
	_currentPageIndex = index;
	if (_currentPageIndex != previousCurrentPage) {
        [self didStartViewingPageAtIndex:index];
    }
	
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	// Hide controls when dragging begins
	[self setControlsHidden:YES animated:YES permanent:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	// Update nav when page changes
	[self updateNavigation];
}

#pragma mark - Navigation

- (void)updateNavigation {
    
	// Title
	if ([self numberOfPhotos] > 1) {
		self.title = [NSString stringWithFormat:@"%i %@ %i", _currentPageIndex+1, NSLocalizedString(@"core_photoBrowserOfString", @"of"), [self numberOfPhotos]];
	} else {
		self.title = nil;
	}
}

- (void)jumpToPageAtIndex:(NSUInteger)index {
	
	// Change page
	if (index < [self numberOfPhotos]) {
		CGRect pageFrame = [self frameForPageAtIndex:index];
		_pagingScrollView.contentOffset = CGPointMake(pageFrame.origin.x - PADDING, 0);
		[self updateNavigation];
	}
	
	// Update timer to give more time
	[self hideControlsAfterDelay];
	
}

- (void)gotoPreviousPage { [self jumpToPageAtIndex:_currentPageIndex-1]; }
- (void)gotoNextPage { [self jumpToPageAtIndex:_currentPageIndex+1]; }

#pragma mark - IB Side bar
-(NSArray *)actionsForIBSideBar
{
  IBSideBarModuleAction *sharePictureAction = [[[IBSideBarModuleAction alloc] init] autorelease];
  sharePictureAction.target = self;
  sharePictureAction.selector = @selector(showActionSelector);
  sharePictureAction.label = [self sharePictureSideBarActionLabel];
  
  return @[sharePictureAction];
}

-(NSString *)sharePictureSideBarActionLabel
{
  return NSLocalizedString(@"core_photoBrowserSideBarSaveAction", @"Save picture");
}

#pragma mark - Control Hiding / Showing

// If permanent then we don't set timers to hide again
- (void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent {
  
  if ([IBSideBarVC appWideSideBar].toggledState == IBSideBarToggledRightView)
    return;
  
    // Cancel any timers
    [self cancelControlHiding];
	
	// Animate
    if (animated) {
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.35];
    }
    CGFloat alpha = hidden ? 0 : 1;
	[self.navigationController.navigationBar setAlpha:alpha];
	[_toolbar setAlpha:alpha];
//    for (UIView *v in captionViews) v.alpha = alpha;
	if (animated) [UIView commitAnimations];
	
	// Control hiding timer
	// Will cancel existing timer but only begin hiding if
	// they are visible
	if (!permanent) [self hideControlsAfterDelay];
	
}

- (void)cancelControlHiding {
	// If a timer exists then cancel and release
	if (_controlVisibilityTimer) {
		[_controlVisibilityTimer invalidate];
		[_controlVisibilityTimer release];
		_controlVisibilityTimer = nil;
	}
}

// Enable/disable control visiblity timer
- (void)hideControlsAfterDelay {
	if (![self areControlsHidden]) {
        [self cancelControlHiding];
		_controlVisibilityTimer = [[NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(hideControls) userInfo:nil repeats:NO] retain];
	}
}

- (BOOL)areControlsHidden { return (_toolbar.alpha == 0); /* [UIApplication sharedApplication].isStatusBarHidden; */ }
- (void)hideControls { [self setControlsHidden:YES animated:YES permanent:NO]; }
- (void)toggleControls { [self setControlsHidden:![self areControlsHidden] animated:YES permanent:NO]; }

#pragma mark - Properties

- (void)setInitialPageIndex:(NSUInteger)index {
    // Validate
    if (index >= [self numberOfPhotos]) index = [self numberOfPhotos]-1;
    _currentPageIndex = index;
	if ([self isViewLoaded]) {
        [self jumpToPageAtIndex:index];
        if (!_viewIsActive) [self tilePages]; // Force tiling if view is not visible
    }
}

-(UIToolbar *)toolBar
{
  return _toolbar;
}

#pragma mark - Misc

- (void)doneButtonPressed:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

-(void)closeInfo
{
  self.navigationController.navigationBar.userInteractionEnabled = YES;

  [UIView animateWithDuration:0.5
                   animations:^{
                     CATransition *animation = [CATransition animation];
                     [animation setDelegate:self];
                     [animation setDuration:0.5];
                     [animation setTimingFunction:UIViewAnimationCurveEaseInOut];
                     animation.type = @"pageUnCurl";
                     animation.fillMode = kCAFillModeForwards;
                     animation.startProgress = 1.f - PAGE_DESCRIPTION_CURL_OFFSET;
                     [animation setRemovedOnCompletion:NO];
                     [self.view.layer addAnimation:animation forKey:@"pageUnCurlAnimation"];
                     
                     [self.descriptionViewController viewWillDisappear:NO];
                     [[self.descriptionViewController view] removeFromSuperview];
                     [self.descriptionViewController viewDidDisappear:NO];
                     self.descriptionViewController = nil;
                     ;}
   ];
}

- (void)actionButtonPressed:(id)sender
{
  id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
  ///----------------------------------------------------------------------------
  [self.descriptionViewController viewWillDisappear:NO];
  [[self.descriptionViewController view] removeFromSuperview];
  [self.descriptionViewController viewDidDisappear:NO];
  ///----------------------------------------------------------------------------
  self.descriptionViewController = [[[MWDescriptionViewController alloc] initWithNibName:nil bundle:nil] autorelease];
  [self.descriptionViewController.view setFrame:self.view.bounds];
  [self.descriptionViewController.view setAutoresizesSubviews:YES];
  [self.descriptionViewController.view setAutoresizingMask:UIViewAutoresizingFlexibleWidth |
                                                           UIViewAutoresizingFlexibleHeight];
  ///----------------------------------------------------------------------------
  self.descriptionViewController.description = [photo description] ? [photo description] : @"";
  [self.descriptionViewController.infoButton addTarget:self
                                                action:@selector(closeInfo)
                                      forControlEvents:UIControlEventTouchUpInside];
  /// add swipe gesture handler -- iBuildApp
  UISwipeGestureRecognizer *downSwipeRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                                              action:@selector(closeInfo)] autorelease];
  [downSwipeRecognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
  [self.descriptionViewController.view addGestureRecognizer:downSwipeRecognizer];
  
  /// modify "info" button tap handler for MWDescriptionViewController --iBuildApp
  self.navigationController.navigationBar.userInteractionEnabled = NO;

  [UIView animateWithDuration:0.5
                   animations:^{
                     CATransition *animation = [CATransition animation];
                     [animation setDelegate:self];
                     [animation setDuration:0.5];
                     [animation setTimingFunction:UIViewAnimationCurveEaseInOut];
                     animation.type = @"pageCurl";
                     animation.fillMode = kCAFillModeForwards;
                     animation.endProgress = PAGE_DESCRIPTION_CURL_OFFSET;
                     [animation setRemovedOnCompletion:NO];
                     [self.view.layer addAnimation:animation forKey:@"pageCurlAnimation"];
                     [self.descriptionViewController viewWillAppear:NO];
                     [self.view addSubview:self.descriptionViewController.view];
                     [self.descriptionViewController viewDidAppear:NO];
                     }
   ];
}

#pragma mark applicationDidEnterBackground
- (void)applicationDidEnterBackground
{
  self.navigationController.navigationBar.userInteractionEnabled = YES;
  [self.descriptionViewController viewWillDisappear:NO];
  [[self.descriptionViewController view] removeFromSuperview];
  [self.descriptionViewController viewDidDisappear:NO];
  self.descriptionViewController = nil;
}



#pragma mark - Action Sheet Delegate

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (actionSheet == _actionsSheet) {           
        // Actions 
        self.actionsSheet = nil;
        if (buttonIndex != actionSheet.cancelButtonIndex) {
            if (buttonIndex == actionSheet.firstOtherButtonIndex) {
                [self savePhoto]; return;
            } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 1) {
                [self copyPhoto]; return;	
            } else if (buttonIndex == actionSheet.firstOtherButtonIndex + 2) {
                [self emailPhoto]; return;
            }
        }
    }
    [self hideControlsAfterDelay]; // Continue as normal...
}

#pragma mark - MBProgressHUD

- (MBProgressHUD *)progressHUD {
    if (!_progressHUD) {
        _progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        _progressHUD.minSize = CGSizeMake(120, 120);
        _progressHUD.minShowTime = 1;
        // The sample image is based on the
        // work by: http://www.pixelpressicons.com
        // licence: http://creativecommons.org/licenses/by/2.5/ca/
        self.progressHUD.customView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"MWPhotoBrowser.bundle/images/Checkmark.png"]] autorelease];
        [self.view addSubview:_progressHUD];
    }
    return _progressHUD;
}

- (void)showProgressHUDWithMessage:(NSString *)message {
    self.progressHUD.labelText = message;
    self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    [self.progressHUD show:YES];
    self.navigationController.navigationBar.userInteractionEnabled = NO;
}

- (void)hideProgressHUD:(BOOL)animated {
    [self.progressHUD hide:animated];
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

- (void)showProgressHUDCompleteMessage:(NSString *)message {
    if (message) {
        if (self.progressHUD.isHidden) [self.progressHUD show:YES];
        self.progressHUD.labelText = message;
        self.progressHUD.mode = MBProgressHUDModeCustomView;
        [self.progressHUD hide:YES afterDelay:1.5];
    } else {
        [self.progressHUD hide:YES];
    }
    self.navigationController.navigationBar.userInteractionEnabled = YES;
}

#pragma mark - Actions

- (void)savePhoto {
    id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"core_photoBrowserSavingMessage", @"Saving")]];
        [self performSelector:@selector(actuallySavePhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallySavePhoto:(id<MWPhoto>)photo {
    if ([photo underlyingImage]) {
        UIImageWriteToSavedPhotosAlbum([photo underlyingImage], self, 
                                       @selector(image:didFinishSavingWithError:contextInfo:), nil);
    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    [self showProgressHUDCompleteMessage: error ? NSLocalizedString(@"core_photoBrowserFailedMessage", @"Failed") : NSLocalizedString(@"core_photoBrowserSavedMessage", @"Saved")];
    [self hideControlsAfterDelay]; // Continue as normal...
}

- (void)copyPhoto {
    id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"core_photoBrowserCopyingMessage", @"Copying")]];
        [self performSelector:@selector(actuallyCopyPhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallyCopyPhoto:(id<MWPhoto>)photo {
    if ([photo underlyingImage]) {
        [[UIPasteboard generalPasteboard] setData:UIImagePNGRepresentation([photo underlyingImage])
                                forPasteboardType:@"public.png"];
        [self showProgressHUDCompleteMessage:NSLocalizedString(@"core_photoBrowserCopiedMessage", @"Copied")];
        [self hideControlsAfterDelay]; // Continue as normal...
    }
}

- (void)emailPhoto {
    id <MWPhoto> photo = [self photoAtIndex:_currentPageIndex];
    if ([photo underlyingImage]) {
        [self showProgressHUDWithMessage:[NSString stringWithFormat:@"%@\u2026" , NSLocalizedString(@"core_photoBrowserPreparingMessage", @"Preparing")]];
        [self performSelector:@selector(actuallyEmailPhoto:) withObject:photo afterDelay:0];
    }
}

- (void)actuallyEmailPhoto:(id<MWPhoto>)photo {
    if ([photo underlyingImage]) {
        MFMailComposeViewController *emailer = [[MFMailComposeViewController alloc] init];
        emailer.mailComposeDelegate = self;
        [emailer setSubject:NSLocalizedString(@"core_photoBrowserPhotoString", @"Photo")];
        [emailer addAttachmentData:UIImagePNGRepresentation([photo underlyingImage]) mimeType:@"png" fileName:@"Photo.png"];
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            emailer.modalPresentationStyle = UIModalPresentationPageSheet;
        }
        [self presentModalViewController:emailer animated:YES];
        [emailer release];
        [self hideProgressHUD:NO];
    }
}

#pragma mark Mail Compose Delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    if (result == MFMailComposeResultFailed) {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"core_photoBrowserEmailAlertTitle", @"Email")
                                                         message:NSLocalizedString(@"core_photoBrowserEmailAlertMessage", @"Email failed to send. Please try again.")
                                                        delegate:nil cancelButtonTitle:NSLocalizedString(@"core_photoBrowserEmailAlertDismissButtonTitle", @"Dismiss") otherButtonTitles:nil] autorelease];
		[alert show];
    }
	[self dismissModalViewControllerAnimated:YES];
}

-(void)pageChangedWithPhoto:(id <MWPhoto>)photo
{
  //To be implemented in descendants
}

@end