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

#import "imageenhancer.h"

#define MAX_COLORS 256


typedef struct tagTGreyColorLookup
{
  float colorRed[MAX_COLORS];
  float colorGrn[MAX_COLORS];
  float colorBlu[MAX_COLORS];
}TGreyColorLookup;



typedef struct tagTHSLcolorref{
  CGFloat h;
  CGFloat s;
  CGFloat l;
}THSLcolorref;

THSLcolorref rgb2hsl(const UIColor *color_);

THSLcolorref rgb2hsl(const UIColor *color_)
{
  const CGFloat *components = CGColorGetComponents([color_ CGColor]);
  
  const CGFloat r_percent = components[0];
  const CGFloat g_percent = components[1];
  const CGFloat b_percent = components[2];
  
  double max_color = 0;
  if((r_percent >= g_percent) && (r_percent >= b_percent))
    max_color = r_percent;
  if((g_percent >= r_percent) && (g_percent >= b_percent))
    max_color = g_percent;
  if((b_percent >= r_percent) && (b_percent >= g_percent))
    max_color = b_percent;
  
  double min_color = 0;
  if((r_percent <= g_percent) && (r_percent <= b_percent))
    min_color = r_percent;
  if((g_percent <= r_percent) && (g_percent <= b_percent))
    min_color = g_percent;
  if((b_percent <= r_percent) && (b_percent <= g_percent))
    min_color = b_percent;
  
  double L = 0;
  double S = 0;
  double H = 0;
  
  L = (max_color + min_color)/2;
  
  if(max_color == min_color)
  {
    S = 0;
    H = 0;
  }
  else
  {
    if(L < .50)
    {
      S = (max_color - min_color)/(max_color + min_color);
    }
    else
    {
      S = (max_color - min_color)/(2 - max_color - min_color);
    }
    if(max_color == r_percent)
    {
      H = (g_percent - b_percent)/(max_color - min_color);
    }
    if(max_color == g_percent)
    {
      H = 2 + (b_percent - r_percent)/(max_color - min_color);
    }
    if(max_color == b_percent)
    {
      H = 4 + (r_percent - g_percent)/(max_color - min_color);
    }
  }
  H = H * 60.f;
  if ( H < 0 )
    H += 360.f;
  
  THSLcolorref clrHSL = { H / 360.f, S, L};
  return clrHSL;
}



const TGreyColorLookup *greyColorLookup(void);

@implementation UIImage (Colorize)


- (UIImage*)colorize:(UIColor *)color_
{
  CGImageRef imgRef = [self CGImage];
  
  size_t width  = CGImageGetWidth (imgRef);
  size_t height = CGImageGetHeight(imgRef);
  
  if ( !(width && height) )
    return nil;
  
  // prepare colorspace
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  size_t bitsPerComponent = 8;
  size_t bytesPerPixel    = 4;
  size_t bytesPerRow      = bytesPerPixel * width;
  size_t totalBytes       = bytesPerRow   * height;
  
  //Allocate Image space
  NSMutableData  *pRawData = [[NSMutableData alloc] initWithLength:totalBytes];
//  uint8_t *pRawData = malloc(totalBytes);
//  memset( pRawData, 0, totalBytes );  // transparent layer alpha = 0
  
  
  //Create Bitmap of same size
  CGContextRef context = CGBitmapContextCreate( [pRawData mutableBytes],
                                    width,
                                    height,
                                    bitsPerComponent,
                                    bytesPerRow,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
  
  //Draw our image to the context
  CGContextDrawImage( context, CGRectMake( 0, 0, width, height), imgRef );
  
  const CGFloat* components = CGColorGetComponents([color_ CGColor]);  

//  const TGreyColorLookup *greyLookup = greyColorLookup();
  size_t totalPixels = totalBytes / 4;
  
  uint8_t *ptr = [pRawData mutableBytes];

  do
  {
    const float luma = 255.f * ( components[0] * 0.299f +  // average luminance added by the color
                                 components[1] * 0.587f +
                                 components[2] * 0.114f);
    
    // 1. desaturate input image and normalize
    // 2. colorize
    *ptr++ = luma * components[0]; // red;
    *ptr++ = luma * components[1]; // green;
    *ptr++ = luma * components[2]; // blue;
    ptr++;          // skip Alpha
  }while(--totalPixels);

  //Create Image
  CGImageRef newImg = CGBitmapContextCreateImage( context );
  
  //Create UIImage struct around image
  
  UIImage* image = [[UIImage alloc] initWithCGImage:newImg];
  
  //Release our hold on the image
  CGImageRelease(newImg);

  //Release Created Data Structs
  CGColorSpaceRelease( colorSpace );
  CGContextRelease( context );
  [pRawData release];

  return [image autorelease];  
}



/*
 function colorize($img_in, $img_out, $color)
 {
      $src = imagecreatefromstring(file_get_contents($img_in));
      imagealphablending($src, false);
      imagesavealpha($src, true);
 
      $w = imagesx($src);
      $h = imagesy($src);
 
      imagefilter($src,IMG_FILTER_GRAYSCALE);
      $luminance=($color[0]+$color[1]+$color[2])/3; // average luminance added by the color
      $brightnessCorrection = $luminance/3; // quantity of brightness to correct for each channel
      if( $luminance < 127 ){
          $brightnessCorrection -= 127/3; // color is dark so we have to negate the brightness correction
      }
      if(! imageistruecolor($src) ){
          $nbColors = imagecolorstotal($src);
          for($i=0; $i<$nbColors; $i++){
              $c = array_values(imgagecolorsforindex($src,$i));
              for($y=0;$y<3;$y++){
                  $c[$y] = max(0, min(255, $c[$y] + ($color[$y]-$luminance) + $brightnessCorrection) ); // parentheses just for better comprehension
              }
              imagecolorset($omgRes,$i,$c[0],$c[1],$c[2]);
          }
      }else{ // much easier with truecolor
          imagefilter($src, IMG_FILTER_COLORIZE, $color[0]-$luminance, $color[1]-$luminance, $color[2]-$luminance);
          imagefilter($src, IMG_FILTER_BRIGHTNESS, $brightnessCorrection);
      }
 
      $dst = imagecreatetruecolor($w, $h);
      imagealphablending($dst, false);
      imagesavealpha($dst, true);
      imagecopy($dst, $src, 0, 0, 0, 0, $w, $h);
 
      imagepng($dst, $img_out);
      imagedestroy($src);
      imagedestroy($dst);
   } 
 */

- (UIImage*)alternativeColorize:(UIColor *)color_
{
  CGImageRef imgRef = [self CGImage];
  
  size_t width  = CGImageGetWidth (imgRef);
  size_t height = CGImageGetHeight(imgRef);
  
  if ( !(width && height) )
    return nil;
  
  // prepare colorspace
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  size_t bitsPerComponent = 8;
  size_t bytesPerPixel    = 4;
  size_t bytesPerRow      = bytesPerPixel * width;
  size_t totalBytes       = bytesPerRow   * height;
  
  //Allocate Image space
  NSMutableData  *pRawData = [[NSMutableData alloc] initWithLength:totalBytes];
//  uint8_t *pRawData = malloc(totalBytes);
//  memset( pRawData, 0, totalBytes );  // transparent layer alpha = 0
  
  //Create Bitmap of same size
  CGContextRef context = CGBitmapContextCreate( [pRawData mutableBytes],
                                               width,
                                               height,
                                               bitsPerComponent,
                                               bytesPerRow,
                                               colorSpace,
                                               kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big );
  
  //Draw our image to the context
  CGContextDrawImage( context, CGRectMake( 0, 0, width, height), imgRef );
  
  const CGFloat *components = CGColorGetComponents([color_ CGColor]);

  const CGFloat luminance      =  (components[0] + components[1] + components[2]) / 3.f; // average luminance added by the color
  CGFloat brightnessCorrection = luminance * 255.f / 3.f; // quantity of brightness to correct for each channel
  
  if ( luminance < 0.5f )
    brightnessCorrection -= 127.f / 3.f; // color is dark so we have to negate the brightness correction

  int brightnessOffset = brightnessCorrection;

  
  int correctedColor[] = { 255.f * (components[0] - luminance),
                           255.f * (components[1] - luminance),
                           255.f * (components[2] - luminance) };

  size_t totalPixels = totalBytes / 4;
  
  uint8_t *ptr = [pRawData mutableBytes];

  do
  {
    union {
      uint32_t   val;
      struct{
        uint8_t  r;
        uint8_t  g;
        uint8_t  b;
        uint8_t  a;
      }rgba;
    }rgbaRef = {*((uint32_t *)ptr)};
    
    // 1. desaturate input image and normalize
    const int luma = ( (float)rgbaRef.rgba.r * 0.299f +  // average luminance added by the color
                       (float)rgbaRef.rgba.g * 0.587f +
                       (float)rgbaRef.rgba.b * 0.114f);
    // 2. colorize
    for (int i = 0; i < 3; ++i )
    {
      int clr = luma + correctedColor[i] + brightnessOffset;
      if ( clr < 0 )
        clr = 0;
      if ( clr > 255 )
        clr = 255;
      *ptr++ = clr;
    }
    ptr++;          // skip Alpha
  }while(--totalPixels);

  //Create Image
  CGImageRef newImg = CGBitmapContextCreateImage( context );
  
  //Create UIImage struct around image
  UIImage* image = [[UIImage alloc] initWithCGImage:newImg];
  
  //Release our hold on the image
  CGImageRelease(newImg);
  
  //Release Created Data Structs
  CGColorSpaceRelease( colorSpace );
  CGContextRelease( context );
  [pRawData release];
  
  return [image autorelease];  
}



typedef struct tagTGreyColorLookupInt
{
  unsigned char colorRed[MAX_COLORS * sizeof(float)];
  unsigned char colorGrn[MAX_COLORS * sizeof(float)];
  unsigned char colorBlu[MAX_COLORS * sizeof(float)];
}TGreyColorLookupInt;



- (UIImage*)scaleToSize:(CGSize)size
               withMode:(UIViewContentMode)mode_
{
  // before we place image on button, we must properly
  // resize image to current button frame
  // calc aspect ratio of current view and image    
  CGFloat farCurrent = size.width ?
                          size.height / size.width :
                          0.f;
  CGFloat farImage   = self.size.height  / self.size.width;

  if ( mode_ == UIViewContentModeScaleAspectFit )
  {
    size = farCurrent > farImage ? 
                          CGSizeMake( size.width, self.size.height * size.width / self.size.width ) :
                          CGSizeMake( self.size.width * size.height / self.size.height, size.height );
  }else if ( mode_ == UIViewContentModeScaleAspectFill )
  {
    size = farCurrent < farImage ? 
                          CGSizeMake( size.width, self.size.height * size.width / self.size.width ) :
                          CGSizeMake( self.size.width * size.height / self.size.height, size.height );
  }else if ( mode_ != UIViewContentModeScaleToFill )
    return self;
  
  UIGraphicsBeginImageContext(size);
  
  CGContextRef context = UIGraphicsGetCurrentContext();
  if ( !context )
  {
    UIGraphicsEndImageContext();
    return nil;
  }
  CGContextTranslateCTM(context, 0.0, size.height);
  CGContextScaleCTM(context, 1.0, -1.0);
  CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, size.width, size.height), self.CGImage);
  UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();
  
  UIGraphicsEndImageContext();
  
  return scaledImage;
}


- (UIImage*)scaleToSize:(CGSize)size
           proportional:(BOOL)bProportion
{
  if ( bProportion )
  {
    // before we place image on button, we must properly
    // resize image to current button frame
    // calc aspect ratio of current view and image    
    CGFloat farCurrent = size.width ? size.height / size.width : 0.f;
    CGFloat farImage   = self.size.height  / self.size.width;
    size = farCurrent > farImage ? 
              CGSizeMake( size.width, self.size.height * size.width / self.size.width ) :
              CGSizeMake( self.size.width * size.height / self.size.height, size.height );
  }
  UIGraphicsBeginImageContext(size);
  
  CGContextRef context = UIGraphicsGetCurrentContext();
  if ( !context )
  {
    UIGraphicsEndImageContext();
    return nil;
  }
  CGContextTranslateCTM(context, 0.0, size.height);
  CGContextScaleCTM(context, 1.0, -1.0);
  CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, size.width, size.height), self.CGImage);
  UIImage* scaledImage = UIGraphicsGetImageFromCurrentImageContext();

  UIGraphicsEndImageContext();
  
  return scaledImage;
}


// 
// lookup table for image desaturation
// 
static const TGreyColorLookupInt g_greyColorLookup =
{
  
  // red color matrix 
  {
    0x00, 0x00, 0x00, 0x00, 0x87, 0x16, 0x99, 0x3E, 0x87, 0x16, 0x19, 0x3F, 0xCB, 0xA1, 0x65, 0x3F, 
    0x87, 0x16, 0x99, 0x3F, 0x29, 0x5C, 0xBF, 0x3F, 0xCB, 0xA1, 0xE5, 0x3F, 0xB6, 0xF3, 0x05, 0x40, 
    0x87, 0x16, 0x19, 0x40, 0x58, 0x39, 0x2C, 0x40, 0x29, 0x5C, 0x3F, 0x40, 0xFA, 0x7E, 0x52, 0x40, 
    0xCB, 0xA1, 0x65, 0x40, 0x9C, 0xC4, 0x78, 0x40, 0xB6, 0xF3, 0x85, 0x40, 0x1F, 0x85, 0x8F, 0x40, 
    0x87, 0x16, 0x99, 0x40, 0xF0, 0xA7, 0xA2, 0x40, 0x58, 0x39, 0xAC, 0x40, 0xC1, 0xCA, 0xB5, 0x40, 
    0x29, 0x5C, 0xBF, 0x40, 0x91, 0xED, 0xC8, 0x40, 0xFA, 0x7E, 0xD2, 0x40, 0x62, 0x10, 0xDC, 0x40, 
    0xCB, 0xA1, 0xE5, 0x40, 0x33, 0x33, 0xEF, 0x40, 0x9C, 0xC4, 0xF8, 0x40, 0x02, 0x2B, 0x01, 0x41, 
    0xB6, 0xF3, 0x05, 0x41, 0x6A, 0xBC, 0x0A, 0x41, 0x1F, 0x85, 0x0F, 0x41, 0xD3, 0x4D, 0x14, 0x41, 
    0x87, 0x16, 0x19, 0x41, 0x3B, 0xDF, 0x1D, 0x41, 0xF0, 0xA7, 0x22, 0x41, 0xA4, 0x70, 0x27, 0x41, 
    0x58, 0x39, 0x2C, 0x41, 0x0C, 0x02, 0x31, 0x41, 0xC1, 0xCA, 0x35, 0x41, 0x75, 0x93, 0x3A, 0x41, 
    0x29, 0x5C, 0x3F, 0x41, 0xDD, 0x24, 0x44, 0x41, 0x91, 0xED, 0x48, 0x41, 0x46, 0xB6, 0x4D, 0x41, 
    0xFA, 0x7E, 0x52, 0x41, 0xAE, 0x47, 0x57, 0x41, 0x62, 0x10, 0x5C, 0x41, 0x17, 0xD9, 0x60, 0x41, 
    0xCB, 0xA1, 0x65, 0x41, 0x7F, 0x6A, 0x6A, 0x41, 0x33, 0x33, 0x6F, 0x41, 0xE7, 0xFB, 0x73, 0x41, 
    0x9C, 0xC4, 0x78, 0x41, 0x50, 0x8D, 0x7D, 0x41, 0x02, 0x2B, 0x81, 0x41, 0x5C, 0x8F, 0x83, 0x41, 
    0xB6, 0xF3, 0x85, 0x41, 0x10, 0x58, 0x88, 0x41, 0x6A, 0xBC, 0x8A, 0x41, 0xC5, 0x20, 0x8D, 0x41, 
    0x1F, 0x85, 0x8F, 0x41, 0x79, 0xE9, 0x91, 0x41, 0xD3, 0x4D, 0x94, 0x41, 0x2D, 0xB2, 0x96, 0x41, 
    0x87, 0x16, 0x99, 0x41, 0xE1, 0x7A, 0x9B, 0x41, 0x3B, 0xDF, 0x9D, 0x41, 0x96, 0x43, 0xA0, 0x41, 
    0xF0, 0xA7, 0xA2, 0x41, 0x4A, 0x0C, 0xA5, 0x41, 0xA4, 0x70, 0xA7, 0x41, 0xFE, 0xD4, 0xA9, 0x41, 
    0x58, 0x39, 0xAC, 0x41, 0xB2, 0x9D, 0xAE, 0x41, 0x0C, 0x02, 0xB1, 0x41, 0x66, 0x66, 0xB3, 0x41, 
    0xC1, 0xCA, 0xB5, 0x41, 0x1B, 0x2F, 0xB8, 0x41, 0x75, 0x93, 0xBA, 0x41, 0xCF, 0xF7, 0xBC, 0x41, 
    0x29, 0x5C, 0xBF, 0x41, 0x83, 0xC0, 0xC1, 0x41, 0xDD, 0x24, 0xC4, 0x41, 0x37, 0x89, 0xC6, 0x41, 
    0x91, 0xED, 0xC8, 0x41, 0xEC, 0x51, 0xCB, 0x41, 0x46, 0xB6, 0xCD, 0x41, 0xA0, 0x1A, 0xD0, 0x41, 
    0xFA, 0x7E, 0xD2, 0x41, 0x54, 0xE3, 0xD4, 0x41, 0xAE, 0x47, 0xD7, 0x41, 0x08, 0xAC, 0xD9, 0x41, 
    0x62, 0x10, 0xDC, 0x41, 0xBC, 0x74, 0xDE, 0x41, 0x17, 0xD9, 0xE0, 0x41, 0x71, 0x3D, 0xE3, 0x41, 
    0xCB, 0xA1, 0xE5, 0x41, 0x25, 0x06, 0xE8, 0x41, 0x7F, 0x6A, 0xEA, 0x41, 0xD9, 0xCE, 0xEC, 0x41, 
    0x33, 0x33, 0xEF, 0x41, 0x8D, 0x97, 0xF1, 0x41, 0xE7, 0xFB, 0xF3, 0x41, 0x42, 0x60, 0xF6, 0x41, 
    0x9C, 0xC4, 0xF8, 0x41, 0xF6, 0x28, 0xFB, 0x41, 0x50, 0x8D, 0xFD, 0x41, 0xAA, 0xF1, 0xFF, 0x41, 
    0x02, 0x2B, 0x01, 0x42, 0x2F, 0x5D, 0x02, 0x42, 0x5C, 0x8F, 0x03, 0x42, 0x89, 0xC1, 0x04, 0x42, 
    0xB6, 0xF3, 0x05, 0x42, 0xE3, 0x25, 0x07, 0x42, 0x10, 0x58, 0x08, 0x42, 0x3D, 0x8A, 0x09, 0x42, 
    0x6A, 0xBC, 0x0A, 0x42, 0x98, 0xEE, 0x0B, 0x42, 0xC5, 0x20, 0x0D, 0x42, 0xF2, 0x52, 0x0E, 0x42, 
    0x1F, 0x85, 0x0F, 0x42, 0x4C, 0xB7, 0x10, 0x42, 0x79, 0xE9, 0x11, 0x42, 0xA6, 0x1B, 0x13, 0x42, 
    0xD3, 0x4D, 0x14, 0x42, 0x00, 0x80, 0x15, 0x42, 0x2D, 0xB2, 0x16, 0x42, 0x5A, 0xE4, 0x17, 0x42, 
    0x87, 0x16, 0x19, 0x42, 0xB4, 0x48, 0x1A, 0x42, 0xE1, 0x7A, 0x1B, 0x42, 0x0E, 0xAD, 0x1C, 0x42, 
    0x3B, 0xDF, 0x1D, 0x42, 0x68, 0x11, 0x1F, 0x42, 0x96, 0x43, 0x20, 0x42, 0xC3, 0x75, 0x21, 0x42, 
    0xF0, 0xA7, 0x22, 0x42, 0x1D, 0xDA, 0x23, 0x42, 0x4A, 0x0C, 0x25, 0x42, 0x77, 0x3E, 0x26, 0x42, 
    0xA4, 0x70, 0x27, 0x42, 0xD1, 0xA2, 0x28, 0x42, 0xFE, 0xD4, 0x29, 0x42, 0x2B, 0x07, 0x2B, 0x42, 
    0x58, 0x39, 0x2C, 0x42, 0x85, 0x6B, 0x2D, 0x42, 0xB2, 0x9D, 0x2E, 0x42, 0xDF, 0xCF, 0x2F, 0x42, 
    0x0C, 0x02, 0x31, 0x42, 0x39, 0x34, 0x32, 0x42, 0x66, 0x66, 0x33, 0x42, 0x93, 0x98, 0x34, 0x42, 
    0xC1, 0xCA, 0x35, 0x42, 0xEE, 0xFC, 0x36, 0x42, 0x1B, 0x2F, 0x38, 0x42, 0x48, 0x61, 0x39, 0x42, 
    0x75, 0x93, 0x3A, 0x42, 0xA2, 0xC5, 0x3B, 0x42, 0xCF, 0xF7, 0x3C, 0x42, 0xFC, 0x29, 0x3E, 0x42, 
    0x29, 0x5C, 0x3F, 0x42, 0x56, 0x8E, 0x40, 0x42, 0x83, 0xC0, 0x41, 0x42, 0xB0, 0xF2, 0x42, 0x42, 
    0xDD, 0x24, 0x44, 0x42, 0x0A, 0x57, 0x45, 0x42, 0x37, 0x89, 0x46, 0x42, 0x64, 0xBB, 0x47, 0x42, 
    0x91, 0xED, 0x48, 0x42, 0xBE, 0x1F, 0x4A, 0x42, 0xEC, 0x51, 0x4B, 0x42, 0x19, 0x84, 0x4C, 0x42, 
    0x46, 0xB6, 0x4D, 0x42, 0x73, 0xE8, 0x4E, 0x42, 0xA0, 0x1A, 0x50, 0x42, 0xCD, 0x4C, 0x51, 0x42, 
    0xFA, 0x7E, 0x52, 0x42, 0x27, 0xB1, 0x53, 0x42, 0x54, 0xE3, 0x54, 0x42, 0x81, 0x15, 0x56, 0x42, 
    0xAE, 0x47, 0x57, 0x42, 0xDB, 0x79, 0x58, 0x42, 0x08, 0xAC, 0x59, 0x42, 0x35, 0xDE, 0x5A, 0x42, 
    0x62, 0x10, 0x5C, 0x42, 0x8F, 0x42, 0x5D, 0x42, 0xBC, 0x74, 0x5E, 0x42, 0xE9, 0xA6, 0x5F, 0x42, 
    0x17, 0xD9, 0x60, 0x42, 0x44, 0x0B, 0x62, 0x42, 0x71, 0x3D, 0x63, 0x42, 0x9E, 0x6F, 0x64, 0x42, 
    0xCB, 0xA1, 0x65, 0x42, 0xF8, 0xD3, 0x66, 0x42, 0x25, 0x06, 0x68, 0x42, 0x52, 0x38, 0x69, 0x42, 
    0x7F, 0x6A, 0x6A, 0x42, 0xAC, 0x9C, 0x6B, 0x42, 0xD9, 0xCE, 0x6C, 0x42, 0x06, 0x01, 0x6E, 0x42, 
    0x33, 0x33, 0x6F, 0x42, 0x60, 0x65, 0x70, 0x42, 0x8D, 0x97, 0x71, 0x42, 0xBA, 0xC9, 0x72, 0x42, 
    0xE7, 0xFB, 0x73, 0x42, 0x14, 0x2E, 0x75, 0x42, 0x42, 0x60, 0x76, 0x42, 0x6F, 0x92, 0x77, 0x42, 
    0x9C, 0xC4, 0x78, 0x42, 0xC9, 0xF6, 0x79, 0x42, 0xF6, 0x28, 0x7B, 0x42, 0x23, 0x5B, 0x7C, 0x42, 
    0x50, 0x8D, 0x7D, 0x42, 0x7D, 0xBF, 0x7E, 0x42, 0xAA, 0xF1, 0x7F, 0x42, 0xEC, 0x91, 0x80, 0x42, 
    0x02, 0x2B, 0x81, 0x42, 0x19, 0xC4, 0x81, 0x42, 0x2F, 0x5D, 0x82, 0x42, 0x46, 0xF6, 0x82, 0x42, 
    0x5C, 0x8F, 0x83, 0x42, 0x73, 0x28, 0x84, 0x42, 0x89, 0xC1, 0x84, 0x42, 0xA0, 0x5A, 0x85, 0x42, 
    0xB6, 0xF3, 0x85, 0x42, 0xCD, 0x8C, 0x86, 0x42, 0xE3, 0x25, 0x87, 0x42, 0xFA, 0xBE, 0x87, 0x42, 
    0x10, 0x58, 0x88, 0x42, 0x27, 0xF1, 0x88, 0x42, 0x3D, 0x8A, 0x89, 0x42, 0x54, 0x23, 0x8A, 0x42, 
    0x6A, 0xBC, 0x8A, 0x42, 0x81, 0x55, 0x8B, 0x42, 0x98, 0xEE, 0x8B, 0x42, 0xAE, 0x87, 0x8C, 0x42, 
    0xC5, 0x20, 0x8D, 0x42, 0xDB, 0xB9, 0x8D, 0x42, 0xF2, 0x52, 0x8E, 0x42, 0x08, 0xEC, 0x8E, 0x42, 
    0x1F, 0x85, 0x8F, 0x42, 0x35, 0x1E, 0x90, 0x42, 0x4C, 0xB7, 0x90, 0x42, 0x62, 0x50, 0x91, 0x42, 
    0x79, 0xE9, 0x91, 0x42, 0x8F, 0x82, 0x92, 0x42, 0xA6, 0x1B, 0x93, 0x42, 0xBC, 0xB4, 0x93, 0x42, 
    0xD3, 0x4D, 0x94, 0x42, 0xE9, 0xE6, 0x94, 0x42, 0x00, 0x80, 0x95, 0x42, 0x17, 0x19, 0x96, 0x42, 
    0x2D, 0xB2, 0x96, 0x42, 0x44, 0x4B, 0x97, 0x42, 0x5A, 0xE4, 0x97, 0x42, 0x71, 0x7D, 0x98, 0x42, 
  },
  // green color matrix 
  {
    0x00, 0x00, 0x00, 0x00, 0xA2, 0x45, 0x16, 0x3F, 0xA2, 0x45, 0x96, 0x3F, 0x73, 0x68, 0xE1, 0x3F, 
    0xA2, 0x45, 0x16, 0x40, 0x0A, 0xD7, 0x3B, 0x40, 0x73, 0x68, 0x61, 0x40, 0xEE, 0x7C, 0x83, 0x40, 
    0xA2, 0x45, 0x96, 0x40, 0x56, 0x0E, 0xA9, 0x40, 0x0A, 0xD7, 0xBB, 0x40, 0xBE, 0x9F, 0xCE, 0x40, 
    0x73, 0x68, 0xE1, 0x40, 0x27, 0x31, 0xF4, 0x40, 0xEE, 0x7C, 0x03, 0x41, 0x48, 0xE1, 0x0C, 0x41, 
    0xA2, 0x45, 0x16, 0x41, 0xFC, 0xA9, 0x1F, 0x41, 0x56, 0x0E, 0x29, 0x41, 0xB0, 0x72, 0x32, 0x41, 
    0x0A, 0xD7, 0x3B, 0x41, 0x64, 0x3B, 0x45, 0x41, 0xBE, 0x9F, 0x4E, 0x41, 0x19, 0x04, 0x58, 0x41, 
    0x73, 0x68, 0x61, 0x41, 0xCD, 0xCC, 0x6A, 0x41, 0x27, 0x31, 0x74, 0x41, 0x81, 0x95, 0x7D, 0x41, 
    0xEE, 0x7C, 0x83, 0x41, 0x1B, 0x2F, 0x88, 0x41, 0x48, 0xE1, 0x8C, 0x41, 0x75, 0x93, 0x91, 0x41, 
    0xA2, 0x45, 0x96, 0x41, 0xCF, 0xF7, 0x9A, 0x41, 0xFC, 0xA9, 0x9F, 0x41, 0x29, 0x5C, 0xA4, 0x41, 
    0x56, 0x0E, 0xA9, 0x41, 0x83, 0xC0, 0xAD, 0x41, 0xB0, 0x72, 0xB2, 0x41, 0xDD, 0x24, 0xB7, 0x41, 
    0x0A, 0xD7, 0xBB, 0x41, 0x37, 0x89, 0xC0, 0x41, 0x64, 0x3B, 0xC5, 0x41, 0x91, 0xED, 0xC9, 0x41, 
    0xBE, 0x9F, 0xCE, 0x41, 0xEC, 0x51, 0xD3, 0x41, 0x19, 0x04, 0xD8, 0x41, 0x46, 0xB6, 0xDC, 0x41, 
    0x73, 0x68, 0xE1, 0x41, 0xA0, 0x1A, 0xE6, 0x41, 0xCD, 0xCC, 0xEA, 0x41, 0xFA, 0x7E, 0xEF, 0x41, 
    0x27, 0x31, 0xF4, 0x41, 0x54, 0xE3, 0xF8, 0x41, 0x81, 0x95, 0xFD, 0x41, 0xD7, 0x23, 0x01, 0x42, 
    0xEE, 0x7C, 0x03, 0x42, 0x04, 0xD6, 0x05, 0x42, 0x1B, 0x2F, 0x08, 0x42, 0x31, 0x88, 0x0A, 0x42, 
    0x48, 0xE1, 0x0C, 0x42, 0x5E, 0x3A, 0x0F, 0x42, 0x75, 0x93, 0x11, 0x42, 0x8B, 0xEC, 0x13, 0x42, 
    0xA2, 0x45, 0x16, 0x42, 0xB8, 0x9E, 0x18, 0x42, 0xCF, 0xF7, 0x1A, 0x42, 0xE5, 0x50, 0x1D, 0x42, 
    0xFC, 0xA9, 0x1F, 0x42, 0x12, 0x03, 0x22, 0x42, 0x29, 0x5C, 0x24, 0x42, 0x3F, 0xB5, 0x26, 0x42, 
    0x56, 0x0E, 0x29, 0x42, 0x6D, 0x67, 0x2B, 0x42, 0x83, 0xC0, 0x2D, 0x42, 0x9A, 0x19, 0x30, 0x42, 
    0xB0, 0x72, 0x32, 0x42, 0xC7, 0xCB, 0x34, 0x42, 0xDD, 0x24, 0x37, 0x42, 0xF4, 0x7D, 0x39, 0x42, 
    0x0A, 0xD7, 0x3B, 0x42, 0x21, 0x30, 0x3E, 0x42, 0x37, 0x89, 0x40, 0x42, 0x4E, 0xE2, 0x42, 0x42, 
    0x64, 0x3B, 0x45, 0x42, 0x7B, 0x94, 0x47, 0x42, 0x91, 0xED, 0x49, 0x42, 0xA8, 0x46, 0x4C, 0x42, 
    0xBE, 0x9F, 0x4E, 0x42, 0xD5, 0xF8, 0x50, 0x42, 0xEC, 0x51, 0x53, 0x42, 0x02, 0xAB, 0x55, 0x42, 
    0x19, 0x04, 0x58, 0x42, 0x2F, 0x5D, 0x5A, 0x42, 0x46, 0xB6, 0x5C, 0x42, 0x5C, 0x0F, 0x5F, 0x42, 
    0x73, 0x68, 0x61, 0x42, 0x89, 0xC1, 0x63, 0x42, 0xA0, 0x1A, 0x66, 0x42, 0xB6, 0x73, 0x68, 0x42, 
    0xCD, 0xCC, 0x6A, 0x42, 0xE3, 0x25, 0x6D, 0x42, 0xFA, 0x7E, 0x6F, 0x42, 0x10, 0xD8, 0x71, 0x42, 
    0x27, 0x31, 0x74, 0x42, 0x3D, 0x8A, 0x76, 0x42, 0x54, 0xE3, 0x78, 0x42, 0x6A, 0x3C, 0x7B, 0x42, 
    0x81, 0x95, 0x7D, 0x42, 0x98, 0xEE, 0x7F, 0x42, 0xD7, 0x23, 0x81, 0x42, 0x62, 0x50, 0x82, 0x42, 
    0xEE, 0x7C, 0x83, 0x42, 0x79, 0xA9, 0x84, 0x42, 0x04, 0xD6, 0x85, 0x42, 0x8F, 0x02, 0x87, 0x42, 
    0x1B, 0x2F, 0x88, 0x42, 0xA6, 0x5B, 0x89, 0x42, 0x31, 0x88, 0x8A, 0x42, 0xBC, 0xB4, 0x8B, 0x42, 
    0x48, 0xE1, 0x8C, 0x42, 0xD3, 0x0D, 0x8E, 0x42, 0x5E, 0x3A, 0x8F, 0x42, 0xE9, 0x66, 0x90, 0x42, 
    0x75, 0x93, 0x91, 0x42, 0x00, 0xC0, 0x92, 0x42, 0x8B, 0xEC, 0x93, 0x42, 0x17, 0x19, 0x95, 0x42, 
    0xA2, 0x45, 0x96, 0x42, 0x2D, 0x72, 0x97, 0x42, 0xB8, 0x9E, 0x98, 0x42, 0x44, 0xCB, 0x99, 0x42, 
    0xCF, 0xF7, 0x9A, 0x42, 0x5A, 0x24, 0x9C, 0x42, 0xE5, 0x50, 0x9D, 0x42, 0x71, 0x7D, 0x9E, 0x42, 
    0xFC, 0xA9, 0x9F, 0x42, 0x87, 0xD6, 0xA0, 0x42, 0x12, 0x03, 0xA2, 0x42, 0x9E, 0x2F, 0xA3, 0x42, 
    0x29, 0x5C, 0xA4, 0x42, 0xB4, 0x88, 0xA5, 0x42, 0x3F, 0xB5, 0xA6, 0x42, 0xCB, 0xE1, 0xA7, 0x42, 
    0x56, 0x0E, 0xA9, 0x42, 0xE1, 0x3A, 0xAA, 0x42, 0x6D, 0x67, 0xAB, 0x42, 0xF8, 0x93, 0xAC, 0x42, 
    0x83, 0xC0, 0xAD, 0x42, 0x0E, 0xED, 0xAE, 0x42, 0x9A, 0x19, 0xB0, 0x42, 0x25, 0x46, 0xB1, 0x42, 
    0xB0, 0x72, 0xB2, 0x42, 0x3B, 0x9F, 0xB3, 0x42, 0xC7, 0xCB, 0xB4, 0x42, 0x52, 0xF8, 0xB5, 0x42, 
    0xDD, 0x24, 0xB7, 0x42, 0x68, 0x51, 0xB8, 0x42, 0xF4, 0x7D, 0xB9, 0x42, 0x7F, 0xAA, 0xBA, 0x42, 
    0x0A, 0xD7, 0xBB, 0x42, 0x96, 0x03, 0xBD, 0x42, 0x21, 0x30, 0xBE, 0x42, 0xAC, 0x5C, 0xBF, 0x42, 
    0x37, 0x89, 0xC0, 0x42, 0xC3, 0xB5, 0xC1, 0x42, 0x4E, 0xE2, 0xC2, 0x42, 0xD9, 0x0E, 0xC4, 0x42, 
    0x64, 0x3B, 0xC5, 0x42, 0xF0, 0x67, 0xC6, 0x42, 0x7B, 0x94, 0xC7, 0x42, 0x06, 0xC1, 0xC8, 0x42, 
    0x91, 0xED, 0xC9, 0x42, 0x1D, 0x1A, 0xCB, 0x42, 0xA8, 0x46, 0xCC, 0x42, 0x33, 0x73, 0xCD, 0x42, 
    0xBE, 0x9F, 0xCE, 0x42, 0x4A, 0xCC, 0xCF, 0x42, 0xD5, 0xF8, 0xD0, 0x42, 0x60, 0x25, 0xD2, 0x42, 
    0xEC, 0x51, 0xD3, 0x42, 0x77, 0x7E, 0xD4, 0x42, 0x02, 0xAB, 0xD5, 0x42, 0x8D, 0xD7, 0xD6, 0x42, 
    0x19, 0x04, 0xD8, 0x42, 0xA4, 0x30, 0xD9, 0x42, 0x2F, 0x5D, 0xDA, 0x42, 0xBA, 0x89, 0xDB, 0x42, 
    0x46, 0xB6, 0xDC, 0x42, 0xD1, 0xE2, 0xDD, 0x42, 0x5C, 0x0F, 0xDF, 0x42, 0xE7, 0x3B, 0xE0, 0x42, 
    0x73, 0x68, 0xE1, 0x42, 0xFE, 0x94, 0xE2, 0x42, 0x89, 0xC1, 0xE3, 0x42, 0x14, 0xEE, 0xE4, 0x42, 
    0xA0, 0x1A, 0xE6, 0x42, 0x2B, 0x47, 0xE7, 0x42, 0xB6, 0x73, 0xE8, 0x42, 0x42, 0xA0, 0xE9, 0x42, 
    0xCD, 0xCC, 0xEA, 0x42, 0x58, 0xF9, 0xEB, 0x42, 0xE3, 0x25, 0xED, 0x42, 0x6F, 0x52, 0xEE, 0x42, 
    0xFA, 0x7E, 0xEF, 0x42, 0x85, 0xAB, 0xF0, 0x42, 0x10, 0xD8, 0xF1, 0x42, 0x9C, 0x04, 0xF3, 0x42, 
    0x27, 0x31, 0xF4, 0x42, 0xB2, 0x5D, 0xF5, 0x42, 0x3D, 0x8A, 0xF6, 0x42, 0xC9, 0xB6, 0xF7, 0x42, 
    0x54, 0xE3, 0xF8, 0x42, 0xDF, 0x0F, 0xFA, 0x42, 0x6A, 0x3C, 0xFB, 0x42, 0xF6, 0x68, 0xFC, 0x42, 
    0x81, 0x95, 0xFD, 0x42, 0x0C, 0xC2, 0xFE, 0x42, 0x98, 0xEE, 0xFF, 0x42, 0x91, 0x8D, 0x00, 0x43, 
    0xD7, 0x23, 0x01, 0x43, 0x1D, 0xBA, 0x01, 0x43, 0x62, 0x50, 0x02, 0x43, 0xA8, 0xE6, 0x02, 0x43, 
    0xEE, 0x7C, 0x03, 0x43, 0x33, 0x13, 0x04, 0x43, 0x79, 0xA9, 0x04, 0x43, 0xBE, 0x3F, 0x05, 0x43, 
    0x04, 0xD6, 0x05, 0x43, 0x4A, 0x6C, 0x06, 0x43, 0x8F, 0x02, 0x07, 0x43, 0xD5, 0x98, 0x07, 0x43, 
    0x1B, 0x2F, 0x08, 0x43, 0x60, 0xC5, 0x08, 0x43, 0xA6, 0x5B, 0x09, 0x43, 0xEC, 0xF1, 0x09, 0x43, 
    0x31, 0x88, 0x0A, 0x43, 0x77, 0x1E, 0x0B, 0x43, 0xBC, 0xB4, 0x0B, 0x43, 0x02, 0x4B, 0x0C, 0x43, 
    0x48, 0xE1, 0x0C, 0x43, 0x8D, 0x77, 0x0D, 0x43, 0xD3, 0x0D, 0x0E, 0x43, 0x19, 0xA4, 0x0E, 0x43, 
    0x5E, 0x3A, 0x0F, 0x43, 0xA4, 0xD0, 0x0F, 0x43, 0xE9, 0x66, 0x10, 0x43, 0x2F, 0xFD, 0x10, 0x43, 
    0x75, 0x93, 0x11, 0x43, 0xBA, 0x29, 0x12, 0x43, 0x00, 0xC0, 0x12, 0x43, 0x46, 0x56, 0x13, 0x43, 
    0x8B, 0xEC, 0x13, 0x43, 0xD1, 0x82, 0x14, 0x43, 0x17, 0x19, 0x15, 0x43, 0x5C, 0xAF, 0x15, 0x43, 
  },
  // blue color matrix 
  {
    0x00, 0x00, 0x00, 0x00, 0xD5, 0x78, 0xE9, 0x3D, 0xD5, 0x78, 0x69, 0x3E, 0xA0, 0x1A, 0xAF, 0x3E, 
    0xD5, 0x78, 0xE9, 0x3E, 0x85, 0xEB, 0x11, 0x3F, 0xA0, 0x1A, 0x2F, 0x3F, 0xBA, 0x49, 0x4C, 0x3F, 
    0xD5, 0x78, 0x69, 0x3F, 0xF8, 0x53, 0x83, 0x3F, 0x85, 0xEB, 0x91, 0x3F, 0x12, 0x83, 0xA0, 0x3F, 
    0xA0, 0x1A, 0xAF, 0x3F, 0x2D, 0xB2, 0xBD, 0x3F, 0xBA, 0x49, 0xCC, 0x3F, 0x48, 0xE1, 0xDA, 0x3F, 
    0xD5, 0x78, 0xE9, 0x3F, 0x62, 0x10, 0xF8, 0x3F, 0xF8, 0x53, 0x03, 0x40, 0xBE, 0x9F, 0x0A, 0x40, 
    0x85, 0xEB, 0x11, 0x40, 0x4C, 0x37, 0x19, 0x40, 0x12, 0x83, 0x20, 0x40, 0xD9, 0xCE, 0x27, 0x40, 
    0xA0, 0x1A, 0x2F, 0x40, 0x66, 0x66, 0x36, 0x40, 0x2D, 0xB2, 0x3D, 0x40, 0xF4, 0xFD, 0x44, 0x40, 
    0xBA, 0x49, 0x4C, 0x40, 0x81, 0x95, 0x53, 0x40, 0x48, 0xE1, 0x5A, 0x40, 0x0E, 0x2D, 0x62, 0x40, 
    0xD5, 0x78, 0x69, 0x40, 0x9C, 0xC4, 0x70, 0x40, 0x62, 0x10, 0x78, 0x40, 0x29, 0x5C, 0x7F, 0x40, 
    0xF8, 0x53, 0x83, 0x40, 0xDB, 0xF9, 0x86, 0x40, 0xBE, 0x9F, 0x8A, 0x40, 0xA2, 0x45, 0x8E, 0x40, 
    0x85, 0xEB, 0x91, 0x40, 0x68, 0x91, 0x95, 0x40, 0x4C, 0x37, 0x99, 0x40, 0x2F, 0xDD, 0x9C, 0x40, 
    0x12, 0x83, 0xA0, 0x40, 0xF6, 0x28, 0xA4, 0x40, 0xD9, 0xCE, 0xA7, 0x40, 0xBC, 0x74, 0xAB, 0x40, 
    0xA0, 0x1A, 0xAF, 0x40, 0x83, 0xC0, 0xB2, 0x40, 0x66, 0x66, 0xB6, 0x40, 0x4A, 0x0C, 0xBA, 0x40, 
    0x2D, 0xB2, 0xBD, 0x40, 0x10, 0x58, 0xC1, 0x40, 0xF4, 0xFD, 0xC4, 0x40, 0xD7, 0xA3, 0xC8, 0x40, 
    0xBA, 0x49, 0xCC, 0x40, 0x9E, 0xEF, 0xCF, 0x40, 0x81, 0x95, 0xD3, 0x40, 0x64, 0x3B, 0xD7, 0x40, 
    0x48, 0xE1, 0xDA, 0x40, 0x2B, 0x87, 0xDE, 0x40, 0x0E, 0x2D, 0xE2, 0x40, 0xF2, 0xD2, 0xE5, 0x40, 
    0xD5, 0x78, 0xE9, 0x40, 0xB8, 0x1E, 0xED, 0x40, 0x9C, 0xC4, 0xF0, 0x40, 0x7F, 0x6A, 0xF4, 0x40, 
    0x62, 0x10, 0xF8, 0x40, 0x46, 0xB6, 0xFB, 0x40, 0x29, 0x5C, 0xFF, 0x40, 0x06, 0x81, 0x01, 0x41, 
    0xF8, 0x53, 0x03, 0x41, 0xE9, 0x26, 0x05, 0x41, 0xDB, 0xF9, 0x06, 0x41, 0xCD, 0xCC, 0x08, 0x41, 
    0xBE, 0x9F, 0x0A, 0x41, 0xB0, 0x72, 0x0C, 0x41, 0xA2, 0x45, 0x0E, 0x41, 0x93, 0x18, 0x10, 0x41, 
    0x85, 0xEB, 0x11, 0x41, 0x77, 0xBE, 0x13, 0x41, 0x68, 0x91, 0x15, 0x41, 0x5A, 0x64, 0x17, 0x41, 
    0x4C, 0x37, 0x19, 0x41, 0x3D, 0x0A, 0x1B, 0x41, 0x2F, 0xDD, 0x1C, 0x41, 0x21, 0xB0, 0x1E, 0x41, 
    0x12, 0x83, 0x20, 0x41, 0x04, 0x56, 0x22, 0x41, 0xF6, 0x28, 0x24, 0x41, 0xE7, 0xFB, 0x25, 0x41, 
    0xD9, 0xCE, 0x27, 0x41, 0xCB, 0xA1, 0x29, 0x41, 0xBC, 0x74, 0x2B, 0x41, 0xAE, 0x47, 0x2D, 0x41, 
    0xA0, 0x1A, 0x2F, 0x41, 0x91, 0xED, 0x30, 0x41, 0x83, 0xC0, 0x32, 0x41, 0x75, 0x93, 0x34, 0x41, 
    0x66, 0x66, 0x36, 0x41, 0x58, 0x39, 0x38, 0x41, 0x4A, 0x0C, 0x3A, 0x41, 0x3B, 0xDF, 0x3B, 0x41, 
    0x2D, 0xB2, 0x3D, 0x41, 0x1F, 0x85, 0x3F, 0x41, 0x10, 0x58, 0x41, 0x41, 0x02, 0x2B, 0x43, 0x41, 
    0xF4, 0xFD, 0x44, 0x41, 0xE5, 0xD0, 0x46, 0x41, 0xD7, 0xA3, 0x48, 0x41, 0xC9, 0x76, 0x4A, 0x41, 
    0xBA, 0x49, 0x4C, 0x41, 0xAC, 0x1C, 0x4E, 0x41, 0x9E, 0xEF, 0x4F, 0x41, 0x8F, 0xC2, 0x51, 0x41, 
    0x81, 0x95, 0x53, 0x41, 0x73, 0x68, 0x55, 0x41, 0x64, 0x3B, 0x57, 0x41, 0x56, 0x0E, 0x59, 0x41, 
    0x48, 0xE1, 0x5A, 0x41, 0x39, 0xB4, 0x5C, 0x41, 0x2B, 0x87, 0x5E, 0x41, 0x1D, 0x5A, 0x60, 0x41, 
    0x0E, 0x2D, 0x62, 0x41, 0x00, 0x00, 0x64, 0x41, 0xF2, 0xD2, 0x65, 0x41, 0xE3, 0xA5, 0x67, 0x41, 
    0xD5, 0x78, 0x69, 0x41, 0xC7, 0x4B, 0x6B, 0x41, 0xB8, 0x1E, 0x6D, 0x41, 0xAA, 0xF1, 0x6E, 0x41, 
    0x9C, 0xC4, 0x70, 0x41, 0x8D, 0x97, 0x72, 0x41, 0x7F, 0x6A, 0x74, 0x41, 0x71, 0x3D, 0x76, 0x41, 
    0x62, 0x10, 0x78, 0x41, 0x54, 0xE3, 0x79, 0x41, 0x46, 0xB6, 0x7B, 0x41, 0x37, 0x89, 0x7D, 0x41, 
    0x29, 0x5C, 0x7F, 0x41, 0x8D, 0x97, 0x80, 0x41, 0x06, 0x81, 0x81, 0x41, 0x7F, 0x6A, 0x82, 0x41, 
    0xF8, 0x53, 0x83, 0x41, 0x71, 0x3D, 0x84, 0x41, 0xE9, 0x26, 0x85, 0x41, 0x62, 0x10, 0x86, 0x41, 
    0xDB, 0xF9, 0x86, 0x41, 0x54, 0xE3, 0x87, 0x41, 0xCD, 0xCC, 0x88, 0x41, 0x46, 0xB6, 0x89, 0x41, 
    0xBE, 0x9F, 0x8A, 0x41, 0x37, 0x89, 0x8B, 0x41, 0xB0, 0x72, 0x8C, 0x41, 0x29, 0x5C, 0x8D, 0x41, 
    0xA2, 0x45, 0x8E, 0x41, 0x1B, 0x2F, 0x8F, 0x41, 0x93, 0x18, 0x90, 0x41, 0x0C, 0x02, 0x91, 0x41, 
    0x85, 0xEB, 0x91, 0x41, 0xFE, 0xD4, 0x92, 0x41, 0x77, 0xBE, 0x93, 0x41, 0xF0, 0xA7, 0x94, 0x41, 
    0x68, 0x91, 0x95, 0x41, 0xE1, 0x7A, 0x96, 0x41, 0x5A, 0x64, 0x97, 0x41, 0xD3, 0x4D, 0x98, 0x41, 
    0x4C, 0x37, 0x99, 0x41, 0xC5, 0x20, 0x9A, 0x41, 0x3D, 0x0A, 0x9B, 0x41, 0xB6, 0xF3, 0x9B, 0x41, 
    0x2F, 0xDD, 0x9C, 0x41, 0xA8, 0xC6, 0x9D, 0x41, 0x21, 0xB0, 0x9E, 0x41, 0x9A, 0x99, 0x9F, 0x41, 
    0x12, 0x83, 0xA0, 0x41, 0x8B, 0x6C, 0xA1, 0x41, 0x04, 0x56, 0xA2, 0x41, 0x7D, 0x3F, 0xA3, 0x41, 
    0xF6, 0x28, 0xA4, 0x41, 0x6F, 0x12, 0xA5, 0x41, 0xE7, 0xFB, 0xA5, 0x41, 0x60, 0xE5, 0xA6, 0x41, 
    0xD9, 0xCE, 0xA7, 0x41, 0x52, 0xB8, 0xA8, 0x41, 0xCB, 0xA1, 0xA9, 0x41, 0x44, 0x8B, 0xAA, 0x41, 
    0xBC, 0x74, 0xAB, 0x41, 0x35, 0x5E, 0xAC, 0x41, 0xAE, 0x47, 0xAD, 0x41, 0x27, 0x31, 0xAE, 0x41, 
    0xA0, 0x1A, 0xAF, 0x41, 0x19, 0x04, 0xB0, 0x41, 0x91, 0xED, 0xB0, 0x41, 0x0A, 0xD7, 0xB1, 0x41, 
    0x83, 0xC0, 0xB2, 0x41, 0xFC, 0xA9, 0xB3, 0x41, 0x75, 0x93, 0xB4, 0x41, 0xEE, 0x7C, 0xB5, 0x41, 
    0x66, 0x66, 0xB6, 0x41, 0xDF, 0x4F, 0xB7, 0x41, 0x58, 0x39, 0xB8, 0x41, 0xD1, 0x22, 0xB9, 0x41, 
    0x4A, 0x0C, 0xBA, 0x41, 0xC3, 0xF5, 0xBA, 0x41, 0x3B, 0xDF, 0xBB, 0x41, 0xB4, 0xC8, 0xBC, 0x41, 
    0x2D, 0xB2, 0xBD, 0x41, 0xA6, 0x9B, 0xBE, 0x41, 0x1F, 0x85, 0xBF, 0x41, 0x98, 0x6E, 0xC0, 0x41, 
    0x10, 0x58, 0xC1, 0x41, 0x89, 0x41, 0xC2, 0x41, 0x02, 0x2B, 0xC3, 0x41, 0x7B, 0x14, 0xC4, 0x41, 
    0xF4, 0xFD, 0xC4, 0x41, 0x6D, 0xE7, 0xC5, 0x41, 0xE5, 0xD0, 0xC6, 0x41, 0x5E, 0xBA, 0xC7, 0x41, 
    0xD7, 0xA3, 0xC8, 0x41, 0x50, 0x8D, 0xC9, 0x41, 0xC9, 0x76, 0xCA, 0x41, 0x42, 0x60, 0xCB, 0x41, 
    0xBA, 0x49, 0xCC, 0x41, 0x33, 0x33, 0xCD, 0x41, 0xAC, 0x1C, 0xCE, 0x41, 0x25, 0x06, 0xCF, 0x41, 
    0x9E, 0xEF, 0xCF, 0x41, 0x17, 0xD9, 0xD0, 0x41, 0x8F, 0xC2, 0xD1, 0x41, 0x08, 0xAC, 0xD2, 0x41, 
    0x81, 0x95, 0xD3, 0x41, 0xFA, 0x7E, 0xD4, 0x41, 0x73, 0x68, 0xD5, 0x41, 0xEC, 0x51, 0xD6, 0x41, 
    0x64, 0x3B, 0xD7, 0x41, 0xDD, 0x24, 0xD8, 0x41, 0x56, 0x0E, 0xD9, 0x41, 0xCF, 0xF7, 0xD9, 0x41, 
    0x48, 0xE1, 0xDA, 0x41, 0xC1, 0xCA, 0xDB, 0x41, 0x39, 0xB4, 0xDC, 0x41, 0xB2, 0x9D, 0xDD, 0x41, 
    0x2B, 0x87, 0xDE, 0x41, 0xA4, 0x70, 0xDF, 0x41, 0x1D, 0x5A, 0xE0, 0x41, 0x96, 0x43, 0xE1, 0x41, 
    0x0E, 0x2D, 0xE2, 0x41, 0x87, 0x16, 0xE3, 0x41, 0x00, 0x00, 0xE4, 0x41, 0x79, 0xE9, 0xE4, 0x41, 
    0xF2, 0xD2, 0xE5, 0x41, 0x6A, 0xBC, 0xE6, 0x41, 0xE3, 0xA5, 0xE7, 0x41, 0x5C, 0x8F, 0xE8, 0x41, 
  }
};

const TGreyColorLookup *greyColorLookup(void)
{
  return (TGreyColorLookup *)&g_greyColorLookup;
}

@end