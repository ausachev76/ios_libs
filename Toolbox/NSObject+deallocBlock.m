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

#import "NSObject+deallocBlock.h"
#import <objc/runtime.h>

@interface DeallocHandler : NSObject
  @property (nonatomic, copy) void (^theBlock)(void);
@end

@implementation DeallocHandler
@synthesize theBlock = _theBlock;

-(id)init
{
  self = [super init];
  if ( self )
  {
    _theBlock = nil;
  }
  return self;
}

- (void)dealloc
{
  if (self.theBlock != nil)
  {
    self.theBlock();
  }
  self.theBlock = nil;
  [super dealloc];
}

@end



static char *deallocArrayKey = "deallocArrayKey";

@implementation NSObject (deallocBlock)

- (void)addDeallocBlock:(void (^)(void))theBlock
{
  NSMutableArray *deallocBlocks = objc_getAssociatedObject(self, &deallocArrayKey);
  if (deallocBlocks == nil)
  {
    deallocBlocks = [NSMutableArray array];
    objc_setAssociatedObject(self, &deallocArrayKey, deallocBlocks, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
  DeallocHandler *handler = [[[DeallocHandler alloc] init] autorelease];
  [handler setTheBlock:theBlock];
  [deallocBlocks addObject:handler];
}

- (void)setDeallocBlock:(void (^)(void))theBlock
{
  DeallocHandler *handler = objc_getAssociatedObject(self, &deallocArrayKey);
  if ( handler == nil )
  {
    handler = [[[DeallocHandler alloc] init] autorelease];
    [handler setTheBlock:theBlock];
    objc_setAssociatedObject( self, &deallocArrayKey, handler, OBJC_ASSOCIATION_RETAIN_NONATOMIC );
  }
}

@end
