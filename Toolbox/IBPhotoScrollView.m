#import "IBPhotoScrollView.h"

#define DEFAULT_MAX_CACHED_PAGE 5
#define DEFAULT_MIN_CACHED_PAGE 1

@interface IBPhotoScrollViewPrivateDelegate : NSObject <UIScrollViewDelegate>
  @property(nonatomic, assign) id<UIScrollViewDelegate> userDelegate;
@end


@interface  IBPhotoScrollView()
  @property(nonatomic, strong)   NSMutableDictionary *cachedPages;
  @property(nonatomic, assign)   BOOL                 enableCallbacks;
  @property(nonatomic, assign)   CGSize               viewSize;
  @property(nonatomic, readonly) IBPhotoScrollViewPrivateDelegate *privateDelegate;
  -(void)privateScrollViewWillBeginDragging:(UIScrollView *)scrollView;
@end

@implementation IBPhotoScrollViewPrivateDelegate
@synthesize userDelegate = _userDelegate;

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  [(IBPhotoScrollView *)scrollView privateScrollViewWillBeginDragging:scrollView];
  if ([_userDelegate respondsToSelector:_cmd])
    [_userDelegate scrollViewDidEndDecelerating:scrollView];
}

- (BOOL)respondsToSelector:(SEL)selector
{
  return [_userDelegate respondsToSelector:selector] || [super respondsToSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
  // This should only ever be called from `UIScrollView`, after it has verified
  // that `_userDelegate` responds to the selector by sending me
  // `respondsToSelector:`.  So I don't need to check again here.
  [invocation invokeWithTarget:_userDelegate];
}

@end



@implementation IBPhotoScrollView
@synthesize currentPage = _currentPage,
             dataSource = _dataSource,
             uiDelegate = _uiDelegate,
          eventDelegate = _eventDelegate,
            cachedPages = _cachedPages,
        privateDelegate = _privateDelegate,
        enableCallbacks = _enableCallbacks,
         maxCachedPages = _maxCachedPages;

- (void)initDelegate
{
  _privateDelegate = [[IBPhotoScrollViewPrivateDelegate alloc] init];
  [super setDelegate:_privateDelegate];
}

-(id)initWithFrame:(CGRect)frame
{
  self = [super initWithFrame:frame];
  if ( self )
  {
    _cachedPages     = [[NSMutableDictionary alloc] init];
    _currentPage     = -1;
    _dataSource      = nil;
    _uiDelegate      = nil;
    _eventDelegate   = nil;
    _privateDelegate = nil;
    _enableCallbacks = YES;
    _maxCachedPages  = DEFAULT_MAX_CACHED_PAGE;
    self.viewSize    = frame.size;
    self.pagingEnabled = YES;
    [self initDelegate];
  }
  return self;
}

-(void)dealloc
{
  [_privateDelegate release];
  _privateDelegate = nil;
  [_cachedPages release];
  [super dealloc];
}

- (void)setDelegate:(id<UIScrollViewDelegate>)delegate
{
  self.privateDelegate.userDelegate = delegate;
  // Scroll view delegate caches whether the delegate responds to some of the delegate
  // methods, so we need to force it to re-evaluate if the delegate responds to them
  super.delegate = nil;
  super.delegate = (id)self.privateDelegate;
}

- (id<UIScrollViewDelegate>)delegate
{
  return self.privateDelegate.userDelegate;
}



-(void)setMaxCachedPages:(NSUInteger)maxCachedPages_
{
  if ( maxCachedPages_ < DEFAULT_MIN_CACHED_PAGE )
    return;
  _maxCachedPages = maxCachedPages_;
}

-(void)setCurrentPage:(NSUInteger)currentPage_ animated:(BOOL)animated_
{
  if ( _currentPage != currentPage_ )
  {
    NSInteger pageCount       = [self.dataSource photoScrollViewNumberOfPages:self];
    if ( (NSInteger)currentPage_ < 0 || (NSInteger)currentPage_ >= pageCount )
      return;
    
    CGPoint offset = CGPointMake( [self bounds].size.width * currentPage_, self.contentOffset.y );
    [self setContentOffset:offset animated:animated_];
    _currentPage = [self cachePage:currentPage_];
    self.enableCallbacks = NO;
  }
}

-(void)setCurrentPage:(NSUInteger)currentPage_
{
  [self setCurrentPage:currentPage_ animated:NO];
}

-(UIView *)dequeueReusableViewWithPage:(NSUInteger)page_
{
  return [self.cachedPages objectForKey:[NSNumber numberWithInteger:page_]];
}

-(void)setFrameForPage:(NSUInteger)page_ withView:(UIView *)view_
{
  CGSize thisSize = [self bounds].size;
  view_.frame = CGRectMake( page_ * thisSize.width, 0.f, thisSize.width, thisSize.height );
}

/*
-(void)setFrame:(CGRect)frame
{
  [super setFrame:frame];
  
  NSUInteger pageCount = [self.dataSource photoScrollViewNumberOfPages:self];
  
  self.contentSize = CGSizeMake( [self bounds].size.width * pageCount, [self bounds].size.height );
  
  for ( NSNumber *page in [self.cachedPages allKeys] )
    [self setFrameForPage:[page integerValue]
                 withView:[self.cachedPages objectForKey:page]];
  
}
*/

-(NSUInteger)pageCount
{
  return [self.dataSource photoScrollViewNumberOfPages:self];
}


-(UIView *)cachedPage:(NSInteger)page_ withReusePages:(NSMutableSet *)reuseCachePages_
{
  NSNumber *reusePageIndex = [reuseCachePages_ anyObject];
  
  UIView *view = [self.cachedPages objectForKey:reusePageIndex];
  if ( view )
  {
    [self.cachedPages setObject:view forKey:[NSNumber numberWithInteger:page_]];
    [self.cachedPages removeObjectsForKeys:[NSArray arrayWithObject:reusePageIndex]];

    [reuseCachePages_ removeObject:reusePageIndex];

    [self.uiDelegate photoScrollView:self viewForPage:page_];
  }else if ( [self.cachedPages count] <= self.maxCachedPages )
  {
    view = [self.uiDelegate photoScrollView:self viewForPage:page_];
    if ( view )
    {
      [self.cachedPages setObject:view forKey:[NSNumber numberWithInteger:page_]];
      [self addSubview:view];
    }
  }
  return view;
}

-(NSInteger)cachePage:(NSInteger)page_
{
  NSInteger pageCount       = [self.dataSource photoScrollViewNumberOfPages:self];
  if ( !pageCount )
    return -1;
  
  NSInteger lastPageIndex   = pageCount - 1;
  if ( page_ < 0 )
    return 0;
  if ( page_ > lastPageIndex )
    return lastPageIndex;
  
  NSInteger halfCachedPages = self.maxCachedPages >> 1;
  
  NSInteger leftIndex  = MAX( page_ - halfCachedPages, 0 );
  NSInteger rightIndex = MIN( page_ + halfCachedPages, lastPageIndex );
  
  
  NSMutableSet *outOfCachePages = [[[NSMutableSet alloc] init] autorelease];
  
  for ( NSInteger i = leftIndex; i <= rightIndex; ++i )
    [outOfCachePages addObject:[NSNumber numberWithInteger:i]];
  
  
  NSMutableSet *inCachePages    = [[[NSMutableSet alloc] initWithArray:[self.cachedPages allKeys]] autorelease];
  NSMutableSet *reuseCachePages = [[[NSMutableSet alloc] initWithArray:[self.cachedPages allKeys]] autorelease];
  
  [inCachePages intersectSet:outOfCachePages];
  
  [reuseCachePages minusSet:inCachePages];
  
  
  UIView *view = [self.cachedPages objectForKey:[NSNumber numberWithInteger:page_]];
  if ( !view )
  {
    view = [self cachedPage:page_ withReusePages:reuseCachePages];
    [self setFrameForPage:page_ withView:view];
  }
  
  for ( NSInteger i = 1; i <= halfCachedPages; ++i )
  {
    NSInteger leftPageIndex  = page_ - i;
    NSInteger rightPageIndex = page_ + i;
    if ( rightPageIndex <= rightIndex )
    {
      UIView *view = [self.cachedPages objectForKey:[NSNumber numberWithInteger:rightPageIndex]];
      if ( !view )
      {
        view = [self cachedPage:rightPageIndex withReusePages:reuseCachePages];
        [self setFrameForPage:rightPageIndex withView:view];
      }
    }
    if ( leftPageIndex >= leftIndex )
    {
      UIView *view = [self.cachedPages objectForKey:[NSNumber numberWithInteger:leftPageIndex]];
      if ( !view )
      {
        view = [self cachedPage:leftPageIndex withReusePages:reuseCachePages];
        [self setFrameForPage:leftPageIndex withView:view];
      }
    }
  }
  
  for( NSNumber *pageIndex in [reuseCachePages allObjects] )
  {
    UIView *view = [self.cachedPages objectForKey:pageIndex];
    [view removeFromSuperview];
  }
  [self.cachedPages removeObjectsForKeys:[reuseCachePages allObjects]];

  if ( [self.uiDelegate respondsToSelector:@selector(photoScrollView:didChangePage:fromOldPage:)] )
    [self.uiDelegate photoScrollView:self
                       didChangePage:page_
                         fromOldPage:self.currentPage];

  if ( [self.eventDelegate respondsToSelector:@selector(photoScrollView:didChangePage:fromOldPage:)] )
    [self.eventDelegate photoScrollView:self
                          didChangePage:page_
                            fromOldPage:self.currentPage];
  return page_;
}

-(void)layoutSubviews
{
  [super layoutSubviews];

  if ( !CGSizeEqualToSize(self.viewSize, [self bounds].size ) )
  {
    NSUInteger pageCount = [self.dataSource photoScrollViewNumberOfPages:self];
    
    self.contentSize = CGSizeMake( [self bounds].size.width * pageCount, [self bounds].size.height );
    
    for ( NSNumber *page in [self.cachedPages allKeys] )
      [self setFrameForPage:[page integerValue]
                   withView:[self.cachedPages objectForKey:page]];
    
    self.viewSize = [self bounds].size;
    CGPoint offset = CGPointMake( [self bounds].size.width * _currentPage, self.contentOffset.y );
    [self setContentOffset:offset animated:YES];
    self.enableCallbacks = NO;
  }else if ( self.enableCallbacks )
  {
    // detect switch page event...
    CGFloat pageWidth = self.frame.size.width;
    float fractionalPage = self.contentOffset.x / pageWidth;
    NSInteger page = lround(fractionalPage);
    if ( _currentPage != page )
    {
      _currentPage = [self cachePage:page];
    }
  }
  [[self subviews] makeObjectsPerformSelector:@selector(layoutSubviews)];
}

- (void)privateScrollViewWillBeginDragging:(UIScrollView *)scrollView
{
  self.enableCallbacks = YES;
}

@end

