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

#import "IBRSSAtomParser.h"
#import "GTMNSString+HTML.h"

#pragma mark IBRSSAtomFeedAuthor

@implementation IBRSSAtomFeedAuthor
@synthesize  name = _name,
            email = _email,
              uri = _uri;
-(id)init
{
  self = [super init];
  if ( self )
  {
    _name  = nil;
    _email = nil;
    _uri   = nil;
  }
  return self;
}

-(void)dealloc
{
  self.name  = nil;
  self.email = nil;
  self.uri   = nil;
  [super dealloc];
}

+(IBRSSAtomFeedAuthor *)parse:(TBXMLElement *)feedElement
{
  IBRSSAtomFeedAuthor *rssAuthor = [[[IBRSSAtomFeedAuthor alloc] init] autorelease];
  
  TBXMLElement *nameElement  = [TBXML childElementNamed:@"name"  parentElement:feedElement];
  if ( nameElement )
    rssAuthor.name = [TBXML textForElement:nameElement];
  
  TBXMLElement *emailElement = [TBXML childElementNamed:@"email" parentElement:feedElement];
  if ( emailElement )
    rssAuthor.email = [TBXML textForElement:emailElement];
  
  TBXMLElement *uriElement   = [TBXML childElementNamed:@"uri"   parentElement:feedElement];
  NSString *szURI = [[[TBXML textForElement:uriElement] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                        stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  if ( szURI )
    rssAuthor.uri = [NSURL URLWithString:szURI];
  
  return rssAuthor;
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark IBRSSAtomFeedEntry


///-------------------------------------------------------
@implementation IBRSSAtomFeedEntry
@synthesize entryID = _entryID,
              title = _title,
            updated = _updated,
          published = _published,
             author = _author,
               link = _link,
           category = _category,
            summary = _summary,
            content = _content;
-(id)init
{
  self = [super init];
  if ( self )
  {
    _entryID    = nil;
    _title      = nil;
    _updated    = nil;
    _published  = nil;
    _author     = nil;
    _link       = nil;
    _category   = nil;
    _summary    = nil;
    _content    = nil;
  }
  return self;
}

-(void)dealloc
{
  self.entryID    = nil;
  self.title      = nil;
  self.updated    = nil;
  self.published  = nil;
  self.author     = nil;
  self.link       = nil;
  self.category   = nil;
  self.summary    = nil;
  self.content    = nil;
  [super dealloc];
}

+(IBRSSAtomFeedEntry *)parse:(TBXMLElement *)feedElement
{
  IBRSSAtomFeedEntry *entry = [[[IBRSSAtomFeedEntry alloc] init] autorelease];
  
  entry.entryID   = [IBRSSAtomParser parseElementNamed:@"id"        parentElement:feedElement];
  entry.title     = [IBRSSAtomParser parseElementNamed:@"title"     parentElement:feedElement];
  entry.updated   = [IBRSSAtomParser parseElementNamed:@"updated"   parentElement:feedElement];
  entry.published = [IBRSSAtomParser parseElementNamed:@"published" parentElement:feedElement];
  
  TBXMLElement *elementAuthor =  [TBXML childElementNamed:@"author" parentElement:feedElement];
  if ( elementAuthor )
    entry.author = [IBRSSAtomFeedAuthor parse:elementAuthor];
  
  entry.link     = [IBRSSAtomParser parseURINamed:@"link" parentElement:feedElement];
  entry.category = [IBRSSAtomParser parseElementNamed:@"category" parentElement:feedElement];
  entry.summary  = [IBRSSAtomParser parseElementNamed:@"summary"  parentElement:feedElement];
  entry.content  = [IBRSSAtomParser parseElementNamed:@"content"  parentElement:feedElement];
  
  return entry;
}
@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////

#pragma mark IBRSSAtomFeed

@implementation IBRSSAtomFeed
@synthesize feedID = _feedID,
             title = _title,
           updated = _updated,
          subtitle = _subtitle,
            author = _author,
              link = _link,
          category = _category,
         generator = _generator,
            genURI = _genURI,
        genVersion = _genVersion,
              icon = _icon,
              logo = _logo,
            rights = _rights,
           entries = _entries;

-(id)init
{
  self = [super init];
  if ( self )
  {
    _feedID     = nil;
    _title      = nil;
    _updated    = nil;
    _subtitle   = nil;
    _author     = nil;
    _link       = nil;
    _category   = nil;
    _generator  = nil;
    _genURI     = nil;
    _genVersion = nil;
    _icon       = nil;
    _logo       = nil;
    _rights     = nil;
    _entries    = nil;
  }
  return self;
}

-(void)dealloc
{
  self.feedID     = nil;
  self.title      = nil;
  self.updated    = nil;
  self.subtitle   = nil;
  self.author     = nil;
  self.link       = nil;
  self.category   = nil;
  self.generator  = nil;
  self.genURI     = nil;
  self.genVersion = nil;
  self.icon       = nil;
  self.logo       = nil;
  self.rights     = nil;
  self.entries    = nil;
  
  [super dealloc];
}

@end

@implementation IBRSSAtomParser

+(NSString *)parseElementNamed:(NSString *)elementName
                 parentElement:(TBXMLElement *)parent
{
  TBXMLElement *element =  [TBXML childElementNamed:elementName parentElement:parent];
  if ( !element )
    return nil;
  
  NSString *szElementText = [TBXML textForElement:element];
  NSString *szType = [[TBXML valueOfAttributeNamed:@"type" forElement:element] lowercaseString];
  if ( [szType isEqualToString:@"html"] )
    return [szElementText gtm_stringByUnescapingFromHTML];
  return szElementText;
}

+(NSURL *)parseURINamed:(NSString *)elementName
          parentElement:(TBXMLElement *)parent
{
  TBXMLElement *elementLink =  [TBXML childElementNamed:@"link" parentElement:parent];
  if ( !elementLink )
    return nil;
  
  NSString *szLink = [[[TBXML textForElement:elementLink] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                                                          stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  if ( szLink )
    return [NSURL URLWithString:szLink];
  
  return nil;
}


+(IBRSSAtomFeed *)parse:(TBXMLElement *)feedElement
{
  if ( !feedElement ||
       ![[[TBXML elementName:feedElement] lowercaseString] isEqual:@"feed"] )
    return nil;
  
  
  IBRSSAtomFeed *atomFeed = [[[IBRSSAtomFeed alloc] init] autorelease];
  
  atomFeed.feedID   = [IBRSSAtomParser parseElementNamed:@"id"       parentElement:feedElement];
  atomFeed.title    = [IBRSSAtomParser parseElementNamed:@"title"    parentElement:feedElement];
  atomFeed.updated  = [IBRSSAtomParser parseElementNamed:@"updated"  parentElement:feedElement];
  atomFeed.subtitle = [IBRSSAtomParser parseElementNamed:@"subtitle" parentElement:feedElement];
  
  TBXMLElement *elementAuthor =  [TBXML childElementNamed:@"author" parentElement:feedElement];
  if ( elementAuthor )
    atomFeed.author = [IBRSSAtomFeedAuthor parse:elementAuthor];
  
  atomFeed.link     = [IBRSSAtomParser parseURINamed:@"link" parentElement:feedElement];
  atomFeed.category = [IBRSSAtomParser parseElementNamed:@"category" parentElement:feedElement];
  
  TBXMLElement *generatorElement = [TBXML childElementNamed:@"generator" parentElement:feedElement];
  if ( generatorElement )
  {
    atomFeed.generator  = [TBXML textForElement:generatorElement];
    atomFeed.genVersion = [TBXML valueOfAttributeNamed:@"version" forElement:generatorElement];
    NSString *szGenURI = [TBXML valueOfAttributeNamed:@"uri" forElement:generatorElement];
    szGenURI = [[szGenURI stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]
                          stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    if ( szGenURI )
      atomFeed.genURI = [NSURL URLWithString:szGenURI];
  }
  
  atomFeed.icon = [IBRSSAtomParser parseURINamed:@"icon" parentElement:feedElement];
  atomFeed.logo = [IBRSSAtomParser parseURINamed:@"logo" parentElement:feedElement];
  atomFeed.rights = [IBRSSAtomParser parseElementNamed:@"rights" parentElement:feedElement];
  
  TBXMLElement *entryElement = [TBXML childElementNamed:@"entry" parentElement:feedElement];
  NSMutableArray *entryList = [NSMutableArray array];
  while ( entryElement )
  {
    [entryList addObject:[IBRSSAtomFeedEntry parse:entryElement]];
    entryElement = [TBXML nextSiblingNamed:[TBXML elementName:entryElement] searchFromElement:entryElement];
  }
  
  if ( [entryList count] )
    atomFeed.entries = [NSArray arrayWithArray:entryList];
  
  return atomFeed;
}


@end


















