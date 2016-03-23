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

#import "NRLabel.h"


@implementation NRLabel

@synthesize verticalAlignment = verticalAlignment_;

- (id)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    self.verticalAlignment = NRLabelVerticalAlignmentMiddle;
  }
  return self;
}

- (void)setVerticalAlignment:(NRLabelVerticalAlignment)verticalAlignment {
  verticalAlignment_ = verticalAlignment;
  [self setNeedsDisplay];
}

- (CGRect)textRectForBounds:(CGRect)bounds limitedToNumberOfLines:(NSInteger)numberOfLines
{
  CGRect textRect = [super textRectForBounds:bounds limitedToNumberOfLines:numberOfLines];
  switch (self.verticalAlignment) {
    case NRLabelVerticalAlignmentTop:
      textRect.origin.y = bounds.origin.y;
      break;
    case NRLabelVerticalAlignmentBottom:
      textRect.origin.y = bounds.origin.y + bounds.size.height - textRect.size.height;
      break;
    case NRLabelVerticalAlignmentMiddle:
      // Fall through.
    default:
      textRect.origin.y = bounds.origin.y + (bounds.size.height - textRect.size.height) / 2.0;
  }
  return textRect;
}

-(void)drawTextInRect:(CGRect)requestedRect {
  CGRect actualRect = [self textRectForBounds:requestedRect limitedToNumberOfLines:self.numberOfLines];
  [super drawTextInRect:actualRect];
}

@end
