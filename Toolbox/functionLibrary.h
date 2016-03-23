#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>
#import <MessageUI/MessageUI.h>

/**
 *  Library with common methods
 */
@interface functionLibrary : NSObject <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate>
{
    BOOL replaceContact;
}

+ (BOOL)addContact:(NSString *)contactName withPhone:(NSString *)phoneNumber;
+ (BOOL)addContact:(NSString *)contactName withPhone:(NSString *)phoneNumber toAddressBook:(ABAddressBookRef) addressBook;
+ (BOOL)contactExistsWithPhone:(NSString *)phoneNumber inAddressBook:(ABAddressBookRef)addressBook;

+ (BOOL)isStringValidPhoneNumber:(NSString *)checkString;
+ (BOOL)isStringValidEmail:(NSString *)checkString;

+ (MFMailComposeViewController *)callMailComposerWithRecipients:(NSArray *)recipients
                                                     andSubject:(NSString *)subj
                                                        andBody:(NSString*)body
                                                         asHTML:(BOOL)isHTML
                                                 withAttachment:(NSData *)attachment
                                                       mimeType:(NSString *)mimeType
                                                       fileName:(NSString *)filename
                                                 fromController:(UIViewController<MFMailComposeViewControllerDelegate> *)controller
                                                       showLink:(BOOL)showLink;

+ (MFMessageComposeViewController *)callSMSComposerWithRecipients:(NSArray *)recipients
                                                          andBody:(NSString *)body
                                                   fromController:(UIViewController<MFMessageComposeViewControllerDelegate> *)controller;


/**
 * @deprecated due to memory leaks.
 */
- (void)callMailComposerWithRecipients:(NSArray *)recipients
                                                     andSubject:(NSString *)subj
                                                        andBody:(NSString*)body
                                                         asHTML:(BOOL)isHTML
                                                 withAttachment:(NSData *)attachment
                                                       mimeType:(NSString *)mimeType
                                                       fileName:(NSString *)filename
                                                 fromController:(UIViewController *)controller
                                                       showLink:(BOOL)showLink;

+ (void)saveEventWithDate:(NSDate*)date
                 andTitle:(NSString*)eventTitle
   andConfirmationMessage:(NSString*)confirmationMessage;

+ (NSString *)getVUrlStr:(NSString*)url;

+ (NSDictionary *)coordinatesForAddress:(NSString *)address;

+ (NSString *)stringByTrimSlash:(NSString *)inputString;
+ (NSString *)stringByReplaceEntitiesInString:(NSString *)inputString;
+ (NSString *) hostNameFromString:(NSString *)inputString;
+ (NSString *)getYTUrlStr:(NSString*)url;
+ (NSString *)extractYoutubeID:(NSString *)youtubeURL;
+ (NSString *)formatTimeInterval:(NSDate *)dateToCompare;
+ (NSDate *)dateWithNoTime:(NSDate *)dateTime;
+ (NSDate *)dateFromInternetDateTimeString:(NSString *)dateString;
+ (NSString *) dateDiffForDate:(NSDate*)date;

@end
