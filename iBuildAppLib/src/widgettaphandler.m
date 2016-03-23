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

#import "widgettaphandler.h"
#import "widget.h"
#import <QuartzCore/QuartzCore.h>

@implementation TWidgetTapHandler

-(id)init
{
  self = [super init];
  if ( self )
  {
    
  }
  return self;
}

-(void)dealloc
{
  [super dealloc];
}

/**
 * Creates a View Controller for a given class name.
 *
 * @param moduleName_   - View controller's class name, without the "ViewController" suffix
 * (this suffix is to be appended inside the method).
 * @param moduleParams_ - dictionary with parameters, passed to the module. 
 *                         The parameters are common for all of the modules and consist of:
 *                             NSString *title       - module's title
 *                             NSString *description - module's brief description
 *                             NSArray  *content     - array of dictionaries as parsed content
 *                                                     of the <content> xml tag in config.
 *
 * @return autoreleased object of type UIViewController
 */
+(UIViewController *)createModuleViewControllerWithName:(NSString *)moduleName_
                                              andParams:(NSDictionary *)moduleParams_
{
  if ( !( moduleName_ &&
         [moduleName_ length] ) )
    return nil;
  
  Class theModuleClass = NSClassFromString( [moduleName_ stringByAppendingString:@"ViewController"] );
  
  if ( !theModuleClass )
    return nil;
  
  id ph = nil;
  
  if ( [theModuleClass isSubclassOfClass:[UIViewController class]] )
  {
    ph = [[theModuleClass alloc] initWithNibName:nil bundle:nil];
    [ph setValue:moduleParams_ forKey:@"params"];
  }
  
  return [ph autorelease];
}

/**
 * Creates a View Controller for a given class name.
 *
 * @param moduleName_   - View controller's class name, without the "ViewController" suffix
 * (this suffix is to be appended inside the method).
 * @param nibName_      - .xib file name to initialize the cotroller with.
 * @param bundleName_   - bundle name to load the .xib file from.
 *
 * @return autoreleased object of type UIViewController
 */
+(UIViewController *)createViewControllerWithName:(NSString *)moduleName_
                                          nibName:(NSString *)nibName_
                                           bundle:(NSString *)bundleName_
{
  if ( !( moduleName_ &&
         [moduleName_ length] ) )
    return nil;
  
  Class theModuleClass = NSClassFromString( [moduleName_ stringByAppendingString:@"ViewController"] );
  
  if ( !theModuleClass )
    return nil;

  if ( [theModuleClass isSubclassOfClass:[UIViewController class]] )
  {
    NSBundle *bundle = nil;
    if ( bundleName_ )
    {
      NSString *bundlePath = [[[NSBundle mainBundle] bundlePath] stringByAppendingString:bundleName_];
      bundle = [NSBundle bundleWithPath:bundlePath];
      if (!bundle)
        NSLog(@"no bundle found at: %@", bundlePath );
    }

    return [[[theModuleClass alloc] initWithNibName:nibName_ bundle:bundle] autorelease];
  }
  return nil;
}


+(BOOL)createAnimationForAction:(TWidgetAction *)action_
                       withView:(UIView *)view_
                       delegate:(id)delegate_
{
  if ( !action_ || !view_ )
    return NO;

  CATransition *animation = nil;
  switch( action_.tapAnimation.style )
  {
    case uiWidgetAnimationRipple:
    {
      animation = [CATransition animation];
      [animation setDelegate:delegate_];
      [animation setDuration:action_.tapAnimation.duration];
      [animation setTimingFunction:UIViewAnimationCurveEaseInOut];
      [animation setType:@"rippleEffect" ];
      [view_.layer addAnimation:animation forKey:NULL];
      break;
    }
    default:
      break;
  }
  return animation != nil;
}

@end
