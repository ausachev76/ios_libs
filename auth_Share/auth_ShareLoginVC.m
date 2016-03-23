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

#import "auth_ShareLoginVC.h"
#import "auth_ShareLoginEmailVC.h"

#import "MBProgressHUD.h"//<MBProgressHUD/MBProgressHUD.h>
#import "appbuilderappconfig.h"

#import "twitterid.h"//<twitterid.h>

#define baseHOST appIBuildAppHostName()
#define authBaseURL  [[@"http://" stringByAppendingString:appIBuildAppHostName()] stringByAppendingString:@"/mdscr/user/"]

#define kSocialButtonWidth 280.0f
#define kSocialButtonHeight 46.0f
#define kSocialButtonCornerRadius 4.0f

#define kFacebookButtonBackgroundColor [UIColor colorWithRed:(CGFloat)0x3b/0x100 green:(CGFloat)0x59/0x100 blue:(CGFloat)0x98/0x100 alpha:1.0f]
#define kTwitterButtonBackgroundColor [UIColor colorWithRed:(CGFloat)0x33/0x100 green:(CGFloat)0xb5/0x100 blue:(CGFloat)0xeb/0x100 alpha:1.0f]
#define kCreateNewAccountButtonBackgroundColor [UIColor colorWithRed:(CGFloat)0xea/0x100 green:(CGFloat)0xec/0x100 blue:(CGFloat)0x73/0x100 alpha:1.0f]
#define kCreateNewAccountButtonTextColor [UIColor colorWithRed:(CGFloat)0x44/0x100 green:(CGFloat)0x44/0x100 blue:(CGFloat)0x44/0x100 alpha:1.0f]

#define kSocialButtonFont [UIFont boldSystemFontOfSize:15.0f]
#define socialIconMarginLeft 10.f
#define kSocialTitleMarginLeft 14.0f

@interface auth_ShareLoginVC () {
  TPKeyboardAvoidingScrollView *sView;
  
  UITextField *eMail;
  UITextField *pWd;
  
  auth_Share *aSha;
  BOOL mayPost;
}

  @property (nonatomic, retain) NSDictionary *serverResponse;
  @property BOOL finished;
  @property (nonatomic, retain) NSMutableData *receivedData;

  @property (nonatomic, retain) UIButton *facebookButton;
  @property (nonatomic, retain) UIButton *twitterButton;
  @property (nonatomic, retain) UIButton *emailButton;

@end

@implementation auth_ShareLoginVC

@synthesize messageText;
@synthesize notificationName;

@synthesize appID;
@synthesize moduleID;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
      self.messageText      = nil;
      self.attach           = nil;
      self.notificationName = nil;
      self.messageKey       = @"message";
      self.attachKey        = @"attach";
      self.appID            = nil;
      self.moduleID         = nil;
    }
    return self;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:@"loginState"
                                                object:nil];
  self.messageText      = nil;
  self.attach           = nil;
  self.notificationName = nil;
  self.messageKey       = nil;
  self.attachKey        = nil;
  self.appID            = nil;
  self.moduleID         = nil;
  
  self.facebookButton   = nil;
  self.twitterButton    = nil;
  
  [super dealloc];
}

+(UIButton *)makeSocialButtonWithOrigin:(CGPoint)origin
                                  title:(NSString *)title
                             titleColor:(UIColor *)titleColor
                             socialIcon:(UIImage *)socialIcon
                        backgroundColor:(UIColor *)backgroundColor
                                 target:(id)target
                                 action:(SEL)action;
{
  UIButton *socialButton = [UIButton buttonWithType:UIButtonTypeCustom];
  
  socialButton.frame = CGRectMake(origin.x, origin.y, kSocialButtonWidth, kSocialButtonHeight);
  socialButton.layer.cornerRadius = kSocialButtonCornerRadius;
  socialButton.layer.masksToBounds = YES;
  [socialButton setBackgroundColor:backgroundColor];

  [socialButton addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
  socialButton.titleLabel.font = kSocialButtonFont;
  
  [socialButton setTitle:title forState:UIControlStateNormal];
  [socialButton setTitleColor:titleColor forState:UIControlStateNormal];

  if(socialIcon){
    
    UIImageView *socialIconView = [[UIImageView alloc] initWithImage:socialIcon];
    
    socialIconView.frame = CGRectMake(socialIconMarginLeft,
                                      (socialButton.frame.size.height - socialIcon.size.height) / 2,
                                      socialIcon.size.width,
                                      socialIcon.size.height);
    
    [socialButton addSubview:socialIconView];
    [socialIconView release];
    
    [socialButton setContentHorizontalAlignment: UIControlContentHorizontalAlignmentLeft];
    
    CGSize titleSize = [title sizeWithFont:socialButton.titleLabel.font];
    
    CGFloat minTitleOriginX = ceilf(CGRectGetMaxX(socialIconView.frame) + kSocialTitleMarginLeft);
    CGFloat titleOriginX = ceilf((socialButton.frame.size.width - titleSize.width) / 2.0f);
    
    titleOriginX = titleOriginX < minTitleOriginX ? minTitleOriginX : titleOriginX;
    
    [socialButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0f, titleOriginX, 0.0f, 0.0f)];
    
  } else {
    [socialButton setContentHorizontalAlignment: UIControlContentHorizontalAlignmentCenter];
  }
  
  return socialButton;
}

- (void)viewDidLoad {
  
  mayPost = YES;
  
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(loginStateNotification:)
                                               name:@"loginState"
                                             object:nil];
  
  [self.navigationController setNavigationBarHidden:NO animated:YES];
  self.navigationItem.hidesBackButton = YES;
  
  self.navigationItem.title = NSLocalizedString(@"mAP_LoginTitle", @"Login");
  
  aSha = [auth_Share sharedInstance];
  aSha.delegate = nil;
  aSha.viewController = self;
  
  sView = [[TPKeyboardAvoidingScrollView alloc] initWithFrame:self.view.bounds];
  sView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
  sView.autoresizesSubviews = YES;
  sView.backgroundColor = [UIColor clearColor];
  [self.view addSubview:sView];
  
  self.view.backgroundColor = [UIColor colorWithRed:243.0f/256.0f green:243.0f/256.0f blue:243.0f/256.0f alpha:1.0f];
  
  self.facebookButton = [[self class] makeSocialButtonWithOrigin:(CGPoint){20.0f, 20.0f}
                                                            title:NSLocalizedString(@"mAP_loginFacebookButtonTitle", @"Login with Facebook")
                                                       titleColor:[UIColor whiteColor]
                                                       socialIcon:[UIImage imageNamed:@"fb_logo"]
                                                  backgroundColor:kFacebookButtonBackgroundColor
                                                          target:self
                                                          action:@selector(FacebookButtonClicked)];
  
  [sView addSubview:self.facebookButton];

  
  self.twitterButton = [[self class] makeSocialButtonWithOrigin:(CGPoint){20.0f, 76.0f}
                                                           title:NSLocalizedString(@"mAP_loginTwitterButtonTitle", @"Login with Twitter")
                                                      titleColor:[UIColor whiteColor]
                                                      socialIcon:[UIImage imageNamed:@"twitter_logo"]
                                                 backgroundColor:kTwitterButtonBackgroundColor
                                                          target:self
                                                          action:@selector(TwitterButtonClicked)];
  
  [sView addSubview:self.twitterButton];

  UIImageView *circle = [[UIImageView alloc] initWithImage:[UIImage imageNamed:resourceFromBundle(@"_aSha_WhiteRound.png")]];
  circle.frame = CGRectMake(145.0f, 137.0f, 30.0f, 30.0f);
  [sView addSubview:circle];
  [circle release];
  
  UILabel *orString = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 141.0f, 320.0f, 20.0f)];
  orString.backgroundColor = [UIColor clearColor];
  orString.textAlignment = NSTextAlignmentCenter;
  orString.textColor = [UIColor darkGrayColor];
  orString.text = NSLocalizedString(@"mAP_Or", @"or");
  [sView addSubview:orString];
  [orString release];
  
  UITableView *signUpTable = [[UITableView alloc] initWithFrame:CGRectMake(12.0f, 172.0f, 296.0f, 109.0f) style:UITableViewStyleGrouped];
  [signUpTable setDelegate:self];
  [signUpTable setDataSource:self];
  [sView addSubview:signUpTable];
  
#ifdef __IPHONE_7_0
  if ([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
  {
    signUpTable.frame = CGRectMake(22.0f, 172.0f, 276.0f, 109.0f);
    
    if ([signUpTable respondsToSelector:@selector(setSeparatorInset:)])
      [signUpTable setSeparatorInset:UIEdgeInsetsZero];
    
    if ([signUpTable respondsToSelector:@selector(setLayoutMargins:)])
      [signUpTable setLayoutMargins:UIEdgeInsetsZero];
    
    signUpTable.contentInset = UIEdgeInsetsMake(-20, 0, 0, 0);
  }
#endif
  
  signUpTable.scrollEnabled = NO;
  signUpTable.backgroundView = nil;
  signUpTable.backgroundColor = [UIColor clearColor];
  
  [signUpTable reloadData];
  
  UIButton *createAccountButton = [[self class] makeSocialButtonWithOrigin:(CGPoint){20.0f, 286.0f}
                                                                     title:NSLocalizedString(@"mAP_CreateNewAccount", @"Create New Account")
                                                                titleColor:kCreateNewAccountButtonTextColor
                                                                socialIcon:nil
                                                           backgroundColor:kCreateNewAccountButtonBackgroundColor
                                                                    target:self
                                                                    action:@selector(createAccountButtonClicked)];
  [sView addSubview:createAccountButton];
  
  UIButton *signInButton = [UIButton buttonWithType:UIButtonTypeCustom];
  signInButton.frame = CGRectMake(20.0f, 331.0f, 280.0f, 46.0f);
  signInButton.layer.cornerRadius = 4.0f;
  signInButton.layer.masksToBounds = YES;
  
  [signInButton addTarget:self action:@selector(logInButtonClicked) forControlEvents:UIControlEventTouchUpInside];
  signInButton.titleLabel.font = [UIFont systemFontOfSize:14.0f];
  [signInButton setTitle:NSLocalizedString(@"mAP_HaveAnAccount", @"I have an account") forState:UIControlStateNormal];
  [signInButton setTitleColor:[UIColor colorWithRed:0x55/256.0f green:0x55/256.0f blue:0x55/256.0f alpha:1.0f] forState:UIControlStateNormal];
  
  CGFloat lineWidth = [signInButton.titleLabel.text sizeWithFont:signInButton.titleLabel.font].width;
  UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake((signInButton.frame.size.width - lineWidth) /2, 30.0f, lineWidth, 1.0f)];
  lineView.backgroundColor = [UIColor colorWithRed:0x55/256.0f green:0x55/256.0f blue:0x55/256.0f alpha:1.0f];
  [signInButton addSubview:lineView];
  [lineView release];
  
  [sView addSubview:signInButton];
  
  self.navigationItem.hidesBackButton = NO;
}

- (void)viewWillAppear:(BOOL)animated {
  UIBarButtonItem *cancelBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(goBack)];
  self.navigationItem.leftBarButtonItem = cancelBtn;
  [cancelBtn release];
  mayPost = YES;
}

- (void)viewWillDisppear:(BOOL)animated {
  mayPost = YES;
}

- (void)goBack {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loginStateNotification:(NSNotification *)notification {
  @synchronized(self){
    if(mayPost){
      mayPost = NO;
      NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:
                                @[self.messageText ? self.messageText : [NSNull null], self.attach ? self.attach:[NSNull null]]
                                                           forKeys:@[self.messageKey, self.attachKey]];
      
      id loginType = notification.object;
      if([loginType isKindOfClass:[NSString class]]){
        if([loginType isEqualToString:@"twitter"]){
          [self performSelector:@selector(goBack) withObject:nil afterDelay:0.6];
          [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationName object:nil userInfo:userInfo];
          return;
        }
      }
      [self goBack];
      
      [[NSNotificationCenter defaultCenter] postNotificationName:self.notificationName object:nil userInfo:userInfo];
    }
  }
}

- (void)FacebookButtonClicked {
  [aSha authenticatePersonUsingService:auth_ShareServiceTypeFacebook andCredentials:nil withCompletion:nil andData:nil shouldShowLoginRequiredPrompt:NO];
}

- (void)TwitterButtonClicked {
  [aSha authenticatePersonUsingService:auth_ShareServiceTypeTwitter andCredentials:nil];
}

- (void)createAccountButtonClicked {
  [sView setTransform:CGAffineTransformMakeTranslation(0.0f, 0.0f)];
  [UIView beginAnimations:nil context:nil];
  [UIView setAnimationDuration:0.3f];
  [self.view setTransform:CGAffineTransformMakeTranslation(0.0f, 0.0f)];
  [UIView commitAnimations];

  if(eMail.isFirstResponder)      [eMail resignFirstResponder];
  if(pWd.isFirstResponder)        [pWd resignFirstResponder];
  
  NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
                          @"",        @"firstname",
                          @"",        @"lastname",
                          eMail.text, @"email",
                          pWd.text,   @"password",
                          @"",        @"password_confirm",
                          nil];
  [MBProgressHUD showHUDAddedTo:self.view animated:YES];

  self.view.userInteractionEnabled = NO;
  
  [self registerUserWithParameters:params];
  int i = 0;
  while (self.finished == NO) {
    [[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.1f]];
    NSLog(@"registering user: %.1f seconds", ++i * 0.1f);
  }
  
  self.view.userInteractionEnabled = YES;
  
  [MBProgressHUD hideAllHUDsForView:self.view animated:YES];
  
  if(self.serverResponse && ![[self.serverResponse objectForKey:@"error"] length]) {
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
    
    [self dismissViewControllerAnimated:YES completion:nil];
  } else {
    
    NSString *message = nil;
    
    message = NSLocalizedString(@"mAP_signUpError08", @"All fields are required.");
    
    if([[self.serverResponse objectForKey:@"error"] isEqualToString:@"Please enter a valid email address."]) message = NSLocalizedString(@"mAP_signUpError04", @"Email address is invalid. Please try again.");
    
    if([[self.serverResponse objectForKey:@"error"] isEqualToString:@"Please enter at least 4 characters."]) message = NSLocalizedString(@"mAP_signUpError05", @"Password must be at least 4 characters long.");
    
    if([[self.serverResponse objectForKey:@"error"] isEqualToString:@"User exists"]) message = NSLocalizedString(@"mAP_signUpError07", @"This email is in use. Please use another email address.");
    
    [[[[UIAlertView alloc] initWithTitle:@""
                                 message:message
                                delegate:self
                       cancelButtonTitle:NSLocalizedString(@"mAP_signUpErrorAlertOkButtonTitle", @"OK")
                       otherButtonTitles:nil] autorelease] show];
  }
}

- (void)registerUserWithParameters:(NSDictionary *)parameters {
  NSLog(@"Try to register user");
  
  NSString *boundary = [NSString stringWithFormat:@"---###---%@--##--%@--###---BOUNDARY---###", self.appID, self.moduleID];
  NSMutableData *postBody = [NSMutableData data];
  NSString *postString = nil;
  
  postString = [NSString stringWithFormat:@"\r\n--%@\r\n", boundary];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"action\"\r\n\r\nsignup"];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"firstname\"\r\n\r\n"];
  postString = [postString stringByAppendingString:[parameters objectForKey:@"firstname"]];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"lastname\"\r\n\r\n"];
  postString = [postString stringByAppendingString:[parameters objectForKey:@"lastname"]];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"email\"\r\n\r\n"];
  postString = [postString stringByAppendingString:[parameters objectForKey:@"email"]];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"password\"\r\n\r\n"];
  postString = [postString stringByAppendingString:[parameters objectForKey:@"password"]];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"password_confirm\"\r\n\r\n"];
  postString = [postString stringByAppendingString:[parameters objectForKey:@"password_confirm"]];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"app_id\"\r\n\r\n"];
  postString = [postString stringByAppendingString:self.appID];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundary]];
  postString = [postString stringByAppendingString:@"Content-Disposition: form-data; name=\"token\"\r\n\r\n"];
  postString = [postString stringByAppendingString:appToken()];
  
  postString = [postString stringByAppendingString:[NSString stringWithFormat:@"\r\n--%@--\r\n", boundary]];
  
  [postBody appendData:[postString dataUsingEncoding:NSUTF8StringEncoding]];
  
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:[authBaseURL stringByAppendingString:@"signup"]]
                                                         cachePolicy:NSURLRequestReturnCacheDataElseLoad
                                                     timeoutInterval:60.0f];
  [request setHTTPMethod:@"POST"];
  
  [request setValue:@"AudioPlayer/iPhone" forHTTPHeaderField:@"User-Agent"];
  [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
  [request setValue:[@"multipart/form-data; boundary=" stringByAppendingString:boundary] forHTTPHeaderField:@"Content-Type"];
  [request setValue:baseHOST forHTTPHeaderField:@"Host"];
  [request setValue:[NSString stringWithFormat:@"%lu", (long unsigned)postBody.length] forHTTPHeaderField:@"Content-Length"];
  
  [request setHTTPBody:postBody];
  
  [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
  
  [[[NSURLConnection alloc] initWithRequest:request delegate:self] autorelease];
  
  self.receivedData = [NSMutableData data];
  self.finished = NO;
}

- (void)logInButtonClicked {
  auth_ShareLoginEmailVC *LogInEMail = [[auth_ShareLoginEmailVC alloc] init];
  
  LogInEMail.appID    = self.appID;
  LogInEMail.moduleID = self.moduleID;
  
  UINavigationController *navController = [[[UINavigationController alloc] initWithRootViewController:LogInEMail] autorelease];
  navController.modalPresentationStyle = UIModalPresentationFormSheet;
  
  navController.navigationBar.barStyle = self.navigationController.navigationBar.barStyle;
  navController.navigationBar.translucent = self.navigationController.navigationBar.translucent;
  navController.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
  
#ifdef __IPHONE_7_0
  if([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending)
    navController.navigationBar.barTintColor = self.navigationController.navigationBar.barTintColor;
  navController.navigationBar.titleTextAttributes = self.navigationController.navigationBar.titleTextAttributes;
#endif

  [self presentViewController:navController animated:YES completion:nil];
  [LogInEMail release];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return 2;
}

- (CGFloat)tableView:textLabeltableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  return 44.0f;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  static NSString *CellWReplies = @"CellWReplies";
  
  UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellWReplies];
  
  if (cell == nil) {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellWReplies] autorelease];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor whiteColor];
  }
  
  switch (indexPath.row) {
    case 0: {
      eMail = [[[UITextField alloc] init] autorelease];
      eMail.autocorrectionType = UITextAutocorrectionTypeNo;
      eMail.autocapitalizationType = UITextAutocapitalizationTypeNone;
      eMail.delegate = self;
      eMail.frame = CGRectMake(15.0f, 0.0f, cell.frame.size.width - 30.0f, cell.frame.size.height);
      eMail.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
      eMail.font = [UIFont systemFontOfSize:17.0f];
      eMail.textAlignment = NSTextAlignmentLeft;
      eMail.textColor = [UIColor colorWithRed:0x99/256.0f green:0x99/256.0f blue:0x99/256.0f alpha:1.0f];
      eMail.placeholder = NSLocalizedString(@"mAP_emailFieldPlaceholder", @"Email");
      eMail.text = @"";
      eMail.keyboardType = UIKeyboardTypeEmailAddress;
      eMail.returnKeyType = UIReturnKeyDone;
      [cell addSubview:eMail];
      break;
    }
    case 1: {
      pWd = [[[UITextField alloc] init] autorelease];
      pWd.autocorrectionType = UITextAutocorrectionTypeNo;
      pWd.autocapitalizationType = UITextAutocapitalizationTypeNone;
      pWd.delegate = self;
      pWd.frame = CGRectMake(15.0f, 0.0f, cell.frame.size.width - 30.0f, cell.frame.size.height);
      pWd.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
      pWd.font = [UIFont systemFontOfSize:17.0f];
      pWd.textAlignment = NSTextAlignmentLeft;
      pWd.textColor = [UIColor colorWithRed:0x99/256.0f green:0x99/256.0f blue:0x99/256.0f alpha:1.0f];
      pWd.placeholder = NSLocalizedString(@"mAP_passwordFieldPlaceholder", @"Password");
      pWd.text = @"";
      pWd.keyboardType = UIKeyboardTypeDefault;
      pWd.returnKeyType = UIReturnKeyDone;
      pWd.secureTextEntry = YES;
      pWd.delegate = self;
      [pWd resignFirstResponder];
      [cell addSubview:pWd];
      break;
    }
  }
  return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

#pragma mark TEXTFIELD DELEGATE
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  
  [self createAccountButtonClicked];
  
  return YES;
}

#pragma mark autorotation
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
  return UIInterfaceOrientationIsPortrait( toInterfaceOrientation );
}

-(BOOL)shouldAutorotate
{
  return NO;
}

- (NSUInteger)supportedInterfaceOrientations
{
  return UIInterfaceOrientationMaskPortrait |
  UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
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