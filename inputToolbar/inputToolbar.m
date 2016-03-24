#import "inputToolbar.h"

#import "NSString+size.h"

@implementation inputToolbar {
  UIColor *buttonColor;
}

@synthesize inputButton;

-(void)inputButtonPressed
{
  NSString *messageText = [self.textView.text copy];
  
  if ([self.textView.text length] > 0) {
    
    /* Remove the keyboard and clear the text */
    [self.textView resignFirstResponder];
    [self.textView clearText];
  }
  
  [[NSNotificationCenter defaultCenter] postNotificationName:@"APPostComment" object:nil userInfo:[NSDictionary dictionaryWithObject:messageText forKey:@"message"]];
}

- (void)drawRect:(CGRect)rect
{
  if([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
    [[UIColor colorWithWhite:1.0f alpha:1.0f] set];
  } else {
    [[UIColor colorWithWhite:0.0f alpha:0.4f] set];
  }
  CGContextFillRect(UIGraphicsGetCurrentContext(), rect);
}

-(void)setupToolbar:(NSString *)buttonLabel withColor:(UIColor *)color
{
  buttonColor = color;
  
  self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin;

  /* Create custom send button*/
  self.inputButton = [UIButton buttonWithType:UIButtonTypeCustom];
  
  [self.inputButton setTitle:buttonLabel forState:UIControlStateNormal];
  
  CGSize buttonSize = [self.inputButton.titleLabel.text sizeForFont:self.inputButton.titleLabel.font
                                                          limitSize:CGSizeMake(120.0f, 18.0f)
                                                    nslineBreakMode:self.inputButton.titleLabel.lineBreakMode];
  
  if(buttonSize.width < 60.0f) buttonSize.width = 60.0f;
  
  self.inputButton.frame = CGRectMake(self.bounds.size.width - buttonSize.width - 5.0f, 5.0f, buttonSize.width, self.bounds.size.height - 10.0f);
  self.inputButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleWidth;
  
  if([[[UIDevice currentDevice] systemVersion] compare:@"7.0" options:NSNumericSearch] != NSOrderedAscending) {
    self.inputButton.titleLabel.font = [UIFont systemFontOfSize:17];
    [self.inputButton setTitleColor:color forState:UIControlStateNormal];
    [self.inputButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateDisabled];
    self.backgroundColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
  } else {
    UIImage *sendButtonBGImage = [UIImage imageNamed:@"_mAP_btn_post.png"];
    float sendButtonW = sendButtonBGImage.size.width  / 2,
    sendButtonH = sendButtonBGImage.size.height / 2;
    UIImage *sendButtonStretchedImage = [sendButtonBGImage stretchableImageWithLeftCapWidth:sendButtonW topCapHeight:sendButtonH];
    [self.inputButton setBackgroundImage:sendButtonStretchedImage forState:UIControlStateNormal];
    self.inputButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    [self.inputButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.4f];
  }
  
  
  [self.inputButton addTarget:self action:@selector(inputButtonPressed) forControlEvents:UIControlEventTouchDown];
  
  [self addSubview:self.inputButton];
  
  self.inputButton.enabled = YES;

  self.textView = [[expandingTextView alloc] initWithFrame:CGRectMake(10.0f, 5.0f, self.bounds.size.width - buttonSize.width - 20.0f, self.bounds.size.height - 10.0f)];
  
  self.textView.layer.borderColor = [UIColor colorWithWhite:0xCE / 256.0 alpha:1.0f].CGColor;
  self.textView.layer.borderWidth = 1.0f;
  self.textView.layer.cornerRadius = 3.0f;
  self.textView.layer.backgroundColor = [UIColor whiteColor].CGColor;
  self.textView.alpha = 1.0f;
  
  self.textView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
  self.textView.delegate = self;
  [self addSubview:self.textView];
}

-(id)initWithColor:(UIColor *)color andFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame])) {
    [self setupToolbar:NSLocalizedString(@"mAP_messageInputButtonTitle", @"Post") withColor:(UIColor *)color];
  }
  return self;
}

-(id)initWithFrame:(CGRect)frame
{
    return self;
}

-(id)init
{
    return self;
}

#pragma mark -
#pragma mark UIExpandingTextView delegate

-(void)expandingTextView:(expandingTextView *)expandingTextView willChangeHeight:(float)height
{
    /* Adjust the height of the toolbar when the input component expands */
    float diff = (self.textView.frame.size.height - height);
    CGRect r = self.frame;
    r.origin.y += diff;
    r.size.height -= diff;
    self.frame = r;
    if ([self.inputDelegate respondsToSelector:_cmd]) {
        [self.inputDelegate expandingTextView:expandingTextView willChangeHeight:height];
    }
}

-(void)expandingTextViewDidChange:(expandingTextView *)expandingTextView
{
    /* Enable/Disable the button */
  if ([expandingTextView.text length] > 0) {
    self.inputButton.enabled = YES;
  } else {
    self.inputButton.enabled = NO;
  }

  if ([self.inputDelegate respondsToSelector:@selector(expandingTextViewDidChange:)])
        [self.inputDelegate expandingTextViewDidChange:expandingTextView];
}

- (BOOL)expandingTextViewShouldReturn:(expandingTextView *)expandingTextView
{
  return NO;
}

- (BOOL)expandingTextViewShouldBeginEditing:(expandingTextView *)expandingTextView
{
    if ([self.inputDelegate respondsToSelector:_cmd]) {
        return [self.inputDelegate expandingTextViewShouldBeginEditing:expandingTextView];
    }
    return YES;
}

- (BOOL)expandingTextViewShouldEndEditing:(expandingTextView *)expandingTextView
{
    if ([self.inputDelegate respondsToSelector:_cmd]) {
        return [self.inputDelegate expandingTextViewShouldEndEditing:expandingTextView];
    }
    return YES;
}

- (void)expandingTextViewDidBeginEditing:(expandingTextView *)expandingTextView
{
    if ([self.inputDelegate respondsToSelector:_cmd]) {
        [self.inputDelegate expandingTextViewDidBeginEditing:expandingTextView];
    }
}

- (void)expandingTextViewDidEndEditing:(expandingTextView *)expandingTextView
{
    if ([self.inputDelegate respondsToSelector:_cmd]) {
        [self.inputDelegate expandingTextViewDidEndEditing:expandingTextView];
    }
}

- (BOOL)expandingTextView:(expandingTextView *)expandingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([self.inputDelegate respondsToSelector:_cmd]) {
        return [self.inputDelegate expandingTextView:expandingTextView shouldChangeTextInRange:range replacementText:text];
    }
    return YES;
}

- (void)expandingTextView:(expandingTextView *)expandingTextView didChangeHeight:(float)height
{
    if ([self.inputDelegate respondsToSelector:_cmd]) {
        [self.inputDelegate expandingTextView:expandingTextView didChangeHeight:height];
    }
}

- (void)expandingTextViewDidChangeSelection:(expandingTextView *)expandingTextView
{
    if ([self.inputDelegate respondsToSelector:_cmd]) {
        [self.inputDelegate expandingTextViewDidChangeSelection:expandingTextView];
    }
}

@end
