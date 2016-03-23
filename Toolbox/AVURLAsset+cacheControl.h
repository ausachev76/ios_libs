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

#import <AVFoundation/AVFoundation.h>

/**
 * Extension of the class for the correct operation of the system caching on iOS7
 * Issue has been identified on iOS7: if NSURLCache overloaded and is set as default cache system,
 * calling (loadValuesAsynchronouslyForKeys:completionHandler:) of AVURLAsset object
 * going to crush.
 * This extension is intended to bypass the error.
 */
@interface AVURLAsset (cacheControl)
  +(void)swizzleAVURLAsset;
@end
