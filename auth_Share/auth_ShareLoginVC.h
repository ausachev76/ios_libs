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

#import "auth_Share.h"

#import "TPKeyboardAvoidingScrollView.h"

/**
 * View controller to perform a login via Facebook, Twiter or iBuildApp.
 * Provides a possibiliyty to create an account on iBuildApp.
 */
@interface auth_ShareLoginVC : UIViewController <UINavigationControllerDelegate,
                                        UITextViewDelegate,
                                        UITextFieldDelegate,
                                        UITableViewDataSource,
                                        UITableViewDelegate> {
  NSUserDefaults *UD;

  BOOL keyboardIsVisible;
}

/**
 * Name for notification to be posted as login state changes.
 */
@property (nonatomic, retain) NSString *notificationName;

/**
 * Key for message text in user info for login state change notification.
 */
@property (nonatomic, retain) NSString *messageKey;

/**
 * Key for attachment in user info for login state change notification.
 */
@property (nonatomic, retain) NSString *attachKey;

/**
 * Value message text in user info for login state change notification.
 *
 * @discussion
 * When authentication interrupts user while composing a message, here you place
 * an attachment already picked by user.
 */
@property (nonatomic, retain) NSString *messageText;

/**
 * Value for attachment in user info for login state change notification.
 *
 * @discussion
 * When authentication interrupts user while composing a message, here you place
 * an attachment already picked by user.
 */
@property (nonatomic, retain) NSObject *attach;

/**
 * Application Id.
 */
@property (nonatomic, retain) NSString *appID;

/**
 * Module Id.
 */
@property (nonatomic, retain) NSString *moduleID;

/**
 * Method to make a button to redirect to a social service authorization.
 *
 * @param origin - point of origin for button in containing view
 * @param title - title text for button
 * @param titleColor - color of title text
 * @param socialIcon - icon for a social service
 * @param backgroundColor - background color of a button
 * @param target - target of button
 * @param selector - actiuon of button
 *
 * @return fully configured button to redirect to a social service authorization.
 */
+(UIButton *)makeSocialButtonWithOrigin:(CGPoint)origin
                                  title:(NSString *)title
                             titleColor:(UIColor *)titleColor
                             socialIcon:(UIImage *)socialIcon
                        backgroundColor:(UIColor *)backgroundColor
                                 target:(id)target
                                 action:(SEL)selector;

@end