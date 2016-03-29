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
#import "urlloader.h"

/**
 * Class to perform downloading of images from a specified URL
 * allows access to the images or if it is already loaded
 * or returns an object of type URLImageView, all objects are stored in the memory
 * the list is intended to speed up the system type display grid view.
 */
@interface TThumbnailArray : NSObject<IURLLoaderDelegate>
{
  /**
   * List url address to download the image.
   */
  NSMutableArray *m_urlList;
  
  /**
   * List of objects of type UIImage or URLImageView
   */
  NSMutableArray *m_imgList;
}

-(void)startDownload;

-(id)initWithImageList:(NSArray *)imageList_;

-(void)appendImageLink:(NSString *)imgLink_;

-(id)objectAtIndex:(NSUInteger)index_;

@property (nonatomic, assign) CGSize                           thumbnailSize;
@property (nonatomic, assign) UIViewContentMode                contentMode;
@property (nonatomic, readonly, getter = getCount) NSUInteger  count;



@end
