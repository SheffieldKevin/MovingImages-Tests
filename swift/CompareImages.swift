//  CompareImages.swift
//  MovingImagesFramework
//
//  Copyright (c) 2015 Zukini Ltd.

import Foundation
import QuartzCore
import ImageIO

#if os(iOS)
import MobileCoreServices
import Photos
#endif

/**
 @brief Returns true if images have same meta. Width, Height, bit depth.
 @discussion Assumes images are non null.
*/
func doImagesHaveSameMeta(image1 image1:CGImage, image2:CGImage) -> Bool {
    if CGImageGetWidth(image1) != CGImageGetWidth(image2) {
        return false
    }
    
    if CGImageGetHeight(image1) != CGImageGetHeight(image2) {
        return false
    }
    
    if CGImageGetBitsPerComponent(image1) != CGImageGetBitsPerComponent(image2) {
        return false
    }
    
    if CGImageGetBytesPerRow(image1) != CGImageGetBytesPerRow(image2) {
        return false
    }
    
    if CGImageGetBitsPerPixel(image1) != CGImageGetBitsPerPixel(image2) {
        return false
    }
    
    return true
}

/*
#if os(iOS)
func compareImages(image1 image1:CGImage, image2:CGImage) -> Int {
    if doImagesHaveSameMeta(image1: image1, image2: image2)
    {
        return 0
    }
    else
    {
        return 255;
    }
}
#else
*/

/**
 @brief Returns the maximum difference of pixel values in the image.
 @discussion Assumes doImagesHaveSameMeta has already returned true on
 the images passed into this function. OSX only as iOS doesn't have the
 CIAreaMaximum filter.
*/
func compareImages(image1 image1:CGImage, image2:CGImage) -> Int {
    var diff = 0

    // First create the CIImage representations of the CGImage.
    let ciImage1 = CIImage(CGImage: image1)
    let ciImage2 = CIImage(CGImage: image2)
    
    // Create the difference blend mode filter and set its properties.
    let diffFilter = CIFilter(name: "CIDifferenceBlendMode")!
    diffFilter.setDefaults()
    diffFilter.setValue(ciImage1, forKey: kCIInputImageKey)
    diffFilter.setValue(ciImage2, forKey: kCIInputBackgroundImageKey)
    
/*
    // Create the area max filter and set its properties.
    let areaMaxFilter = CIFilter(name: "CIAreaMaximum")!
    areaMaxFilter.setDefaults()
    areaMaxFilter.setValue(diffFilter.valueForKey(kCIOutputImageKey),
        forKey: kCIInputImageKey)
    let compareRect = CGRectMake(0.0, 0.0, CGFloat(CGImageGetWidth(image1)),
        CGFloat(CGImageGetHeight(image1)))
    let extents = CIVector(CGRect: compareRect)
    areaMaxFilter.setValue(extents, forKey: kCIInputExtentKey)
*/
    // The filters have been setup, now set up the CGContext bitmap context the
    // output is drawn to. Setup the context with our supplied buffer.
    let alphaInfo = CGImageAlphaInfo.PremultipliedLast
    let bitmapInfo = CGBitmapInfo(rawValue: alphaInfo.rawValue)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var buf: [CUnsignedChar] = Array<CUnsignedChar>(count: 16, repeatedValue: 127)
    let context = CGBitmapContextCreate(&buf, 1, 1, 8, 16, colorSpace, bitmapInfo.rawValue)!

    // Now create the core image context CIContext from the bitmap context.
    let ciContextOpts : [String : AnyObject] = [
          kCIContextWorkingColorSpace : colorSpace as! AnyObject,
        kCIContextUseSoftwareRenderer : false as AnyObject
    ]
    let ciContext = CIContext(CGContext: context, options: ciContextOpts)
    
    // Get the output CIImage and draw that to the Core Image context.
    // let valueImage = areaMaxFilter.valueForKey(kCIOutputImageKey) as! CIImage
    let valueImage = diffFilter.valueForKey(kCIOutputImageKey) as! CIImage
    ciContext.drawImage(valueImage, inRect: CGRectMake(0,0,1,1),
        fromRect: valueImage.extent)
    
    // This will have modified the contents of the buffer used for the CGContext.
    // Find the maximum value of the different color components. Remember that
    // the CGContext was created with a Premultiplied last meaning that alpha
    // is the fourth component with red, green and blue in the first three.
    let maxVal = max(buf[0], max(buf[1], buf[2]))
    diff = Int(maxVal)
    return diff
}
// #endif

