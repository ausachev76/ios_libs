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

#import "NSString+html.h"
#import <UIKit/UIKit.h>


#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

@implementation NSString (html)

-(NSString *)htmlToText
{
  return [self htmlToTextFast];
}

-(NSString *)htmlToTextFast
{
  NSArray *components = [self componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
  
  NSMutableArray *componentsToKeep = [NSMutableArray array];
  for (int i = 0; i < [components count]; i = i + 2)
  {
    [componentsToKeep addObject:[components objectAtIndex:i]];
  }
  
  return [componentsToKeep componentsJoinedByString:@""];

}

-(NSString *)htmlToNewLinePreservingText
{
  NSString *newLinePreservingString = [self stringByReplacingOccurrencesOfString:@"<br"
                                                                      withString:@"\n<br"];
  return [newLinePreservingString htmlToText];
}

-(NSString *)htmlToNewLinePreservingTextFast
{
  NSString *newLinePreservingString = [self stringByReplacingOccurrencesOfString:@"<br"
                                                                      withString:@"\n<br"];
  return [newLinePreservingString htmlToTextFast];
}

@end
