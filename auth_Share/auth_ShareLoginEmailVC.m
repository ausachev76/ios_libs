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

#import "auth_ShareLoginEmailVC.h"
#import "auth_Share.h"
#import "MBProgressHUD.h"//<MBProgressHUD/MBProgressHUD.h>
#import "appbuilderappconfig.h"

#define baseHOST appIBuildAppHostName()
#define authBaseURL  [[@"http://" stringByAppendingString:appIBuildAppHostName()] stringByAppendingString:@"/mdscr/user/"]

#define kLoginButtonBackgroundColor [UIColor colorWithRed:(CGFloat)0x45/0x100 green:(CGFloat)0xbf/0x100 blue:(CGFloat)0x1b/0x100 alpha:1.0f]

@interface auth_ShareLoginEmailVC()
  @property (nonatomic, retain) NSDictionary *serverResponse;
  @property BOOL finished;
  @property (nonatomic, retain) NSMutableData *receivedData;
@end

@implementation auth_ShareLoginEmailVC {
  UITableView *table;
  UITextField *eMail;
  UITextField *pWd;
  UILabel *firstString;
  UIToolbar *navBar;
  NSUserDefaults *UD;
  UIButton *logInButton;
  
  auth_Share *aSha;
}

@synthesize serverResponse;
@synthesize finished;
@synthesize receivedData;

@synthesize appID;
@synthesize moduleID;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    self.appID            = nil;
    self.moduleID         = nil;
  }
  return self;
}

- (void)dealloc {
  self.appID            = nil;
  self.moduleID         = nil;
  
  [super dealloc];
}

-(void)viewDidLoad {
  aSha = [auth_Share sharedInstance];
  
  [self.navigationController setNavigationBarHidden:NO animated:NO];
  self.navigationItem.title = NSLocalizedString(@"mAP_LoginTitle", @"Login");
  
  table = [[UITableView alloc] initWithFrame:CGRectMake(12.0f, 20.0f, 296.0f, 109.0f) style:UITableViewStyleGrouped];
  table.backgroundColor = [UIColor clearColor];
  table.dataSource = self;
  table.delegate = self;
  table.scrollEnabled = NO;
  
#ifdef __IPHONE_7_0
  if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
  {
    table.frame = CGRectMake(22.0f, 20.0f, 276.0f, 109.0f);
    
    if ([table respondsToSelector:@selector(setSeparatorInset:)])
      [table setSeparatorInset:UIEdgeInsetsZero];
    
    if ([table respondsToSelector:@selector(setLayoutMargins:)])
      [table setLayoutMargins:UIEdgeInsetsZero];
    
    table.contentInset = UIEdgeInsetsMake(-20, 0, 0, 0);
  }
#endif
  
  UIView *backgroundView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
  backgroundView.backgroundColor = [UIColor clearColor];
  table.backgroundView = backgroundView;
  [backgroundView release];
  
  [self.view addSubview:table];
  
  self.view.backgroundColor = [UIColor colorWithRed:243.0f/256.0f green:243.0f/256.0f blue:243.0f/256.0f alpha:1.0f];

  logInButton = [auth_ShareLoginVC makeSocialButtonWithOrigin:(CGPoint){20.0f, 144.0f}
                                                title:NSLocalizedString(@"mAP_loginButtonTitle", @"Login")
                                           titleColor:[UIColor whiteColor]
                                           socialIcon:nil
                                      backgroundColor:kLoginButtonBackgroundColor
                                               target:self
                                               action:@selector(logInButtonClicked)];

  [self.view addSubview:logInButton];
  
  [super viewDidLoad];
}

-(void)viewWillAppear:(BOOL)animated {
  UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(goBack)];
  self.navigationItem.leftBarButtonItem = cancelBtn;

  [cancelBtn release];
}

-(void)goBack {
  [self dismissViewControllerAnimated:YES completion:nil];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 2;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellIdentifier = @"Cell";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier] autorelease];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.font = [UIFont boldSystemFontOfSize:15.0f];
    cell.backgroundColor = [UIColor whiteColor];
    
    switch (indexPath.row) {
      case 0:
        eMail = [[UITextField alloc] init];
        eMail.autocorrectionType = UITextAutocorrectionTypeNo;
        eMail.autocapitalizationType = UITextAutocapitalizationTypeNone;
        eMail.delegate = self;
        eMail.frame = CGRectMake(20.0f, 0.0f, 280.0f, 44.0f);
        eMail.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        eMail.font = [UIFont systemFontOfSize:18.0f];

        eMail.textAlignment = NSTextAlignmentLeft;

        eMail.placeholder = NSLocalizedString(@"mAP_emailFieldPlaceholder", @"Email");
        eMail.text = @"";
        eMail.keyboardType = UIKeyboardTypeEmailAddress;
        eMail.returnKeyType = UIReturnKeyDone;
        
        [cell addSubview:eMail];
        break;
        
      case 1:
        pWd = [[UITextField alloc] init];
        pWd.autocorrectionType = UITextAutocorrectionTypeNo;
        pWd.autocapitalizationType = UITextAutocapitalizationTypeNone;
        pWd.delegate = self;
        pWd.frame = CGRectMake(20.0f, 0.0f, 280.0f, 44.0f);
        pWd.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        pWd.font = [UIFont systemFontOfSize:18.0f];
        pWd.textAlignment = NSTextAlignmentLeft;
        pWd.placeholder = NSLocalizedString(@"mAP_passwordFieldPlaceholder", @"Password");
        pWd.text = @"";
        pWd.keyboardType = UIKeyboardTypeDefault;
        pWd.returnKeyType = UIReturnKeyDone;
        pWd.secureTextEntry = YES;
        pWd.delegate = self;
        [pWd resignFirstResponder];
        pWd.tag = 1;
        
        [cell addSubview:pWd];
        break;
    }
  }
  return cell;
}

#define MAX_LENGTH 40 // Max password length

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
  if(textField.tag == 1) {
    NSUInteger newLength = (textField.text.length - range.length) + string.length;
    if(newLength <= MAX_LENGTH)
    {
      return YES;
    }
    else
    {
      NSUInteger emptySpace = MAX_LENGTH - (textField.text.length - range.length);
      textField.text = [[[textField.text substringToIndex:range.location] stringByAppendingString:[string substringToIndex:emptySpace]] stringByAppendingString:[textField.text substringFromIndex:(range.location + range.length)]];
      return NO;
    }
  }
  return YES;
}

-(void)logInButtonClicked
{
  if(eMail.isFirstResponder) [eMail resignFirstResponder];
  if(pWd.isFirstResponder)   [pWd   resignFirstResponder];
  
  if (pWd.text.length < 4 || eMail.text.length < 4)
  {
    NSString *errorMessage = NSLocalizedString(@"mAP_loginError01", nil);
    [[[[UIAlertView alloc] initWithTitle:@""
                                 message:errorMessage
                                delegate:self
                       cancelButtonTitle:NSLocalizedString(@"OK", nil)
                       otherButtonTitles:nil] autorelease] show];
    return;
  }
  
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.3f];
  [self.view setTransform:CGAffineTransformMakeTranslation(0.0f, 0.0f)];
  navBar.frame = CGRectMake(0.0f, 0.0f, 320.0f, 44.0f);
  [UIView commitAnimations];
  
  [MBProgressHUD showHUDAddedTo:self.view animated:YES];

  self.view.userInteractionEnabled = NO;
  navBar.userInteractionEnabled = NO;
  
  [self loginWithEmail:eMail.text andPassword:pWd.text];
  int i = 0;
  while (self.finished == NO)
  {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1f]];
    NSLog(@"login user: %.1f seconds", ++i * 0.1f);
  }

  self.view.userInteractionEnabled = YES;
  navBar.userInteractionEnabled = YES;
  
  [MBProgressHUD hideAllHUDsForView:self.view animated:YES];

  if(self.serverResponse && ![[self.serverResponse objectForKey:@"error"] length])
  {
    aSha.user.authentificatedWith =  auth_ShareServiceTypeEmail;
    aSha.user.type                =  @"ibuildapp";
    aSha.user.name                =  [[self.serverResponse objectForKey:@"data"] objectForKey:@"username"];
    aSha.user.ID                  =  [[self.serverResponse objectForKey:@"data"] objectForKey:@"user_id"];
    aSha.user.avatar              =  [[self.serverResponse objectForKey:@"data"] objectForKey:@"user_avatar"];
    
    [UD setInteger:aSha.user.authentificatedWith forKey:@"mAuthentificatedWith"];
    [UD setObject :aSha.user.type                forKey:@"mAccountType"];
    [UD setObject :aSha.user.ID                  forKey:@"mAccountID"];
    [UD setObject :aSha.user.name                forKey:@"mUserName"];
    [UD setObject :aSha.user.avatar              forKey:@"mAvatar"];
    [UD synchronize];
    
    [self dismissViewControllerAnimated:NO completion:nil];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"loginState" object:nil userInfo:[NSDictionary dictionaryWithObject:@"ibuildapp" forKey:@"type"]];
  } else {

    [[[[UIAlertView alloc] initWithTitle:@""
                                 message:NSLocalizedString(@"mAP_loginError03", @"The username and password did not match\nour records, please try again")
                                delegate:self
                       cancelButtonTitle:NSLocalizedString(@"mAP_loginErrorAlertOkButtonTitle", @"OK")
                       otherButtonTitles:nil] autorelease] show];
  }
}

-(void)loginWithEmail:(NSString *)email andPassword:(NSString *)password
{
  
  NSLog(@"Request for login");
  
  NSString *boundary = [NSString stringWithFormat:@"---###---%@--##--%@--###---BOUNDARY---###", self.appID, @"5"];
  NSMutableData *postBody = [NSMutableData data];
  NSString *postString = nil;
  
  postString = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"login\"\r\n\r\n"];
  postString = [postString stringByAppendingString:email];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"password\"\r\n\r\n"];
  postString = [postString stringByAppendingString:password];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"app_id\"\r\n\r\n"];
  postString = [postString stringByAppendingString:self.appID];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"token\"\r\n\r\n"];
  postString = [postString stringByAppendingString:appToken()];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary]];
  
  [postBody appendData:[postString dataUsingEncoding:NSUTF8StringEncoding]];
  
  NSString *requestURL = [authBaseURL stringByAppendingString:@"login"];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:requestURL]
                                                         cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                     timeoutInterval:60.0f];
  [request setHTTPMethod:@"POST"];
  
  [request setValue:@"VideoPlayer/iPhone" forHTTPHeaderField:@"User-Agent"];
  [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
  [request setValue:[@"multipart/form-data; boundary=" stringByAppendingString:boundary] forHTTPHeaderField:@"Content-Type"];
  [request setValue:baseHOST forHTTPHeaderField:@"Host"];
  [request setValue:[NSString stringWithFormat:@"%lu", (long unsigned)postBody.length] forHTTPHeaderField:@"Content-Length"];
  
  [request setHTTPBody:postBody];
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
  
  self.receivedData = [NSMutableData data];
  
  NSLog(@"login answer: %lu bytes", (long unsigned)self.receivedData.length);
  self.finished = NO;
}

-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.25f];
  [self.view setTransform:CGAffineTransformMakeTranslation(0.0f, -28.0f)];
  navBar.frame = CGRectMake(0.0f, 28.0f, 320.0f, 44.0f);
  [UIView commitAnimations];
  return YES;
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.25f];
  [self.view setTransform:CGAffineTransformMakeTranslation(0.0f, 0.0f)];
  navBar.frame = CGRectMake(0.0f, 0.0f, 320.0f, 44.0f);
  [UIView commitAnimations];
  
  [self logInButtonClicked];
  
  return YES;
}

-(BOOL)nsStringIsValidEmail:(NSString *)checkString {
  BOOL stricterFilter = YES;
  NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
  NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
  NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
  NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
  return [emailTest evaluateWithObject:checkString];
}

#pragma mark Autorotation

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  return UIInterfaceOrientationIsPortrait( toInterfaceOrientation );
}

-(BOOL)shouldAutorotate {
  return YES;
}

-(NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait |
  UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
  return UIInterfaceOrientationPortrait;
}

#pragma mark NSURLConnection delegate

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)theData {
  [self.receivedData appendData:theData];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection {
  NSError *error = nil;
  self.serverResponse = [NSJSONSerialization JSONObjectWithData:self.receivedData options:NSJSONReadingMutableLeaves error:&error];
  self.finished = YES;
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
  NSLog(@">>> Failed With Error %@", error);
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

@end