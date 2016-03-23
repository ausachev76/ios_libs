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

#import "MessagesInput.h"

@implementation MessagesInput

- (void) composeView {
   
   CGSize size = self.frame.size;
  
   // Input
  _inputBackgroundView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];

	_inputBackgroundView.autoresizingMask = UIViewAutoresizingNone;
 _inputBackgroundView.contentMode = UIViewContentModeScaleToFill;

	[self addSubview:_inputBackgroundView];
  [_inputBackgroundView release];
  
  
	// Text field
	_textView = [[UITextView alloc] initWithFrame:CGRectMake(70.0f, 0, 185, 0)];
	_textView.delegate = self;
  _textView.contentInset = UIEdgeInsetsMake(-4, -2, -4, 0);
  _textView.showsVerticalScrollIndicator = NO;
  _textView.showsHorizontalScrollIndicator = NO;
  _textView.font = [UIFont systemFontOfSize:15.0f];
	[self addSubview:_textView];
  [_textView release];

  [self adjustTextInputHeightForText:@"" animated:NO];

  _textViewPlaceholder = [[UILabel alloc] initWithFrame:CGRectMake(78.0f, 14, 160, 20)];
  _textViewPlaceholder.font = [UIFont systemFontOfSize:15.0f];
  _textViewPlaceholder.backgroundColor = [UIColor clearColor];
	[self addSubview:_textViewPlaceholder];
  [_textViewPlaceholder release];

// Send button
  _sendButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
  _sendButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
  [_sendButton addTarget:self action:@selector(sendButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
  [self addSubview:_sendButton];
  [_sendButton release];

   [self sendSubviewToBack:_inputBackgroundView];
}

- (void) awakeFromNib {
   
   _inputHeight = 38.0f;
   _inputHeightWithShadow = 44.0f;
   _autoResizeOnKeyboardVisibilityChanged = YES;

   [self composeView];
}

- (void) adjustTextInputHeightForText:(NSString*)text animated:(BOOL)animated {
   
   int h1 = [text sizeWithFont:_textView.font].height;
   int h2 = [text sizeWithFont:_textView.font
             constrainedToSize:CGSizeMake(_textView.frame.size.width - 16, 170.0f)
                 lineBreakMode:NSLineBreakByWordWrapping].height;

   [UIView animateWithDuration:(animated ? .1f : 0) animations:^
    {
       int h = h2 == h1 ? _inputHeightWithShadow : h2 + 24;
       int delta = h - self.frame.size.height;
       CGRect r2 = CGRectMake(0, self.frame.origin.y - delta, self.frame.size.width, h);
       self.frame = r2;
       _inputBackgroundView.frame = CGRectMake(0, 0, self.frame.size.width, h);
       
       CGRect r = _textView.frame;
       r.origin.y = 12;
       r.size.height = h - 18;
       _textView.frame = r;
       
    } completion:^(BOOL finished)
    {
      
    }];
}

- (id) initWithFrame:(CGRect)frame {
   
   self = [super initWithFrame:frame];
   
   if (self)
   {
      _inputHeight = 38.0f;
      _inputHeightWithShadow = 44.0f;
      _autoResizeOnKeyboardVisibilityChanged = YES;
      
      [self composeView];
   }
   return self;
}

- (void) fitText {
   
   [self adjustTextInputHeightForText:_textView.text animated:YES];
}

- (void) setText:(NSString*)text {
   
   _textView.text = text;
   _textViewPlaceholder.hidden = text.length > 0;
   [self fitText];
}


#pragma mark UITextFieldDelegate Delegate

- (void) textViewDidBeginEditing:(UITextView*)textView {
   
   if (_autoResizeOnKeyboardVisibilityChanged)
   {
      [UIView animateWithDuration:.25f animations:^{
         CGRect r = self.frame;
         r.origin.y -= 216;
         [self setFrame:r];
      }];
      [self fitText];
   }
   if ([_delegate respondsToSelector:@selector(textViewDidBeginEditing:)])
      [_delegate performSelector:@selector(textViewDidBeginEditing:) withObject:textView];
}

- (void) textViewDidEndEditing:(UITextView*)textView {
   
   if (_autoResizeOnKeyboardVisibilityChanged)
   {
      [UIView animateWithDuration:.25f animations:^{
         CGRect r = self.frame;
         r.origin.y += 216;
         [self setFrame:r];
      }];
      
      [self fitText];
   }
   _textViewPlaceholder.hidden = _textView.text.length > 0;
   
   if ([_delegate respondsToSelector:@selector(textViewDidEndEditing:)])
      [_delegate performSelector:@selector(textViewDidEndEditing:) withObject:textView];
}

- (BOOL) textView:(UITextView*)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString*)text {
   
   if ([text isEqualToString:@"\n"])
   {
      if ([_delegate respondsToSelector:@selector(returnButtonPressed:)])
         [_delegate performSelector:@selector(returnButtonPressed:) withObject:_textView afterDelay:.1];
      return NO;
   }
   else if (text.length > 0)
   {
      [self adjustTextInputHeightForText:[NSString stringWithFormat:@"%@%@", _textView.text, text] animated:YES];
   }
   return YES;
}

- (void) textViewDidChange:(UITextView*)textView {
   
    _textViewPlaceholder.hidden = _textView.text.length > 0;
   
   [self fitText];
   
   if ([_delegate respondsToSelector:@selector(textViewDidChange:)])
      [_delegate performSelector:@selector(textViewDidChange:) withObject:textView];
}


#pragma mark MessagesInput Delegate

- (void) sendButtonPressed:(id)sender {
   
   if ([_delegate respondsToSelector:@selector(sendButtonPressed:)])
      [_delegate performSelector:@selector(sendButtonPressed:) withObject:sender];
}


@end
