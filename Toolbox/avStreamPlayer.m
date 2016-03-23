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

#import "avStreamPlayer.h"
#import "avStreamPlayerPluginManager.h"
#import <UIKit/UIKit.h>
#import "notifications.h"
#import "NSURLCache+external.h"

static void *MyStreamingMovieViewControllerTimedMetadataObserverContext    = &MyStreamingMovieViewControllerTimedMetadataObserverContext;
static void *MyStreamingMovieViewControllerRateObservationContext          = &MyStreamingMovieViewControllerRateObservationContext;
static void *MyStreamingMovieViewControllerCurrentItemObservationContext   = &MyStreamingMovieViewControllerCurrentItemObservationContext;
static void *MyStreamingMovieViewControllerPlayerItemStatusObserverContext = &MyStreamingMovieViewControllerPlayerItemStatusObserverContext;

NSString *kTracksKey		    = @"tracks";
NSString *kStatusKey		    = @"status";
NSString *kRateKey		     	= @"rate";
NSString *kPlayableKey		  = @"playable";
NSString *kCurrentItemKey	  = @"currentItem";
NSString *kTimedMetadataKey	= @"currentItem.timedMetadata";

static avStreamPlayer *g_avStreamPlayerSingleton = nil;

@interface avStreamPlayer()
{
  AVAudioSession *avAudioSession;
  CMTime interruprionPauseTime;
}
  @property(nonatomic, strong) AVPlayerItem *playerItem;
  @property(nonatomic, assign)           id  timeObserver;
  @property(nonatomic, assign)         BOOL  bPlayingBeforeInterruption;
@end

@implementation avStreamPlayer
@synthesize   player = _player,
            playList = _playList,
          playerItem = _playerItem,
            delegate = _delegate,
        timeObserver = _timeObserver,
         currentItem = _currentItem,
             looping = _looping,
remoteControlEnabled = _remoteControlEnabled,
   autoplayNextTrack = _autoplayNextTrack,
       trackDuration = _trackDuration,
bPlayingBeforeInterruption = _bPlayingBeforeInterruption,
       trackPosition = _trackPosition,
               state = _state;

+(avStreamPlayer *)sharedInstance
{
  @synchronized(self)
  {
    if (g_avStreamPlayerSingleton == nil)
    {
      g_avStreamPlayerSingleton = [NSAllocateObject([self class], 0, NULL) init];
    }
  }
  return g_avStreamPlayerSingleton;
}

- (id) copyWithZone:(NSZone*)zone
{
  return self;
}

- (id) retain
{
  return self;
}

- (NSUInteger) retainCount
{
  return NSUIntegerMax;
}

- (oneway void)release { }

- (id) autorelease
{
  return self;
}


-(id)init
{
  self = [super init];
  if ( self )
  {
    _player        = nil;
    _playList      = nil;
    _playerItem    = nil;
    _timeObserver  = nil;
    _delegate      = nil;
    _looping              = NO;
    _autoplayNextTrack    = NO;
    _remoteControlEnabled = NO;
    _bPlayingBeforeInterruption = NO;
    _currentItem   = 0;
    _trackDuration = 0;
    _trackPosition = 0;
    
    _state = _Stopped;
    
    interruprionPauseTime = kCMTimeZero;
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
  }
  return self;
}

-(void)dealloc
{
  self.remoteControlEnabled = NO;
  
  [_timeObserver release];

  [[NSNotificationCenter defaultCenter] removeObserver:self
                                                  name:AVPlayerItemDidPlayToEndTimeNotification
                                                object:nil];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self
                                               name:AVAudioSessionInterruptionNotification
                                             object:[AVAudioSession sharedInstance]];
  
  [self.player removeObserver:self forKeyPath:kCurrentItemKey];
  [self.player removeObserver:self forKeyPath:kTimedMetadataKey];
  [self.player removeObserver:self forKeyPath:kRateKey];
	[_player release];

  self.playList   = nil;
  self.playerItem = nil;
  self.delegate   = nil;
  [super dealloc];
}

-(void)setRemoteControlEnabled:(BOOL)bEnabled_
{
  if ( _remoteControlEnabled != bEnabled_ )
  {
    if ( bEnabled_ )
      [[NSNotificationCenter defaultCenter] addObserver:self
                                               selector:@selector(remoteControDidlReceivedNotification:)
                                                   name:kAPP_NOTIFICATION_REMOTE_CONTROL
                                                 object:nil];
    else
      [[NSNotificationCenter defaultCenter] removeObserver:self
                                                      name:kAPP_NOTIFICATION_REMOTE_CONTROL
                                                    object:nil];
    _remoteControlEnabled = bEnabled_;
  }
}

-(void)deinitPlayer
{
  // destroy the object player, who was previously, or some tracks will not play
  [self.player removeObserver:self forKeyPath:kCurrentItemKey];
  [self.player removeObserver:self forKeyPath:kTimedMetadataKey];
  [self.player removeObserver:self forKeyPath:kRateKey];
  [_player release];
  _player = nil;
}

-(void)setPlayList:(NSArray *)playList_
{
  if ( playList_ != _playList )
  {
    [self stop];
    [_playList release];
    _playList = [playList_ retain];
    _currentItem = 0;
    [self deinitPlayer];
  }
}

-(void)setCurrentItem:(NSInteger)currentItem_
{
  if ( currentItem_ != _currentItem )
  {
    [self stop];
    if ( currentItem_ < 0 || currentItem_ >= [self.playList count] )
      _currentItem = 0;
    else
      _currentItem = currentItem_;
  }
}

-(void)startPlayingWithItem:(NSUInteger)item_
{
  if ( item_ >= [self.playList count] )
  {
    NSString *szErrorMsg = [NSString stringWithFormat:@"item \"%lu\" out of range [0..%lu]", (unsigned long)item_, (unsigned long)[self.playList count] - 1 ];
    [self assetFailedToPrepareForPlayback:[NSError errorWithDomain:szErrorMsg code:3 userInfo:nil]];
    return;
  }
	/* Has the user entered a movie URL? */
  NSObject *obj = [self.playList objectAtIndex:item_];
  if ( ![obj isKindOfClass:[NSString class]] )
  {
    NSString *szErrorMsg = [NSString stringWithFormat:@"wrong object type: \"%@\" in playlist", [obj class]];
    [self assetFailedToPrepareForPlayback:[NSError errorWithDomain:szErrorMsg code:2 userInfo:nil]];
    return;
  }
  NSString *szURL = (NSString *)obj;
  
  NSLog(@"avSP: PLAYING URL: %@", szURL);
  
	if ( szURL.length > 0)
	{
    szURL = [[szURL stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSURL *newMovieURL = [NSURL URLWithString:szURL];
		if ([newMovieURL scheme])	/* Sanity check on the URL. */
		{
      avStreamPlayerPlugin *plugin = [[avStreamPlayerPluginManager pluginWithStreamURL:newMovieURL] retain];
      [plugin resolveStreamURL:newMovieURL withCompletionHandler:^(NSURL *streamURL, NSError *error)
       {
         dispatch_async( dispatch_get_main_queue(),
                        ^{
                          if ( streamURL && !error )
                          {
                            // Create an asset for inspection of a resource referenced by a given URL.
                            // Load the values for the asset keys "tracks", "playable".
                            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:streamURL options:nil];
                            
                            NSArray *requestedKeys = [NSArray arrayWithObjects:kTracksKey, kPlayableKey, nil];
                            /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
                            [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
                             ^{
                               dispatch_async( dispatch_get_main_queue(),
                                              ^{
                                                [self prepareToPlayAsset:asset withKeys:requestedKeys];
                                              });
                             }];
                          }else{
                            [self assetFailedToPrepareForPlayback:error];
                          }
                          [plugin release];
                        });
       }];
		}
	}
}

/* Cancels the previously registered time observer. */
-(void)removePlayerTimeObserver
{
	if ( _timeObserver )
	{
		[self.player removeTimeObserver:_timeObserver];
		[_timeObserver release];
		_timeObserver = nil;
	}
}


-(NSUInteger)trackDuration
{
  CMTime trackDuration = [self duration];
  if ( !CMTIME_IS_VALID(trackDuration) )
    return NSUIntegerMax;
  return trackDuration.timescale ?
                trackDuration.value / trackDuration.timescale :
                NSUIntegerMax;
}

-(NSUInteger)trackPosition
{
  if ( [self isPlaying] )
  {
    CMTime currentPosition = [self.playerItem currentTime];
    if ( !CMTIME_IS_VALID(currentPosition) )
      return NSUIntegerMax;
    return currentPosition.timescale ?
              currentPosition.value / currentPosition.timescale :
              NSUIntegerMax;
  }
  return NSUIntegerMax;
}

-(void)setTrackPosition:(NSUInteger)trackPosition_
{
  CMTime trackDuration = [self duration];
  if ( CMTIME_IS_VALID( trackDuration ) )
  {
    if ( !trackDuration.timescale )
      return;
    NSUInteger length = trackDuration.value / trackDuration.timescale;
    if ( trackPosition_ < length )
      [self.player seekToTime:CMTimeMake( trackPosition_ * trackDuration.timescale,
                                          trackDuration.timescale ) ];
  }
}

/* ---------------------------------------------------------
 **  Get the duration for a AVPlayerItem.
 ** ------------------------------------------------------- */

- (CMTime)duration
{
	AVPlayerItem *thePlayerItem = [self.player currentItem];
	if (thePlayerItem.status == AVPlayerItemStatusReadyToPlay)
	{
    /*
     NOTE:
     Because of the dynamic nature of HTTP Live Streaming Media, the best practice
     for obtaining the duration of an AVPlayerItem object has changed in iOS 4.3.
     Prior to iOS 4.3, you would obtain the duration of a player item by fetching
     the value of the duration property of its associated AVAsset object. However,
     note that for HTTP Live Streaming Media the duration of a player item during
     any particular playback session may differ from the duration of its asset. For
     this reason a new key-value observable duration property has been defined on
     AVPlayerItem.
     
     See the AV Foundation Release Notes for iOS 4.3 for more information.
     */
    
		return([self.playerItem duration]);
	}
  
	return(kCMTimeInvalid);
}

- (BOOL)isPlaying
{
	return [self.player rate] != 0.f;
}

-(void)assetFailedToPrepareForPlayback:(NSError *)error
{
  [self removePlayerTimeObserver];
  self.state = _Failed;
  if ( [self.delegate respondsToSelector:@selector(avStreamPlayer:failedToPrepareForPlayback:)] )
    [self.delegate avStreamPlayer:self failedToPrepareForPlayback:error];
  

  NSLog(@"avStreamPlayerError: %@ (%@)", [error localizedDescription], [error localizedFailureReason] );
}


/**
 * Invoked at the completion of the loading of the values for all keys on the asset that we require.
 * Checks whether loading was successfull and whether the asset is playable.
 * If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
 */
- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
{
  /* Make sure that the value of each key has loaded successfully. */
	for (NSString *thisKey in requestedKeys)
	{
		NSError *error = nil;
		AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
		if ( keyStatus == AVKeyValueStatusFailed )
		{
			[self assetFailedToPrepareForPlayback:error];
			return;
		}
		/* If you are also implementing the use of -[AVAsset cancelLoading], add your code here to bail
     out properly in the case of cancellation. */
	}
  
  /* Use the AVAsset playable property to detect whether the asset can be played. */
  if (!asset.playable)
  {
    /* Generate an error describing the failure. */
		NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
		NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
		NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               localizedDescription, NSLocalizedDescriptionKey,
                               localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                               nil];
		NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"avStreamPlayer" code:0 userInfo:errorDict];
    
    /* Display the error to the user. */
    [self assetFailedToPrepareForPlayback:assetCannotBePlayedError];
    return;
  }
	
	/* At this point we're ready to set up for playback of the asset. */
  
//	[self initScrubberTimer];
//	[self enableScrubber];
//	[self enablePlayerButtons];
	
  /* Stop observing our prior AVPlayerItem, if we have one. */
  if (self.playerItem)
  {
    /* Remove existing player item key value observers and notifications. */
    
    [self.playerItem removeObserver:self forKeyPath:kStatusKey];
		
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.playerItem];
  }
	
  /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
  self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
  
  /* Observe the player item "status" key to determine when it is ready to play. */
  [self.playerItem addObserver:self
                    forKeyPath:kStatusKey
                       options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                       context:MyStreamingMovieViewControllerPlayerItemStatusObserverContext];

  /* When the player item has played to its end time we'll toggle
   the movie controller Pause button to be the Play button */
  [[NSNotificationCenter defaultCenter] addObserver:self
                                           selector:@selector(playerItemDidReachEnd:)
                                               name:AVPlayerItemDidPlayToEndTimeNotification
                                             object:self.playerItem];
	
	[self deinitPlayer];
  
  /* Create new player, if we don't already have one. */
  if (![self player])
  {
    _bPlayingBeforeInterruption = NO;
    /* Get a new AVPlayer initialized to play the specified player item. */
    _player = [[AVPlayer playerWithPlayerItem:self.playerItem] retain];
		
    /* Observe the AVPlayer "currentItem" property to find out when any
     AVPlayer replaceCurrentItemWithPlayerItem: replacement will/did
     occur.*/
    [self.player addObserver:self
                  forKeyPath:kCurrentItemKey
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:MyStreamingMovieViewControllerCurrentItemObservationContext];
    
    /* A 'currentItem.timedMetadata' property observer to parse the media stream timed metadata. */
    [self.player addObserver:self
                  forKeyPath:kTimedMetadataKey
                     options:0
                     context:MyStreamingMovieViewControllerTimedMetadataObserverContext];
    
    /* Observe the AVPlayer "rate" property to update the scrubber control. */
    [self.player addObserver:self
                  forKeyPath:kRateKey
                     options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                     context:MyStreamingMovieViewControllerRateObservationContext];
  }
  
  /* Make our new AVPlayerItem the AVPlayer's current item. */
  if ( self.player.currentItem != self.playerItem )
  {
    /* Replace the player item with a new player item. The item replacement occurs
     asynchronously; observe the currentItem property to find out when the
     replacement will/did occur*/
    [[self player] replaceCurrentItemWithPlayerItem:self.playerItem];
  }
  [self.player seekToTime:interruprionPauseTime];//[self.player seekToTime:kCMTimeZero];
  [self.player play];
}

#pragma mark -
#pragma mark Asset Key Value Observing
#pragma mark

#pragma mark Key Value Observer for player rate, currentItem, player item status

/* ---------------------------------------------------------
 **  Called when the value at the specified key path relative
 **  to the given object has changed.
 **  Adjust the movie play and pause button controls when the
 **  player item "status" value changes. Update the movie
 **  scrubber control when the player item is ready to play.
 **  Adjust the movie scrubber control when the player item
 **  "rate" value changes. For updates of the player
 **  "currentItem" property, set the AVPlayer for which the
 **  player layer displays visual output.
 **  NOTE: this method is invoked on the main queue.
 ** ------------------------------------------------------- */
- (void)observeValueForKeyPath:(NSString*)path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
	/* AVPlayerItem "status" property value observer. */
	if ( context == MyStreamingMovieViewControllerPlayerItemStatusObserverContext )
	{
    AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
    switch (status)
    {
        /* Indicates that the status of the player is not yet known because
         it has not tried to load new media resources for playback */
      case AVPlayerStatusUnknown:
      {
        [self removePlayerTimeObserver];
      }
      break;
        
      case AVPlayerStatusReadyToPlay:
      {
        // Once the AVPlayerItem becomes ready to play, i.e.
        // [playerItem status] == AVPlayerItemStatusReadyToPlay,
        // its duration can be fetched from the item.
        
        /*
         * Nasty bug. (Or a feature). Spent many hours to fix it.
         * When AVPlayerItem status changed to ReadyToPlay, the whole PLAYER state changed to _Preparing.
         *
         * When the phone call arrived on a paused stream, the paused state of a player was switching to _Preparing
         * and we were getting paused stream with Pause icon, meaning that it was already playing (but it was not).
         *
         * Very arguable decision to switch player's state always to _Preparing every time item's status
         * changes to AVPlayerStatusReadyToPlay.
         */
        
        if(self.state != _Paused){
          self.state = _Preparing;
          if ( [self.delegate respondsToSelector:@selector(avStreamPlayer:readyForPlaybackWithItem:)] )
            [self.delegate avStreamPlayer:self readyForPlaybackWithItem:(AVPlayerItem *)object];
        }
      }
      break;
        
      case AVPlayerStatusFailed:
      {
        AVPlayerItem *thePlayerItem = (AVPlayerItem *)object;
        [self assetFailedToPrepareForPlayback:thePlayerItem.error];
      }
      break;
    }
	}
	/* AVPlayer "rate" property value observer. */
	else if (context == MyStreamingMovieViewControllerRateObservationContext)
	{
//    [self syncPlayPauseButtons];
	}
	/* AVPlayer "currentItem" property observer.
   Called when the AVPlayer replaceCurrentItemWithPlayerItem:
   replacement will/did occur. */
	else if ( context == MyStreamingMovieViewControllerCurrentItemObservationContext )
	{
    AVPlayerItem *newPlayerItem = [change objectForKey:NSKeyValueChangeNewKey];
    
    /* New player item null? */
    if (newPlayerItem == (id)[NSNull null])
    {
      /* You may handle it like
       * [self disablePlayerButtons];
       * [self disableScrubber];
      
       * self.isPlayingAdText.text = @"";
       */
    }
    else
    {
      /* Replacement of player currentItem has occurred
       * Set the AVPlayer for which the player layer displays visual output.
       * [playerLayerView.playerLayer setPlayer:self.player];
      
       * Specifies that the player should preserve the video’s aspect ratio and
       * fit the video within the layer’s bounds.
       * [playerLayerView setVideoFillMode:AVLayerVideoGravityResizeAspect];
      
       * [self syncPlayPauseButtons];
      */
    }
	}
	/* Observe the AVPlayer "currentItem.timedMetadata" property to parse the media stream
   timed metadata. */
	else if (context == MyStreamingMovieViewControllerTimedMetadataObserverContext)
	{
		NSArray* array = [[self.player currentItem] timedMetadata];
		for ( AVMetadataItem *metadataItem in array )
			[self handleTimedMetadata:metadataItem];
	}else{
		[super observeValueForKeyPath:path ofObject:object change:change context:context];
	}
  
  return;
}

#pragma mark -
#pragma mark Timed metadata
#pragma mark -

- (void)handleTimedMetadata:(AVMetadataItem*)timedMetadata
{
	/* We expect the content to contain plists encoded as timed metadata. AVPlayer turns these into NSDictionaries. */
	if ([(NSString *)[timedMetadata key] isEqualToString:AVMetadataID3MetadataKeyGeneralEncapsulatedObject])
	{
		if ([[timedMetadata value] isKindOfClass:[NSDictionary class]])
		{
			NSDictionary *propertyList = (NSDictionary *)[timedMetadata value];
      
			/* Metadata payload could be the list of ads. */
			NSArray *newAdList = [propertyList objectForKey:@"ad-list"];
			if (newAdList != nil)
			{
				NSLog(@"ad-list is %@", newAdList);
			}
      
			/* Or it might be an ad record. */
			NSString *adURL = [propertyList objectForKey:@"url"];
			if (adURL != nil)
			{
				if ([adURL isEqualToString:@""])
				{
					/* Ad is not playing, so clear text. */
					NSLog(@"enabling seek at %g", CMTimeGetSeconds([self.player currentTime]));
				}
				else
				{
					NSLog(@"disabling seek at %g", CMTimeGetSeconds([self.player currentTime]));
				}
			}
		}
	}
}

#pragma mark Player Notifications

/* Called when the player item has played to its end time. */
- (void)playerItemDidReachEnd:(NSNotification*)aNotification
{
  if ( [self.delegate respondsToSelector:@selector(avStreamPlayer:didFinishPlaybackWithItem:)] )
    [self.delegate avStreamPlayer:self didFinishPlaybackWithItem:self.player.currentItem];
  if ( self.autoplayNextTrack )
    [self forward];
}


- (void)play
{
  if ( ![self isPlaying] )
  {
    
    if ( [self.player status] == AVPlayerStatusReadyToPlay )
    {
      self.state = _Preparing;
      [self.player play];
    }
    else
    {
      self.state = _Playing;
      [self startPlayingWithItem:self.currentItem];
    }
  } else {
    [self assetFailedToPrepareForPlayback:[NSError errorWithDomain:@"AVPlayerStatusUnknown" code:AVPlayerStatusFailed userInfo:nil]];

  }
}

- (void)pause
{
  self.state = _Paused;
  [self.player pause];
}

- (void)stop
{
  self.state = _Stopped;
  [self deinitPlayer];
}

- (void)back
{
  if ( [self.playList count] > 1 )
  {
    [self stop];
    if ( --self.currentItem < 0 )
    {
      if ( self.looping )
      {
        self.currentItem = [self.playList count] - 1;
        [self startPlayingWithItem:self.currentItem];
      }else{
        self.currentItem = 0;
        [self startPlayingWithItem:self.currentItem];
      }
    }else{
      [self startPlayingWithItem:self.currentItem];
    }
  }
}

- (void)forward
{
  if ( [self.playList count] > 1 )
  {
    [self stop];
    if ( ++self.currentItem >= [self.playList count] )
    {
      if ( self.looping )
      {
        self.currentItem = 0;
        [self startPlayingWithItem:self.currentItem];
      }else{
        self.currentItem = [self.playList count] - 1;
        [self startPlayingWithItem:self.currentItem];
      }
    }else{
      [self startPlayingWithItem:self.currentItem];
    }
  }
}

//**********************************************************************************************
//                        intercept events from remoteControlCenter
//        events called by uiRootWindow - root window of application
//**********************************************************************************************
- (void)remoteControDidlReceivedNotification:(NSNotification *)aNotification
{
  if ( ![aNotification.object isKindOfClass:[UIEvent class]] )
    return;
  
  UIEvent *receivedEvent = aNotification.object;
  avStreamPlayer *avStream = self;
  
  if (receivedEvent.type == UIEventTypeRemoteControl)
  {
    switch (receivedEvent.subtype)
    {
      case UIEventSubtypeRemoteControlTogglePlayPause:
        if ( [avStream isPlaying] )
          [avStream pause];
        else
          [avStream play];
        break;
        
      case UIEventSubtypeRemoteControlPlay:
        [avStream play];
        break;
        
      case UIEventSubtypeRemoteControlPause:
        [avStream pause];
        break;
        
      case UIEventSubtypeRemoteControlPreviousTrack:
        [avStream back];
        break;
        
      case UIEventSubtypeRemoteControlNextTrack:
        [avStream forward];
        break;
      default:
        break;
    }
  }
}

@end