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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "urlloader.h"

@interface TURLImageDescriptor : NSObject

  /**
   * Alternative image data to be used in the event that
   * main image upload failed.
   */
  @property (nonatomic, strong)  NSData   *alterImageData;

  /**
   * Object available for display (image or urlLoader)
   */
  @property (nonatomic, strong)  id        obj;

  -(id) initWithObject:(id)obj_
        alterImageData:(NSData *)alterData_;
@end

/**
 * Class to perform downloading of images from a specified URL
 * allows access to the images or if it is already loaded
 * or returns an object of type URLImageView, all objects are stored in the memory
 * list for bulk upload images interface elements.
 */
@interface TURLImageDictionary : NSObject<IURLLoaderDelegate>
{
  NSMutableDictionary *m_imageDictionary;
  NSUInteger           m_count;
  NSMutableArray      *m_delegatesList;
  BOOL                 m_bBeginRequest;
  BOOL                 m_bBeginDownload;
}


-(BOOL)addDelegate:(id <IURLLoaderDelegate>)delegate;

-(BOOL)removeDelegate:(id <IURLLoaderDelegate>)delegate;

-(void)startDownload;

-(id)initWithImageList:(NSArray *)imageList_;

-(void)appendImageLink:(NSString *)imgLink_;

-(void)appendImageLink:(NSString *)imgLink_
    withAlterImageData:(NSData *)alterImageData_;

-(void)setImage:(UIImage *)image_ forKey:(NSString *)key_;

-(id)objectForKey:(NSString *)key_;

-(NSArray *)allKeys;

-(NSArray *)allValues;

-(void)removeAllObjects;

-(TURLImageDescriptor *)valueForKey:(NSString *)key_;

@property (nonatomic, assign) CGSize                           thumbnailSize;
@property (nonatomic, assign) UIViewContentMode                contentMode;
@property (nonatomic, readonly, getter = getCount) NSUInteger  count;
@property (nonatomic, readonly ) NSMutableArray               *delegatesList;

@end
