//
//  sharedFunctions.m
//  Builder
//
//  Created by John Smith on 10/28/10.
//  Copyright 2010 Spring. All rights reserved.
//

#import "sharedFunctions.h"

void setOnlineMode(bool enabled)
{
	NSUserDefaults *udefaults=[NSUserDefaults standardUserDefaults];
	[udefaults setBool:enabled forKey:@"OnlineMode"];
}

bool isOnlineMode()
{
	NSUserDefaults *udefaults=[NSUserDefaults standardUserDefaults];
	return [udefaults boolForKey:@"OnlineMode"];
}


bool isMemoryWarning()
{
	NSUserDefaults *udefaults=[NSUserDefaults standardUserDefaults];
	NSString *mem=[udefaults objectForKey:@"MEMORY"];
	return (mem&&[mem isEqualToString:@"PANIC"]);
}

NSTextAlignment getAlignByText(NSString *alignText)
{
	if ( alignText )
	{
		if ( [alignText isEqualToString:@"left"] )
      return NSTextAlignmentLeft;
		else if ( [alignText isEqualToString:@"right"] )
      return NSTextAlignmentRight;
	}
	return NSTextAlignmentCenter;
}

UIFont* createFont(NSString *style,NSString *size)
{
	if(size)
	{
		if(style)
		{
			if([style isEqualToString:@"bold"])
				return [UIFont boldSystemFontOfSize:[size intValue]];
			else if([style isEqualToString:@"italic"])
				 return [UIFont italicSystemFontOfSize:[size intValue]];
			else return [UIFont fontWithName:@"Helvetica" size:[size intValue]];
		}
		return [UIFont fontWithName:@"Helvetica" size:[size intValue]];
	}
	return nil;
}
UILabel* createLabel(NSString *text,CGRect frame,NSString *align,NSString *fontStyle,NSString *fontSize,UIColor *fontColor)
{
	UILabel *label = [[UILabel alloc] initWithFrame:frame];
	[label setText:text];
	[label setTextAlignment:getAlignByText(align)];
	label.backgroundColor = [UIColor clearColor];
	
	UIFont *l_font=createFont(fontStyle,fontSize);
	if(l_font) label.font=l_font;
	if(fontColor) [label setTextColor:fontColor];
	return label;
}
NSString* getAttribFromText(NSString *text,NSString *attrib)
{
	NSString *res=nil;
	NSRange pos=[text rangeOfString:attrib];
	if(pos.location!=NSNotFound)
	{
		NSRange content;
		content.location=pos.location+pos.length;
		NSRange space=[text rangeOfString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(pos.location, [text length]-pos.location)];
		if(space.location==NSNotFound) space.location=[text length];
		content.length=space.location-pos.location-[attrib length];
		res=[[text substringWithRange:content] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\'\""]];
	}
	return res;
}

NSString* htmlToText(NSString *html)
{
	if(!html) return nil;
	
	NSString *res=[NSString stringWithString:html];
	
	NSScanner *theScanner;
    NSString *text = nil;
    theScanner = [NSScanner scannerWithString:res];
	
    while ([theScanner isAtEnd] == NO) 
	{
		[theScanner scanUpToString:@"<" intoString:NULL]; 
		[theScanner scanUpToString:@">" intoString:&text];
		NSRange pos=[text rangeOfString:@"br"];
		if(pos.location!=NSNotFound)
			res = [res stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@"."];
		else res = [res stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"%@>", text] withString:@""];				
    }
    res = [res stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	NSRange pos=[res rangeOfString:@"."];
	if(pos.location==0) 
		res=[res substringFromIndex:1];
	
    return res;
	
}

UIColor* colorFromHexRGB(NSString *inColorString)
{
	if(![inColorString length]) return nil;
	UIColor *result = nil;
	unsigned int colorCode = 0;
	unsigned char redByte, greenByte, blueByte;
	
	NSScanner *scanner = [NSScanner scannerWithString:[NSString stringWithFormat:@"0x%@",[inColorString substringFromIndex:1]]];
	(void) [scanner scanHexInt:&colorCode];	// ignore error
	
	redByte		= (unsigned char) (colorCode >> 16);
	greenByte	= (unsigned char) (colorCode >> 8);
	blueByte	= (unsigned char) (colorCode);	// masks off high bits
	result=[[UIColor alloc] initWithRed:(float)redByte/0xff
								  green:(float)greenByte/0xff
								   blue:(float)blueByte/0xff
								  alpha:1.0];
	return result;
}


void internetRequiredMessage()
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:NSLocalizedString(@"core_internetRequiredAlertMessage", @"To retrieve actual content, you must have an Internet connection.")
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"core_internetRequiredAlertOkButtonTitle", @"OK")
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
}
