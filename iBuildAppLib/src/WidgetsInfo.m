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

#import "WidgetsInfo.h"
#import "SQLiteManager+DefaultManager.h"
#import "appbuilderappconfig.h"
#import "NSString+md5.h"

#define kWidgetInfoCacheFolderPath @"WidgetInfo"
#define kWidgetInfoFileNamePrefix  @"WidgetInfo"


@interface WidgetsInfo()

+ (NSString *)currentCacheFileName;


@end


@implementation WidgetsInfo

@synthesize widgetsInfoArray, isFirstLoading, enableBadgesOnButtons;

static WidgetsInfo *sharedInstance = nil;


+ (WidgetsInfo *)sharedInstance
{
  
  @synchronized (self)
  {
    if (sharedInstance == nil)
    {
      sharedInstance = [[self alloc] init];
    }
  }
  return sharedInstance;
}

+ (NSString *)currentCacheFileName
{
  return [NSString stringWithFormat:@"%@_%@.dat", kWidgetInfoFileNamePrefix, appProjectID()];
}

- (id)init
{
  if (self = [super init])
  {
    widgetsInfoArray = [[NSMutableArray alloc] init];
    isFirstLoading = NO;
    enableBadgesOnButtons = NO;

    [self loadSavedWidgetInfo];
  }
  
  return self;
}

- (void) dealloc
{
  if (widgetsInfoArray)
    [widgetsInfoArray release];
  
  widgetsInfoArray = nil;
  
  [super dealloc];
}


- (void)loadSavedWidgetInfo
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES);
  NSString *folderPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:kWidgetInfoCacheFolderPath];
  
  NSString *filePath = [folderPath stringByAppendingPathComponent:[WidgetsInfo currentCacheFileName]];
  id obj = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
  
  if ([obj isKindOfClass:[NSArray class]])
  {
    [self.widgetsInfoArray removeAllObjects];
    [self.widgetsInfoArray addObjectsFromArray:(NSArray *)obj];
  }
  else
  {
    NSLog(@"loadSavedWidgetInfo error!");

    isFirstLoading = YES;
  }
}




- (void)saveWidgetInfo
{
  NSError *error = nil;
  NSArray *paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES);
  NSString *folderPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:kWidgetInfoCacheFolderPath];
  
    //Optionally check if folder already hasn't existed.
  if ( ![[NSFileManager defaultManager] fileExistsAtPath:folderPath] )
    [[NSFileManager defaultManager] createDirectoryAtPath:folderPath
                              withIntermediateDirectories:NO
                                               attributes:nil
                                                    error:&error];
  
  if (error)
  {
    NSLog(@"saveWidgetInfo error: %@", [error localizedDescription]);
    return;
  }
  else
  {
    NSLog(@"widgetsInfoArray saved");
    [NSKeyedArchiver archiveRootObject:self.widgetsInfoArray
                                toFile:[folderPath stringByAppendingPathComponent:[WidgetsInfo currentCacheFileName]]];
  }
}


- (WidgetInfoContent *)contentByModuleID:(NSInteger)widgetID_
{
  for (WidgetInfoContent *wic in self.widgetsInfoArray)
  {
    if (wic.widgetID == widgetID_)
      return wic;
  }
  
  return nil;
}

- (WidgetInfoContent *)contentByActionID:(NSInteger)actionID_
{
  for (WidgetInfoContent *wic in self.widgetsInfoArray)
  {
    if (wic.actionID == actionID_)
      return wic;
  }
  
  return nil;
}


- (BOOL)contentUpdatedForActionID:(NSInteger)actionID
{
    // do not show badges if XML parameter update_content_push_enabled not set 0
  if (!enableBadgesOnButtons)
    return NO;
  
    // On first loading do not shows badges either:
  if (isFirstLoading)
    return NO;
  
  WidgetInfoContent *wic = [self contentByActionID:actionID];
  if (!wic)
  {
    NSLog(@"can not find widget info for actionID = %ld", (long)actionID);
    return NO;
  }
  
  if (!wic.latestHash && !wic.prevHash)
    return NO;
  
  if (wic.latestHash && ![wic.latestHash isEqualToString:wic.prevHash] )
  {
    return YES;
  }
  
  return NO;

}


- (void)refreshPrevHashForActionID:(NSInteger)actionID
{
  WidgetInfoContent *wic = [self contentByActionID:actionID];
  if (!wic)
  {
    NSLog(@"can not find widget info for actionID = %ld", (long)actionID);
    return;
  }
  
  wic.prevHash = wic.latestHash;
}



#pragma mark - Working with widgetsInfoArray

- (void)addWidgetInfoWithActionId:(NSInteger)actionID andWidgetId:(NSInteger)widgetID
{
    // deprecated. Use refreshWidgetInfoWithArray instead
  WidgetInfoContent *wic = [self contentByModuleID:widgetID];
  
  if (!wic)
  {
    for (WidgetInfoContent *wic2 in self.widgetsInfoArray)
    {
      if (wic2.actionID == actionID)
        wic2.actionID = -1;
    }
    
    wic = [[WidgetInfoContent alloc] init];
    wic.widgetID = widgetID;
    
    [self.widgetsInfoArray addObject:wic];
    [wic release];
  }
  
  wic.actionID = actionID;
  
}


- (BOOL)refreshWidgetInfoWithArray:(NSArray *)inputArray
{
  if (!inputArray || !inputArray.count)
    return NO;

  NSMutableArray *tmpArray = [NSMutableArray new];

  for (WidgetInfoContent *updatedWic in inputArray)
  {
    if (!updatedWic)
      continue;

    WidgetInfoContent *storedWic = [self contentByModuleID:updatedWic.widgetID];
    
    if (storedWic)
    {
      storedWic.actionID = updatedWic.actionID;
      [tmpArray addObject:storedWic];
    }
    else
    {
      [tmpArray addObject:updatedWic];
    }
  }
  
  if (!tmpArray.count)
    return NO;

  [self.widgetsInfoArray removeAllObjects];
  [self.widgetsInfoArray addObjectsFromArray:tmpArray];
  
  [self saveWidgetInfo];
  
  return YES;
}


- (void)saveWidgetsHash
{
  NSLog(@"saveWidgetsHash");

  for (WidgetInfoContent *wic in self.widgetsInfoArray)
  {
    wic.prevHash = wic.latestHash;
  }

  for (int i = self.widgetsInfoArray.count - 1; i >= 0; i--)
  {
    WidgetInfoContent *wic = self.widgetsInfoArray[i];
    if (wic.actionID < 0)
        [self.widgetsInfoArray removeObject:wic];
  }
  
  [self saveWidgetInfo];
}


- (NSString *)widgetsArrayToString
{
  NSMutableString *str = [[[NSMutableString alloc] initWithString:@"i; widgetID; actionID;  prevHash; latestHash;\r\n"] autorelease];
  
  for (int i = 0; i < self.widgetsInfoArray.count; i++)
  {
    WidgetInfoContent *wic = self.widgetsInfoArray[i];
    NSString *wicStr = [NSString stringWithFormat:@"[%d]; %ld; %ld; %@; %@; \r\n", i, (long)wic.widgetID, (long)wic.actionID, wic.prevHash, wic.latestHash];
    [str appendString:wicStr];
  }
  
  return [NSString stringWithString:str];
}


+ (NSString *)hashForParams:(NSDictionary *)params
{
  if (!params)
    return nil;
  
  NSMutableDictionary *correctedParams = [params mutableCopy];
  [correctedParams setObject:@"" forKey:@"module_id"]; // order
  [correctedParams setObject:@"" forKey:@"title"]; // title
  
  [correctedParams setObject:@"" forKey:@"params"];
  
  NSArray *keys = correctedParams.allKeys;
  for (NSString *key in keys) {
    id<NSCoding> obj = correctedParams[key];
    if (obj) {
       NSData *objData = [NSKeyedArchiver archivedDataWithRootObject:obj];
       correctedParams[key] = objData;
    }
  }
  
  NSString *strRepresentation = [correctedParams description];
  
  NSString *md5Hash = [strRepresentation MD5Hash];

  [correctedParams release];
  
  return md5Hash;
}



- (void)updateHashForWidgetID:(NSInteger)widgetID withHash:(NSString *)hash
{
  WidgetInfoContent *wic = [self contentByModuleID:widgetID];
  if (!wic)
  {
    NSLog(@"can not find widget info for widgetID = %ld", (long)widgetID);
    return;
  }
  
  wic.latestHash = hash;
}



@end



#pragma mark - WidgetInfoContent implementation

@implementation WidgetInfoContent

@synthesize widgetID, actionID, prevHash, latestHash;

- (id)init
{
  if (self = [super init])
  {
    widgetID = -1;
    actionID = -1;
    prevHash   = nil;
    latestHash = nil;
  }
  
  return self;
  
}

- (void)dealloc
{
  prevHash    = nil;
  latestHash  = nil;
  
  [super dealloc];
}


#pragma mark - NSCoder

  // Encode an object for an archive
- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeInteger:self.widgetID  forKey:@"widgetID"  ];
  [coder encodeInteger:self.actionID  forKey:@"actionID"  ];
  [coder encodeObject:self.prevHash   forKey:@"prevHash"  ];
  [coder encodeObject:self.latestHash forKey:@"latestHash"];

}

  // Decode an object from an archive
- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if ( self )
  {
    self.widgetID   = [coder decodeIntegerForKey:@"widgetID"];
    self.actionID   = [coder decodeIntegerForKey:@"actionID"];
    self.prevHash   = [coder decodeObjectForKey :@"prevHash"];
    self.latestHash = [coder decodeObjectForKey :@"latestHash"];
  }
  return self;
}





@end


@implementation SQLiteManager (WidgetsInfo)

- (BOOL)saveWidgets
{
  WidgetsInfo *wInfo = [WidgetsInfo sharedInstance];
  NSArray *array = wInfo.widgetsInfoArray;
  
  if (!array || !array.count)
  {
    NSLog(@"error: empty array!");
    return NO;
  }
  
  NSString *query = @"INSERT OR REPLACE INTO ModuleInfoContent \
                     (widgetID, actionID, appID, prevHash, latestHash) VALUES ";
  
  NSInteger baseQueryLength = [query length];
  
  NSString *delimiter = @", ";
  NSString *appID = appProjectID();
  
//  for (NSObject *obj in array)
  for (int i = 0; i < array.count; i++)
  {
    WidgetInfoContent *wic = array[i];
    
    if (!wic)
      continue;
    
    if (i == array.count - 1)
      delimiter = @";";
    
    NSString *valuesStr = [NSString stringWithFormat:@"(%ld, %ld, %@, '%@', '%@')%@", (long)wic.widgetID, (long)wic.actionID, appID, wic.prevHash, wic.latestHash, delimiter];
    
    query = [query stringByAppendingString:valuesStr];
    
  }
  
  if (baseQueryLength == [query length])
  {
    NSLog(@"error: incorrect query!");
    return NO;
  }
  
  
  return [self doQuery:query] == nil;
}


- (BOOL)loadWidgets
{
  NSString *query =
  [NSString stringWithFormat:@"SELECT widgetID, actionID, prevHash, latestHash  FROM ModuleInfoContent WHERE appID = %@;", appProjectID()];
  
  NSArray *rows = [self getRowsForQuery:query];
  
  if (rows && [rows count] > 0 && [[rows firstObject] isKindOfClass:[NSDictionary class]])
  {
    WidgetsInfo *wInfo = [WidgetsInfo sharedInstance];
    
    for (NSObject *obj in rows)
    {
      NSDictionary *currentDict = (NSDictionary *)obj;
      
      if (!currentDict)
        continue;
      
      WidgetInfoContent *wic = [[WidgetInfoContent alloc] init];
      wic.widgetID = [[currentDict objectForKey:@"widgetID"] integerValue];
      wic.actionID = [[currentDict objectForKey:@"actionID"] integerValue];
      wic.prevHash = [currentDict objectForKey:@"prevHash"];
      wic.latestHash = [currentDict objectForKey:@"latestHash"];
      
      [wInfo.widgetsInfoArray addObject:wic];
      [wic release];
    }
    
    return YES;
  }
  else
    return NO;
}

@end