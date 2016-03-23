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

@interface TDownloadIndicator : UIView <IURLLoaderDelegate>
{
  @private
    UIView                   *m_bigLockView;
    UIView                   *m_smallLockView;
    UIActivityIndicatorView  *m_activityIndicator;
    UIProgressView           *m_progressIndicator;
    UILabel                  *m_progressVolume;
    TURLLoader               *m_pLoader;
    BOOL                      m_bEnabled;
    NSUInteger                m_progressCounter;
}

@property (nonatomic, readonly) TURLLoader *urlLoader;
@property (nonatomic, assign  ) BOOL        enabled;
@property (nonatomic, readonly) UIView     *bigLockView;
@property (nonatomic, readonly) UIView     *smallLockView;


-(void)setProgressValue:(double_t)loadProgress;
-(void)startLockViewAnimating:(BOOL)bStart_;
-(void)createViews;
-(void)removeFromURLloader;

@end


