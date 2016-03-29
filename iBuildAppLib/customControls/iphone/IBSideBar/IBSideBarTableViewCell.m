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

#import "IBSideBarTableViewCell.h"
#import "IBSideBarAction.h"

#define kIBSideBarActionCellHeight 54.0f
#define kIBSideBarActionCellSelectionColor [[UIColor whiteColor] colorWithAlphaComponent:0.2f]

#define kIBSideBarActionCellContentMarginLeft 20.0f

#define kIBSideBarActionCellSeparatorHeight 0.5f
#define kIBSideBarActionCellTextLabelMarginLeft kIBSideBarActionCellContentMarginLeft
#define kIBSideBarActionCellTextLabelMarginRight kIBSideBarActionCellTextLabelMarginLeft
#define kIBSideBarActionCellSeparatorColor [[UIColor whiteColor] colorWithAlphaComponent:0.3f]

#define kIBSideBarActionCellTextLabelDisabledColor [[UIColor whiteColor] colorWithAlphaComponent:0.3f]
#define kIBSideBarActionCellTextLabelEnabledColor [UIColor whiteColor]

#define kIBSideBarActionCellIconWidth 27.0f
#define kIBSideBarActionCellIconHeight kIBSideBarActionCellIconWidth
#define kIBSideBarActionCellIconMarginLeft kIBSideBarActionCellContentMarginLeft
#define kIBSideBarActionCellIconMarginRight 15.0f
#define kIBSideBarActionCellIconMarginTop ((kIBSideBarActionCellHeight - kIBSideBarActionCellIconHeight) / 2.0f)

#define kIBSideBarActionCellCustomViewTag 12345

@interface IBSideBarTableViewCell()

@property (nonatomic, retain) UIView *separatorView;

@end

@implementation IBSideBarTableViewCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
  self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
  if (self)
  {
    [self setupInterface];
  }
  return self;
}

-(void)dealloc
{
  self.separatorView = nil;
  
  [super dealloc];
}

-(void)setupInterface
{
  self.backgroundColor = [UIColor clearColor];
  self.autoresizesSubviews = YES;
  self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  
  self.imageView.contentMode = UIViewContentModeCenter;
  
  self.textLabel.backgroundColor = [UIColor clearColor];
  self.textLabel.font = [UIFont systemFontOfSize:21.0f];
  self.textLabel.textColor = [UIColor whiteColor];
  
  [self substituteSelectedBackgroundView];
  
  self.separatorView.hidden = YES;
}

-(void)substituteSelectedBackgroundView
{
  UIView *selectedBackgroundView = [[[UIView alloc] init] autorelease];
  
  [selectedBackgroundView setBackgroundColor:kIBSideBarActionCellSelectionColor];
  self.selectedBackgroundView = selectedBackgroundView;
}

-(UIView *)separatorView
{
  if(!_separatorView)
  {
    _separatorView = [[UIView alloc] init];
    _separatorView.backgroundColor = kIBSideBarActionCellSeparatorColor;
    
    [self.contentView addSubview:_separatorView];
  }
  
  return _separatorView;
}

-(void)updateInterface
{
  UIImage *iconImage = self.action.currentIconImage;
  NSString *labelText = self.action.label;
  
  UITableViewCellSelectionStyle selectionStyle;
  
  if(self.action.preventsSelection)
  {
    selectionStyle = UITableViewCellSelectionStyleNone;
  } else {
    selectionStyle = UITableViewCellSelectionStyleDefault;
  }
  
  self.selectionStyle = selectionStyle;
  
  [self removeCustomViewIfNeeded];
  
  if(self.action.customView)
  {
    self.action.customView.tag = kIBSideBarActionCellCustomViewTag;
    [self.contentView addSubview:self.action.customView];
    
    iconImage = nil;
    labelText = nil;
  }
  
  self.imageView.image = iconImage;
  self.textLabel.text = labelText;
  
  self.separatorView.hidden = !self.shouldShowSeparator;
  
  UIColor *textColor = self.action.enabled ? kIBSideBarActionCellTextLabelEnabledColor
                                           : kIBSideBarActionCellTextLabelDisabledColor;
  self.textLabel.textColor = textColor;
  
  [self setNeedsLayout];
}

-(void)removeCustomViewIfNeeded
{
  UIView *customView = [self.contentView viewWithTag:kIBSideBarActionCellCustomViewTag];
  [customView removeFromSuperview];
}

//-(void)readdCustomViewIfNeeded
//{
//  for(UIView *view in self.contentView.subviews)
//  {
//    [view removeFromSuperview];
//  }
//  
//  [self.contentView addSubview:self.action.customView];
//}

-(void)setAction:(IBSideBarAction *)action
{
  [action retain];
  [_action release];
  
  _action = action;
  
  [self updateInterface];
}

-(void)setShouldShowSeparator:(BOOL)shouldShowSeparator
{
  if(_shouldShowSeparator != shouldShowSeparator)
  {
    _shouldShowSeparator = shouldShowSeparator;
    
    [self updateInterface];
  }
}

-(void)layoutSubviews
{
  [super layoutSubviews];
  
  if(self.action.customView)
  {
    [self layoutCustomView];
    return;
  }
  
  [self layoutImageView];
  [self layoutTextLabel];
  [self layoutSeparatorView];
}

-(void)layoutCustomView
{
  self.contentView.frame = self.bounds;
  self.action.customView.frame = self.contentView.bounds;
}

-(void)layoutImageView
{
  CGRect imageViewFrame = CGRectZero;
  
  if(!self.imageView.image)
  {
    return;
  } else {
    imageViewFrame = (CGRect)
    {
      kIBSideBarActionCellIconMarginLeft,
      kIBSideBarActionCellIconMarginTop,
      kIBSideBarActionCellIconWidth,
      kIBSideBarActionCellIconHeight
    };
  }

  self.imageView.frame = imageViewFrame;
}

-(void)layoutTextLabel
{
  CGFloat textLabelOriginX;
  CGFloat textLabelWidth;
  
  if(!self.imageView.image)
  {
    textLabelOriginX = kIBSideBarActionCellTextLabelMarginLeft;
    textLabelWidth = self.bounds.size.width
                     - kIBSideBarActionCellTextLabelMarginLeft
                     - kIBSideBarActionCellTextLabelMarginRight;
  } else {
    textLabelOriginX = CGRectGetMaxX(self.imageView.frame) + kIBSideBarActionCellIconMarginRight;
    textLabelWidth = self.bounds.size.width
                     - textLabelOriginX
                     - kIBSideBarActionCellTextLabelMarginRight;
  }
  
  CGRect textLabelFrame = self.bounds;
  textLabelFrame.origin.x = textLabelOriginX;
  textLabelFrame.size.width = textLabelWidth;
  
  self.textLabel.frame = textLabelFrame;
}

-(void)layoutSeparatorView
{
  CGFloat width = self.bounds.size.width
                  - kIBSideBarActionCellTextLabelMarginLeft
                  - kIBSideBarActionCellTextLabelMarginRight;
  
  CGRect separatorViewFrame = (CGRect)
  {
    kIBSideBarActionCellTextLabelMarginLeft,
    self.contentView.frame.size.height - kIBSideBarActionCellSeparatorHeight,
    width,
    kIBSideBarActionCellSeparatorHeight
  };
  
  self.separatorView.frame = separatorViewFrame;
}

+(CGFloat)heightForSideBarAction:(IBSideBarAction *)item
{
  return kIBSideBarActionCellHeight;
}

@end
