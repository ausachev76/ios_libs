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

#import "mDBLocalizedResource.h"
#import "NSString+UrlConvertion.h"

#define kDefaultLocalizationKey @"en"

@interface mDBLocalizedResource()
  @property(nonatomic, strong) NSMutableDictionary *localizedMap;
@end

@implementation mDBLocalizedResource
@synthesize localizedMap = _localizedMap;
-(id)init
{
  self = [super init];
  if ( self )
  {
    _localizedMap = nil;
  }
  return self;
}

-(id)initWithResourceMap:(NSMutableDictionary *)resourceMap_
{
  self = [super init];
  if ( self )
  {
    _localizedMap = [resourceMap_ retain];
  }
  return self;
}

-(void)dealloc
{
  [_localizedMap release];
  [super dealloc];
}

-(NSArray *)languageCodes
{
  return [_localizedMap allKeys];
}

-(NSArray *)allObjects
{
  return [_localizedMap allValues];
}

-(NSMutableDictionary *)localizedMap
{
  if ( !_localizedMap )
    _localizedMap = [[NSMutableDictionary alloc] init];
  return _localizedMap;
}

-(id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if ( self )
  {
    _localizedMap = [[coder decodeObjectForKey:@"mDBLocalizedResource:localizedMap"] retain];
  }
  return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
  if ( _localizedMap && [_localizedMap count] )
  {
    [coder encodeObject:_localizedMap forKey:@"mDBLocalizedResource:localizedMap"];
  }
}

-(id)resourceForLocale:(NSString *)languageCode
{
  id obj = [self.localizedMap objectForKey:languageCode];
  if ( !obj )
  {
    obj = [self.localizedMap objectForKey:kDefaultLocalizationKey];
    if ( !obj )
    {
      NSArray *localeList = [self.localizedMap allKeys];
      if ( [localeList count] )
        obj = [self.localizedMap objectForKey:[localeList objectAtIndex:0]];
    }
  }
  return obj;
}

-(void)setResource:(id<NSCoding, NSCopying>)resource
         forLocale:(NSString *)languageCode
{
  if ( !languageCode || ![languageCode length] )
    languageCode = kDefaultLocalizationKey;
  if ( resource )
    [self.localizedMap setObject:resource forKey:languageCode];
}

-(id)copyWithZone:(NSZone *)zone
{
  return [[mDBLocalizedResource alloc] initWithResourceMap:[[_localizedMap copy] autorelease]];
}

-(id)initWithXMLElement:(TBXMLElement *)element
{
  self = [super init];
  if ( self )
  {
    _localizedMap = nil;
    while( element )
    {
      NSString *locale = [[TBXML valueOfAttributeNamed:@"lang" forElement:element] lowercaseString];
      if ( locale && [locale length] )
        [self setResource:[TBXML textForElement:element]
                forLocale:locale];
      else
        [self setResource:[TBXML textForElement:element]
                forLocale:kDefaultLocalizationKey];
      element = [TBXML nextSiblingNamed:[TBXML elementName:element] searchFromElement:element];
    }
  }
  return self;
}

-(id)initWithXMLElement:(TBXMLElement *)element
                process:(id<NSCopying, NSCoding>(^)(NSString *value))callback
{
  self = [super init];
  if ( self )
  {
    _localizedMap = nil;
    while( element )
    {
      NSString *locale = [[TBXML valueOfAttributeNamed:@"lang" forElement:element] lowercaseString];
      NSString *value  = [TBXML textForElement:element];
      id<NSCopying, NSCoding> obj = callback ? callback(value) : value;
      if ( locale && [locale length] )
        [self setResource:obj
                forLocale:locale];
      else
        [self setResource:obj
                forLocale:kDefaultLocalizationKey];
      element = [TBXML nextSiblingNamed:[TBXML elementName:element] searchFromElement:element];
    }
  }
  return self;
}

-(id)initWithXMLElement:(TBXMLElement *)element
      processWithLocale:(id<NSCopying, NSCoding>(^)(NSString *value, NSString *locale))callback
{
  self = [super init];
  if ( self )
  {
    _localizedMap = nil;
    while( element )
    {
      NSString *locale = [[TBXML valueOfAttributeNamed:@"lang" forElement:element] lowercaseString];
      NSString *value  = [TBXML textForElement:element];
      id<NSCopying, NSCoding> obj = callback ? callback(value, locale) : value;
      if ( locale && [locale length] )
        [self setResource:obj
                forLocale:locale];
      else
        [self setResource:obj
                forLocale:kDefaultLocalizationKey];
      element = [TBXML nextSiblingNamed:[TBXML elementName:element] searchFromElement:element];
    }
  }
  return self;
}

-(id)copyWithProcess:(id<NSCopying, NSCoding>(^)(id<NSCopying, NSCoding> value, NSString *locale))callback
{
  if ( !callback )
    return [self copy];
  
  NSArray *keys = [_localizedMap allKeys];
  if ( ![keys count] )
    return [self copy];
  
  mDBLocalizedResource *lResource = [[mDBLocalizedResource alloc] init];
  for( NSString *key in [_localizedMap allKeys] )
  {
    [lResource setResource:callback([_localizedMap objectForKey:key], key )
                 forLocale:key];
  }
  return lResource;
}


-(NSString *)description
{
  NSMutableString *str = [NSMutableString stringWithString:@"\n(\n"];
  for ( NSString *lang in [self languageCodes] )
    [str appendFormat:@"  [%@] = \"%@\";\n", lang, [self resourceForLocale:lang]];
  [str appendString:@")"];
  return [NSString stringWithString:str];
}

@end

