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

#import "avStreamPlayerPluginManager.h"
#import "avStreamPlayerSoundCloudPlugin.h"

typedef struct tagavStreamPlayerPluginList
{
  NSString  *serviceName;
  NSString  *plugin;
}avStreamPlayerPluginList;

static const avStreamPlayerPluginList g_avStreamPlayerPluginList[] =
{
  { @"soundcloud", @"avStreamPlayerSoundCloudPlugin" },
};

@implementation avStreamPlayerPlugin
-(void)resolveStreamURL:(NSURL *)url_
  withCompletionHandler:(avStreamPlayerPluginCompletionHandler)completionHandler
{
  NSLog(@"avSP: resolving URL %@", url_.absoluteString);
  if ( completionHandler )
    completionHandler( [[url_ copy] autorelease], nil );
}
@end


@implementation avStreamPlayerPluginManager

+(avStreamPlayerPlugin *)pluginWithServiceName:(NSString *)serviceName_
{
  serviceName_ = [serviceName_ lowercaseString];
  for ( unsigned i = 0; i < sizeof(g_avStreamPlayerPluginList)/sizeof(g_avStreamPlayerPluginList[0]); ++i )
  {
    if ( [g_avStreamPlayerPluginList[i].serviceName isEqualToString:serviceName_] )
    {
      Class cls = NSClassFromString(g_avStreamPlayerPluginList[i].plugin);
      if ( cls )
        return [[[cls alloc] init] autorelease];
    } else {
      return [[[NSClassFromString(@"avStreamPlayerShoutcastTesterPlugin") alloc] init] autorelease];
    }
  }
  return [[[avStreamPlayerPlugin alloc] init] autorelease];
}

+(avStreamPlayerPlugin *)pluginWithStreamURL:(NSURL *)streamURL_
{
  NSString *hostName = [streamURL_ host];
  NSArray *temp = [hostName componentsSeparatedByString: @"."];
  if ([temp count] > 1)
    hostName = [temp objectAtIndex:([temp count] - 2)];
  return [avStreamPlayerPluginManager pluginWithServiceName:hostName];
}

@end