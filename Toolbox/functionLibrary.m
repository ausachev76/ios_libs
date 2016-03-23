#import "functionLibrary.h"
#import "SBJSON.h"

#import <EventKit/EventKit.h>

#import <Smartling.i18n/SLLocalization.h>

#import "UIAlertView+MKBlockAdditions.h"//"MKAdditions/UIAlertView+MKBlockAdditions.h"


@interface TMailComposeViewController : MFMailComposeViewController
@end
@implementation TMailComposeViewController
#pragma mark autorotate handlers
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation { return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);}
-(BOOL)shouldAutorotate { return YES; }
-(NSUInteger)supportedInterfaceOrientations { return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown; }

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation { return UIInterfaceOrientationPortrait; }
@end

@interface TMessageComposeViewController : MFMessageComposeViewController
@end
@implementation TMessageComposeViewController
#pragma mark autorotate handlers
-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation { return UIInterfaceOrientationIsPortrait(toInterfaceOrientation);}
-(BOOL)shouldAutorotate { return YES; }
-(NSUInteger)supportedInterfaceOrientations { return UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown; }
- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation { return UIInterfaceOrientationPortrait; }
@end


@implementation functionLibrary

UIViewController *parentController;


#pragma mark    >>>    ADDRESS BOOK & CONTACTS

+ (BOOL)addContact:(NSString *)contactName
         withPhone:(NSString *)phoneNumber {
    if( ![phoneNumber length] )
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:contactName
                                                        message:NSLocalizedString(@"core_emptyPhoneNumberAddMessage", @"Can not add contact without phone number!")
                                                       delegate:nil
                                              cancelButtonTitle:NSLocalizedString(@"core_emptyPhoneNumberAddOkButtonTitle", @"OK")
                                              otherButtonTitles:nil];
        [alert show];
        [alert release];
        return false;
    }
    
    ABAddressBookRef addressBook = NULL;
    __block BOOL isGranted = YES;
    __block BOOL successfullyAdded = NO;
    
    if ( &ABAddressBookCreateWithOptions != NULL ) // >= iOS 6
    {
        CFErrorRef  error;
        addressBook = ABAddressBookCreateWithOptions( NULL, &error );
        
        if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)            
        {
          dispatch_semaphore_t sema = dispatch_semaphore_create(0);
          
            ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error){
                if(!granted) {
                    NSLog(@"AddressBook access not granted!!!");
                    isGranted = NO;
                    successfullyAdded = NO;
                }
              
              dispatch_semaphore_signal(sema);
            });
            
            // wait until block is finished
          dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
          dispatch_release(sema);
          
            if (isGranted)
                successfullyAdded = [functionLibrary addContact:contactName
                                                      withPhone:phoneNumber
                                                  toAddressBook:addressBook];
        }
        else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
        {
            successfullyAdded = [functionLibrary addContact:contactName
                                                  withPhone:phoneNumber
                                              toAddressBook:addressBook];
        }
        else
        {
            NSLog(@"AddressBook access not granted!!!");
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"core_ABAccessDeniedAlertTitle", @"Access denied")
                                                            message:NSLocalizedString(@"core_ABAccessDeniedAlertMessage", @"Allow iBuildApp access your address book by going to  Settings > Privacy > Contacts")
                                                           delegate:self
                                                  cancelButtonTitle:NSLocalizedString(@"core_ABAccessDeniedAlertOkButtonTitle", @"OK")
                                                  otherButtonTitles: nil];
            [alert show];
            [alert release];
          
        }
        CFRelease(addressBook);
    }
    else // iOS 4/5
    {
        addressBook = ABAddressBookCreate();
        successfullyAdded = [functionLibrary addContact:contactName withPhone:phoneNumber toAddressBook:addressBook];
        CFRelease(addressBook);
    }
	
	return successfullyAdded;
}


+ (BOOL)addContact:(NSString *)contactName withPhone:(NSString *)phoneNumber toAddressBook:(ABAddressBookRef) addressBook {
    
    if([self contactExistsWithPhone:phoneNumber inAddressBook:addressBook])
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:phoneNumber
                                                        message:NSLocalizedString(@"core_contactExistsAlertMessage", @"Contact already exists.")
                                                       delegate:self
                                              cancelButtonTitle:NSLocalizedString(@"core_contactExistsAlertOkButtonTitle", @"OK")
                                              otherButtonTitles: nil];
        [alert show];
        [alert release];
        return false;
    }
    
	ABRecordRef aRecord = ABPersonCreate();
	CFErrorRef    *anError = NULL;
	ABRecordSetValue(aRecord, kABPersonFirstNameProperty, contactName, anError);
	if (anError != NULL)
  {
		CFRelease(aRecord);
		return false;
	}
	
	ABMutableMultiValueRef phoneNumberMultiValue = ABMultiValueCreateMutable(kABMultiStringPropertyType);
	ABMultiValueAddValueAndLabel(phoneNumberMultiValue, phoneNumber, (CFStringRef)@"Mobile", NULL);
	ABRecordSetValue(aRecord, kABPersonPhoneProperty, phoneNumberMultiValue, anError);
	CFRelease(phoneNumberMultiValue);
	
	if (anError != NULL)
  {
		CFRelease(aRecord);
		return false;
	}
	
	CFErrorRef error = NULL;
	
	BOOL isAdded = ABAddressBookAddRecord (addressBook, aRecord, &error);
	
	if (!isAdded || error)
  {
		CFRelease(aRecord);
		return false;
	}
	
	BOOL isSaved = ABAddressBookSave (addressBook, &error);
	
	if(!isSaved || error != NULL) {
		CFRelease(aRecord);
		return false;
	}
	
	CFRelease(aRecord);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:phoneNumber
                                                    message:NSLocalizedString(@"core_contactAddedAlertMessage", @"Contact has been added to the Address Book.")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"core_contactAddedAlertOkButtonTitle", @"OK")
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
	
	return true;
}

+ (BOOL)contactExistsWithPhone:(NSString *)phoneNumber inAddressBook:(ABAddressBookRef)addressBook {
    
    NSArray *people= (NSArray *)ABAddressBookCopyArrayOfAllPeople(addressBook);
    
    for (int i = 0; i < people.count; i++) {
        ABRecordRef person = (ABRecordRef)[people objectAtIndex:i];
        
        ABMutableMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
        CFIndex phoneNumberCount = ABMultiValueGetCount(phoneNumbers);
        
        for (int k = 0; k < phoneNumberCount; k++) {
            CFStringRef phoneNumberValue = ABMultiValueCopyValueAtIndex(phoneNumbers, k);
            
            if([phoneNumber isEqualToString:(NSString *)phoneNumberValue]) {
                CFRelease(phoneNumberValue);
                CFRelease(phoneNumbers);
                CFRelease(people);
                return YES;
            }
            
            CFRelease(phoneNumberValue);
        }
      
        CFRelease(phoneNumbers);
    }
    CFRelease(people);
    
    return NO;
}

#pragma mark    >>>    PHONE  

+ (BOOL) isStringValidPhoneNumber:(NSString *)checkString{
  NSString *filterString = @"[+]{0,1}[0-9]{5,12}";
  NSPredicate *phoneNumberTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", filterString];
  return [phoneNumberTest evaluateWithObject:checkString];
}

#pragma mark    >>>    EMAIL    

+ (BOOL) isStringValidEmail:(NSString *)checkString {
  BOOL stricterFilter = YES;
  NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
  NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
  NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
  NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
  return [emailTest evaluateWithObject:checkString];
}


+ (MFMailComposeViewController *)callMailComposerWithRecipients:(NSArray *)recipients
                                                     andSubject:(NSString *)subject
                                                        andBody:(NSString *)body
                                                         asHTML:(BOOL)isHTML
                                                 withAttachment:(NSData *)attachment
                                                       mimeType:(NSString *)mimeType
                                                       fileName:(NSString *)filename
                                                 fromController:(UIViewController<MFMailComposeViewControllerDelegate> *) controller
                                                       showLink:(BOOL)showLink
{
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    if (mailClass != nil){
        if ([MFMailComposeViewController canSendMail])
        {
            NSString *messageBody = [[[NSString alloc] initWithFormat:@""] autorelease];
            
            if (showLink) messageBody = [messageBody stringByAppendingString:[NSString stringWithFormat:@"<br /><br />%@ <a href=\"http://ibuildapp.com\">iBuildApp</a>", NSLocalizedString(@"core_messageTextShowLinkAddition", @"Sent from")]];
            messageBody = [body stringByAppendingString:messageBody];
            TMailComposeViewController	*mailPicker = [[[TMailComposeViewController alloc] init] autorelease];
            mailPicker.mailComposeDelegate = controller;
            mailPicker.navigationBar.barStyle = UIBarStyleBlack;
            
            [mailPicker setToRecipients:recipients];
            if (showLink) {
                [mailPicker setSubject:[subject stringByAppendingString:[NSString stringWithFormat:@" %@ iBuildApp", NSLocalizedString(@"core_messageTextShowLinkAddition", @"Sent from")]]];
            } else {
                [mailPicker setSubject:subject];
            }
            [mailPicker setMessageBody:messageBody isHTML:YES]; 
            
            if(attachment)
              [mailPicker addAttachmentData:attachment mimeType:mimeType fileName:filename];

            [controller presentViewController:mailPicker animated:YES completion:nil];
          
            return mailPicker;
        } else {
            NSLog(@"Device not configured to send mail.");
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"core_cannotSendEmailAlertTitle", @"Mail cannot be send")
                                                            message:NSLocalizedString(@"core_cannotSendEmailAlertMessage", @"This device not configured to send mail")
                                                           delegate:self 
                                                  cancelButtonTitle:NSLocalizedString(@"core_cannotSendEmailAlertOkButtonTitle", @"OK")
                                                  otherButtonTitles:nil];
            [alert show];
            [alert release];
        }
    } else {
        NSLog(@"Device not configured to send mail.");
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"core_cannotSendEmailAlertTitle", @"Mail cannot be send")
                                                      message:NSLocalizedString(@"core_cannotSendEmailAlertMessage", @"This device not configured to send mail")
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"core_cannotSendEmailAlertOkButtonTitle", @"OK")
                                            otherButtonTitles:nil];
        [alert show];
        [alert release];
    }
    return nil;
}


- (void)callMailComposerWithRecipients:(NSArray *)recipients
                            andSubject:(NSString *)subject
                               andBody:(NSString *)body
                                asHTML:(BOOL)isHTML
                        withAttachment:(NSData *)attachment
                              mimeType:(NSString *)mimeType
                              fileName:(NSString *)filename
                        fromController:(UIViewController *)controller
                              showLink:(BOOL)showLink
{
  Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
  if (mailClass != nil) {
    if ([mailClass canSendMail]) {
      
      parentController = controller;
      
      NSString *messageBody = [[[NSString alloc] initWithFormat:@""] autorelease];
      
      if (showLink) messageBody = [messageBody stringByAppendingString:[NSString stringWithFormat:@"<br /><br />%@ <a href=\"http://ibuildapp.com\">iBuildApp</a>)", NSLocalizedString(@"core_messageTextShowLinkAddition", @"Sent from")]];
      messageBody = [body stringByAppendingString:messageBody];
      TMailComposeViewController	*mailPicker = [[TMailComposeViewController alloc] init];
      mailPicker.mailComposeDelegate = self;
      mailPicker.navigationBar.barStyle = UIBarStyleBlack;
      
      [mailPicker setToRecipients:recipients];
      if (showLink) {
        [mailPicker setSubject:[subject stringByAppendingString:[NSString stringWithFormat:@" (%@ iBuildApp)", NSLocalizedString(@"core_messageTextShowLinkAddition", @"Sent from")]]];
      } else {
        [mailPicker setSubject:subject];
      }
      [mailPicker setMessageBody:messageBody isHTML:YES];
      
      if(attachment) [mailPicker addAttachmentData:attachment mimeType:mimeType fileName:filename];
      
      [controller presentModalViewController:mailPicker animated:YES];
      [mailPicker release];
    } else {
      NSLog(@"Device not configured to send mail.");
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"core_cannotSendEmailAlertTitle", @"Mail cannot be send")
                                                      message:NSLocalizedString(@"core_cannotSendEmailAlertMessage", @"This device not configured to send mail")
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"core_cannotSendEmailAlertOkButtonTitle", @"OK")
                                            otherButtonTitles:nil];
      [alert show];
      [alert release];
    }
  } else {
    NSLog(@"Device not configured to send mail.");
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"core_cannotSendEmailAlertTitle", @"Mail cannot be send")
                                                    message:NSLocalizedString(@"core_cannotSendEmailAlertMessage", @"This device not configured to send mail")
                                                   delegate:self
                                          cancelButtonTitle:NSLocalizedString(@"core_cannotSendEmailAlertOkButtonTitle", @"OK")
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
  }
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)composeResult error:(NSError *)error {
    switch (composeResult) {
        case MFMailComposeResultCancelled:
            NSLog(@"Result: Mail sending canceled");
            break;
            
        case MFMailComposeResultSaved:
            NSLog(@"Result: Mail saved");
            break;
            
        case MFMailComposeResultSent:
            NSLog(@"Result: Mail sent");
            break;
            
        case MFMailComposeResultFailed:
            NSLog(@"Result: Mail sending failed");
            break;
            
        default:
            NSLog(@"Result: Mail not sent");
            break;
    }
    [parentController dismissModalViewControllerAnimated:YES];
}


#pragma mark    >>>    SMS
+ (MFMessageComposeViewController *)callSMSComposerWithRecipients:(NSArray *)recipients
                                                          andBody:(NSString *)body
                                                   fromController:(UIViewController<MFMessageComposeViewControllerDelegate> *)controller
{
    if ([MFMessageComposeViewController canSendText])
    {
      MFMessageComposeViewController *SMSPicker = [[[MFMessageComposeViewController alloc] init] autorelease];
      SMSPicker.messageComposeDelegate = controller;
      SMSPicker.navigationBar.barStyle = UIBarStyleBlack;
      SMSPicker.recipients             = recipients;
      NSString *msg = [body stringByReplacingOccurrencesOfString:@"<br />" withString:@""];
      SMSPicker.body = msg;
      [[controller navigationController] presentModalViewController:SMSPicker animated:YES];
      return SMSPicker;
    } else {
      UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"core_cannotSendSMSAlertTitle", @"SMS cannot be send")
                                                      message:NSLocalizedString(@"core_cannotSendSMSAlertMessage", @"This device not configured to send SMS")
                                                     delegate:self
                                            cancelButtonTitle:NSLocalizedString(@"core_cannotSendSMSAlertOkButtonTitle", @"OK")
                                            otherButtonTitles:nil];
      [alert show];
      [alert release];
    }
    return nil;
}



- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)composeResult {
    switch (composeResult) {
        case MessageComposeResultCancelled:
            NSLog(@"Result: SMS sending canceled");
            break;
            
        case MessageComposeResultSent:
            NSLog(@"Result: SMS sent");
            break;
            
        case MessageComposeResultFailed:
            NSLog(@"Result: SMS sending failed");
            break;
            
        default:
            NSLog(@"Result: SMS not sent");
            break;
    }
    [parentController dismissModalViewControllerAnimated:YES];
}


#pragma mark >>> EVENTS AND CALENDAR

+ (void)saveEventWithDate:(NSDate*)date
                 andTitle:(NSString*)eventTitle
   andConfirmationMessage:(NSString*)confirmationMessage {
  
  
  EKEventStore *eventStore = [[[EKEventStore alloc] init] autorelease];
  
  if([eventStore respondsToSelector:@selector(requestAccessToEntityType:completion:)]) {
    
    // iOS 6 and later
    [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
      if (granted){
        //---- codes here when user allow your app to access theirs' calendar.
        //        NSLog(@"user allow your app to access theirs' calendar.");
        
        [functionLibrary saveEventWithEventStore:eventStore andDate:date andTitle:eventTitle andConfirmationMessage:confirmationMessage];
      }else
      {
        //----- codes here when user NOT allow your app to access the calendar.
        //        NSLog(@"user NOT allow your app to access the calendar.");
        
        [functionLibrary performSelectorOnMainThread:@selector(showMessage:) withObject:NSLocalizedString(@"core_addingToCalendarDisabledMessage", @"Adding to calendar is disabled") waitUntilDone:FALSE];
      }
    }];
  } else {
    //---- codes here for IOS < 6.0.
    [functionLibrary saveEventWithEventStore:eventStore andDate:date andTitle:eventTitle andConfirmationMessage:confirmationMessage];
  }
}


+ (void)saveEventWithEventStore:(EKEventStore*)eventStore
                        andDate:(NSDate*)date
                       andTitle:(NSString*)eventTitle
         andConfirmationMessage:(NSString*)confirmationMessage             
{
  EKEvent *event  = [EKEvent eventWithEventStore:eventStore];
  event.title     = eventTitle;
  
  event.startDate = date;
  event.endDate = event.startDate;
  
  [event setCalendar:[eventStore defaultCalendarForNewEvents]];
  
  NSDate *minDate = [[NSDate alloc] initWithTimeInterval:-(60 * 60 * 12) sinceDate:event.endDate];
  NSDate *maxDate = [[NSDate alloc] initWithTimeInterval:60 * 60 * 12 sinceDate:event.endDate];
  
  NSPredicate *prediction=[eventStore predicateForEventsWithStartDate:minDate endDate:maxDate calendars:[eventStore calendars]];
  
  NSArray *events = [eventStore eventsMatchingPredicate:prediction];
  
  BOOL save = YES;
  
  for (EKEvent *eventOnDate in events) {
    if([eventOnDate.title isEqualToString:event.title])
    {
      save = NO;  //event already exists
      [functionLibrary performSelectorOnMainThread:@selector(showMessage:)
                             withObject:NSLocalizedString(@"core_eventAlreadyExistsMessage", @"Event already exists.")
                          waitUntilDone:FALSE];
      
      break;
    }
  }
  
  if(save)
  {
    NSError *err = nil;
    [eventStore saveEvent:event span:EKSpanThisEvent error:&err];
    
    if (!confirmationMessage)
      confirmationMessage = [NSString stringWithFormat:NSLocalizedString(@"core_eventAddedMessage", @"The event '%@' has been successfully added to your calendar"), eventTitle];
    
    if (!err)
    {
      //      NSLog(@"The event has been successfully added to your calendar");
      [functionLibrary performSelectorOnMainThread:@selector(showMessage:) withObject:confirmationMessage waitUntilDone:FALSE];
    }
    
  }
  [minDate release];
  [maxDate release];
}


+ (void) showMessage: (NSString*) messsage
{
  // if we use UIAlerView in block - it freeze UI and shows after big delay.. so we use performSelectorOnMainThread :)
  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"core_eventGeneralAlertTitle", @"Event")
                                                      message:messsage
                                                     delegate:nil
                                            cancelButtonTitle:NSLocalizedString(@"core_eventGeneralAlertOkButtonTitle", @"OK")
                                            otherButtonTitles:nil];
  [alertView show];
  [alertView release];
}


#pragma mark    >>>    GEOCODING

+ (NSDictionary *)coordinatesForAddress:(NSString*)address {

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSString *status;
    NSString *latitude;
    NSString *longitude;
    
    NSError* error = nil;
    NSURLResponse* response = nil;
    NSMutableURLRequest* request = [[[NSMutableURLRequest alloc] init] autorelease];
    
    
    NSURL *URL = [[NSURL alloc] initWithString:[[NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/geocode/json?address=%@&sensor=true", address] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    [request setURL:URL];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setTimeoutInterval:60];
    
    [URL release];
    
    NSData *data = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    if (error) {
        status = @"Error performing request";
        latitude  = @"";
        longitude = @"";
    }
    
    NSString *jsonString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    SBJsonParser *jsonParser = [SBJsonParser new]; 
    
    NSMutableDictionary *results = [jsonParser objectWithString:jsonString];
    
    if(results) {
        if ([[results objectForKey:@"status"] isEqual:@"ZERO_RESULTS"]) {            
            status = @"Address cannot be displayed!";
            latitude  = @"";
            longitude = @"";
            
        } else {
            
            status = @"OK";
            
            latitude  = [[[[[results objectForKey:@"results"] objectAtIndex:0] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lat"];
            longitude = [[[[[results objectForKey:@"results"] objectAtIndex:0] objectForKey:@"geometry"] objectForKey:@"location"] objectForKey:@"lng"];
        }
    } else {
      UIAlertView *noNetwork = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"general_cellularDataTurnedOff",@"Cellular Data is Turned off")
                                                     message:NSLocalizedString(@"general_cellularDataTurnOnMessage",@"Turn on cellular data or use Wi-Fi to access data")
                                                    delegate:nil
                                           cancelButtonTitle:NSLocalizedString(@"general_defaultButtonTitleOK",@"OK")
                                           otherButtonTitles:nil] autorelease];
        [noNetwork show];
        
        status = @"No Network Available!";
        latitude  = @"";
        longitude = @"";
    }

    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [jsonString release];
    [jsonParser release];
    
    return [NSDictionary dictionaryWithObjectsAndKeys:status, @"status", latitude, @"latitude", longitude, @"longitude", nil];
}

#pragma mark    >>>    DATE

+ (NSDate *)dateFromInternetDateTimeString:(NSString *)dateString {

    if (!dateString)
      return nil;
  
    NSDate *date = nil;
    NSDateFormatter *formatter = nil;
    NSLocale *en_US_POSIX = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter = [[NSDateFormatter alloc] init];
    [formatter setLocale:en_US_POSIX];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    [en_US_POSIX release];
  
//     * RFC3339
    NSString *RFC3339String = [[NSString stringWithString:dateString] uppercaseString];
    RFC3339String = [RFC3339String stringByReplacingOccurrencesOfString:@"Z" withString:@"-0000"];
    
  
    if (!date) { // 1996-12-19T16:39:57-0800
        [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZ"];
        date = [formatter dateFromString:RFC3339String];
    }
    if (!date) { // 1937-01-01T12:00:27.87+0020
        [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSSZZZ"];
        date = [formatter dateFromString:RFC3339String];
    }
    if (!date) { // 1937-01-01T12:00:27
        [formatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"];
        date = [formatter dateFromString:RFC3339String];
    }
    if (date)
    {
      [formatter release];
      return date;
    }
//     * RFC822
    NSString *RFC822String = [[NSString stringWithString:dateString] uppercaseString];
    if (!date) { // Sun, 19 May 02 15:21:36 GMT
        [formatter setDateFormat:@"EEE, d MMM yy HH:mm:ss zzz"];
        date = [formatter dateFromString:RFC822String];
    }
    if (!date) { // Sun, 19 May 2002 15:21:36 GMT
        [formatter setDateFormat:@"EEE, d MMM yyyy HH:mm:ss zzz"];
        date = [formatter dateFromString:RFC822String];
    }
    if (!date) { // Sun, 19 May 2002 15:21 GMT
        [formatter setDateFormat:@"EEE, d MMM yyyy HH:mm zzz"];
        date = [formatter dateFromString:RFC822String];
    }
    if (!date) { // 19 May 2002 15:21:36 GMT
        [formatter setDateFormat:@"d MMM yyyy HH:mm:ss zzz"];
        date = [formatter dateFromString:RFC822String];
    }
    if (!date) { // 19 May 2002 15:21 GMT
        [formatter setDateFormat:@"d MMM yyyy HH:mm zzz"];
        date = [formatter dateFromString:RFC822String];
    }
    if (!date) { // 19 May 2002 15:21:36
        [formatter setDateFormat:@"d MMM yyyy HH:mm:ss"];
        date = [formatter dateFromString:RFC822String];
    }
    if (!date) { // 19 May 2002 15:21
        [formatter setDateFormat:@"d MMM yyyy HH:mm"];
        date = [formatter dateFromString:RFC822String];
    }
// *Twitter
  if (!date) { // May 19 15:21:36, 2013
    [formatter setTimeStyle:NSDateFormatterFullStyle];
    [formatter setDateFormat:@"MMM d HH:mm:ss, yyyy"];
    date = [formatter dateFromString:RFC822String];
  }
  
    [formatter release];
    if (date)
      return date;
    
    // Failed
    return nil;
}


#pragma mark    >>>    STRING

//   http://google-toolbox-for-mac.googlecode.com/svn/trunk/Foundation/GTMNSString+HTML.m
typedef struct {
    NSString *escapeSequence;
    unichar uchar;
} HTMLEscapeMap;

static HTMLEscapeMap ASCIIHTMLEscapeMap[] = {
    {@"&quot;", 34},
    {@"&amp;", 38},
    {@"&apos;", 39},
    {@"&lt;", 60},
    {@"&gt;", 62},
    {@"&nbsp;", 160}, 
    {@"&iexcl;", 161}, 
    {@"&cent;", 162}, 
    {@"&pound;", 163}, 
    {@"&curren;", 164}, 
    {@"&yen;", 165}, 
    {@"&brvbar;", 166}, 
    {@"&sect;", 167}, 
    {@"&uml;", 168}, 
    {@"&copy;", 169}, 
    {@"&ordf;", 170}, 
    {@"&laquo;", 171}, 
    {@"&not;", 172}, 
    {@"&shy;", 173}, 
    {@"&reg;", 174}, 
    {@"&macr;", 175}, 
    {@"&deg;", 176}, 
    {@"&plusmn;", 177}, 
    {@"&sup2;", 178}, 
    {@"&sup3;", 179}, 
    {@"&acute;", 180}, 
    {@"&micro;", 181}, 
    {@"&para;", 182}, 
    {@"&middot;", 183}, 
    {@"&cedil;", 184}, 
    {@"&sup1;", 185}, 
    {@"&ordm;", 186}, 
    {@"&raquo;", 187}, 
    {@"&frac14;", 188}, 
    {@"&frac12;", 189}, 
    {@"&frac34;", 190}, 
    {@"&iquest;", 191}, 
    {@"&Agrave;", 192}, 
    {@"&Aacute;", 193}, 
    {@"&Acirc;", 194}, 
    {@"&Atilde;", 195}, 
    {@"&Auml;", 196}, 
    {@"&Aring;", 197}, 
    {@"&AElig;", 198}, 
    {@"&Ccedil;", 199}, 
    {@"&Egrave;", 200}, 
    {@"&Eacute;", 201}, 
    {@"&Ecirc;", 202}, 
    {@"&Euml;", 203}, 
    {@"&Igrave;", 204}, 
    {@"&Iacute;", 205}, 
    {@"&Icirc;", 206}, 
    {@"&Iuml;", 207}, 
    {@"&ETH;", 208}, 
    {@"&Ntilde;", 209}, 
    {@"&Ograve;", 210}, 
    {@"&Oacute;", 211}, 
    {@"&Ocirc;", 212}, 
    {@"&Otilde;", 213}, 
    {@"&Ouml;", 214}, 
    {@"&times;", 215}, 
    {@"&Oslash;", 216}, 
    {@"&Ugrave;", 217}, 
    {@"&Uacute;", 218}, 
    {@"&Ucirc;", 219}, 
    {@"&Uuml;", 220}, 
    {@"&Yacute;", 221}, 
    {@"&THORN;", 222}, 
    {@"&szlig;", 223}, 
    {@"&agrave;", 224}, 
    {@"&aacute;", 225}, 
    {@"&acirc;", 226}, 
    {@"&atilde;", 227}, 
    {@"&auml;", 228}, 
    {@"&aring;", 229}, 
    {@"&aelig;", 230}, 
    {@"&ccedil;", 231}, 
    {@"&egrave;", 232}, 
    {@"&eacute;", 233}, 
    {@"&ecirc;", 234}, 
    {@"&euml;", 235}, 
    {@"&igrave;", 236}, 
    {@"&iacute;", 237}, 
    {@"&icirc;", 238}, 
    {@"&iuml;", 239}, 
    {@"&eth;", 240}, 
    {@"&ntilde;", 241}, 
    {@"&ograve;", 242}, 
    {@"&oacute;", 243}, 
    {@"&ocirc;", 244}, 
    {@"&otilde;", 245}, 
    {@"&ouml;", 246}, 
    {@"&divide;", 247}, 
    {@"&oslash;", 248}, 
    {@"&ugrave;", 249}, 
    {@"&uacute;", 250}, 
    {@"&ucirc;", 251}, 
    {@"&uuml;", 252}, 
    {@"&yacute;", 253}, 
    {@"&thorn;", 254}, 
    {@"&yuml;", 255},
    {@"&OElig;", 338},
    {@"&oelig;", 339},
    {@"&Scaron;", 352},
    {@"&scaron;", 353},
    {@"&Yuml;", 376},
    {@"&fnof;", 402}, 
    {@"&circ;", 710},
    {@"&tilde;", 732},
    {@"&Alpha;", 913}, 
    {@"&Beta;", 914}, 
    {@"&Gamma;", 915}, 
    {@"&Delta;", 916}, 
    {@"&Epsilon;", 917}, 
    {@"&Zeta;", 918}, 
    {@"&Eta;", 919}, 
    {@"&Theta;", 920}, 
    {@"&Iota;", 921}, 
    {@"&Kappa;", 922}, 
    {@"&Lambda;", 923}, 
    {@"&Mu;", 924}, 
    {@"&Nu;", 925}, 
    {@"&Xi;", 926}, 
    {@"&Omicron;", 927}, 
    {@"&Pi;", 928}, 
    {@"&Rho;", 929}, 
    {@"&Sigma;", 931}, 
    {@"&Tau;", 932}, 
    {@"&Upsilon;", 933}, 
    {@"&Phi;", 934}, 
    {@"&Chi;", 935}, 
    {@"&Psi;", 936}, 
    {@"&Omega;", 937}, 
    {@"&alpha;", 945}, 
    {@"&beta;", 946}, 
    {@"&gamma;", 947}, 
    {@"&delta;", 948}, 
    {@"&epsilon;", 949}, 
    {@"&zeta;", 950}, 
    {@"&eta;", 951}, 
    {@"&theta;", 952}, 
    {@"&iota;", 953}, 
    {@"&kappa;", 954}, 
    {@"&lambda;", 955}, 
    {@"&mu;", 956}, 
    {@"&nu;", 957}, 
    {@"&xi;", 958}, 
    {@"&omicron;", 959}, 
    {@"&pi;", 960}, 
    {@"&rho;", 961}, 
    {@"&sigmaf;", 962}, 
    {@"&sigma;", 963}, 
    {@"&tau;", 964}, 
    {@"&upsilon;", 965}, 
    {@"&phi;", 966}, 
    {@"&chi;", 967}, 
    {@"&psi;", 968}, 
    {@"&omega;", 969}, 
    {@"&thetasym;", 977}, 
    {@"&upsih;", 978}, 
    {@"&piv;", 982}, 
    {@"&ensp;", 8194},
    {@"&emsp;", 8195},
    {@"&thinsp;", 8201},
    {@"&zwnj;", 8204},
    {@"&zwj;", 8205},
    {@"&lrm;", 8206},
    {@"&rlm;", 8207},
    {@"&ndash;", 8211},
    {@"&mdash;", 8212},
    {@"&lsquo;", 8216},
    {@"&rsquo;", 8217},
    {@"&sbquo;", 8218},
    {@"&ldquo;", 8220},
    {@"&rdquo;", 8221},
    {@"&bdquo;", 8222},
    {@"&dagger;", 8224},
    {@"&Dagger;", 8225},
    {@"&bull;", 8226}, 
    {@"&hellip;", 8230}, 
    {@"&permil;", 8240},
    {@"&prime;", 8242}, 
    {@"&Prime;", 8243}, 
    {@"&lsaquo;", 8249},
    {@"&rsaquo;", 8250},
    {@"&oline;", 8254}, 
    {@"&frasl;", 8260}, 
    {@"&euro;", 8364},
    {@"&image;", 8465},
    {@"&weierp;", 8472}, 
    {@"&real;", 8476}, 
    {@"&trade;", 8482}, 
    {@"&alefsym;", 8501}, 
    {@"&larr;", 8592}, 
    {@"&uarr;", 8593}, 
    {@"&rarr;", 8594}, 
    {@"&darr;", 8595}, 
    {@"&harr;", 8596}, 
    {@"&crarr;", 8629}, 
    {@"&lArr;", 8656}, 
    {@"&uArr;", 8657}, 
    {@"&rArr;", 8658}, 
    {@"&dArr;", 8659}, 
    {@"&hArr;", 8660}, 
    {@"&forall;", 8704}, 
    {@"&part;", 8706}, 
    {@"&exist;", 8707}, 
    {@"&empty;", 8709}, 
    {@"&nabla;", 8711}, 
    {@"&isin;", 8712}, 
    {@"&notin;", 8713}, 
    {@"&ni;", 8715}, 
    {@"&prod;", 8719}, 
    {@"&sum;", 8721}, 
    {@"&minus;", 8722}, 
    {@"&lowast;", 8727}, 
    {@"&radic;", 8730}, 
    {@"&prop;", 8733}, 
    {@"&infin;", 8734}, 
    {@"&ang;", 8736}, 
    {@"&and;", 8743}, 
    {@"&or;", 8744}, 
    {@"&cap;", 8745}, 
    {@"&cup;", 8746}, 
    {@"&int;", 8747}, 
    {@"&there4;", 8756}, 
    {@"&sim;", 8764}, 
    {@"&cong;", 8773}, 
    {@"&asymp;", 8776}, 
    {@"&ne;", 8800}, 
    {@"&equiv;", 8801}, 
    {@"&le;", 8804}, 
    {@"&ge;", 8805}, 
    {@"&sub;", 8834}, 
    {@"&sup;", 8835}, 
    {@"&nsub;", 8836}, 
    {@"&sube;", 8838}, 
    {@"&supe;", 8839}, 
    {@"&oplus;", 8853}, 
    {@"&otimes;", 8855}, 
    {@"&perp;", 8869}, 
    {@"&sdot;", 8901}, 
    {@"&lceil;", 8968}, 
    {@"&rceil;", 8969}, 
    {@"&lfloor;", 8970}, 
    {@"&rfloor;", 8971}, 
    {@"&lang;", 9001}, 
    {@"&rang;", 9002}, 
    {@"&loz;", 9674}, 
    {@"&spades;", 9824}, 
    {@"&clubs;", 9827}, 
    {@"&hearts;", 9829}, 
    {@"&diams;", 9830 }
};

+ (NSString *)stringByTrimSlash:(NSString *)inputString {
  NSString *outputString = inputString;
  if([inputString hasSuffix:@"/"]) {
    outputString = [inputString stringByPaddingToLength:(inputString.length - 1) withString:@"" startingAtIndex:0];
  }
  return outputString;
}

+ (NSString *)stringByReplaceEntitiesInString:(NSString *)inputString {
    NSRange range = NSMakeRange(0, [inputString length]);
    NSRange subrange = [inputString rangeOfString:@"&" options:NSBackwardsSearch range:range];
    if (subrange.length == 0) return inputString;
    NSMutableString *finalString = [NSMutableString stringWithString:inputString];
    do {
        NSRange semiColonRange = NSMakeRange(subrange.location, NSMaxRange(range) - subrange.location);
        semiColonRange = [inputString rangeOfString:@";" options:0 range:semiColonRange];
        range = NSMakeRange(0, subrange.location);
        if (semiColonRange.location == NSNotFound) {
            continue;
        }
        NSRange escapeRange = NSMakeRange(subrange.location, semiColonRange.location - subrange.location + 1);
        NSString *escapeString = [inputString substringWithRange:escapeRange];
        NSUInteger length = [escapeString length];
        if (length > 3 && length < 11) {
            if ([escapeString characterAtIndex:1] == '#') {
                unichar char2 = [escapeString characterAtIndex:2];
                if (char2 == 'x' || char2 == 'X') {
                    NSString *hexSequence = [escapeString substringWithRange:NSMakeRange(3, length - 4)];
                    NSScanner *scanner = [NSScanner scannerWithString:hexSequence];
                    unsigned value;
                    if ([scanner scanHexInt:&value] && 
                        value < USHRT_MAX &&
                        value > 0 
                        && [scanner scanLocation] == length - 4) {
                        unichar uchar = value;
                        NSString *charString = [NSString stringWithCharacters:&uchar length:1];
                        [finalString replaceCharactersInRange:escapeRange withString:charString];
                    }
                } else {
                    NSString *numberSequence = [escapeString substringWithRange:NSMakeRange(2, length - 3)];
                    NSScanner *scanner = [NSScanner scannerWithString:numberSequence];
                    int value;
                    if ([scanner scanInt:&value] && 
                        value < USHRT_MAX &&
                        value > 0 
                        && [scanner scanLocation] == length - 3) {
                        unichar uchar = value;
                        NSString *charString = [NSString stringWithCharacters:&uchar length:1];
                        [finalString replaceCharactersInRange:escapeRange withString:charString];
                    }
                }
            } else {
                for (unsigned i = 0; i < sizeof(ASCIIHTMLEscapeMap) / sizeof(HTMLEscapeMap); ++i) {
                    if ([escapeString isEqualToString:ASCIIHTMLEscapeMap[i].escapeSequence]) {
                        [finalString replaceCharactersInRange:escapeRange withString:[NSString stringWithCharacters:&ASCIIHTMLEscapeMap[i].uchar length:1]];
                        break;
                    }
                }
            }
        }
    } while ((subrange = [inputString rangeOfString:@"&" options:NSBackwardsSearch range:range]).length != 0);
    return finalString;
}

+ (NSString *) hostNameFromString:(NSString *)inputString {
    NSURL *url = [NSURL URLWithString:inputString];
    if (!url)
        return nil;
    
    return url.host;
}

+ (NSString *)extractYoutubeID:(NSString *)youtubeURL
{
  NSError *error = nil;
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"v=([^&]+)"
                                                                         options:NSRegularExpressionCaseInsensitive
                                                                           error:&error];
  NSTextCheckingResult *match = [regex firstMatchInString:youtubeURL
                                                  options:0
                                                    range:NSMakeRange( 0, [youtubeURL length])];
  if (match) {
    NSRange videoIDRange = [match rangeAtIndex:1];
    return [youtubeURL substringWithRange:videoIDRange];
  }
  return nil;
}

+ (NSString*)getVUrlStr:(NSString*)url
{
  if (url == nil)
    return nil;
  
  NSRange pos=[url.lowercaseString rangeOfString:@"vimeo"];
  if(pos.location == NSNotFound)
    return url;
  
  NSString *retVal = [url stringByReplacingOccurrencesOfString:@"vimeo.com" withString:@"player.vimeo.com/video"];
  
  return retVal;
}


+ (NSString*)getYTUrlStr:(NSString*)url
{
    if (url == nil)
        return nil;
    
    NSRange pos=[url rangeOfString:@"youtu"];
    if(pos.location == NSNotFound)
        return url;
    
    NSString *retVal = [url stringByReplacingOccurrencesOfString:@"watch?v=" withString:@"v/"];
    pos=[retVal rangeOfString:@"version"];
	if(pos.location == NSNotFound)
    {
        retVal = [retVal stringByAppendingString:@"?version=3&hl=en_EN"];
    }
    return retVal;
}


+ (NSString *)addSuffixToNumber:(int) number
{
  NSString *suffix;
  NSInteger ones = number % 10;
  NSInteger temp = floor(number / 10.0f);
  NSInteger tens = temp % 10;
  
  if(tens == 1) {
    suffix = @"th";
  } else if(ones ==1) {
    suffix = @"st";
  } else if(ones == 2) {
    suffix = @"nd";
  } else if(ones == 3) {
    suffix = @"rd";
  } else {
    suffix = @"th";
  }
  
  NSString *completeAsString = [NSString stringWithFormat:@"%d%@", number, suffix];
  return completeAsString;
}


+ (NSString *)formatTimeInterval:(NSDate *)dateToCompare {
  
  NSTimeInterval tInterval = [[NSDate date] timeIntervalSinceDate:dateToCompare];
  NSTimeInterval dayDiff = floor(tInterval / 86400.0f);
  
  if(dayDiff < 0.0f) {
    return NSLocalizedString(@"core_formatTimeIntervalJustNow", @"Just Now");
  }
  else if(tInterval < 60.0f) {
    return NSLocalizedString(@"core_formatTimeIntervalJustNow", @"Just Now");
  }
  else if(tInterval < 120.0f) {
    return NSLocalizedString(@"core_formatTimeIntervalOneMinuteAgo", @"1 minute ago");
  }
  else if(tInterval < 3600.0f) {
    NSNumber *number = [NSNumber numberWithFloat:floor(tInterval / 60.0f)];
    return [NSString stringWithFormat:SLPluralizedString(@"core_formatTimeIntervalSomeMinutesAgo_%@ minutes ago", number, nil), number];
    
//    return [NSString stringWithFormat:@"%.f %@", floor(tInterval / 60.0f), NSLocalizedString(@"core_formatTimeIntervalSomeMinutesAgo", @"minutes ago")];
  }
  else if(tInterval < 7200.0f) {
    return NSLocalizedString(@"core_formatTimeIntervalOneHourAgo", @"1 hour ago");
  }
  else if(tInterval < 86400.0f) {
//    return [NSString stringWithFormat:@"%.f %@", floor(tInterval / 3600.0f), NSLocalizedString(@"core_formatTimeIntervalSomeHoursAgo", @"hours ago")];
    NSNumber *number = [NSNumber numberWithFloat:floor(tInterval / 3600.0f)];
    return [NSString stringWithFormat:SLPluralizedString(@"core_formatTimeIntervalSomeHoursAgo_%@ hours ago", number, nil), number];
  }
  else if(dayDiff == 1.0f) {
    return NSLocalizedString(@"core_formatTimeIntervalYesterday", @"Yesterday");
  }
  else if(dayDiff < 4.0f) {
//    return [NSString stringWithFormat:@"%.f %@", dayDiff, NSLocalizedString(@"core_formatTimeIntervalSomeDaysAgo", @"days ago")];
    NSNumber *number = [NSNumber numberWithFloat:dayDiff];
    return [NSString stringWithFormat:SLPluralizedString(@"core_formatTimeIntervalSomeDaysAgo_%@ days ago", number, nil), number];
  }
  else {


    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateStyle:NSDateFormatterLongStyle];
    
    NSString *str = [dateFormat stringFromDate:dateToCompare];
    [dateFormat setDateStyle:NSDateFormatterNoStyle];
    [dateFormat setTimeStyle:NSDateFormatterShortStyle];
    str = [str stringByAppendingFormat:@" %@ %@", NSLocalizedString(@"core_formatTimeIntervalAt", @"At"), [dateFormat stringFromDate:dateToCompare]];
    
    [dateFormat release];
    
    return str;
  }
  
  return @"";
}

+ (NSDate *)dateWithNoTime:(NSDate *)dateTime {
  if( dateTime == nil ) {
    dateTime = [NSDate date];
  }
  
  NSCalendar       *calendar   = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];

  NSDateComponents *components = [[[NSDateComponents alloc] init] autorelease];
  components = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit
                           fromDate:dateTime];
  
  NSDate *dateOnly = [calendar dateFromComponents:components];
  
  return dateOnly;
}

+ (NSString *) dateDiffForDate:(NSDate*)date
{
  // Analog for method in widget mTwitter:
  // + (NSString *) dateDiffForString:(NSString *)string
  
  NSDateFormatter *outputDateFormat = [[[NSDateFormatter alloc] init] autorelease];
  
  NSCalendar *calendar = [[[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar] autorelease];
  NSDateComponents *components = [calendar components: ( NSHourCalendarUnit   |
                                                        NSMinuteCalendarUnit |
                                                        NSSecondCalendarUnit |
                                                        NSMonthCalendarUnit  |
                                                        NSDayCalendarUnit    |
                                                        NSYearCalendarUnit
                                                        )
                                             fromDate:date
                                               toDate:[NSDate date]
                                              options:0];
  //	int months = [components month];
  NSInteger days   = [components day];
  NSInteger hours   = [components hour];
  NSInteger minutes = [components minute];
  NSInteger seconds = [components second];
  NSInteger years =  [components year];
  
  NSNumber *number = nil;
  NSString *timePart = @"";
  
  if (years > 0)
  {
    [outputDateFormat setDateFormat:@"dd.MM.yyyy"];
    return [outputDateFormat stringFromDate:date];
  }
  
  if (days > 0)
  {
    [outputDateFormat setDateFormat:@"EEE dd"];
    return [outputDateFormat stringFromDate:date];
  }
  
  // else (during current day): h, m, s
  
  if (hours > 0)
  {
    number = [NSNumber numberWithInt:hours];
    timePart = NSLocalizedString(@"core_timeComponent_hours", @"h");
  }
  else if (minutes > 0)
  {
    number = [NSNumber numberWithInt:minutes];
    timePart = NSLocalizedString(@"core_timeComponent_minutes", @"m");
  }
  else if (seconds > 0)
  {
    number = [NSNumber numberWithInt:seconds];
    timePart = NSLocalizedString(@"core_timeComponent_seconds", @"s");
  }
  
  return [NSString stringWithFormat:@"%@%@", number, timePart];
  
}


@end