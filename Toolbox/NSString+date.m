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

#import "NSString+date.h"
#import "NSString+truncation.h"

@implementation NSString (date)

-(NSDate *)asDate
{
  NSString *szDate = [self truncate];
  //--------------------------------------------------------------------------------------
  NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
  [df setDateFormat:@"EEE, dd MMMM yyyy HH:mm:ss Z"];
  [df setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
  // set locale to something English
  NSLocale *enLocale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en"] autorelease];
  [df setLocale:enLocale];
  
  return [df dateFromString:szDate];
}
@end
