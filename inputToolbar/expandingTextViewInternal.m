#import "expandingTextViewInternal.h"

#define kTopContentInset -4
#define lBottonContentInset 12

@implementation expandingTextViewInternal

-(void)setContentOffset:(CGPoint)s
{
    /* Check if user scrolled */
	if(self.tracking || self.decelerating)
    {
		self.contentInset = UIEdgeInsetsMake(kTopContentInset, 0, 0, 0);
	}
    else
    {
		float bottomContentOffset = (self.contentSize.height - self.frame.size.height + self.contentInset.bottom);
		if(s.y < bottomContentOffset && self.scrollEnabled)
        {
			self.contentInset = UIEdgeInsetsMake(kTopContentInset, 0, lBottonContentInset, 0);
		}
	}
	[super setContentOffset:s];
}

-(void)setContentInset:(UIEdgeInsets)s
{
	UIEdgeInsets edgeInsets = s;
	edgeInsets.top = kTopContentInset;
	if(s.bottom > 12)
    {
        edgeInsets.bottom = 4;
    }
	[super setContentInset:edgeInsets];
}

@end
