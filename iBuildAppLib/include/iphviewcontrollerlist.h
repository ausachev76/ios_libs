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

/*
 * Defines a list of view controllers used in the application
 */

typedef struct tagTIphoneVCdescriptor
{
  /**
   * Class name, the object of which will be created
   */
  NSString *className;
  
  /**
   * .xib file name
   */
  NSString *nibName;
}TIphoneVCdescriptor;

typedef struct tagTIphoneVC
{
  /**
   * Module name used in the xml
   */
  NSString                  *type;
  
  /**
   * Class name + file name xib
   */
  const TIphoneVCdescriptor  desc;
}TIphoneVC;

/**
 * Returns TIphoneVCdescriptor for the given widget type.
 * 
 * @see <widget> -> <type> in xml config.
 */
const TIphoneVCdescriptor *viewControllerByType( NSString *type_ );