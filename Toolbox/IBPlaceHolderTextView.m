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

#import "IBPlaceHolderTextView.h"


#define kTextInsetY 8.f
#define kTextInsetX 8.f

#define kTextInsetY_iOS7 8.f
#define kTextInsetX_iOS7 5.f

#define kPlaceholderHideSpeed 0.2f

@implementation IBPlaceHolderTextView
@synthesize placeholder = _placeholder;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
      _placeholder = nil;
      
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(textChanged:)
                                                   name:UITextViewTextDidChangeNotification
                                                 object:nil];
    }
    return self;
}

-(void)dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UITextViewTextDidChangeNotification
                                                object:nil];
  if ( _placeholder )
  {
    [_placeholder removeFromSuperview];
    [_placeholder release];
  }
  [super dealloc];
}

-(void)setFont:(UIFont *)font_
{
  [super setFont:font_];
  _placeholder.font = font_;
}


-(CGRect)placeholderFrameForRect:(CGRect)frm
{
  CGRect labelFrm = CGRectMake( frm.origin.x  + kTextInsetX,
                                frm.origin.y  + kTextInsetY,
                                frm.size.width - kTextInsetX * 2.f,
                                frm.size.height - kTextInsetY * 2.f );
#ifdef __IPHONE_7_0
  if( floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_6_1 )
  {
    labelFrm = CGRectMake( frm.origin.x  + kTextInsetX_iOS7,
                           frm.origin.y  + kTextInsetY_iOS7,
                           frm.size.width - kTextInsetX_iOS7 * 2.f,
                           frm.size.height - kTextInsetY_iOS7 * 2.f );
  }
#endif
  
  CGSize maximumLabelSize = labelFrm.size;
  
  CGSize expectedLabelSize = [_placeholder.text sizeWithFont:_placeholder.font
                                           constrainedToSize:maximumLabelSize
                                               lineBreakMode:_placeholder.lineBreakMode];
  
  CGFloat maxHeight = ceilf(_placeholder.font.lineHeight * _placeholder.numberOfLines);
  
  CGFloat labelHeight = !_placeholder.numberOfLines ?
                              ceilf(expectedLabelSize.height) :
                              MIN( ceilf(expectedLabelSize.height), maxHeight );
  
  labelFrm.size.height = labelHeight;
  
  return labelFrm;
}

-(UILabel *)placeholder
{
  if ( !_placeholder )
  {
    _placeholder = [[UILabel alloc] initWithFrame:CGRectZero];
    _placeholder.text            = @"";
    _placeholder.font            = self.font;
    _placeholder.lineBreakMode   = NSLineBreakByWordWrapping;
    _placeholder.numberOfLines   = 0;
    _placeholder.backgroundColor = [UIColor clearColor];
    _placeholder.textColor       = [UIColor lightGrayColor];
    _placeholder.textAlignment   = NSTextAlignmentLeft;
    _placeholder.autoresizesSubviews = YES;
    _placeholder.autoresizingMask    = UIViewAutoresizingFlexibleWidth;
    _placeholder.adjustsFontSizeToFitWidth = NO;
    _placeholder.hidden              = [[self text] length] != 0;
    [self addSubview:_placeholder];
  }
  return _placeholder;
}

- (void)setText:(NSString *)text
{
  [super setText:text];
  [self textChanged:nil];
}

-(void)hidePlaceholder:(BOOL)bHide animated:(BOOL)animated
{
  if ( animated )
  {
    if ( bHide )
    {
      [UIView animateWithDuration:kPlaceholderHideSpeed
                       animations:^{
                         _placeholder.alpha = 0.f;
                       } completion:^(BOOL finished) {
                         [_placeholder setHidden:bHide];
                       }];
    }else{
      [_placeholder setHidden:bHide];
      [UIView animateWithDuration:kPlaceholderHideSpeed
                       animations:^{
                         _placeholder.alpha = 1.f;
                       } completion:^(BOOL finished) {
                       }];
    }
  }else{
    [_placeholder setHidden:bHide];
  }
}

- (void)textChanged:(NSNotification *)notification
{
  if( ![_placeholder.text length] )
    return;
  
  [self hidePlaceholder:([[self text] length] != 0) animated:YES];
}

-(void)layoutSubviews
{
  [super layoutSubviews];
  
  if ( [_placeholder isHidden] || ![_placeholder.text length] )
    return;
  
  _placeholder.frame = [self placeholderFrameForRect:self.bounds];
}

@end
