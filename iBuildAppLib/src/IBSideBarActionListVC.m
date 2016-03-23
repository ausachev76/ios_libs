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

#import "IBSideBarActionListVC.h"
#import "IBSideBarTableViewCell.h"
#import "IBSideBarModuleAction.h"
#import "IBSideBarWidgetAction.h"
#import "IBSideBarVC.h"

#import "appbuilderappconfig.h"

#import "NSString+colorizer.h"

#import "notifications.h"
#import "widget.h"



#define kSideBarActionListBackgroundColor [@"#262A31" asColor]

@interface IBSideBarActionListViewController ()

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UISwipeGestureRecognizer *closingGestureRecognizer;

@property (nonatomic, strong) NSArray *serviceActions;
@property (nonatomic, strong) NSArray *defaultActions;
@property (nonatomic, strong) NSArray *moduleActions;

@property (nonatomic, readwrite, strong) NSMutableArray *actions;

@end

@implementation IBSideBarActionListViewController

-(instancetype)init
{
  self = [super init];
  
  if(self)
  {
    _selectedWidgetActionUid = WidgetActionUnknown;
    _tableView = nil;
  }
  
  return self;
}

-(void)dealloc
{
  self.serviceActions = nil;
  self.defaultActions = nil;
  self.moduleActions = nil;
  
  self.actions = nil;
  
  self.selectedWidgetAction = nil;
  
  self.tableView = nil;
  self.closingGestureRecognizer = nil;
  
  [super dealloc];
}

#pragma mark -
-(void)viewDidLoad
{
  [super viewDidLoad];
  
  self.view.backgroundColor = kSideBarActionListBackgroundColor;
  self.view.autoresizesSubviews = YES;
  self.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
  
  [self placeTableView];
}

-(void)placeTableView
{
  [self.view addSubview:self.tableView];
}

-(UISwipeGestureRecognizer *)closingGestureRecognizer
{
  if(!_closingGestureRecognizer)
  {
    _closingGestureRecognizer = [[[UISwipeGestureRecognizer alloc] initWithTarget:self
                                                                           action:@selector(closingGestureRecognizerHandlerCalled)] autorelease];
    _closingGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
  }
  
  return _closingGestureRecognizer;
}

-(void)closingGestureRecognizerHandlerCalled{
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"sideBarClosingGestureNotification"
                                                      object:nil];
}

-(UITableView *)tableView
{
  if(!_tableView)
  {
    CGRect tableViewFrame = self.view.bounds;
    
  #ifndef IBUILDAPP_BUSINESS_APP
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
      tableViewFrame.origin.y = 20.0f;
      tableViewFrame.size.height -= 20.0f;
    }
  #endif
    
    _tableView = [[UITableView alloc] initWithFrame:tableViewFrame style:UITableViewStylePlain];
    
    _tableView.allowsSelection = YES;
    
    _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    _tableView.backgroundColor = self.view.backgroundColor;
    
    _tableView.autoresizesSubviews = YES;
    _tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    for(UIGestureRecognizer *recognizer in _tableView.gestureRecognizers)
    {
      [recognizer requireGestureRecognizerToFail:self.closingGestureRecognizer];
    }
    
    [_tableView addGestureRecognizer:self.closingGestureRecognizer];
  }
  
  return _tableView;
}

-(void)setSelectedWidgetAction:(IBSideBarWidgetAction *)selectedWidgetAction
{
  _selectedWidgetAction.selected = NO;
  
  [self deselectRowForAction:_selectedWidgetAction];

  [selectedWidgetAction retain];
  [_selectedWidgetAction release];
  
  _selectedWidgetAction = selectedWidgetAction;
  
  _selectedWidgetAction.selected = YES;
  
  if(_selectedWidgetAction != nil)
  {
    _selectedWidgetActionUid = _selectedWidgetAction.uid;
  } else {
    _selectedWidgetActionUid = WidgetActionUnknown;
  }
  
  [self refreshTableView];
}

-(void)refreshTableView
{
  [self actions];
  
  /*
   * One may think that just [self.tableView reloadData]; will do. Nope.
   * It has been spent many hours to refresh the table view in more traditional ways,
   * but nothing helped.
   */
  [self.tableView removeFromSuperview];
  
  [self.view addSubview:self.tableView];
  
  [self.tableView reloadData];
  
  if(_selectedWidgetAction)
  {
    [self selectRowForAction:_selectedWidgetAction];
  }
}

-(void)deselectRowForAction:(IBSideBarWidgetAction *)action
{
  NSIndexPath *path = [self indexPathForAction:action];
  
  if(!path)
  {
    return;
  }
  
  [self.tableView deselectRowAtIndexPath:path animated:NO];
}

-(void)selectRowForAction:(IBSideBarWidgetAction *)action
{
  NSIndexPath *path = [self indexPathForAction:action];
  
  if(!path)
  {
    return;
  }
  
  [self.tableView selectRowAtIndexPath:path
                              animated:NO
                        scrollPosition:UITableViewScrollPositionNone];
  
  self.tableView.contentOffset = CGPointZero;
}

-(void)setSelectedWidgetActionUid:(NSInteger)uid
{
  self.selectedWidgetAction = [self widgetActionForUid:uid];
}

-(void)reloadVisibleRows
{
  [self.tableView reloadRowsAtIndexPaths:[self.tableView indexPathsForVisibleRows]
                        withRowAnimation:UITableViewRowAnimationNone];
}

-(NSIndexPath *)indexPathForAction:(IBSideBarAction *)action
{
  NSInteger row = [self.actions indexOfObject:action];
  
  if(row == NSNotFound)
  {
    return nil;
  }
  
  NSIndexPath *path = [NSIndexPath indexPathForRow:row inSection:0];
  
  return path;
}

-(void)clearModuleActions
{
  self.moduleActions = nil;
  
  [self refreshTableView];
}

-(void)clearServiceActions
{
  self.serviceActions = nil;
  
  [self refreshTableView];
}

-(NSMutableArray *)actions
{
  if(!_actions)
  {
    _actions = [[NSMutableArray array] retain];
  }
  
  [_actions removeAllObjects];
  
  if(self.serviceActions.count)
  {
    [_actions addObjectsFromArray:self.serviceActions];
  }
  if(self.moduleActions.count)
  {
    [_actions addObjectsFromArray:self.moduleActions];
  }
  if(self.defaultActions.count)
  {
    [_actions addObjectsFromArray:self.defaultActions];
  }
  
  return _actions;
}

-(void)setServiceActions:(NSArray *)serviceActions
{
  NSMutableArray *serviceActionMutable = [serviceActions mutableCopy];
  [_serviceActions release];
  
  _serviceActions = serviceActionMutable;
  
  [self refreshTableView];
}

-(void)setDefaultActions:(NSArray *)defaultActions
{
  NSMutableArray *defaultActionsMutable = [defaultActions mutableCopy];
  [_defaultActions release];
  
  _defaultActions = defaultActionsMutable;
  
  [self refreshTableView];
}

-(void)setModuleActions:(NSArray *)moduleActions
{
  NSMutableArray *moduleActionsMutable = [moduleActions mutableCopy];
  [_moduleActions release];
  
  _moduleActions = moduleActionsMutable;

  if(_moduleActions.count)
  {
    NSRange moduleActionsRange = NSMakeRange(0, _moduleActions.count);
    NSIndexSet *moduleActionsIndexSet = [NSIndexSet indexSetWithIndexesInRange:moduleActionsRange];
    
    [self.actions insertObjects:_moduleActions atIndexes:moduleActionsIndexSet];
  }
  
  [self refreshTableView];
}

-(void)updateScrollEnabled
{
  CGFloat height = 0;
  
  for (IBSideBarAction *action in self.actions)
  {
    height += [IBSideBarTableViewCell heightForSideBarAction:action];
  }
  
  self.tableView.scrollEnabled = CGRectGetHeight(self.view.frame) < height;
}

-(BOOL)isEnabled
{
#ifdef IBUILDAPP_BUSINESS_APP
  return YES;
#else
  return self.actions.count > 0;
#endif
}


-(IBSideBarWidgetAction *)widgetActionForUid:(NSInteger)uid
{
  for(IBSideBarAction *action in self.actions)
  {
    if([action isKindOfClass:[IBSideBarWidgetAction class]])
    {
      IBSideBarWidgetAction *widgetAction = (IBSideBarWidgetAction *)action;
      
      if(widgetAction.uid == uid)
      {
        return widgetAction;
      }
    }
  }
  
  return nil;
}

+(IBSideBarActionListViewController *)appWideActionListVC
{
  static IBSideBarActionListViewController *sharedInstance = nil;
  
  static dispatch_once_t onceToken = 0;
  
  dispatch_once(&onceToken, ^{
    sharedInstance = [[IBSideBarActionListViewController alloc] init];
  });
  
  return sharedInstance;
}

#pragma mark UITableViewDataSource
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  static NSString *cellIdentifier = @"IBSideBarActionCell";
  
  IBSideBarTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
  
  if(cell == nil)
  {
    cell = [[[IBSideBarTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                          reuseIdentifier:cellIdentifier] autorelease];
  }

  IBSideBarAction *action = _actions[indexPath.row];
  action.delegate = self;
  
  cell.action = action;
  
  BOOL shouldShowSeparator = [self shouldShowSeparatorForAction:action];
  
  cell.shouldShowSeparator = shouldShowSeparator;

  return cell;
}

-(BOOL)shouldShowSeparatorForAction:(IBSideBarAction *)action
{
  if(action == _actions.lastObject)
  {
    return NO;
  }
  
  if(action == self.serviceActions.lastObject)
  {
    return YES;
  }
  
  if(action == self.moduleActions.lastObject)
  {
    return YES;
  }
  
  return NO;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
  [self updateScrollEnabled];
  
  NSInteger count =  self.actions.count;
  
  return count;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
  return 1;
}

#pragma mark UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return [IBSideBarTableViewCell heightForSideBarAction:self.actions[indexPath.row]];
}

// @"kAction" is  the key in userInfo dictionary to detect sended object in sideBarOpenNotification
// of iphmasterviewcontroller
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  IBSideBarAction *action = [self.actions objectAtIndex:indexPath.row];
  
  if([action isKindOfClass:[IBSideBarModuleAction class]])
  {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
  }
  
  void(^completion)() = ^{
    [action performAction];
  };
  
  if(action.closesSidebarWhenCalled)
  {
    NSDictionary* userInfoDict = [NSDictionary dictionaryWithObject:action
                                                     forKey:@"kAction"];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"sideBarOpenNotification"
                                                        object:nil
                                                      userInfo:userInfoDict];
  } else {
    completion();
  }
}

#pragma mark - IBSideBarAction delegate
-(void)sideBarActionHasBeenUpdated:(IBSideBarAction *)action
{
  NSIndexPath *updatedActionPath = [self indexPathForAction:action];
  
  if(!updatedActionPath)
  {
    return;
  }

  [self refreshTableView];
}

#pragma mark - Action insertion / removal
-(void)insertAction:(IBSideBarAction *)actionToInsert
        belowAction:(IBSideBarAction *)existentAction
{
  [self insertAction:actionToInsert inArrayAfterAction:existentAction];
  
  NSIndexPath *insertionIndexPath = [self indexPathForAction:actionToInsert];
  
  UITableViewRowAnimation animation = [self sharingPanelRowAnimation];
  
  [self.tableView beginUpdates];
  [self.tableView insertRowsAtIndexPaths:@[insertionIndexPath]
                        withRowAnimation:animation];
  [self.tableView endUpdates];
}

-(void)removeAction:(IBSideBarAction *)actionToRemove
{
  NSIndexPath *removalIndexPath = [self indexPathForAction:actionToRemove];
  
  BOOL success = [self removeActionFromAppropriateArray:actionToRemove];
  
  if(!success)
  {
    return;
  }
  
  UITableViewRowAnimation animation = [self sharingPanelRowAnimation];

  [self.tableView beginUpdates];
  [self.tableView deleteRowsAtIndexPaths:@[removalIndexPath]
                        withRowAnimation:animation];
  [self.tableView endUpdates];
}

-(UITableViewRowAnimation)sharingPanelRowAnimation
{
  UITableViewRowAnimation animation = UITableViewRowAnimationBottom;
  
  if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0") &&
     SYSTEM_VERSION_LESS_THAN(@"8.0"))
  {
    animation = UITableViewRowAnimationNone;
  }
  
  return animation;
}

-(void)insertAction:(IBSideBarAction *)newAction
 inArrayAfterAction:(IBSideBarAction *)existentAction
{
  NSMutableArray *appropriateArray = [self arrayForAction:existentAction];
  
  if(!appropriateArray)
  {
    return;
  }
  
  NSUInteger existentActionIndex = [appropriateArray indexOfObject:existentAction];
  NSUInteger insertionIndex = existentActionIndex + 1;
  
  [appropriateArray insertObject:newAction atIndex:insertionIndex];
}

-(BOOL)removeActionFromAppropriateArray:(IBSideBarAction *)action
{
  NSMutableArray *appropriateArray = [self arrayForAction:action];
  
  if(!appropriateArray)
  {
    return NO;
  }
  
  [appropriateArray removeObject:action];
  
  return YES;
}

-(NSMutableArray *)arrayForAction:(IBSideBarAction *)action
{
  if([self.serviceActions containsObject:action])
  {
    return (NSMutableArray *)self.serviceActions;
  }
  if([self.defaultActions containsObject:action])
  {
    return (NSMutableArray *)self.defaultActions;
  }
  if([self.moduleActions containsObject:action])
  {
    return (NSMutableArray *)self.moduleActions;
  }
  
  return nil;
}

@end
