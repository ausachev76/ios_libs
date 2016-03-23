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

#import "IBPDBManager.h"
#define kIBPDBName @"IBPayments.sqlite"

static IBPDBManager *sharedDBManager = nil;

@implementation IBPDBManager

+(instancetype)sharedInstance
{
  if(!sharedDBManager)
  {
    sharedDBManager = [[self alloc] initWithDatabaseNamed:[self dbFilePath]];
    [sharedDBManager prepareDatabase];
  }
  
  return sharedDBManager;
}

-(void)dealloc
{  
  [super dealloc];
}

+ (NSString *)dbFilePath
{
  
  NSArray *paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES);
  
  if ( !paths || ![paths count] )
    return nil;
  
  NSString *folderPath = [paths objectAtIndex:0];
  NSString *filePath = [folderPath stringByAppendingPathComponent:kIBPDBName];
  
  NSLog(@"IBPPayPalDBManager: DB FILEPATH %@", filePath);
  
  return filePath;
}

- (BOOL)prepareDatabase
{
  NSError *error = [self openDatabase];
  
  if ( error ){
    // can't open database, so database doesn't exists, create database file
    BOOL result = [[NSFileManager defaultManager] createFileAtPath:databaseName
                                                          contents:nil
                                                        attributes:nil];
    if ( !result ){
      return NO;
    }
    
    // now, try to open database
    error = [self openDatabase];
    if ( error ){
      return NO;
    }
    
  }
  
  // create tables in database
  [self createTables];
  [self closeDatabase];
  
  return YES;
}

-(void)createTables
{
  NSString *query = @"SELECT * FROM table1";
  [self doQuery:query];
  
  query = @"CREATE TABLE IF NOT EXISTS \"PendingPayPalConfirmations\"\
  (\"Id\" INTEGER NOT NULL,\
  \"ConfirmationPOSTBody\" TEXT NOT NULL,\
  PRIMARY KEY (\"Id\"));";
  
  [self doQuery:query];
}

-(void)savePendingConfirmationPOSTBody:(NSString *)confirmation
{
  
  NSTimeInterval timeInterval = ([[NSDate date] timeIntervalSince1970] * 100);
  
  NSString *Id = [NSString stringWithFormat:@"%.0f", floorf(timeInterval)];

  NSString *query = [NSString stringWithFormat:@"INSERT OR REPLACE INTO PendingPayPalConfirmations\
                     (Id, ConfirmationPOSTBody) VALUES (%@, '%@');", Id, confirmation];
  
  [self openDatabase];
  [self doQuery:query];
  [self closeDatabase];
}

-(void)deletePendingConfirmationWithId:(NSString *)Id
{
  NSString *query = [NSString stringWithFormat:@"DELETE FROM PendingPayPalConfirmations WHERE Id = %@;", Id];
  
  [self openDatabase];
  [self doQuery:query];
  [self closeDatabase];
}

-(NSArray *)selectPendingConfirmations
{
  static NSString *query = @"SELECT * FROM PendingPayPalConfirmations;";
  
  [self openDatabase];
  NSArray *results = [self getRowsForQuery:query];
  [self closeDatabase];
  
  return results;
}

@end
