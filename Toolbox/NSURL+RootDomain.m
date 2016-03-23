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

#import "NSURL+RootDomain.h"

@implementation NSURL (RootDomain)

-(NSString *)rootDomain
{
  // Get the host, e.g. "secure.twitter.com"
  NSString *host = [self host];
  
  // Separate the host into its constituent components, e.g. [@"secure", @"twitter", @"com"]
  NSArray *hostComponents = [host componentsSeparatedByString:@"."];
  if ( [hostComponents count] >= 2 )
  {
    // Create a string out of the last two components in the host name, e.g. @"twitter" and @"com"
    return [NSString stringWithFormat:@"%@.%@", [hostComponents objectAtIndex:([hostComponents count] - 2)],
                                                [hostComponents objectAtIndex:([hostComponents count] - 1)]];
  }
  return host;
}
@end
