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

#import "httpurlresponse_extesion.h"

static Boolean caseInsensitiveEqual(const void *a, const void *b)
{
  return [(id)a compare:(id)b options: NSCaseInsensitiveSearch | NSLiteralSearch] == NSOrderedSame;
}

static CFHashCode caseInsensitiveHash ( const void *value )
{
  return [[(id)value lowercaseString] hash];
}

@implementation NSHTTPURLResponse (caseInsensitiveAdditions)

- (NSDictionary *)caseInsensitiveHTTPHeaders;
{
  NSDictionary *src = [self allHeaderFields];
  
  CFDictionaryKeyCallBacks keyCallbacks = kCFTypeDictionaryKeyCallBacks;
  keyCallbacks.equal = caseInsensitiveEqual;
  keyCallbacks.hash  = caseInsensitiveHash;
  
  CFMutableDictionaryRef dest = CFDictionaryCreateMutable (
                                                           kCFAllocatorDefault,
                                                           [src count], // capacity
                                                           &keyCallbacks,
                                                           &kCFTypeDictionaryValueCallBacks
                                                           );
  
  NSEnumerator *enumerator = [src keyEnumerator];
  id key = nil;
  while (key = [enumerator nextObject]) {
    id value = [src objectForKey:key];
    [(NSMutableDictionary *)dest setObject:value forKey:key];
  }
  
  return [(NSDictionary *)dest autorelease];
}

@end
