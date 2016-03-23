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
 * NSString truncation category.
 */
@interface NSString (truncation)

 /**
  * Deletes the newline and spaces at beginning of line and end of line
  */
  -(NSString *)truncate;

  -(NSString *)stringByReplaceCharacterSet:(NSCharacterSet *)characterset
                                withString:(NSString *)string_;

@end
