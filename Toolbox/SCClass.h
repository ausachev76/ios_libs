
#import <Foundation/Foundation.h>

/**
 * Special class, allows to make a series of adjustments to
 * redefine methods allow for categories
 */
@interface SCClass : NSObject

  + (void)swizzleSelector:(SEL)orig ofClass:(Class)c withSelector:(SEL)new;

@end