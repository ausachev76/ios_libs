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

#import "SQLiteManager+DefaultManager.h"

@implementation SQLiteManager (DefaultManager)

#define defaultDBName @"appDB.sqlite"

- (BOOL)createSystemTables
{
    // PopupImages:
  
  [self openDatabase];
  NSString *query = @"CREATE  TABLE IF NOT EXISTS \"PopupImages\"\
  (\"Id\" INTEGER NOT NULL,\
  \"ImageUrl\" TEXT,\
  \"Message\" TEXT,\
  \"Header\" TEXT,\
  \"Description\" TEXT,\
  \"ModuleOrderId\" INT,\
  PRIMARY KEY (\"Id\"));";
  
  [self doQuery:query];
  
  
    // ModuleInfoContent
  
  query = @"CREATE  TABLE IF NOT EXISTS \"ModuleInfoContent\"\
  (\"widgetID\" INTEGER NOT NULL DEFAULT -1,\
  \"actionID\" INTEGER NOT NULL DEFAULT -1,\
  \"appID\" INTEGER NOT NULL DEFAULT -1,\
  \"prevHash\" TEXT,\
  \"latestHash\" TEXT,\
  PRIMARY KEY (\"widgetID\", \"actionID\"));";
  
  [self doQuery:query];
  
  
  query = @"CREATE INDEX \"ModuleInfoContent_appID_idx\" ON \"ModuleInfoContent\" (\"appID\" ASC)";
  [self doQuery:query];
  
  
  return YES;
  
}

- (void) alterSystemTables
{
  NSString *query = @"ALTER TABLE \"PopupImages\"\
  ADD COLUMN ImageTimeStamp INT NOT NULL DEFAULT 0";
  
  [self doQuery:query];
}


+ (NSString *) defaultDBFilePath
{
  NSArray *paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES);
  if ( !paths || ![paths count] )
    return nil;
  NSString *folderPath = [paths objectAtIndex:0];
  return [folderPath stringByAppendingPathComponent:defaultDBName];
}


+(SQLiteManager *) defaultManager
{
  static SQLiteManager *dbDefaultManager = nil;
  
  static dispatch_once_t oncePredicate;
  
  dispatch_once(&oncePredicate, ^{
    NSString *dbFilePath = [SQLiteManager defaultDBFilePath];
    
    NSLog(@"FILEPATH: %@", dbFilePath);
    
    dbDefaultManager = [[SQLiteManager alloc] initWithDatabaseNamed:dbFilePath];
    NSError *error = [dbDefaultManager openDatabase];
    if ( error )
    {
      BOOL result = [[NSFileManager defaultManager] createFileAtPath:dbFilePath
                                                            contents:nil
                                                          attributes:nil];
      if ( !result )
      {
        NSLog(@"Can not create database!");
        [dbDefaultManager release];
        dbDefaultManager = nil;
      }
      
      [dbDefaultManager createSystemTables];
      
      [dbDefaultManager closeDatabase];

      error = [dbDefaultManager openDatabase];
      if ( error )
      {
        NSLog(@"Can not open database! \r\n%@", error );
        [dbDefaultManager release];
        dbDefaultManager = nil;
      }
    }
    
    if (dbDefaultManager)
      [dbDefaultManager alterSystemTables];
    
  });
  
  return dbDefaultManager;
}

@end
