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

#import "thumbnailcache.h"

#import <CommonCrypto/CommonDigest.h> // Need to import for CC_MD5 access

@implementation NSString (MyExtensions)
- (NSString *) md5
{
  const char *cStr = [self UTF8String];
  unsigned char result[16];
  CC_MD5( cStr, strlen(cStr), result ); // This is the md5 call
  return [NSString stringWithFormat:
          @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
          result[0], result[1], result[2], result[3], 
          result[4], result[5], result[6], result[7],
          result[8], result[9], result[10], result[11],
          result[12], result[13], result[14], result[15]
          ];
}
@end

@implementation NSData (MyExtensions)
- (NSString*)md5
{
  unsigned char result[16];
  CC_MD5( self.bytes, self.length, result ); // This is the md5 call
  return [NSString stringWithFormat:
          @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
          result[0], result[1], result[2], result[3], 
          result[4], result[5], result[6], result[7],
          result[8], result[9], result[10], result[11],
          result[12], result[13], result[14], result[15]
          ];  
}
@end


@interface TThumbnailItem : NSObject <NSCoding>
{
  CGSize     m_size;
  NSString  *m_filename;
}
@property (nonatomic, copy)   NSString *filename;
@property (nonatomic, assign) CGSize    size;

-(id)initWithFilename:(NSString *)filename_
              andSize:(CGSize )size_;
@end

@implementation TThumbnailItem
@synthesize filename = m_filename,
            size     = m_size;

-(id)initWithFilename:(NSString *)filename_
              andSize:(CGSize )size_
{
  self = [super init];
  if ( self )
  {
    self.filename = filename_;
    self.size     = size_;
  }
  return self;
}

-(void)dealloc
{
  self.filename = nil;
  [super dealloc];
}

// Encode an object for an archive
- (void)encodeWithCoder:(NSCoder *)coder
{
  [coder encodeObject:self.filename  forKey:@"filename"];
  [coder encodeDouble:m_size.width   forKey:@"imageWidth"];
  [coder encodeDouble:m_size.height  forKey:@"imageHeight"];
}
// Decode an object from an archive
- (id)initWithCoder:(NSCoder *)coder
{
  self = [super init];
  if ( self )
  {
    self.filename = [coder decodeObjectForKey:@"filename"];
    m_size = CGSizeMake( [coder decodeDoubleForKey:@"imageWidth" ],
                         [coder decodeDoubleForKey:@"imageHeight"] );
  }
  return self;
}

@end


@implementation TThumbnailCache

static NSString *g_jpegMIMEtypes[] = {
  @"jp2" ,
  @"jpeg",
  @"jpm" ,
  @"jpx" ,
};

static BOOL isJPEGmimeType(NSString *type_);

BOOL isJPEGmimeType(NSString *type_)
{
  for( unsigned i = 0; i < sizeof(g_jpegMIMEtypes) / sizeof(g_jpegMIMEtypes[0]); ++i )
    if ( [type_ isEqualToString:g_jpegMIMEtypes[i]] )
      return YES;
  return NO;
}

static TThumbnailCache *instance_;

static void singleton_remover()
{
  [instance_ release];
}


+ (TThumbnailCache*)instance {
  @synchronized(self)
  {
    if( instance_ == nil )
    {
      instance_ = [[self alloc] init];
    }
  }
  return instance_;
}

-(id)init
{
  self = [super init];
  if (self)
  {
    instance_ = self;
    m_cache = [[NSMutableDictionary alloc] init];
    m_queue = dispatch_queue_create("TThumbnailCacheQueue", NULL);
    atexit(singleton_remover);
  }
  return self;
}

-(void)dealloc
{
  if ( m_cache )
  {
    [m_cache release];
    m_cache = nil;
  }
  if ( m_queue )
    dispatch_release( m_queue );
  [super dealloc];
}

+(NSString *)cacheDir
{
  return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0];
}

+(NSURL *)path
{
  return [NSURL fileURLWithPath:[TThumbnailCache cacheDir]];
}


-(BOOL)isCached:(NSURL *)url_
{
  return [m_cache objectForKey:url_.absoluteString] ? YES : NO;
}

-(NSURL *)getCachedURL:(NSURL *)url_
{
  NSArray *thumbnails = [m_cache objectForKey:url_.absoluteString];

  if ( thumbnails && thumbnails.count )
  {
    return [[[NSURL alloc ]  initWithString:((TThumbnailItem *)[thumbnails objectAtIndex:0]).filename
                              relativeToURL:[TThumbnailCache path]] autorelease];
  }
  return nil;
}

-(NSURL *)getCachedURL:(NSURL *)url_
              withSize:(CGSize)size_
{
  NSArray *thumbnails = [m_cache objectForKey:url_.absoluteString];

  if ( thumbnails )
  {
    TThumbnailItem *bestItem = nil;

    CGFloat minDist = MAXFLOAT;
    for( TThumbnailItem *it in thumbnails )
    {
      CGFloat dist = ABS(it.size.width  - size_.width ) +
                     ABS(it.size.height - size_.height);
      if ( dist < minDist )
      {
        minDist = dist;
        bestItem = it;
      }
    }
    if ( bestItem )
      return [[[NSURL alloc ]  initWithString:bestItem.filename
                                relativeToURL:[TThumbnailCache path]] autorelease];
  }
  return nil;
}


-(BOOL)commitToDBwithURL:(NSURL *)url_
                fileName:(NSString *)filename_
                 andSize:(CGSize)size_
{
  NSMutableArray *thumbnails = [m_cache objectForKey:url_.absoluteString];
  if ( !thumbnails )
  {
    thumbnails = [NSMutableArray arrayWithObjects: [[[TThumbnailItem alloc] initWithFilename:filename_
                                                                                     andSize:size_ ] autorelease] , nil];
    [m_cache setObject:thumbnails
                forKey:url_.absoluteURL];
    return YES;
  }else{
    for( TThumbnailItem *it in thumbnails )
    {
      if ( it.size.width  == size_.width &&
          it.size.height == size_.height )
        return NO;
    }
    [thumbnails addObject:[[[TThumbnailItem alloc] initWithFilename:filename_
                                                            andSize:size_ ] autorelease]];
    return YES;
  }
  return NO;
}


-(BOOL)saveThumbnail:(UIImage *)img_
             withURL:(NSURL *)url_
                type:(NSString *)type_
{
  @autoreleasepool
  {
    NSString *filename = [url_.absoluteString md5];
    
    BOOL bJPEG = isJPEGmimeType( type_ );
    filename = [filename stringByAppendingFormat:@"_%lux%lu.%@", (long unsigned)img_.size.width,
                                                                 (long unsigned)img_.size.height,
                                                                 bJPEG ? @"jpg" : @"png"];
    
    NSString *filePath = [[TThumbnailCache cacheDir] stringByAppendingPathComponent:filename];
    
    if ( [[NSFileManager defaultManager] fileExistsAtPath:filePath] )
    {
      [self commitToDBwithURL:url_
                     fileName:filename
                      andSize:img_.size];
      return NO;
    }
    dispatch_async( m_queue,
                   ^ {
                       @autoreleasepool
                       {
                         NSData *thumbData = bJPEG ? UIImageJPEGRepresentation( img_, 0.9 ) :
                                                     UIImagePNGRepresentation( img_ );

                         if ( ![[NSFileManager defaultManager] createFileAtPath:filePath
                                                                       contents:thumbData
                                                                     attributes:nil] )
                           return;

                         NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:filePath];
                         // execute asynchronously
                         [fileHandle seekToEndOfFile];
                         [fileHandle writeData:thumbData];
                         [fileHandle closeFile];
                         
                         CGSize imgSize = img_.size;
                         NSURL    *url   = [[url_ copy] autorelease];
                         NSString *fName = [[filePath copy] autorelease];

                         dispatch_async(dispatch_get_main_queue(), ^{
                           [self commitToDBwithURL:url
                                          fileName:fName
                                           andSize:imgSize];
                         });
                       }
                   });
    return YES;
  }
  return NO;
}

@end
