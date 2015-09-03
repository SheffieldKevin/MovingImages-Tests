//  TestUtilities.swift
//  MovingImagesFramework
//
//  Created by Kevin Meaney on 02/09/2015.
//  Copyright © 2015 Zukini Ltd. All rights reserved.

import Foundation
import QuartzCore
import ImageIO
import AVFoundation

#if os(iOS)
    import MobileCoreServices
    import Photos
#endif

func cmTimeAsDictionary(time: CMTime) -> [NSString : NSObject] {
    return [
        NSString(string: "value") : NSNumber(longLong: time.value),
        NSString(string: "timescale") : NSNumber(int: time.timescale),
        NSString(string: "epoch") : NSNumber(longLong: time.epoch),
        NSString(string: "flags") : NSNumber(unsignedInt: time.flags.rawValue)
    ]
}

func makeSizeDict(width width: Int, height: Int) -> [NSString : NSObject] {
    return [
        MIJSONKeyWidth : NSNumber(integer: width),
        MIJSONKeyHeight : NSNumber(integer: height)
    ]
}

func makeURLFromNamedFile(namedFile: String, fileExtension: String) -> NSURL {
    let testBundle = NSBundle(forClass: MovingImagesFrameworkiOSSwift.self)
    let url = testBundle.URLForResource(namedFile, withExtension:fileExtension)!
    return url
}

func createCGImageFromNamedFile(namedImage: String, fileExtension: String)
    -> CGImage? {
        let theURL = makeURLFromNamedFile(namedImage, fileExtension: fileExtension)
        guard let imageSource = CGImageSourceCreateWithURL(theURL, nil) else {
            return .None
        }
        let myImage = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
        return myImage
}

func createCGImageFromNamedJPEGImage(namedImage: String) -> CGImage! {
    return createCGImageFromNamedFile(namedImage, fileExtension:"jpg")
}

func createCGImageFromNamedPNGImage(namedImage: String) -> CGImage! {
    return createCGImageFromNamedFile(namedImage, fileExtension:"png")
}

func saveCGImage(theImage: CGImageRef, fileURL: NSURL, uti: String) -> Void {
    guard let exporter = CGImageDestinationCreateWithURL(
        fileURL, uti, 1, nil) else {
            return
    }
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
        #if os(iOS)
            return NSURL.fileURLWithPath("/Users/ktam/Desktop/Current/iOSSim/" + fileName)!
            #else
            let fp = NSString(string: "~/Desktop/Current/OSX/").stringByExpandingTildeInPath + "/" + fileName
            return NSURL.fileURLWithPath(fp)
        #endif
    }
    
    func saveCGImageToAPNGFile(theImage: CGImageRef, fileName: String) -> Void {
        saveCGImage(theImage, fileURL: makeSaveFileURLPath(fileName), uti: kUTTypePNG as String)
    }
    
    func saveCGImageToAJPEGFile(theImage: CGImageRef, fileName: String) -> Void {
        saveCGImage(theImage, fileURL: makeSaveFileURLPath(fileName), uti: kUTTypePNG as String)
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
    func saveCGImageToAPNGFile(theImage: CGImageRef, fileName: String) -> Void {
        let fileURL = makeSaveFileURLPath(fileName)
        saveCGImage(theImage, fileURL, String(kUTTypePNG))
        
        // Now move the image to the photos library.
        moveImageFileToPhotoLibrary(fileURL)
    }
    
    // This version is for saving a file when running on an iOS device.
    func saveCGImageToAJPEGFile(theImage: CGImageRef, fileName: String) -> Void {
        let fileURL = makeSaveFileURLPath(fileName)
        saveCGImage(theImage, fileURL, String(kUTTypeJPEG))
        
        // Now move the image to the photos library.
        moveImageFileToPhotoLibrary(fileURL)
    }
    
#endif

func makeFileName(baseName baseName: String) -> String {
    return baseName + platformSuffix
}

func makeFileNameWithExtension(baseName: String, extn: String) -> String {
    return makeFileName(baseName: baseName) + extn;
}

func saveCGImageToAPNGFile(theImage: CGImageRef, baseName: String) -> Void {
    let fileName = makeFileNameWithExtension(baseName, extn: ".png")
    saveCGImageToAPNGFile(theImage, fileName: fileName)
}

func saveCGImageToAJPEGFile(theImage: CGImageRef, baseName: String) -> Void {
    let fileName = makeFileNameWithExtension(baseName, extn: ".jpg")
    saveCGImageToAJPEGFile(theImage, fileName: fileName)
}
