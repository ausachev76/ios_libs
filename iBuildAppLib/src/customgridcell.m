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

#import "customgridcell.h"
#import "widget.h"
#import "labelwidget.h"
#import "uiboxlayout.h"
#import "gridwidget.h"

@implementation TCustomGridCell

@synthesize imageWidget = imageWidget_,
            titleWidget = titleWidget_,
      descriptionWidget = descriptionWidget_,
          delimiterView = delimiterView_,
                  badge = _badge,
        delimiterWidget = delimiterWidget_,
            titleMaxWordWidth,
            descriptionMaxWordWidth,
               layout;

- (id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if (self)
  {
    self.delimiterView     = nil;
    self.badge             = nil;
    self.imageWidget       = nil;
    self.titleWidget       = nil;
    self.descriptionWidget = nil;
    self.delimiterWidget   = nil;
    self.layout            = nil;
    self.titleMaxWordWidth       = 0.f;
    self.descriptionMaxWordWidth = 0.f;
  }
  return self;
}

-(void)dealloc
{
  self.delimiterView     = nil;
  
  if (_badge)
    [_badge release];
  _badge             = nil;
  
  self.imageWidget       = nil;
  self.titleWidget       = nil;
  self.descriptionWidget = nil;
  self.delimiterWidget   = nil;
  self.layout            = nil;
  [super dealloc];
}

- (void)setDelimiterView:(UIImageView *)dlmView_
{
  if( delimiterView_ != dlmView_)
  {
    [delimiterView_ removeFromSuperview];
    [delimiterView_ release];
    delimiterView_ = [dlmView_ retain];
    if( self.backgroundView )
    {
      [delimiterView_ setFrame:[self.contentView convertRect:[delimiterView_ frame]
                                                      toView:self.backgroundView]];
      [self.backgroundView addSubview:delimiterView_];
    }
  }
}

- (UIImageView *)badge
{
  if ( !_badge)
  {
    _badge = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"new_content.png"]];
    _badge.tag = kTabBarButtonBadgeViewTag;
    _badge.clipsToBounds = NO;
    _badge.hidden = YES;

    [self addSubview:_badge];
  }
  return _badge;
}


-(void)layoutSubviews
{
  [super layoutSubviews];
  [self.layout layoutWidgets:self.contentView.bounds];
  
  [[self contentView] sendSubviewToBack:self.imageView];
  [[self contentView] bringSubviewToFront:self.textLabel];
  [[self contentView] bringSubviewToFront:self.detailedTextLabel];
  [self bringSubviewToFront:self.badge];
  
  
#ifdef ADAPTIVE_LABEL_BEHAVIOR
  CGRect titleFrame       = self.textLabel.frame;
  CGRect descriptionFrame = self.detailedTextLabel.frame;

  if ( titleFrame.size.width < self.titleMaxWordWidth )
  {
    self.textLabel.numberOfLines = 1;
    self.textLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  }else{
    self.textLabel.numberOfLines = self.titleWidget.numberOfLines;
    self.textLabel.lineBreakMode = self.titleWidget.lineBreakMode;
  }
  if ( descriptionFrame.size.width < self.descriptionMaxWordWidth )
  {
    self.detailedTextLabel.numberOfLines = 1;
    self.detailedTextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
  }else{
    self.detailedTextLabel.numberOfLines = self.descriptionWidget.numberOfLines;
    self.detailedTextLabel.lineBreakMode = self.descriptionWidget.lineBreakMode;
  }
#endif

  [delimiterView_ setFrame:[self.contentView convertRect:[delimiterView_ frame]
                                                  toView:self.backgroundView]];
}

-(void)setTitleWidget:(TLabelWidgetData *)labelWidgetData_
{
  if ( labelWidgetData_ != titleWidget_ )
  {
    [titleWidget_ release];
    titleWidget_ = [labelWidgetData_ retain];
  }
  if ( titleWidget_ )
  {
    self.textLabel.adjustsFontSizeToFitWidth = NO;
    self.textLabel.font          = titleWidget_.font;
    self.textLabel.textAlignment = titleWidget_.textAlignment;
    self.textLabel.lineBreakMode = titleWidget_.lineBreakMode;
    self.textLabel.textColor     = titleWidget_.textColor;
    self.textLabel.highlightedTextColor = titleWidget_.highlightedTextColor;
    self.textLabel.numberOfLines = titleWidget_.numberOfLines;
    self.textLabel.shadowColor   = titleWidget_.shadowColor;
    self.textLabel.shadowOffset  = titleWidget_.shadowOffset;
  }
}

-(void)setDescriptionWidget:(TLabelWidgetData *)labelWidgetData_
{
  if ( labelWidgetData_ != descriptionWidget_ )
  {
    [descriptionWidget_ release];
    descriptionWidget_ = [labelWidgetData_ retain];
  }
  if ( descriptionWidget_ )
  {
    self.detailedTextLabel.adjustsFontSizeToFitWidth = NO;
    self.detailedTextLabel.verticalAlignment = NRLabelVerticalAlignmentTop;
    self.detailedTextLabel.backgroundColor = [UIColor redColor];
    self.detailedTextLabel.font          = descriptionWidget_.font;
    self.detailedTextLabel.textAlignment = descriptionWidget_.textAlignment;
    self.detailedTextLabel.lineBreakMode = descriptionWidget_.lineBreakMode;
    self.detailedTextLabel.textColor     = descriptionWidget_.textColor;
    self.detailedTextLabel.highlightedTextColor     = descriptionWidget_.highlightedTextColor;
    self.detailedTextLabel.numberOfLines = descriptionWidget_.numberOfLines;
  }
}

- (void)removeBadgeFromTab
{
  self.badge.hidden = YES;
}

@end
