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

#import "IBPItem.h"

@implementation IBPItem

-(void)dealloc
{
  self.name = nil;
  self.currencyCode = nil;
  self.price = nil;
  self.shortDescription = nil;
  
  [super dealloc];
}

@end
