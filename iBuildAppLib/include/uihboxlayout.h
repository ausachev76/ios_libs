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
 * Container for arbitrary horizontal positioning of elements.
 */
@interface uiHBoxLayout : uiBoxLayout<NSCopying, NSCoding>
{
  /**
   * Relative width.
   */
  CGFloat m_width;
  
  /**
   * Total width of static components.
   */
  CGFloat m_staticWidth;
}

@end
