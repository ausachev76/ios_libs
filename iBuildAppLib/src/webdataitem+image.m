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

#import "webdataitem+image.h"

@implementation TWebDataItem (image)

-(UIImage *)asImage
{
  return self.webData ? [UIImage imageWithData:self.webData] : [UIImage imageWithData:self.localData];
}


@end
