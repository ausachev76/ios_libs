#import <UIKit/UIKit.h>
#import "expandingTextViewInternal.h"

@class expandingTextView;

@protocol BHExpandingTextViewDelegate <NSObject>

@optional
- (BOOL)expandingTextViewShouldBeginEditing:(expandingTextView *)expandingTextView;
- (BOOL)expandingTextViewShouldEndEditing:(expandingTextView *)expandingTextView;

- (void)expandingTextViewDidBeginEditing:(expandingTextView *)expandingTextView;
- (void)expandingTextViewDidEndEditing:(expandingTextView *)expandingTextView;

- (BOOL)expandingTextView:(expandingTextView *)expandingTextView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text;
- (void)expandingTextViewDidChange:(expandingTextView *)expandingTextView;

- (void)expandingTextView:(expandingTextView *)expandingTextView willChangeHeight:(float)height;
- (void)expandingTextView:(expandingTextView *)expandingTextView didChangeHeight:(float)height;

- (void)expandingTextViewDidChangeSelection:(expandingTextView *)expandingTextView;
- (BOOL)expandingTextViewShouldReturn:(expandingTextView *)expandingTextView;
@end

@interface expandingTextView : UIView <UITextViewDelegate>

@property (nonatomic, strong) UITextView *internalTextView;

@property (nonatomic, assign) BOOL animateHeightChange;

@property (nonatomic, weak) id<BHExpandingTextViewDelegate> delegate;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, copy) UIFont *font;
@property (nonatomic, copy) UIColor *textColor;
@property (nonatomic) NSTextAlignment textAlignment;
@property (nonatomic) NSRange selectedRange;
@property (nonatomic,getter=isEditable) BOOL editable;
@property (nonatomic) UIDataDetectorTypes dataDetectorTypes __OSX_AVAILABLE_STARTING(__MAC_NA, __IPHONE_3_0);
@property (nonatomic) UIReturnKeyType returnKeyType;
@property (nonatomic, strong) UIImageView *textViewBackgroundImage;
@property (nonatomic,copy) NSString *placeholder;
- (BOOL)hasText;
- (void)scrollRangeToVisible:(NSRange)range;
- (void)clearText;

@end
