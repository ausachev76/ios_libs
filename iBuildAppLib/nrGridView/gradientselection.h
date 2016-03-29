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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "TBXML.h"

/**
 * Conatiner to store an info about a single point of a gradient.
 */
@interface TGradientPoint : NSObject
@property (nonatomic, assign ) CGFloat pos;    // Point position on a gradient stripe (0..1)
@property (nonatomic, retain ) UIColor *color; // Color for a point.
-(id)initWithPos:(CGFloat)pos_
           color:(UIColor*)color_;
@end

/**
 * Container to store info about gridView cell color fill when this cell is selected.
 */
typedef enum tagTSelectionGradientDirection
{
  SelectionGradientHorizontal,
  SelectionGradientVertical,
}TSelectionGradientDirection;

@interface TElementSelection : NSObject

 /**
  * Gradient direction.
  */
  @property (nonatomic, assign ) TSelectionGradientDirection direction;

 /**
  * Gradient's control points.
  */
  @property (nonatomic, retain ) NSArray *points;

  /**
   * Selected element corner radius.
   */
  @property (nonatomic, assign ) CGFloat cornerRadius;

  /**
   * Selection rect's paddings.
   */
  @property (nonatomic, assign ) CGSize  padding;
  -(id)initWithDirection:(TSelectionGradientDirection)direction_
                  points:(NSArray *)points_
            cornerRadius:(CGFloat)radius_;
  +(TElementSelection *)defaultSelection;
  +(TElementSelection *)selectionFromXMLelement:(TBXMLElement *)element
                                 withAttributes:(NSDictionary *)attributes_;

@end

