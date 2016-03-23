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

#import "mDBResource.h"
#import "mDBLocalizedResource.h"
#import "NSString+UrlConvertion.h"

#define kDefaultLocalizationKey @"en"

@implementation mDBResource
@synthesize external = _external, local = _local;

-(void)initialize
{
  _external = nil;
  _local    = nil;
}

-(id)init
{
  self = [super init];
  if ( self )
  {
    [self initialize];
  }
  return self;
}

-(void)dealloc
{
  self.external   = nil;
  self.local = nil;
  [super dealloc];
}

-(id)copyWithZone:(NSZone *)zone
{
  mDBResource *resource = [[mDBResource alloc] init];
  resource.external = [[self.external copyWithZone:zone] autorelease];
  resource.local    = [[self.local copyWithZone:zone] autorelease];
  return resource;
}

-(id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if ( self )
  {
    [self initialize];
    self.external = [coder decodeObjectForKey:@"mDBResource::external"];
    self.local    = [coder decodeObjectForKey:@"mDBResource::local"];
  }
  return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
  if ( self.external )
    [coder encodeObject:self.external forKey:@"mDBResource::external"];
  if ( self.local )
    [coder encodeObject:self.local forKey:@"mDBResource::local"];
}


+(NSString *)localResourceFilePathWithFileName:(NSString *)filename_
{
  if ( filename_ && [filename_ length] )
  {
    NSString *filename  = [filename_ stringByDeletingPathExtension];
    NSString *extension = [filename_ pathExtension];
    NSString *filepath = nil;
    if ( !filepath )
      filepath  = [[NSBundle mainBundle] pathForResource:filename
                                                  ofType:extension];

    if ( ![[NSFileManager defaultManager] fileExistsAtPath:filepath] )
      return nil;
    return filepath;
  }
  return nil;
}

+(NSURL *)localURLResourceWithValue:(NSString *)value_
{
  NSString *filepath = [[self class] localResourceFilePathWithFileName:value_];
  return filepath ? [NSURL fileURLWithPath:filepath] : nil;
}

+(NSURL *)externalURLResourceWithValue:(NSString *)value_
{
  return [value_ asURL];
}

+(mDBResource *)localizedURLResourceWithElement:(TBXMLElement *)parent
                                externalTagName:(NSString *)externalTagName
                                   localTagName:(NSString *)localTagName
{
  mDBResource *resource = [[[mDBResource alloc] init] autorelease];
  TBXMLElement *xmlElementExternal = [TBXML childElementNamed:externalTagName parentElement:parent];
  if ( xmlElementExternal )
  {
    resource.external = [[[mDBLocalizedResource alloc] initWithXMLElement:xmlElementExternal
                                                                  process:^id<NSCopying,NSCoding>(NSString *value)
                          {
                            return [[self class] externalURLResourceWithValue:value];
                          }] autorelease];
  }
  TBXMLElement *xmlElementLocal = [TBXML childElementNamed:localTagName parentElement:parent];
  if ( xmlElementLocal )
  {
    resource.local = [[[mDBLocalizedResource alloc] initWithXMLElement:xmlElementLocal
                                                               process:^id<NSCopying,NSCoding>(NSString *value)
                       {
                         return [[self class] localURLResourceWithValue:value];
                       }] autorelease];
  }
  return resource;
}

+(mDBResource *)URLResourceWithElement:(TBXMLElement *)parent
                       externalTagName:(NSString *)externalTagName
                          localTagName:(NSString *)localTagName
{
  mDBResource *resource = [[[mDBResource alloc] init] autorelease];
  TBXMLElement *xmlElementExternal = [TBXML childElementNamed:externalTagName parentElement:parent];
  if ( xmlElementExternal )
  {
    NSString *value = [TBXML textForElement:xmlElementExternal];
    if ( value && [value length] )
      resource.external = [[self class] externalURLResourceWithValue:value];
  }
  TBXMLElement *xmlElementLocal = [TBXML childElementNamed:localTagName parentElement:parent];
  if ( xmlElementLocal )
  {
    NSString *value = [TBXML textForElement:xmlElementLocal];
    if ( value && [value length] )
      resource.local = [[self class] localURLResourceWithValue:value];
  }
  return resource;
}



-(NSString *)description
{
  NSMutableString *str = [NSMutableString stringWithString:@"\n(\n["];
  if ( self.local )
    [str appendFormat:@"  local = \"%@\";\n", self.local ];
  if ( self.external )
    [str appendFormat:@"  local = \"%@\";\n", self.external ];
  [str appendString:@"]"];
  return [NSString stringWithString:str];
}

@end
