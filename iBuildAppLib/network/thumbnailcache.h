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

@interface TThumbnailCache : NSObject
{
  NSMutableDictionary  *m_cache;
  NSFileHandle         *m_fileHandle;
  dispatch_queue_t      m_queue;
}

+(TThumbnailCache*) instance;

+(NSURL *)path;

+(NSString *)cacheDir;

-(NSURL *)getCachedURL:(NSURL *)url_;

-(NSURL *)getCachedURL:(NSURL *)url_
              withSize:(CGSize)size_;

-(BOOL)saveThumbnail:(UIImage *)img_
             withURL:(NSURL *)url_
                type:(NSString *)type_;
@end
