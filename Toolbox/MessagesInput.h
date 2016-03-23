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

@interface MessagesInput : UIView <UITextViewDelegate>

@property (assign) IBOutlet id delegate;

@property (assign) int  inputHeight;
@property (assign) int  inputHeightWithShadow;
@property (assign) BOOL autoResizeOnKeyboardVisibilityChanged;

@property (strong, nonatomic) UIButton    *sendButton;
@property (strong, nonatomic) UITextView  *textView;
@property (strong, nonatomic) UILabel     *textViewPlaceholder;
@property (strong, nonatomic) UIView      *inputBackgroundView;

- (void)fitText;

- (void)setText:(NSString *)text;

@end