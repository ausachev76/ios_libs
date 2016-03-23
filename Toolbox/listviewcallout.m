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

#import "listviewcallout.h"
#import <QuartzCore/QuartzCore.h>

#define BOUNCE_ANIMATION_DURATION (1.0/3.0) // the official bounce animation duration adds up to 0.3 seconds; but there is a bit of delay introduced by Apple using a sequence of callback-based CABasicAnimations rather than a single CAKeyframeAnimation. So we bump it up to 0.33333 to make it feel identical on the device.


@interface TListViewCallout()
  @property (nonatomic, retain) UITableView *tableView;
  @property (nonatomic, retain) NSArray     *stringList;
@end

@implementation TListViewCallout
@synthesize tableView, stringList;


- (void)presentCalloutFromRect:(CGRect)rect
                        inView:(UIView *)view
             constrainedToView:(UIView *)constrainedView
      permittedArrowDirections:(SMCalloutArrowDirection)arrowDirections
                      animated:(BOOL)animated
{

  // size the callout to fit the width constraint as best as possible

  CGRect rc =self.frame;
  rc.size = [self sizeThatFits:CGSizeMake(constrainedView.frame.size.width, 150)];
  self.frame = rc;

  // add the callout to the given view
  [view addSubview:self];
  
  // now set the *actual* anchor point for our layer so that our "popup" animation starts from this point.
  CGPoint anchorPoint = [view convertPoint:CGPointMake( 0, 0) toView:self];
  anchorPoint.x /= self.frame.size.width;
  anchorPoint.y /= self.frame.size.height;
  self.layer.anchorPoint = anchorPoint;
  
  // layout now so we can immediately start animating to the final position if needed
  [self setNeedsLayout];
  [self layoutIfNeeded];
  
  // if we need to delay, we don't want to be visible while we're delaying, so hide us in preparation for our popup
  self.hidden = YES;
  
  self.alpha = 1; // in case it's zero from fading out in -dismissCalloutAnimated
  
  CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
  CAMediaTimingFunction *easeInOut = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
  
  bounceAnimation.beginTime = CACurrentMediaTime() + 0;
  bounceAnimation.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.05],
                            [NSNumber numberWithFloat:1.11245],
                            [NSNumber numberWithFloat:0.951807],
                            [NSNumber numberWithFloat:1.0],
                            nil];
  bounceAnimation.keyTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0],
                              [NSNumber numberWithFloat:(4.0/9.0)],
                              [NSNumber numberWithFloat:(4.0/9.0+5.0/18.0)],
                              [NSNumber numberWithFloat:1.0],
                              nil];
  bounceAnimation.duration = animated ? BOUNCE_ANIMATION_DURATION : 0.0000001; // can't be zero or the animation won't "run"
  bounceAnimation.timingFunctions = [NSArray arrayWithObjects: easeInOut, easeInOut, easeInOut, easeInOut, nil];
  bounceAnimation.delegate = self;
  
  [self.layer addAnimation:bounceAnimation forKey:@"bounce"];
}

- (void)animationDidStart:(CAAnimation *)anim {
  // ok, animation is on, let's make ourselves visible!
  self.hidden = NO;
}

- (void)animationDidStop:(CAAnimation *)anim
                finished:(BOOL)finished
{

}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
      self.stringList = [NSArray arrayWithObjects:@"frdsf", @"gfjkds", nil];
      self.tableView = [[[UITableView alloc] initWithFrame:CGRectZero] autorelease];
      self.tableView.delegate   = self;
      self.tableView.dataSource = self;
      self.tableView.backgroundColor = [UIColor clearColor];
      
      self.backgroundColor = [UIColor redColor];
      [self addSubview:self.tableView];
    }
    return self;
}

-(void)dealloc
{
  self.stringList = nil;
  self.tableView  = nil;
  [super dealloc];
}

- (CGSize)sizeThatFits:(CGSize)size
{
  CGSize preferedSize = CGSizeMake( 500.f, 370 - 41 );

  return preferedSize;
}

#pragma mark -
#pragma mark Table delegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
 numberOfRowsInSection:(NSInteger)section
{
  return [self.stringList count];
}

-(NSIndexPath *)tableView:(UITableView *)tableView
 willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
  return indexPath;
}

-(UITableViewCell *)tableView:(UITableView *)tableView_
        cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
  NSString *CellIdentifier = [NSString stringWithFormat:@"Cell%ld%ld" ,(long)indexPath.section, (long)indexPath.row];
  UITableViewCell *cell;
  

  cell = [tableView_ dequeueReusableCellWithIdentifier:CellIdentifier];
  if(cell == nil)
  {
    cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                   reuseIdentifier:CellIdentifier] autorelease];
    cell.autoresizesSubviews = YES;
    cell.autoresizingMask    = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [[cell contentView] setBackgroundColor:[UIColor clearColor]];
    [[cell backgroundView] setBackgroundColor:[UIColor clearColor]];
    [cell setBackgroundColor:[UIColor clearColor]];
  }
  //-----------------------------------------------------------------------------------------------------------------
  cell.textLabel.text = [stringList objectAtIndex:indexPath.row];
  return cell;
}

-    (CGFloat)tableView:(UITableView *)tableView_
heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
  return 40.f;
}

-(void)layoutSubviews
{
  [super layoutSubviews];
  [self.tableView setFrame:CGRectMake(5,5,self.frame.size.width - 10, self.frame.size.height - 10)];
}


@end
