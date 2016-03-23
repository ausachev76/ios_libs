//
//  PayPalOAuthScopes.h
//
//  Version 2.9.0
//
//  Copyright (c) 2014, PayPal
//  All rights reserved.
//

// Currently available scope-values to which the user can be asked to consent.
// @see https://developer.paypal.com/docs/integration/direct/identity/attributes/ for more details

/// Authorize charges for future purchases paid for with PayPal.
static NSString *const kPayPalOAuth2ScopeFuturePayments;
/// Share basic account information.
static NSString *const kPayPalOAuth2ScopeProfile;
/// Basic Authentication.
static NSString *const kPayPalOAuth2ScopeOpenId;
/// Share your personal and account information.
static NSString *const kPayPalOAuth2ScopePayPalAttributes;
/// Share your email address.
static NSString *const kPayPalOAuth2ScopeEmail;
/// Share your account address.
static NSString *const kPayPalOAuth2ScopeAddress;
/// Share your phone number.
static NSString *const kPayPalOAuth2ScopePhone;

