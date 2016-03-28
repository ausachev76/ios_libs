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

#import "iphviewcontrollerlist.h"

static const TIphoneVC g_viewControllerList[] = 
{
  { @"html"             , { @"mWebVCViewController"             , nil } },
  { @"taptocall"        , { @"mTapToCallViewController"         , nil } },
  { @"contact"          , { @"mMultiContactsViewController"     , nil } },
  { @"events"           , { @"mEventsViewController"            , nil } },
  { @"fanwall"          , { @"mFanWallViewController"           , nil } },
  { @"rss"              , { @"mNewsViewController"              , nil } },
  { @"news"             , { @"mNewsViewController"              , nil } },
  { @"images"           , { @"mGalleryViewController"           , nil } },
  { @"twitter"          , { @"mTwitterViewController"           , nil } },
  { @"facebook"         , { @"mWebVCViewController"             , nil } },
  { @"coupons"          , { @"mCouponsViewController"           , nil } },
  { @"map"              , { @"mMapViewController"               , nil } },
  { @"calendar"         , { @"mWebVCViewController"             , nil } },
  { @"googleform"       , { @"mWebVCViewController"             , nil } },
  { @"store"            , { @"mCommerceViewController"          , nil } },
  { @"table"            , { @"mTableChaptersViewController"     , nil } },
  { @"tablereservation" , { @"mTableReservationViewController"  , nil } },
  { @"customform"       , { @"mCustomFormViewController"        , nil } },
  { @"takepicture"      , { @"mTakePictureViewController"       , nil } },
  { @"barcode"          , { @"mBarCodeViewController"           , nil } },
  { @"calculator"       , { @"mMathCalcViewController"          , nil } },
  { @"multicontacts"    , { @"mMultiContactsViewController"     , nil } },
  { @"catalogbooks"     , { @"mDBViewerCatalogueViewController" , nil } },
  { @"email"            , { @"mEmailViewController"             , nil } },
  { @"videoplayer"      , { @"mVideoPlayerViewController"       , nil } },
  { @"audioplayer"      , { @"mAudioPlayerViewController"       , nil } },
  { @"photogallery"     , { @"mPhotoGalleryViewController"      , nil } },
  { @"menu"             , { @"mMenuViewController"              , nil } },
  { @"directory"        , { @"mMenuViewController"              , nil } },
  { @"opentable"        , { @"mOpenTableViewController"         , nil } },
  { @"shopcart"         , { @"mShoppingCartViewController"      , nil } },
  { @"messenger"        , { @"mSendMessageViewController"       , nil } },
  { @"jshtml"           , { @"mJSHTMLViewController"            , nil } },
  { @"catalogue"        , { @"mCatalogueViewController"         , nil } },
  { @"facebook2"        , { @"mFacebookViewController"          , nil } },
  { @"zopimchat"        , { @"mZopimchatViewController"         , nil } },
  { @"custom_module"    , { nil                                 , nil } },
};

const TIphoneVCdescriptor *viewControllerByType( NSString *type_ )
{
  for ( unsigned i = 0; i < sizeof(g_viewControllerList)/sizeof(g_viewControllerList[0]); ++i )
  {
    if ( [g_viewControllerList[i].type isEqualToString:type_] )
      return &g_viewControllerList[i].desc;
  }
  return nil;
}
