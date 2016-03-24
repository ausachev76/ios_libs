#import <UIKit/UIKit.h>
#import "expandingTextView.h"

@protocol inputToolbarDelegate <BHExpandingTextViewDelegate>
@optional
-(void)inputButtonPressed:(NSString *)inputText;
@end

@interface inputToolbar : UIToolbar <BHExpandingTextViewDelegate>

//- (void)drawRect:(CGRect)rect;

@property (nonatomic, strong) expandingTextView *textView;
@property (nonatomic, strong) UIButton *inputButton;
@property (nonatomic, strong) UIColor  *inputButtonColor;
@property (nonatomic, weak) id<inputToolbarDelegate> inputDelegate;

-(id)initWithColor:(UIColor *)color andFrame:(CGRect)frame;

@end
