#import "expandingTextView.h"

#define kTextInsetX 4
#define kTextInsetBottom 0

@interface expandingTextView ()

@property (nonatomic, strong) UILabel *placeholderLabel;

@property (nonatomic, assign) CGFloat minimumHeight;
@property (nonatomic, assign) CGFloat maximumHeight;

@property (nonatomic, assign) BOOL forceSizeUpdate;

@end

@implementation expandingTextView

- (void)setPlaceholder:(NSString *)placeholders
{
    _placeholder = placeholders;
    self.placeholderLabel.text = placeholders;
}

- (id)initWithFrame:(CGRect)frame
{
  if ((self = [super initWithFrame:frame]))
  {
    self.forceSizeUpdate     = NO;
    self.autoresizingMask    = UIViewAutoresizingFlexibleWidth;
		CGRect backgroundFrame   = frame;
    backgroundFrame.origin.y = 0.0f;
		backgroundFrame.origin.x = 0.0f;

    CGRect textViewFrame = CGRectInset(backgroundFrame, kTextInsetX, 0.0f);

    /* Internal Text View component */
		self.internalTextView = [[UITextView alloc] initWithFrame:textViewFrame];
		self.internalTextView.delegate        = self;
		self.internalTextView.font            = [UIFont systemFontOfSize:15.0];
		self.internalTextView.contentInset    = UIEdgeInsetsMake(-4.0f, -2.0f, -4.0f, 0.0f);
		self.internalTextView.scrollEnabled   = NO;
    self.internalTextView.opaque          = NO;
    self.internalTextView.backgroundColor = [UIColor clearColor];
    self.internalTextView.showsHorizontalScrollIndicator = NO;
    [self.internalTextView sizeToFit];
    self.internalTextView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    /* set placeholder */
    self.placeholderLabel = [[UILabel alloc]initWithFrame:CGRectMake(8.0f, 3.0f, self.bounds.size.width - 16.0f, self.bounds.size.height)];
    self.placeholderLabel.text = self.placeholder;
    self.placeholderLabel.font = self.internalTextView.font;
    self.placeholderLabel.backgroundColor = [UIColor clearColor];
    self.placeholderLabel.textColor = [UIColor grayColor];
    [self.internalTextView addSubview:self.placeholderLabel];

    [self addSubview:self.internalTextView];

    /* Calculate the text view height */
		UIView *internal = (UIView*)[[self.internalTextView subviews] objectAtIndex:0];
		self.minimumHeight = internal.frame.size.height;
		self.animateHeightChange = YES;
		self.internalTextView.text = @"";
    
    self.maximumHeight = 60.0f; // 3 lines of text

    [self sizeToFit];
    }
  return self;
}

-(void)sizeToFit
{
  CGRect r = self.frame;
  if ([self.text length] > 0)
  {
    /* No need to resize is text is not empty */
    return;
  }
  r.size.height = self.minimumHeight + kTextInsetBottom;
  self.frame = r;
}

-(void)setFrame:(CGRect)aframe
{
  CGRect backgroundFrame   = aframe;
  backgroundFrame.origin.y = 0;
  backgroundFrame.origin.x = 0;
  CGRect textViewFrame = CGRectInset(backgroundFrame, kTextInsetX, 0);
	self.internalTextView.frame   = textViewFrame;
  backgroundFrame.size.height  -= 8;
  self.textViewBackgroundImage.frame = backgroundFrame;
  self.forceSizeUpdate = YES;
	[super setFrame:aframe];
}

-(void)clearText
{
  self.text = @"";
  [self textViewDidChange:self.internalTextView];
}


-(CGFloat)measureHeightOfUITextView:(UITextView *)textView
{
    if ([textView respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)])
    {
        // This is the code for iOS 7. contentSize no longer returns the correct value, so
        // we have to calculate it.
        //
        // This is partly borrowed from HPGrowingTextView, but I've replaced the
        // magic fudge factors with the calculated values (having worked out where
        // they came from)
        
        CGRect frame = textView.bounds;
        
        // Take account of the padding added around the text.
        
        UIEdgeInsets textContainerInsets = textView.textContainerInset;
        UIEdgeInsets contentInsets = textView.contentInset;
        
        CGFloat leftRightPadding = textContainerInsets.left + textContainerInsets.right + textView.textContainer.lineFragmentPadding * 2 + contentInsets.left + contentInsets.right;
        CGFloat topBottomPadding = textContainerInsets.top + textContainerInsets.bottom + contentInsets.top + contentInsets.bottom;
        
        frame.size.width -= leftRightPadding;
        frame.size.height -= topBottomPadding;
      
        NSString *textToMeasure = textView.text;
        if ([textToMeasure hasSuffix:@"\n"])
        {
            textToMeasure = [NSString stringWithFormat:@"%@-", textView.text];
        }
        
        // NSString class method: boundingRectWithSize:options:attributes:context is
        // available only on ios7.0 sdk.
        
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        [paragraphStyle setLineBreakMode:NSLineBreakByWordWrapping];
        
        NSDictionary *attributes = @{ NSFontAttributeName: textView.font, NSParagraphStyleAttributeName : paragraphStyle };
        
        CGRect size = [textToMeasure boundingRectWithSize:CGSizeMake(CGRectGetWidth(frame), MAXFLOAT)
                                                  options:NSStringDrawingUsesLineFragmentOrigin
                                               attributes:attributes
                                                  context:nil];
        
      CGFloat measuredHeight = ceilf(CGRectGetHeight(size));// + topBottomPadding);
      
        return measuredHeight + 8.0f;
    }
    else
    {
        return textView.contentSize.height;
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
	NSInteger newHeight;
    if(floor(NSFoundationVersionNumber)>NSFoundationVersionNumber_iOS_6_1) {
        newHeight = [self measureHeightOfUITextView:self.internalTextView];
    }else {
        newHeight = self.internalTextView.contentSize.height;
    }

	if(newHeight < self.minimumHeight || !self.internalTextView.hasText)
    {
        newHeight = self.minimumHeight;
    }

	if (self.internalTextView.frame.size.height != newHeight || self.forceSizeUpdate)
	{
        self.forceSizeUpdate = NO;
        if (newHeight > self.maximumHeight && self.internalTextView.frame.size.height <= self.maximumHeight)
        {
            newHeight = self.maximumHeight;
        }
		if (newHeight <= self.maximumHeight)
		{
			if(self.animateHeightChange)
            {
				[UIView beginAnimations:@"" context:nil];
				[UIView setAnimationDelegate:self];
				[UIView setAnimationDidStopSelector:@selector(growDidStop)];
				[UIView setAnimationBeginsFromCurrentState:YES];
			}

			if ([self.delegate respondsToSelector:@selector(expandingTextView:willChangeHeight:)])
            {
				[self.delegate expandingTextView:self willChangeHeight:(newHeight+ kTextInsetBottom)];
			}

			/* Resize the frame */
			CGRect r = self.frame;
			r.size.height = newHeight + kTextInsetBottom;
			self.frame = r;
			r.origin.y = 0;
			r.origin.x = 0;
            self.internalTextView.frame = CGRectInset(r, kTextInsetX, 0);
            r.size.height -= 8;
            self.textViewBackgroundImage.frame = r;

			if(self.animateHeightChange)
            {
				[UIView commitAnimations];
			}
            else if ([self.delegate respondsToSelector:@selector(expandingTextView:didChangeHeight:)])
            {
                [self.delegate expandingTextView:self didChangeHeight:(newHeight+ kTextInsetBottom)];
            }
		}

		if (newHeight >= self.maximumHeight)
		{
            /* Enable vertical scrolling */
			if(!self.internalTextView.scrollEnabled)
            {
				self.internalTextView.scrollEnabled = YES;
				[self.internalTextView flashScrollIndicators];
			}
		}
        else
        {
            /* Disable vertical scrolling */
			self.internalTextView.scrollEnabled = NO;
		}
	}

	if ([self.delegate respondsToSelector:@selector(expandingTextViewDidChange:)])
    {
		[self.delegate expandingTextViewDidChange:self];
	}
}

-(void)growDidStop
{
	if ([self.delegate respondsToSelector:@selector(expandingTextView:didChangeHeight:)])
    {
		[self.delegate expandingTextView:self didChangeHeight:self.frame.size.height];
	}
}

-(BOOL)resignFirstResponder
{
	[super resignFirstResponder];
	return [self.internalTextView resignFirstResponder];
}

#pragma mark UITextView properties

-(void)setText:(NSString *)atext
{
	self.internalTextView.text = atext;
    [self performSelector:@selector(textViewDidChange:) withObject:self.internalTextView];
}

-(NSString*)text
{
	return self.internalTextView.text;
}

-(void)setFont:(UIFont *)afont
{
	self.internalTextView.font= afont;
}

-(UIFont *)font
{
	return self.internalTextView.font;
}

-(void)setTextColor:(UIColor *)color
{
	self.internalTextView.textColor = color;
}

-(UIColor*)textColor
{
	return self.internalTextView.textColor;
}

-(void)setTextAlignment:(NSTextAlignment)aligment
{
	self.internalTextView.textAlignment = aligment;
}

-(NSTextAlignment)textAlignment
{
	return (NSTextAlignment)self.internalTextView.textAlignment;
}

-(void)setSelectedRange:(NSRange)range
{
	self.internalTextView.selectedRange = range;
}

-(NSRange)selectedRange
{
	return self.internalTextView.selectedRange;
}

-(void)setEditable:(BOOL)beditable
{
	self.internalTextView.editable = beditable;
}

-(BOOL)isEditable
{
	return self.internalTextView.editable;
}

-(void)setReturnKeyType:(UIReturnKeyType)keyType
{
	self.internalTextView.returnKeyType = keyType;
}

-(UIReturnKeyType)returnKeyType
{
	return self.internalTextView.returnKeyType;
}

-(void)setDataDetectorTypes:(UIDataDetectorTypes)datadetector
{
	self.internalTextView.dataDetectorTypes = datadetector;
}

-(UIDataDetectorTypes)dataDetectorTypes
{
	return self.internalTextView.dataDetectorTypes;
}

- (BOOL)hasText
{
	return [self.internalTextView hasText];
}

- (void)scrollRangeToVisible:(NSRange)range
{
	[self.internalTextView scrollRangeToVisible:range];
}

#pragma mark -
#pragma mark UIExpandingTextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
	if ([self.delegate respondsToSelector:@selector(expandingTextViewShouldBeginEditing:)])
    {
		return [self.delegate expandingTextViewShouldBeginEditing:self];
	}
    else
    {
		return YES;
	}
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	if ([self.delegate respondsToSelector:@selector(expandingTextViewShouldEndEditing:)])
    {
		return [self.delegate expandingTextViewShouldEndEditing:self];
	}
    else
    {
		return YES;
	}
}

- (void)textViewDidBeginEditing:(UITextView *)textView
{
  self.placeholderLabel.alpha = 0;
  
	if ([self.delegate respondsToSelector:@selector(expandingTextViewDidBeginEditing:)])
    {
		[self.delegate expandingTextViewDidBeginEditing:self];
	}
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
  self.placeholderLabel.alpha = 1;
  
  if ([self.delegate respondsToSelector:@selector(expandingTextViewDidEndEditing:)])
  {
    [self.delegate expandingTextViewDidEndEditing:self];
  }
}


- (BOOL)textViewShouldReturn:(UITextView *)textView
{
  [self performSelector:@selector(textViewDidChange:) withObject:self.internalTextView];
  return NO;
}

#define MAX_LENGTH 150 // Max message length

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)atext
{
	if(![textView hasText] && [atext isEqualToString:@""])
    {
        return NO;
	}
  
  NSUInteger newLength = (textView.text.length - range.length) + atext.length;
  if(newLength > MAX_LENGTH) {
    NSUInteger emptySpace = MAX_LENGTH - (textView.text.length - range.length);
    textView.text = [[[textView.text substringToIndex:range.location] stringByAppendingString:[atext substringToIndex:emptySpace]] stringByAppendingString:[textView.text substringFromIndex:(range.location + range.length)]];
    return NO;
  }

	if ([atext isEqualToString:@"\n"])
    {
		if ([self.delegate respondsToSelector:@selector(expandingTextViewShouldReturn:)])
        {
			if (![self.delegate performSelector:@selector(expandingTextViewShouldReturn:) withObject:self])
            {
				return YES;
			}
            else
            {
				[textView resignFirstResponder];
				return NO;
			}
		}
	}
	return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
	if ([self.delegate respondsToSelector:@selector(expandingTextViewDidChangeSelection:)])
    {
		[self.delegate expandingTextViewDidChangeSelection:self];
	}
}

@end
