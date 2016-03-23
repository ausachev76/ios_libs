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

@class NSString;

@interface NSString (html)

  -(NSString *)htmlToText;

  -(NSString *)htmlToTextFast;

  /**
   * This method differs from htmlToText in interpreting <br>s as new line characters.
   */
  -(NSString *)htmlToNewLinePreservingText;

  -(NSString *)htmlToNewLinePreservingTextFast;

@end
