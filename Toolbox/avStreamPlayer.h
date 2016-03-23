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
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

@class avStreamPlayer;
@protocol avStreamPlayerDelegate<NSObject>
  @optional

    -(void)avStreamPlayer:(avStreamPlayer *)streamPlayer_ failedToPrepareForPlayback:(NSError *)error_;

    /**
     * Callback called at the end of the procedure for connecting to the audio stream
     */
    -(void)avStreamPlayer:(avStreamPlayer *)streamPlayer_ readyForPlaybackWithItem:(AVPlayerItem *)playerItem_;

    /**
     * Callback called at the end of track playback
     */
    -(void)avStreamPlayer:(avStreamPlayer *)streamPlayer_ didFinishPlaybackWithItem:(AVPlayerItem *)playerItem_;
@end

@interface avStreamPlayer : NSObject<AVAudioSessionDelegate>

  @property (strong   , readonly) AVPlayer  *player;
  @property (nonatomic, strong  ) NSArray   *playList;
  @property (nonatomic, assign  ) NSInteger  currentItem;
  @property (nonatomic, assign  ) BOOL       looping;
  @property (nonatomic, assign  ) BOOL       autoplayNextTrack;
  @property (nonatomic, assign  ) BOOL       remoteControlEnabled;
  @property (nonatomic, readonly) NSUInteger trackDuration;
  @property (nonatomic, assign  ) NSUInteger trackPosition;

  @property (nonatomic, assign  ) id<avStreamPlayerDelegate> delegate;


  +(avStreamPlayer *)sharedInstance;

  - (BOOL)isPlaying;

  /** 
   * Get track duration track duration can be known, when he will ready to play
   * (in method avStreamPlayer:readyForPlaybackWithItem: )
   *
   * @return - kCMTimeInvalid - if duration of track presently unknown
   */
  - (CMTime)duration;

  /**
   * Begin playing form playList with track index "currentItem"
   */
  - (void)play;

  /** 
   * Pause track
   */
  - (void)pause;

  /** 
   * Pause track and reset current position
   */
  - (void)stop;

  /** 
   * Play prev track from playList
   */
  - (void)back;

  /** 
   * Play next track from playList
   */
  - (void)forward;

  @property int state;

  typedef enum
  {
    _Stopped   = 0,
    _Preparing = 1,
    _Playing   = 2,
    _Paused    = 3,
    _Failed    = 4
  } state;
@end



