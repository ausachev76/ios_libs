// UIImage+Resize.m
// Created by Trevor Harmon on 8/5/09.
// Free for personal or commercial use, with or without modification.
// No warranty is expressed or implied.

#import "UIImage+Resize.h"
#import "UIImage+RoundedCorner.h"
#import "UIImage+Alpha.h"


#define kSourceImageTileSizeMB 10.f

#define bytesPerMB 1048576.0f
#define bytesPerPixel 4.0f
#define pixelsPerMB ( bytesPerMB / bytesPerPixel ) // 262144 pixels, for 4 bytes per pixel.

#define tileTotalPixels kSourceImageTileSizeMB * pixelsPerMB

#define destSeemOverlap 2.0f // the numbers of pixels to overlap the seems where tiles meet.

// Private helper methods
//@interface UIImage ()
//- (UIImage *)resizedImage:(CGSize)newSize
//                transform:(CGAffineTransform)transform
//           drawTransposed:(BOOL)transpose
//     interpolationQuality:(CGInterpolationQuality)quality;
//- (CGAffineTransform)transformForOrientation:(CGSize)newSize;
//@end

@implementation UIImage (Resize)


#pragma mark -
#pragma mark Private helper methods

// Returns a copy of the image that has been transformed using the given affine transform and scaled to the new size
// The new image's orientation will be UIImageOrientationUp, regardless of the current image's orientation
// If the new size is not integral, it will be rounded up
- (UIImage *)resizedImage:(CGSize)newSize
                transform:(CGAffineTransform)transform
           drawTransposed:(BOOL)transpose
     interpolationQuality:(CGInterpolationQuality)quality
{
  if ( !newSize.width || !newSize.height )
    return nil;
  
  CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
  CGRect transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
  CGImageRef imageRef = self.CGImage;
  
  // Build a context that's the same dimensions as the new size
  CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                              newRect.size.width,
                                              newRect.size.height,
                                              CGImageGetBitsPerComponent(imageRef),
                                              0,
                                              CGImageGetColorSpace(imageRef),
                                              (CGBitmapInfo)kCGImageAlphaPremultipliedLast );
  
  // Rotate and/or flip the image if required by its orientation
  CGContextConcatCTM(bitmap, transform);
  
  // Set the quality level to use when rescaling
  CGContextSetInterpolationQuality(bitmap, quality);
  
  // Draw into the context; this scales the image
  CGContextDrawImage(bitmap, transpose ? transposedRect : newRect, imageRef);
  
  // Get the resized image from the context and a UIImage
  CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
  UIImage *newImage = [UIImage imageWithCGImage:newImageRef];
  
  // Clean up
  CGContextRelease(bitmap);
  CGImageRelease(newImageRef);
  
  return newImage;
}

// Returns an affine transform that takes into account the image orientation when drawing a scaled image
- (CGAffineTransform)transformForOrientation:(CGSize)newSize {
  CGAffineTransform transform = CGAffineTransformIdentity;
  
  switch (self.imageOrientation) {
    case UIImageOrientationDown:           // EXIF = 3
    case UIImageOrientationDownMirrored:   // EXIF = 4
      transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
      transform = CGAffineTransformRotate(transform, M_PI);
      break;
      
    case UIImageOrientationLeft:           // EXIF = 6
    case UIImageOrientationLeftMirrored:   // EXIF = 5
      transform = CGAffineTransformTranslate(transform, newSize.width, 0);
      transform = CGAffineTransformRotate(transform, M_PI_2);
      break;
      
    case UIImageOrientationRight:          // EXIF = 8
    case UIImageOrientationRightMirrored:  // EXIF = 7
      transform = CGAffineTransformTranslate(transform, 0, newSize.height);
      transform = CGAffineTransformRotate(transform, -M_PI_2);
      break;
    default:
      break;
  }
  
  switch (self.imageOrientation) {
    case UIImageOrientationUpMirrored:     // EXIF = 2
    case UIImageOrientationDownMirrored:   // EXIF = 4
      transform = CGAffineTransformTranslate(transform, newSize.width, 0);
      transform = CGAffineTransformScale(transform, -1, 1);
      break;
      
    case UIImageOrientationLeftMirrored:   // EXIF = 5
    case UIImageOrientationRightMirrored:  // EXIF = 7
      transform = CGAffineTransformTranslate(transform, newSize.height, 0);
      transform = CGAffineTransformScale(transform, -1, 1);
      break;
    default:
      break;
  }
  
  return transform;
}


// Returns a copy of this image that is cropped to the given bounds.
// The bounds will be adjusted using CGRectIntegral.
// This method ignores the image's imageOrientation setting.
- (UIImage *)croppedImage:(CGRect)bounds {
  CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], bounds);
  UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
  CGImageRelease(imageRef);
  return croppedImage;
}

// Returns a copy of this image that is squared to the thumbnail size.
// If transparentBorder is non-zero, a transparent border of the given size will be added around the edges of the thumbnail. (Adding a transparent border of at least one pixel in size has the side-effect of antialiasing the edges of the image when rotating it using Core Animation.)
- (UIImage *)thumbnailImage:(NSInteger)thumbnailSize
          transparentBorder:(NSUInteger)borderSize
               cornerRadius:(NSUInteger)cornerRadius
       interpolationQuality:(CGInterpolationQuality)quality {
  UIImage *resizedImage = [self resizedImageWithContentMode:UIViewContentModeScaleAspectFill
                                                     bounds:CGSizeMake(thumbnailSize, thumbnailSize)
                                       interpolationQuality:quality];
  
  // Crop out any part of the image that's larger than the thumbnail size
  // The cropped rect must be centered on the resized image
  // Round the origin points so that the size isn't altered when CGRectIntegral is later invoked
  CGRect cropRect = CGRectMake(round((resizedImage.size.width - thumbnailSize) / 2),
                               round((resizedImage.size.height - thumbnailSize) / 2),
                               thumbnailSize,
                               thumbnailSize);
  UIImage *croppedImage = [resizedImage croppedImage:cropRect];
  
  UIImage *transparentBorderImage = borderSize ? [croppedImage transparentBorderImage:borderSize] : croppedImage;
  
  return [transparentBorderImage roundedCornerImage:cornerRadius borderSize:borderSize];
}

// Returns a rescaled copy of the image, taking into account its orientation
// The image will be scaled disproportionately if necessary to fit the bounds specified by the parameter
- (UIImage *)resizedImage:(CGSize)newSize interpolationQuality:(CGInterpolationQuality)quality {
  BOOL drawTransposed;
  
  switch (self.imageOrientation) {
    case UIImageOrientationLeft:
    case UIImageOrientationLeftMirrored:
    case UIImageOrientationRight:
    case UIImageOrientationRightMirrored:
      drawTransposed = YES;
      break;
      
    default:
      drawTransposed = NO;
  }
  
  return [self resizedImage:newSize
                  transform:[self transformForOrientation:newSize]
             drawTransposed:drawTransposed
       interpolationQuality:quality];
}

// Resizes the image according to the given content mode, taking into account the image's orientation
- (UIImage *)resizedImageWithContentMode:(UIViewContentMode)contentMode
                                  bounds:(CGSize)bounds
                    interpolationQuality:(CGInterpolationQuality)quality {
  CGFloat horizontalRatio = bounds.width / self.size.width;
  CGFloat verticalRatio = bounds.height / self.size.height;
  CGFloat ratio;
  
  switch (contentMode) {
    case UIViewContentModeScaleAspectFill:
      ratio = MAX(horizontalRatio, verticalRatio);
      break;
      
    case UIViewContentModeScaleAspectFit:
      ratio = MIN(horizontalRatio, verticalRatio);
      break;
      
    default:
      return nil;
      //[NSException raise:NSInvalidArgumentException format:@"Unsupported content mode: %d", contentMode];
  }
  
  CGSize newSize = CGSizeMake(self.size.width * ratio, self.size.height * ratio);
  
  return [self resizedImage:newSize interpolationQuality:quality];
}


-(UIImage *)resizeImageWithContentMode:(UIViewContentMode)contentMode
                                bounds:(CGSize)bounds
                  interpolationQuality:(CGInterpolationQuality)quality
{
  // create an autorelease pool to catch calls to -autorelease.
  NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
  // create an image from the image filename constant. Note this
  // doesn't actually read any pixel information from disk, as that
  // is actually done at draw time.
  CGSize sourceResolution = CGSizeMake( CGImageGetWidth(self.CGImage), CGImageGetHeight(self.CGImage));
  
  // determine the scale ratio to apply to the input image
  // that results in an output image of the defined size.
  // see kDestImageSizeMB, and how it relates to destTotalPixels.
  CGFloat horizontalRatio = bounds.width / self.size.width;
  CGFloat verticalRatio = bounds.height / self.size.height;
  CGFloat imageScale = contentMode == UIViewContentModeScaleAspectFill ?
                                          MAX(horizontalRatio, verticalRatio) :
                                          MIN(horizontalRatio, verticalRatio);
  CGSize destResolution = CGSizeMake( floorf(self.size.width * imageScale), floorf(self.size.height * imageScale) );
  
  // create an offscreen bitmap context that will hold the output image
  // pixel data, as it becomes available by the downscaling routine.
  // use the RGB colorspace as this is the colorspace iOS GPU is optimized for.
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  int bytesPerRow = bytesPerPixel * destResolution.width;
  // allocate enough pixel data to hold the output image.
  void* destBitmapData = malloc( bytesPerRow * destResolution.height );
  if( destBitmapData == NULL )
  {
    NSLog(@"failed to allocate space for the output image!");
    CGColorSpaceRelease( colorSpace );
    [pool drain];
    return nil;
  }
  // create the output bitmap context
  CGContextRef destContext = CGBitmapContextCreate(destBitmapData,
                                                   destResolution.width,
                                                   destResolution.height,
                                                   8,
                                                   bytesPerRow,
                                                   colorSpace,
                                                   (CGBitmapInfo)kCGImageAlphaPremultipliedLast );
  // remember CFTypes assign/check for NULL. NSObjects assign/check for nil.
  if( destContext == NULL )
  {
    CGColorSpaceRelease( colorSpace );
    free( destBitmapData );
    NSLog(@"failed to create the output bitmap context!");
    [pool drain];
    return nil;
  }
  // release the color space object as its job is done
  CGColorSpaceRelease( colorSpace );

  // now define the size of the rectangle to be used for the
  // incremental blits from the input image to the output image.
  // we use a source tile width equal to the width of the source
  // image due to the way that iOS retrieves image data from disk.
  // iOS must decode an image from disk in full width 'bands', even
  // if current graphics context is clipped to a subrect within that
  // band. Therefore we fully utilize all of the pixel data that results
  // from a decoding opertion by achnoring our tile size to the full
  // width of the input image.
  CGRect sourceTile = CGRectZero;
  sourceTile.size.width = sourceResolution.width;
  // the source tile height is dynamic. Since we specified the size
  // of the source tile in MB, see how many rows of pixels high it
  // can be given the input image width.
  sourceTile.size.height = (int)( tileTotalPixels / sourceTile.size.width );
  NSLog(@"source tile size: %f x %f",sourceTile.size.width, sourceTile.size.height);
  sourceTile.origin.x = 0.0f;
  // the output tile is the same proportions as the input tile, but
  // scaled to image scale.
  CGRect destTile = CGRectZero;
  destTile.size.width  = destResolution.width;
  destTile.size.height = sourceTile.size.height * imageScale;
  destTile.origin.x = 0.0f;
  NSLog(@"dest tile size: %f x %f",destTile.size.width, destTile.size.height);
  // the source seem overlap is proportionate to the destination seem overlap.
  // this is the amount of pixels to overlap each tile as we assemble the ouput image.
  float sourceSeemOverlap = (int)( ( destSeemOverlap / destResolution.height ) * sourceResolution.height );
  NSLog(@"dest seem overlap: %f, source seem overlap: %f", destSeemOverlap, sourceSeemOverlap);
  CGImageRef sourceTileImageRef;
  // calculate the number of read/write opertions required to assemble the
  // output image.
  int iterations = (int)( sourceResolution.height / sourceTile.size.height );
  // if tile height doesn't divide the image height evenly, add another iteration
  // to account for the remaining pixels.
  int remainder = (int)sourceResolution.height % (int)sourceTile.size.height;
  if( remainder )
    iterations++;
  // add seem overlaps to the tiles, but save the original tile height for y coordinate calculations.
  float sourceTileHeightMinusOverlap = sourceTile.size.height;
  sourceTile.size.height += sourceSeemOverlap;
  destTile.size.height += destSeemOverlap;
  NSLog(@"beginning downsize. iterations: %d, tile height: %f, remainder height: %d", iterations, sourceTile.size.height,remainder );
  for( int y = 0; y < iterations; ++y )
  {
    // create an autorelease pool to catch calls to -autorelease made within the downsize loop.
    NSAutoreleasePool* pool2 = [[NSAutoreleasePool alloc] init];
    NSLog(@"iteration %d of %d",y+1,iterations);
    sourceTile.origin.y = y * sourceTileHeightMinusOverlap + sourceSeemOverlap;
    destTile.origin.y = ( destResolution.height ) - ( ( y + 1 ) * sourceTileHeightMinusOverlap * imageScale + destSeemOverlap );
    // create a reference to the source image with its context clipped to the argument rect.
    sourceTileImageRef = CGImageCreateWithImageInRect( self.CGImage, sourceTile );
    // if this is the last tile, it's size may be smaller than the source tile height.
    // adjust the dest tile size to account for that difference.
    if( y == iterations - 1 && remainder )
    {
      float dify = destTile.size.height;
      destTile.size.height = CGImageGetHeight( sourceTileImageRef ) * imageScale;
      dify -= destTile.size.height;
      destTile.origin.y += dify;
    }
    // read and write a tile sized portion of pixels from the input image to the output image.
    CGContextDrawImage( destContext, destTile, sourceTileImageRef );
    /* release the source tile portion pixel data. note,
     releasing the sourceTileImageRef doesn't actually release the tile portion pixel
     data that we just drew, but the call afterward does. */
    CGImageRelease( sourceTileImageRef );
    /* while CGImageCreateWithImageInRect lazily loads just the image data defined by the argument rect,
     that data is finally decoded from disk to mem when CGContextDrawImage is called. sourceTileImageRef
     maintains internally a reference to the original image, and that original image both, houses and
     caches that portion of decoded mem. Thus the following call to release the source image. */
    // free all objects that were sent -autorelease within the scope of this loop.
    [pool2 drain];
    // we reallocate the source image after the pool is drained since UIImage -imageNamed
    // returns us an autoreleased object.
    //    if( y < iterations - 1 )
    //    {
    //      sourceImage = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:kImageFilename ofType:nil]];
    //      [self performSelectorOnMainThread:@selector(updateScrollView:) withObject:nil waitUntilDone:YES];
    //    }
  }
  //  NSLog(@"downsize complete.");
  //  [self performSelectorOnMainThread:@selector(initializeScrollView:) withObject:nil waitUntilDone:YES];
  // free the context since its job is done. destImageRef retains the pixel data now.
  CGImageRef destImageRef = CGBitmapContextCreateImage( destContext );
  
  if( destImageRef == NULL )
  {
    NSLog(@"destImageRef is null.");
    CGContextRelease( destContext );
    free( destBitmapData );
    [pool drain];
    return nil;
  }
  // wrap a UIImage around the CGImage
  [pool drain];
  
  UIImage *destImage = [UIImage imageWithCGImage:destImageRef
                                           scale:1.0f
                                     orientation:UIImageOrientationUp];
  // release ownership of the CGImage, since destImage retains ownership of the object now.
  CGImageRelease( destImageRef );
	CGContextRelease( destContext );
  free( destBitmapData );
  return destImage;
}


@end