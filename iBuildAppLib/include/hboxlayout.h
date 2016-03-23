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
#import "boxlayout.h"

@interface THBoxLayoutData : TBoxLayoutData

-(void)parseXMLitems:(TBXMLElement *)item_
      withAttributes:(NSDictionary *)attributes_;

@end


/**
 * THBoxLayout - container to lay out elements horizontally.
 */
@interface THBoxLayout : TBoxLayout
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
