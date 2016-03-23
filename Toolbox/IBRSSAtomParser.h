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

#import <Foundation/Foundation.h>
#import "TBXML.h"

@interface IBRSSAtomFeedAuthor : NSObject
  @property (nonatomic, copy) NSString *name;
  @property (nonatomic, copy) NSString *email;
  @property (nonatomic, copy) NSURL    *uri;

  +(IBRSSAtomFeedAuthor *)parse:(TBXMLElement *)feedElement;
@end

@interface IBRSSAtomFeedEntry : NSObject

  @property (nonatomic, copy  ) NSString *entryID;
  @property (nonatomic, copy  ) NSString *title;
  @property (nonatomic, copy  ) NSString *updated;

  @property (nonatomic, copy  ) NSString *published;
  @property (nonatomic, strong) IBRSSAtomFeedAuthor *author;
  @property (nonatomic, strong) NSURL    *link;
  @property (nonatomic, copy  ) NSString *category;
  @property (nonatomic, copy  ) NSString *summary;
  @property (nonatomic, copy  ) NSString *content;

  +(IBRSSAtomFeedEntry *)parse:(TBXMLElement *)feedElement;
@end

@interface IBRSSAtomFeed : NSObject
  @property (nonatomic, copy  ) NSString        *feedID;
  @property (nonatomic, copy  ) NSString        *title;
  @property (nonatomic, copy  ) NSString        *updated;
  @property (nonatomic, copy  ) NSString        *subtitle;
  @property (nonatomic, strong) IBRSSAtomFeedAuthor *author;
  @property (nonatomic, strong) NSURL    *link;
  @property (nonatomic, copy  ) NSString *category;
  @property (nonatomic, copy  ) NSString *generator;
  @property (nonatomic, copy  ) NSURL *genURI;
  @property (nonatomic, copy  ) NSString *genVersion;
  @property (nonatomic, strong) NSURL    *icon;
  @property (nonatomic, strong) NSURL    *logo;
  @property (nonatomic, copy  ) NSString *rights;
  @property (nonatomic, strong) NSArray  *entries;
@end


@interface IBRSSAtomParser : NSObject

+(NSString *)parseElementNamed:(NSString *)elementName
                 parentElement:(TBXMLElement *)parent;

+(NSURL *)parseURINamed:(NSString *)elementName
          parentElement:(TBXMLElement *)parent;


+(IBRSSAtomFeed *)parse:(TBXMLElement *)feedElement;

@end
