//
//  FontRegistry.m
//  Tabris
//
//  Created by Jordi Böhme López on 25.07.12.
//  Copyright (c) 2012 EclipseSource.
//  All rights reserved. This program and the accompanying materials
//  are made available under the terms of the Eclipse Public License v1.0
//  which accompanies this distribution, and is available at
//  http://www.eclipse.org/legal/epl-v10.html
//
//  Modified by iBuildApp

#import "FontRegistry.h"
#import <UIKit/UIKit.h>

@implementation TFontRegistry

- (id)init
{
  self = [super init];
  if (self)
  {
    fonts = [[NSMutableDictionary alloc] init];
    [self initFonts];
  }
  return self;
}

-(void)initFonts
{
  NSArray *fontFamilies = [UIFont familyNames];
  for (NSString *fontFamily in fontFamilies)
  {
    [fonts setObject:[self computeFont:fontFamily forBold:NO  andItalic:NO ] forKey:[self computeKey:fontFamily forBold:NO  andItalic:NO ]];
    [fonts setObject:[self computeFont:fontFamily forBold:YES andItalic:NO ] forKey:[self computeKey:fontFamily forBold:YES andItalic:NO ]];
    [fonts setObject:[self computeFont:fontFamily forBold:NO  andItalic:YES] forKey:[self computeKey:fontFamily forBold:NO  andItalic:YES]];
    [fonts setObject:[self computeFont:fontFamily forBold:YES andItalic:YES] forKey:[self computeKey:fontFamily forBold:YES andItalic:YES]];
  }
}

- (void)dealloc
{
  [fonts release];
  [super dealloc];
}

#pragma mark - API Methods

+(TFontRegistry *)instance
{
  static TFontRegistry *instance;
  @synchronized( self )
  {
    if( !instance ) {
      instance = [[TFontRegistry alloc] init];
    }
    return instance;
  }
}

-(NSString *)fontForFamily:(NSString *)fontFamily
                   forBold:(BOOL)isBold
                 andItalic:(BOOL)isItalic
{
  NSString *key = [self computeKey:fontFamily
                           forBold:isBold
                         andItalic:isItalic];
  
  return [fonts objectForKey:key];
}

#pragma mark - Internal Methods
-(NSString *)computeKey:(NSString *)fontFamily
                forBold:(BOOL)isBold
              andItalic:(BOOL)isItalic
{
  NSString *fntKey = [[[fontFamily lowercaseString] componentsSeparatedByCharactersInSet: [NSCharacterSet whitespaceCharacterSet]]
                      componentsJoinedByString: @""];
  
  return [NSString stringWithFormat:@"%@;%d;%d", fntKey, isBold, isItalic];
}

-(NSArray *)sortFontNames:(NSArray *)fontNames {
  
  NSArray *sortedFontNames = [fontNames sortedArrayUsingComparator:(NSComparator)^(id obj1, id obj2) {
    NSString *str1 = (NSString *)obj1;
    NSString *str2 = (NSString *)obj2;
    
    if( [str1 rangeOfString:@"Bold"].location != NSNotFound && [str2 rangeOfString:@"Black"].location != NSNotFound )
    {
      return NSOrderedAscending;
    }
    
    if( [str1 rangeOfString:@"Light"].location != NSNotFound || [str1 rangeOfString:@"Condensed"].location != NSNotFound )
    {
      return NSOrderedDescending;
    }
    
    if( [str2 rangeOfString:@"Light"].location != NSNotFound || [str2 rangeOfString:@"Condensed"].location != NSNotFound )
    {
      return NSOrderedAscending;
    }
    
    return (NSInteger)[str1 caseInsensitiveCompare:str2];
  }];
  
  return sortedFontNames;
}

-(BOOL)isItalic:(NSString *)fontName {
  return (   [fontName rangeOfString:@"Italic"].location != NSNotFound
          || [fontName rangeOfString:@"Oblique"].location != NSNotFound
          || [fontName hasSuffix:@"It"]
          || [fontName hasSuffix:@"Ita"] );
}

-(BOOL)isBold:(NSString *)fontName {
  return (   [fontName rangeOfString:@"Bold"].location != NSNotFound
          || [fontName rangeOfString:@"Black"].location != NSNotFound
          || [fontName rangeOfString:@"Wide"].location != NSNotFound
          || [fontName hasSuffix:@"-W6"]
          || ([fontName hasSuffix:@"-Medium"] && [fontName rangeOfString:@"Heiti"].location != NSNotFound ));
}


-(NSString *)findRegularFontForFamily:(NSString *)family
{
  NSArray *fontNames = [UIFont fontNamesForFamilyName:family];
  NSArray *sortedFontNames = [self sortFontNames:fontNames];
  for (NSString *fontName in sortedFontNames)
  {
    if( ![self isItalic:fontName] &&
       ![self isBold:fontName] )
    {
      return fontName;
    }
  }
  
  return [sortedFontNames firstObject];
}

-(NSString *)findBoldFontForFamily:(NSString *)family {
  NSString *result = nil;
  NSArray *fontNames = [UIFont fontNamesForFamilyName:family];
  NSArray *sortedFontNames = [self sortFontNames:fontNames];
  for (NSString *fontName in sortedFontNames) {
    if( [self isBold:fontName] && ![self isItalic:fontName] ) {
      return fontName;
    }
  }
  return result;
}

-(NSString *)findItalicFontForFamily:(NSString *)family {
  
  NSString *result = nil;
  NSArray *fontNames = [UIFont fontNamesForFamilyName:family];
  NSArray *sortedFontNames = [self sortFontNames:fontNames];
  
  for (NSString *fontName in sortedFontNames) {
    if( [self isItalic:fontName] && ![self isBold:fontName] ) {
      return fontName;
    }
  }
  return result;
}

-(NSString *)findBoldItalicFontForFamily:(NSString *)family
{
  NSString *result = nil;
  
  NSArray *fontNames = [UIFont fontNamesForFamilyName:family];
  
  NSArray *sortedFontNames = [self sortFontNames:fontNames];
  
  for (NSString *fontName in sortedFontNames)
  {
    if( [self isItalic:fontName] && [self isBold:fontName] ) {
      return fontName;
    }
  }
  
  return result;
}

-(NSString *)computeFont:(NSString *)family
                 forBold:(BOOL)isBold
               andItalic:(BOOL)isItalic
{
  NSString *result = nil;
  if( isBold && isItalic ) {
    result = [self findBoldItalicFontForFamily:family];
  }
  if( !result && isItalic ) {
    result = [self findItalicFontForFamily:family];
  }
  if( !result && isBold ) {
    result = [self findBoldFontForFamily:family];
  }
  if( !result ) {
    result = [self findRegularFontForFamily:family];
  }
  
  if(!result)
  {
    result = @""; //prevent inserting nil value into fonts dictionary
  }
  
  return result;
}

@end
