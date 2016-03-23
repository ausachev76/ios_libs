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

#import <UIKit/UIKit.h>
#import "toolbar.h"

@class uiBoxLayout;
@interface TNavigationBar : UINavigationBar
{
  TToolBar *m_toolBar;
}

  @property (nonatomic, readonly ) TToolBar     *toolBar;
  @property (nonatomic, assign   ) CGFloat       height;

 /**
  * Original layout for the navigation buttons
  * in accordance with the configuration xml.
  */
  @property (nonatomic, strong   ) uiBoxLayout  *sourceLayout;

/**
 * Hide / display a list of buttons.
 *
 * @param bHidden  - hide / show elements, the task list buttons.
 * @param indexes  - index list of items that you want to hide / show.
 * @param animated - produce hiding / showing animation.
 */
-(void)setHidden:(BOOL)bHidden
     withIndexes:(NSIndexSet *)indexes_
        animated:(BOOL)animated;

-(void)setBackButtonHidden:(BOOL)bHidden animated:(BOOL)animated;

-(void)setHomeButtonHidden:(BOOL)bHidden animated:(BOOL)animated;

@end
