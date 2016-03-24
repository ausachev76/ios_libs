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

#import "MWPhotoTitle.h"

@implementation MWPhotoTitle
@synthesize title = _title;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
      _title = [[UILabel alloc] initWithFrame:CGRectMake(0,0,frame.size.width, frame.size.height)];
      _title.autoresizesSubviews = YES;
      _title.autoresizingMask    = UIViewAutoresizingNone;
      _title.textAlignment       = NSTextAlignmentCenter;
      
      [self setShowsHorizontalScrollIndicator:NO];
      [self setShowsVerticalScrollIndicator:NO];
      self.autoresizesSubviews  = YES;
      self.contentSize          = CGSizeZero;
      self.contentOffset        = CGPointZero;
      self.alwaysBounceVertical = NO;
      [self addSubview:_title];
    }
    return self;
}

-(void)dealloc
{
  [_title release];
  [super dealloc];
}

-(void)layoutSubviews
{
  [super layoutSubviews];
  CGSize textSize = [_title.text sizeWithFont:_title.font];

  if ( textSize.width < self.frame.size.width )
  {
    textSize = CGSizeMake( self.frame.size.width, textSize.height );
  }
  self.contentSize = textSize;
  _title.frame = CGRectMake(0,0,textSize.width, self.frame.size.height);
}


@end
