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

#import "IBSequencePhotoScrollView.h"

@interface UIView(hide)
  -(void)setHidden:(BOOL)hidden animated:(BOOL)animated;
@end

@implementation UIView(hide)

-(void)setHidden:(BOOL)hidden animated:(BOOL)animated
{
  if ( self.hidden == hidden )
    return;

  if ( !animated )
  {
    [self setHidden:hidden];
    return;
  }
  
  CGFloat alpha = hidden ? 0.f : 1.f;
  
  if ( !hidden )
    [self setHidden:hidden];
  
  [UIView animateWithDuration:0.3f
                        delay:0.f
                      options:UIViewAnimationOptionCurveLinear
                   animations:^{
                     self.alpha = alpha;
                   } completion:^(BOOL finished){
                     if ( hidden )
                       [self setHidden:hidden];
                   }];
  
}

@end


@implementation IBSequencePhotoScrollView
@synthesize photoScrollView = _photoScrollView,
                 leftButton = _leftButton,
                rightButton = _rightButton,
              controlsInset = _controlsInset;

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if ( self )
  {
    _photoScrollView = nil;
    _leftButton      = nil;
    _rightButton     = nil;
    _controlsInset   = UIEdgeInsetsZero;
  }
  return self;
}

-(void)dealloc
{
  [_photoScrollView removeFromSuperview];
  [_photoScrollView release];
  [_leftButton      removeFromSuperview];
  [_leftButton release];
  [_rightButton     removeFromSuperview];
  [_rightButton release];
  [super dealloc];
}

-(IBPhotoScrollView *)photoScrollView
{
  if ( !_photoScrollView )
  {
    _photoScrollView = [[IBPhotoScrollView alloc] initWithFrame:self.bounds];
    _photoScrollView.backgroundColor     = [UIColor clearColor];
    _photoScrollView.autoresizesSubviews = YES;
    _photoScrollView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _photoScrollView.eventDelegate       = self;
    [self addSubview:_photoScrollView];
    [self sendSubviewToBack:_photoScrollView];

  }
  return _photoScrollView;
}

-(UIButton *)leftButton
{
  if ( !_leftButton )
  {
    _leftButton = [[UIButton alloc] initWithFrame:CGRectZero];
    _leftButton.backgroundColor = [UIColor clearColor];
    _leftButton.hidden = YES;
    [_leftButton addTarget:self
                    action:@selector(didLeftButtonClicked:)
          forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_leftButton];
  }
  return _leftButton;
}

-(UIButton *)rightButton
{
  if ( !_rightButton )
  {
    _rightButton = [[UIButton alloc] initWithFrame:CGRectZero];
    _rightButton.backgroundColor = [UIColor clearColor];
    _rightButton.hidden = YES;
    [_rightButton addTarget:self
                     action:@selector(didRightButtonClicked:)
           forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:_rightButton];
  }
  return _rightButton;
}

-(void)layoutSubviews
{
  [super layoutSubviews];

  CGRect frame = [self bounds];
  
  CGRect leftButtonFrame  = _leftButton.frame;
  CGRect rightButtonFrame = _rightButton.frame;
  
  leftButtonFrame.origin.x  = -_controlsInset.left;
  leftButtonFrame.origin.y  = floorf( (CGRectGetHeight( frame ) - CGRectGetHeight( leftButtonFrame )) / 2.f );
  _leftButton.frame = leftButtonFrame;
  
  rightButtonFrame.origin.x = CGRectGetMaxX( frame ) - CGRectGetWidth( rightButtonFrame ) + _controlsInset.right;
  rightButtonFrame.origin.y = floorf( (CGRectGetHeight( frame ) - CGRectGetHeight( rightButtonFrame )) / 2.f );
  _rightButton.frame = rightButtonFrame;
  
  [[self subviews] makeObjectsPerformSelector:@selector(layoutSubviews)];
}

-(void)didRightButtonClicked:(UIButton *)sender
{
  NSInteger pageCount = _photoScrollView.pageCount;
  NSInteger lastPage  = MAX(pageCount - 1, 0);
  NSInteger page = ((NSInteger)_photoScrollView.currentPage) + 1;
  if ( page <= lastPage )
    [_photoScrollView setCurrentPage:page animated:YES];
}

-(void)didLeftButtonClicked:(UIButton *)sender
{
  NSInteger page = ((NSInteger)_photoScrollView.currentPage) - 1;
  if ( page >= 0 )
    [_photoScrollView setCurrentPage:page animated:YES];
}

-(void)photoScrollView:(IBPhotoScrollView *)scrollView_
         didChangePage:(NSUInteger)newPage_
           fromOldPage:(NSUInteger)oldPage_
{
  NSInteger pageCount = _photoScrollView.pageCount;
  NSInteger lastPage  = MAX(pageCount - 1, 0);

  [_leftButton setHidden:(newPage_ == 0) animated:YES];
  [_rightButton setHidden:(newPage_ == lastPage) animated:YES];
}



@end
