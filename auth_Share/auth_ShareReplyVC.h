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

/**
 * View Controller with a text view to type and submit a message for sharing.
 */
@interface auth_ShareReplyVC : UIViewController<UITextViewDelegate>

  /**
   * Text view to type a text.
   */
  @property (nonatomic, readonly, strong) UITextView       *textView;

 /**
  * Auxiliary data to pass along the ReplyVC.
  */
  @property (nonatomic, strong)    NSMutableDictionary     *data;

 /**
  * You can set maxLettersCount to 140 to fit the twitter format
  * Defaults to  NSIntegerMax
  */
  @property (nonatomic) NSInteger maxMessageLength;

@end
