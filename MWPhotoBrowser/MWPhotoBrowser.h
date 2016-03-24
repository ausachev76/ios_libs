//
//  MWPhotoBrowser.h
//  MWPhotoBrowser
//
//  Created by Michael Waterfall on 14/10/2010.
//  Copyright 2010 d3i. All rights reserved.
//

// Modified by iBuildApp

#import <UIKit/UIKit.h>
#import <MessageUI/MessageUI.h>
#import "MWPhoto.h"
#import "MWPhotoProtocol.h"
#import "MWCaptionView.h"

// Debug Logging
#if 0 // Set to 1 to enable debug logging
#define MWLog(x, ...) NSLog(x, ## __VA_ARGS__);
#else
#define MWLog(x, ...)
#endif

// Delgate
@class MWPhotoBrowser;
@protocol MWPhotoBrowserDelegate <NSObject>
- (NSUInteger)numberOfPhotosInPhotoBrowser:(MWPhotoBrowser *)photoBrowser;
- (id<MWPhoto>)photoBrowser:(MWPhotoBrowser *)photoBrowser photoAtIndex:(NSUInteger)index;
@optional
- (MWCaptionView *)photoBrowser:(MWPhotoBrowser *)photoBrowser captionViewForPhotoAtIndex:(NSUInteger)index;
@end

// MWPhotoBrowser
@interface MWPhotoBrowser : UIViewController <UIScrollViewDelegate, UIActionSheetDelegate, MFMailComposeViewControllerDelegate, UIActionSheetDelegate> {
  NSUInteger _currentPageIndex;
}

// Properties
@property (nonatomic) BOOL displayActionButton;

@property (nonatomic) BOOL bSavePicture;

@property (nonatomic, copy  ) NSString      *leftBarButtonCaption;


// Init
- (id)initWithPhotos:(NSArray *)photosArray  __attribute__((deprecated)); // Depreciated
- (id)initWithDelegate:(id <MWPhotoBrowserDelegate>)delegate;

// Reloads the photo browser and refetches data
- (void)reloadData;

// Set page that photo browser starts on
- (void)setInitialPageIndex:(NSUInteger)index;

-(UIToolbar *)toolBar;

-(void)pageChangedWithPhoto:(id <MWPhoto>)photo;

-(void)setControlsHidden:(BOOL)hidden animated:(BOOL)animated permanent:(BOOL)permanent;


@end


