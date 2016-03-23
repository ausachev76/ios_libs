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

#import "UILabel+measure.h"

@implementation UILabel (measure)

-(CGSize)sizeConstrainedToSize:(CGSize)size_
{
  CGSize expectedLabelSize = [self.text sizeWithFont:self.font
                                   constrainedToSize:size_
                                       lineBreakMode:self.lineBreakMode];
  
  CGFloat maxHeight = ceilf(self.font.lineHeight * self.numberOfLines);
  
  CGFloat labelHeight = !self.numberOfLines ?
                                ceilf(expectedLabelSize.height) :
                                MIN(ceilf(expectedLabelSize.height), maxHeight );
  return CGSizeMake( ceilf(expectedLabelSize.width), labelHeight );
}

@end
