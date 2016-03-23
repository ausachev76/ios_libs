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

#import "uiboxlayout.h"

/**
 * Container for arbitrary vertical positioning of elements.
 */
@interface uiVBoxLayout : uiBoxLayout<NSCopying, NSCoding>
{
  /**
   * Relative height.
   */
  CGFloat m_height;
  
  /**
   * Total height of static components.
   */
  CGFloat m_staticHeight;
}
@end