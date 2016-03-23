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

/**
 * Extension class for including NSHTTPURLResponse to have the opportunity to
 * work with NSDictionary through case insensetive keys that are essential in the analysis
 * of the http headers.
 */
@interface NSHTTPURLResponse (caseInsensitiveAdditions)

- (NSDictionary *)caseInsensitiveHTTPHeaders;

@end
