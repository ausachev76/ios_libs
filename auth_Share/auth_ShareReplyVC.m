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

#import "auth_ShareReplyVC.h"

#define kTextViewMarginX 10.f
#define kTextViewMarginY 10.f

#define kLettersUnlimitedCount NSIntegerMax

@implementation auth_ShareReplyVC

@synthesize textView = _textView;
@synthesize data = _data;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
  self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
  if (self) {
    _textView = nil;
    _data     = nil;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShown:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    self.view.backgroundColor = [UIColor blackColor];
    
    _textView = [[UITextView alloc] init];
    _textView.autoresizesSubviews = YES;
    _textView.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    _textView.font = [UIFont systemFontOfSize:17.0f];
    _textView.layer.cornerRadius  = 6.0f;
    _textView.layer.masksToBounds = YES;
    
    _maxMessageLength = kLettersUnlimitedCount;
    
    [self.view addSubview:self.textView];
  }
  return self;
}

-(void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:UIKeyboardWillShowNotification
                                                object:nil];
  if(_textView){
    [_textView release];
    _textView = nil;
  }
  
  if(_data){
    [_data release];
    _data = nil;
  }
  
  [super dealloc];
}

- (void)viewDidLoad {
  [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
}

#pragma mark keyboard notification handler
- (void)keyboardWillShown:(NSNotification*)aNotification {
  NSDictionary* info = [aNotification userInfo];
  CGRect keyboardFrame = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
  
  CGRect txtRect = _textView.frame;
  txtRect.size.height = self.view.bounds.size.height - keyboardFrame.size.height - kTextViewMarginY * 2.f;
  txtRect.size.width  = self.view.bounds.size.width  - kTextViewMarginX * 2.f;
  txtRect.origin.x    = kTextViewMarginX;
  txtRect.origin.y    = kTextViewMarginY;
  _textView.frame = CGRectMake(txtRect.origin.x + txtRect.size.width,
                               txtRect.origin.y + txtRect.size.height,0,0);
  
  //  [UIView beginAnimations:nil context:nil];
  //  [UIView setAnimationDuration:0.35f];
  _textView.frame = txtRect;
  _textView.delegate = self;
  //  [UIView commitAnimations];
}

#pragma mark autorotation
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
  return UIInterfaceOrientationIsPortrait( toInterfaceOrientation );
}

-(BOOL)shouldAutorotate {
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
  return UIInterfaceOrientationMaskPortrait |
  UIInterfaceOrientationMaskPortraitUpsideDown;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
  return UIInterfaceOrientationPortrait;
}

- (void)viewWillAppear:(BOOL)animated {
  [_textView becomeFirstResponder];
  [super viewWillAppear:animated];
}

//avoid ugly partial dismissing when keyboard hides after the controller's view did
- (void)viewWillDisappear:(BOOL)animated {
  [_textView resignFirstResponder];
  [super viewWillDisappear:animated];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
  
  if(range.length + range.location > textView.text.length)
  {
    return NO;
  }
  
  NSUInteger newLength = [textView.text length] + [text length] - range.length;
  return (newLength > _maxMessageLength) ? NO : YES;
}

@end