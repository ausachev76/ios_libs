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
#import "SQLiteManager+DefaultManager.h"

@class WidgetInfoContent;

@interface WidgetsInfo : NSObject

@property (nonatomic, strong, readonly) NSMutableArray *widgetsInfoArray;
@property (nonatomic, assign) BOOL enableBadgesOnButtons;
@property (nonatomic, assign, readonly) BOOL isFirstLoading;

+ (WidgetsInfo *) sharedInstance;
+ (NSString *)hashForParams:(NSDictionary *)params;
- (BOOL)refreshWidgetInfoWithArray:(NSArray *)inputArray;
- (void)updateHashForWidgetID:(NSInteger)actionID withHash:(NSString *)hash;
- (BOOL)contentUpdatedForActionID:(NSInteger)actionID;
- (void)refreshPrevHashForActionID:(NSInteger)actionID;

- (void)loadSavedWidgetInfo;
- (void)saveWidgetInfo;
- (void)saveWidgetsHash;

@end



@interface WidgetInfoContent : NSObject<NSCoding>

@property (nonatomic, assign) NSInteger widgetID;
@property (nonatomic, assign) NSInteger actionID;
@property (nonatomic, strong) NSString *prevHash;
@property (nonatomic, strong) NSString *latestHash;

@end




@interface SQLiteManager (WidgetsInfo)

- (BOOL)saveWidgets;
- (BOOL)loadWidgets;

@end