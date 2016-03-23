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

@class IBPhotoScrollView;


/**
 * Interface for interface IBPhotoScrollView to interact with its view
 */
@protocol IBPhotoScrollViewEventDelegate<NSObject>


/**
 * Optional allback method that is invoked at the time of transition from one page to another.
 * 
 * @param photoScrollView - widget to display a series of windows (objects of type UIView)
 * @param newPage_ - page on which switched
 * @param oldPage_ - Page which went on newPage_
 */
@optional
  -(void)photoScrollView:(IBPhotoScrollView *)scrollView_
           didChangePage:(NSUInteger)newPage_
             fromOldPage:(NSUInteger)oldPage_;
@end

/**
 * IBPhotoScrollViewDelegate - interface for interacting with his component IBPhotoScrollView graphical representation
 */
@protocol IBPhotoScrollViewDelegate<IBPhotoScrollViewEventDelegate>

/**
 * Binding method interface must implement creating and filling UIView content.
 *
 * @param scrollView_ - widget to display a series of windows (objects of type UIView)
 * @param page_       - Page to be filled
 *
 * @return method should return the object of type UIView - filled performance for page page_
 */
-(UIView *)photoScrollView:(IBPhotoScrollView *)scrollView_ viewForPage:(NSUInteger)page_;
@end

/**
 * Interface to interact with the data component IBPhotoScrollView on which he will be drawn
 */
@protocol IBPhotoScrollViewDataSourceDelegate<NSObject>

  /**
   * Binding method interface including IBPhotoScrollView could know the number of pages it will display
   *
   * @param IBPhotoScrollView - widget to display a series of windows (objects of type UIView)
   *
   * @return the number of pages that can display widget
   */
  -(NSUInteger)photoScrollViewNumberOfPages:(IBPhotoScrollView *)scrollView_;
@end


/**
 * Widget to display a series of windows (objects of type UIView) with the possibility of horizontal scrolling
 */
@interface IBPhotoScrollView : UIScrollView


 /**
  * Page currently displayed by widget.
  */
  @property(nonatomic, assign) NSUInteger                              currentPage;

 /**
  * Delegate acting as the data source.
  */
  @property(nonatomic, assign) id<IBPhotoScrollViewDataSourceDelegate> dataSource;

 /**
  * Delegate for the event count. interface.
  */
  @property(nonatomic, assign) id<IBPhotoScrollViewDelegate>           uiDelegate;

 /**
  * Service delegate for handling events move from page to page.
  */
  @property(nonatomic, assign) id<IBPhotoScrollViewEventDelegate>      eventDelegate;

 /**
  * Maximum number of pages stored in the cache.
  */
  @property(nonatomic, assign) NSUInteger                              maxCachedPages;

 /**
  * Total number of pages.
  */
  @property(nonatomic, readonly) NSUInteger                            pageCount;

 /**
  * Go to the page ...
  *
  * @param currentPage_ - page that you want to go to
  * @param animated_    - make the transaction with or without animation
  */
  -(void)setCurrentPage:(NSUInteger)currentPage_ animated:(BOOL)animated_;

 /**
  * Use an existing UIView to display the contents page
  * because in memory can be located only maxCachedPages, it displays the contents of the old page
  * they can be reused
  */
  -(UIView *)dequeueReusableViewWithPage:(NSUInteger)page_;

@end
