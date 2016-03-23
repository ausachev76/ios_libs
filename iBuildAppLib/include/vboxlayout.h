//
//  THBoxLayout.h
//  NRGridViewSampleApp
//
//  Created by Exception13 on 01.10.12.
//  Copyright (c) 2012 Novedia Regions. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "boxlayout.h"

@interface TVBoxLayoutData : TBoxLayoutData
@end

/**
 * Container for arbitrary vertical positioning of elements.
 */
@interface TVBoxLayout : TBoxLayout
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
