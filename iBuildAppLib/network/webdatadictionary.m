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

#import "webdatadictionary.h"

@implementation TWebDataItem
@synthesize localData = _localData,
              webData = _webData;

-(void)initialize
{
  _localData = nil;
  _webData   = nil;
}

-(id)initWithWebData:(NSData *)webData_
           localData:(NSData *)localData_
{
  self = [super init];
  if ( self )
  {
    [self initialize];
    self.localData = localData_;
    self.webData   = webData_;
  }
  return self;
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
  self.localData = nil;
  self.webData   = nil;
  [super dealloc];
}

-(id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if ( self )
  {
    [self initialize];
    self.localData = [coder decodeObjectForKey:@"TWebDataItem::localData"];
    self.webData   = [coder decodeObjectForKey:@"TWebDataItem::webData"];
  }
  return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
  if ( self.localData )
    [coder encodeObject:self.localData forKey:@"TWebDataItem::localData"];
  if ( self.webData )
    [coder encodeObject:self.webData forKey:@"TWebDataItem::webData"];
}

-(id)copyWithZone:(NSZone *)zone
{
  TWebDataItem *dataItem = [[TWebDataItem alloc] initWithWebData:[[self.webData copy] autorelease]
                                                       localData:[[self.localData copy] autorelease]];
  return dataItem;
}


@end


@interface TWebDataDictionary()
  @property(nonatomic, strong) NSMutableDictionary *dataDictionary;
@end

@implementation TWebDataDictionary
@synthesize dataDictionary = _dataDictionary;

-(id)initWithDictionary:(NSDictionary *)dictionary_
{
  self = [super init];
  if ( self )
  {
    _dataDictionary = nil;
    
    NSMutableDictionary *dc = [[NSMutableDictionary alloc] init];
    NSArray *keys = [dictionary_ allKeys];
    for( NSString *key in keys )
    {
      id obj = [dictionary_ objectForKey:key];
      if ( [obj isKindOfClass:[TWebDataItem class]])
        [dc setObject:obj forKey:key];
    }
    if ( [dc count] )
      self.dataDictionary = dc;
    [dc release];
  }
  return self;
}

-(id)init
{
  self = [super init];
  if ( self )
  {
    NSLog(@">>> create %@", [self class] );
    _dataDictionary = [[NSMutableDictionary alloc] init];
  }
  return self;
}

-(void)dealloc
{
  NSLog(@"<<< destroy %@", [self class] );
  self.dataDictionary = nil;
  [super dealloc];
}

-(id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if ( self )
  {
    _dataDictionary = nil;
    self.dataDictionary = [coder decodeObjectForKey:@"TWebDataDictionary::dataDictionary"];
  }
  return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
  if ( self.dataDictionary )
    [coder encodeObject:self.dataDictionary forKey:@"TWebDataDictionary::dataDictionary"];
}

-(id)copyWithZone:(NSZone *)zone
{
  return [[TWebDataDictionary alloc] initWithDictionary:self.dataDictionary];
}

-(void)setItem:(TWebDataItem *)item_ forURL:(NSURL *)url_
{
  if ( !item_ || !url_ )
    return;
  
  [self.dataDictionary setObject:item_ forKey:[url_ absoluteString]];
}

-(TWebDataItem *)itemForURL:(NSURL *)url_
{
  if ( !url_ )
    return nil;
  return [self.dataDictionary objectForKey:[url_ absoluteString]];
}

-(NSUInteger)count
{
  return [self.dataDictionary count];
}

-(NSArray *)allKeys
{
  return [self.dataDictionary allKeys];
}

-(NSArray *)allValues
{
  return [self.dataDictionary allValues];
}

-(void)removeAllObjects
{
  [self.dataDictionary removeAllObjects];
}

-(void)removeObjectForKey: (NSString *) key
{
  [self.dataDictionary removeObjectForKey: key];
}

@end
