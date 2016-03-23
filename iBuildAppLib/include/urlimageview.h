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

#import <UIKit/UIKit.h>
#import "downloadindicator.h"

typedef enum {
  
  /** 
   * Completely fill the image widget (image proportions are ignored).
   */
  ContentModeScaleToFill     = UIViewContentModeScaleToFill,
  
  /** 
   * Scale image with the original aspect ratio, the image is scaled in the framework of the widget.
   */
  ContentModeScaleAspectFit  = UIViewContentModeScaleAspectFit,
  
  /** 
   * Scale image with the original aspect ratio, image fills widget completely, the rest is cut off.
   */
  ContentModeScaleAspectFill = UIViewContentModeScaleAspectFill,
  
  /** 
   * The image does not change its size, changing only its location inside the widget.
   */
  ContentModeCenter          = UIViewContentModeCenter,
  ContentModeTop             = UIViewContentModeTop,
  ContentModeBottom          = UIViewContentModeBottom,
  ContentModeLeft            = UIViewContentModeLeft,
  ContentModeRight           = UIViewContentModeRight,
  ContentModeTopLeft         = UIViewContentModeTopLeft,
  ContentModeTopRight        = UIViewContentModeTopRight,
  ContentModeBottomLeft      = UIViewContentModeBottomLeft,
  ContentModeBottomRight     = UIViewContentModeBottomRight,
  
  /** 
   * Use an image as the background fill.
   */
  ContentModePatternTiled,
  
  /** 
   * The image is stretched from the center (the angles remain the same, just stretched the central pixel).
   */
  ContentModeStretchableFromCenter,
}TImageMode;

@interface TURLImageView : TDownloadIndicator
{
  /** 
   * Component for displaying pictures.
   */
  UIImageView      *m_imageView;
  
  /** 
   * Image description.
   */
  NSString         *m_description;
  
  /** 
   * MIME type.
   */
  NSString         *m_imgType;
  
  /** 
   * Preview size.
   */
  CGSize            m_thumbSize;
  
  /** 
   * Image display mode.
   */
  TImageMode        m_mode;
  
  /** 
   * Whether to show the default image (default - no).
   */
  BOOL              m_bShowDefaultImage;
  
  /** 
   * Generate or not a small copy of the loaded image.
   */
  BOOL              bThumbnail;
  
  /** 
   * Save or not a small copy of the loaded image.
   */
  BOOL              bSaveThumbs;
}


@property (nonatomic, copy  )   NSString    *description;
@property (nonatomic, readonly) UIImageView *imageView;
@property (nonatomic, assign, getter = isGenerateThumbnail,
                              setter = generateThumbnail:) BOOL bThumbnail; 
@property (nonatomic, assign) CGSize thumbnailSize;
@property (nonatomic, assign, getter = isSaveThumbnail,
              setter = saveThumbnail:) BOOL bSaveThumbs; 

@property (nonatomic, assign) BOOL showDefaultImage;
@property (nonatomic, assign) TImageMode mode;

-(id)initWithFrame:(CGRect)frame
    andDescription:(NSString *)description_;

-(void)showDefaultImage:(BOOL)bShow_;

-(void)setImage:(UIImage *)image_
       withMode:(TImageMode)mode_;

@end
