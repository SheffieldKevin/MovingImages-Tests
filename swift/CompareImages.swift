//
//  CompareImages.swift
//  MovingImagesFramework
//
//  Created by Kevin Meaney on 10/12/2014.
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

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
func doImagesHaveSameMeta(#image1:CGImage, #image2:CGImage) -> Bool {
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

#if os(iOS)
func compareImages(#image1:CGImage, #image2:CGImage) -> Int {
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
/**
 @brief Returns the maximum difference of pixel values in the image.
 @discussion Assumes doImagesHaveSameMeta has already returned true on
 the images passed into this function. OSX only as iOS doesn't have the
 CIAreaMaximum filter.
*/
func compareImages(#image1:CGImage, #image2:CGImage) -> Int {
    var diff = 0

    // First create the CIImage representations of the CGImage.
    let ciImage1 = CIImage(CGImage: image1)
    let ciImage2 = CIImage(CGImage: image2)
    
    // Create the difference blend mode filter and set its properties.
    let diffFilter = CIFilter(name: "CIDifferenceBlendMode")
    diffFilter.setDefaults()
    diffFilter.setValue(ciImage1, forKey: kCIInputImageKey)
    diffFilter.setValue(ciImage2, forKey: kCIInputBackgroundImageKey)
    
    // Create the area max filter and set its properties.
    let areaMaxFilter = CIFilter(name: "CIAreaMaximum")
    areaMaxFilter.setDefaults()
    areaMaxFilter.setValue(diffFilter.valueForKey(kCIOutputImageKey),
        forKey: kCIInputImageKey)
    let compareRect = CGRectMake(0.0, 0.0, CGFloat(CGImageGetWidth(image1)),
        CGFloat(CGImageGetHeight(image1)))
    let extents = CIVector(CGRect: compareRect)
    areaMaxFilter.setValue(extents, forKey: kCIInputExtentKey)

    // The filters have been setup, now set up the CGContext bitmap context the
    // output is drawn to. Setup the context with our supplied buffer.
    let alphaInfo = CGImageAlphaInfo.PremultipliedLast
    let bitmapInfo = CGBitmapInfo(rawValue: alphaInfo.rawValue)
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    var buf: [CUnsignedChar] = Array<CUnsignedChar>(count: 16, repeatedValue: 255)
    let context = CGBitmapContextCreate(&buf, 1, 1, 8, 16, colorSpace, bitmapInfo)
    
    // Now create the core image context CIContext from the bitmap context.
    let ciContextOpts = [
          kCIContextWorkingColorSpace : colorSpace,
        kCIContextUseSoftwareRenderer : false
    ]
    let ciContext = CIContext(CGContext: context, options: ciContextOpts)
    
    // Get the output CIImage and draw that to the Core Image context.
    let valueImage = areaMaxFilter.valueForKey(kCIOutputImageKey)! as CIImage
    ciContext.drawImage(valueImage, inRect: CGRectMake(0,0,1,1),
        fromRect: valueImage.extent())
    
    // This will have modified the contents of the buffer used for the CGContext.
    // Find the maximum value of the different color components. Remember that
    // the CGContext was created with a Premultiplied last meaning that alpha
    // is the fourth component with red, green and blue in the first three.
    let maxVal = max(buf[0], max(buf[1], buf[2]))
    diff = Int(maxVal)
    return diff
}
#endif

func createCGImageFromNamedFile(namedImage: NSString, #fileExtension: NSString)
    -> CGImage? {
    let testBundle = NSBundle(forClass: MovingImagesFrameworkiOSSwift.self)
    let jpegURL = testBundle.URLForResource(namedImage,
        withExtension:fileExtension)!
    let imageSource = CGImageSourceCreateWithURL(jpegURL, nil)
    let myImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
    return myImage
}

func createCGImageFromNamedJPEGImage(namedImage: NSString) -> CGImage! {
    return createCGImageFromNamedFile(namedImage, fileExtension:"jpg")
}

func createCGImageFromNamedPNGImage(namedImage: NSString) -> CGImage! {
    return createCGImageFromNamedFile(namedImage, fileExtension:"png")
}

func saveCGImage(theImage: CGImageRef, fileURL: NSURL, uti: String) -> Void {
    let exporter = CGImageDestinationCreateWithURL(
        fileURL, uti, 1, nil);
    CGImageDestinationAddImage(exporter, theImage, nil);
    CGImageDestinationFinalize(exporter);
}

#if arch(x86_64)

#if os(iOS)
let platformSuffix = "iOSSim"
#else
let platformSuffix = "OSX"
#endif

// This version is for OSX and the iOS simulator
func makeSaveFileURLPath(fileName: String) -> NSURL {
    // Don't use expand tilde version. iOS simulator homedir is not what we want.
    // let fp = "~/Desktop/".stringByExpandingTildeInPath + "/" + fileName
    return NSURL.fileURLWithPath("/Users/ktam/Desktop/" + fileName)!
}

func saveCGImageToAPNGFile(theImage: CGImageRef, #fileName: NSString) -> Void {
    saveCGImage(theImage, makeSaveFileURLPath(fileName), kUTTypePNG)
}

func saveCGImageToAJPEGFile(theImage: CGImageRef, #fileName: NSString) -> Void {
    saveCGImage(theImage, makeSaveFileURLPath(fileName), kUTTypePNG)
}

#else
let platformSuffix = "iOS"

// This version is for running on a iOS device.
func makeSaveFileURLPath(fileName: String) -> NSURL {
    let fm = NSFileManager.defaultManager()
    var error:NSError?
    
    let folderURL = fm.URLForDirectory(NSSearchPathDirectory.CachesDirectory,
                 inDomain: NSSearchPathDomainMask.UserDomainMask,
        appropriateForURL: .None,
                   create: false,
                    error: &error)
    
    return NSURL(string: fileName, relativeToURL:folderURL)!.absoluteURL!
}

func moveImageFileToPhotoLibrary(fileURL: NSURL) -> Void {
    let wait = dispatch_semaphore_create(0)

    PHPhotoLibrary.sharedPhotoLibrary().performChanges({
        let request =
        PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL(fileURL)
    },
    completionHandler: { success, error in
        dispatch_semaphore_signal(wait)
        Void.self
    })

    dispatch_semaphore_wait(wait, DISPATCH_TIME_FOREVER)
    let fm = NSFileManager.defaultManager()
    var error:NSError?
    fm.removeItemAtURL(fileURL, error:&error)
}

// This version is for saving a file when running on an iOS device.
func saveCGImageToAPNGFile(theImage: CGImageRef, #fileName: NSString) -> Void {
    let fileURL = makeSaveFileURLPath(fileName)
    saveCGImage(theImage, fileURL, kUTTypePNG)

    // Now move the image to the photos library.
    moveImageFileToPhotoLibrary(fileURL)
}

// This version is for saving a file when running on an iOS device.
func saveCGImageToAJPEGFile(theImage: CGImageRef, #fileName: NSString) -> Void {
    let fileURL = makeSaveFileURLPath(fileName)
    saveCGImage(theImage, fileURL, kUTTypeJPEG)

    // Now move the image to the photos library.
    moveImageFileToPhotoLibrary(fileURL)
}

#endif

func makeFileName(#baseName: String) -> String {
    return baseName + platformSuffix
}

func makeFileNameWithExtension(baseName: String, #extn: String) -> String {
    return makeFileName(baseName: baseName) + extn;
}

func saveCGImageToAPNGFile(theImage: CGImageRef, #baseName: String) -> Void {
    let fileName = makeFileNameWithExtension(baseName, extn: ".png")
    saveCGImageToAPNGFile(theImage, fileName: fileName)
}

func saveCGImageToAJPEGFile(theImage: CGImageRef, #baseName: String) -> Void {
    let fileName = makeFileNameWithExtension(baseName, extn: ".jpg")
    saveCGImageToAJPEGFile(theImage, fileName: fileName)
}
