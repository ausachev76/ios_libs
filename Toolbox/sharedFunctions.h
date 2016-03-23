//
//  sharedFunctions.h
//  Builder
//
//  Created by John Smith on 10/28/10.
//  Copyright 2010 Spring. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

void setOnlineMode(bool enabled); //++
bool isOnlineMode();
//bool isUrl(NSString *maybeUrl);
bool isMemoryWarning();
//bool isURLImage(NSString *url);
NSTextAlignment getAlignByText(NSString *alignText);
UIFont* createFont(NSString *style,NSString *size);
UILabel* createLabel(NSString *text,CGRect frame,NSString *align,NSString *fontStyle,NSString *fontSize,UIColor *fontColor);
NSString* getAttribFromText(NSString *text,NSString *attrib);
NSString* htmlToText(NSString *html);
//NSDate * dateFromInternetDateTimeString(NSString *dateString);
UIColor* colorFromHexRGB(NSString *inColorString);
//UIImage *imageWithColor(UIColor *color,CGRect rect);
void internetRequiredMessage();