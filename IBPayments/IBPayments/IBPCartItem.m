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

#import "IBPCartItem.h"

@implementation IBPCartItem

-(instancetype)initWithItem:(IBPItem *)item
                      count:(NSUInteger)count
{
  self = [super init];
  
  if(self){
    self.item = item;
    self.count = count;
  }
  
  return self;
}

-(void)dealloc
{
  self.item = nil;
  [super dealloc];
}

@end
