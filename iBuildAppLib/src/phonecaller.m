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

#import "phonecaller.h"
#import "notifications.h"

@interface TPhoneCaller()

@property (nonatomic,copy) NSString *number;
@property (nonatomic,copy) NSString *name;

@end

@implementation TPhoneCaller

- (id)init
{
  self = [super init];
  if ( self )
  {
    self.number = nil;
    self.name   = nil;
  }
  return self;
}

- (void)dealloc
{
  self.number = nil;
  self.name   = nil;
  [super dealloc];
}

-(void)callNumber:(NSString*)num
{
  if ( ![num length] )
  {
      // send notification. Now this object may be dispossed.
    [[NSNotificationCenter defaultCenter] postNotificationName:kAPP_NOTIFICATION_RELEASE_OBJECT
                                                        object:self];
    return;
  }
	self.number = num;
	self.name   = nil;
	UIAlertView *msg = [[[UIAlertView alloc] initWithTitle:@""
                                                 message:num
                                                delegate:self
                                       cancelButtonTitle:NSLocalizedString(@"core_callNumberAlertCancelButtonTitle", @"Cancel")
                                       otherButtonTitles:NSLocalizedString(@"core_callNumberAlertCallButtonTitle", @"Call"),nil]
                      autorelease];
	[msg show];
}

-(void)callNumberOrAdd:(NSString*)num  showAddTo:(NSString*)contactName
{
  if ( ![num length] )
  {
    [[NSNotificationCenter defaultCenter] postNotificationName:kAPP_NOTIFICATION_RELEASE_OBJECT
                                                        object:self];
    return;
  }
	self.number = num;
	self.name   = contactName;
	UIAlertView *msg = [[[UIAlertView alloc] initWithTitle:@""
                                                 message:num
                                                delegate:self
                                       cancelButtonTitle:NSLocalizedString(@"core_callNumberAlertCancelButtonTitle", @"Cancel")
                                       otherButtonTitles:NSLocalizedString(@"core_callNumberAlertCallButtonTitle", @"Call"),
                       NSLocalizedString(@"core_callNumberAlertAddToContactsButtonTitle", @"Add to Contacts"), nil]
                      autorelease];
	[msg show];
}

#pragma mark -
#pragma mark UIAlert delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
  if ( buttonIndex == 1 )
	{
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[[NSString stringWithFormat: @"tel:%@", self.number] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
  }else if( buttonIndex == 2 )
	{
      //		[Plugins AddContact:name mobilePhone:number];
	}
  [[NSNotificationCenter defaultCenter] postNotificationName:kAPP_NOTIFICATION_RELEASE_OBJECT
                                                      object:self];
}

#pragma mark -
@end
