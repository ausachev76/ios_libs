//
//  buttonwidget.h
//  layoutViewApp
//
//  Created by Mac on 09.11.12.
//  Copyright (c) 2012 Novedia Regions. All rights reserved.
//

// Modified by iBuildApp.

#import <Foundation/Foundation.h>
#import "labelwidget.h"

@interface TButtonWidgetData : TLabelWidgetData <NSCoding>
  @property (nonatomic, copy  ) NSString *imgSel;
  @property (nonatomic, copy  ) NSString *textSel;
@end
