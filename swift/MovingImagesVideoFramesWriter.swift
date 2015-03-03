//  MovingImagesMovieEditor.swift
//  MovingImagesFramework
//
//  Created by Kevin Meaney on 06/01/2015.
//  Copyright (c) 2015 Apple Inc. All rights reserved.

import Foundation
import ImageIO

#if os(iOS)
    import UIKit
    import Photos
    import MovingImagesiOS
#endif

import AVFoundation
import XCTest

let videoWriterName = "test001.movievideoframeswriter"
let videoWriterObject = [
    MIJSONKeyObjectType : MIMovieVideoFramesWriterKey,
    MIJSONKeyObjectName : videoWriterName
]

func GetMoviesURL() -> NSURL? {
    let fm = NSFileManager.defaultManager()
    var error:NSError?

    #if os(iOS)
        return fm.URLForDirectory(NSSearchPathDirectory.CachesDirectory,
                inDomain: NSSearchPathDomainMask.UserDomainMask,
       appropriateForURL: .None,
                  create: false,
                   error: &error)
    #else
    return fm.URLForDirectory(NSSearchPathDirectory.MoviesDirectory,
                inDomain: NSSearchPathDomainMask.UserDomainMask,
       appropriateForURL: .None,
                  create: false,
                   error: &error)
    #endif
}

func GetMoviePathInMoviesDir(fileName: String = "videowriter.mov") -> String {
    return GetMoviesURL()!.path! + "/" + fileName
}

#if os(iOS)
func saveMovieFileToSharedPhotoLibrary(#filePath: String) -> Void {
    let url = NSURL.fileURLWithPath(filePath)
    
    let wait = dispatch_semaphore_create(0)
    PHPhotoLibrary.sharedPhotoLibrary().performChanges({
        let request =
        PHAssetChangeRequest.creationRequestForAssetFromVideoAtFileURL(url)
    },
    completionHandler: { success, error in
        dispatch_semaphore_signal(wait)
        Void.self
    })
    dispatch_semaphore_wait(wait, DISPATCH_TIME_FOREVER)
}
#endif

class MovingImagesVideoFramesWriter: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    let createVideoWriterCommand = [
        MIJSONKeyCommand : MIJSONValueCreateCommand,
        MIJSONKeyObjectType : MIMovieVideoFramesWriterKey,
        MIJSONKeyObjectName : videoWriterName,
        MIJSONPropertyFile : GetMoviePathInMoviesDir(),
        MIJSONPropertyFileType : AVFileTypeQuickTimeMovie
    ]

    let createVideoWriterCommand3 = [
        MIJSONKeyCommand : MIJSONValueCreateCommand,
        MIJSONKeyObjectType : MIMovieVideoFramesWriterKey,
        MIJSONKeyObjectName : videoWriterName,
        MIJSONPropertyFile : GetMoviePathInMoviesDir(fileName: "videowriter.mp4"),
        MIJSONPropertyFileType : AVFileTypeMPEG4
    ]

    let closeVideoWriter = [
        MIJSONKeyCommand : MIJSONValueCloseCommand,
        MIJSONKeyReceiverObject : videoWriterObject
    ]
    
    let getVideoWriterProperties = [
        MIJSONKeyCommands : [
            [
                MIJSONKeyCommand : MIJSONValueGetPropertiesCommand,
                MIJSONKeyReceiverObject : videoWriterObject,
                MIJSONKeySaveResultsType : MIJSONPropertyJSONString
            ]
        ]
    ]

    let getVideoWriterPropertiesAsDict = [
            MIJSONKeyCommand : MIJSONValueGetPropertiesCommand,
            MIJSONKeyReceiverObject : videoWriterObject,
            MIJSONKeySaveResultsType : MIJSONPropertyDictionaryObject
    ]

    func testCreatingAndClosingVideoFramesWriter() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                createVideoWriterCommand
            ]
        ]
        let theContext = MIContext()
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0, "Error creating a movie editor.")
        // println("Reply string: \(MIGetStringFromReplyDictionary(result))")
        
        if errorCode == MIReplyErrorEnum.NoError
        {
            let resultValue = MIGetNumericReplyValueFromDictionary(result)!
            XCTAssertEqual(resultValue.integerValue, 0,
                "Object reference should be 0")
            // We've create the object now attempt to close it using the obj ref.
            let commandsDict2 = [
                MIJSONKeyCommands : [
                    [
                        MIJSONKeyCommand : MIJSONValueCloseCommand,
                        MIJSONKeyReceiverObject : [
                            MIJSONKeyObjectReference : resultValue.integerValue
                        ]
                    ]
                ]
            ]
            let result2 = MIMovingImagesHandleCommands(theContext, commandsDict2,
                nil)
            let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
            XCTAssertEqual(errorCode2.rawValue, 0, "Error closing movie editor.")
        }
        
        let createVideoWriterCommand2 = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieVideoFramesWriterKey,
            MIJSONKeyObjectName : videoWriterName,
            MIJSONPropertyPathSubstitution : "test1.pathsubstitution",
            MIJSONPropertyFileType : "com.apple.quicktime-movie"
        ]
        let variablesDict = [ "test1.pathsubstitution" :
                              GetMoviePathInMoviesDir() ]
        theContext.appendVariables(variablesDict)
        let commandsDict3 = [
            MIJSONKeyCommands : [
                createVideoWriterCommand2
            ]
        ]
        let result3 = MIMovingImagesHandleCommands(theContext, commandsDict3, nil)
        let errorCode3 = MIGetErrorCodeFromReplyDictionary(result3)
        XCTAssertEqual(errorCode3.rawValue, 0,
                       "Error creating video frames writer.")

        // Get the properties of the video writer with an input attached.
        let result4 = MIMovingImagesHandleCommand(theContext,
            getVideoWriterPropertiesAsDict)
        let errorCode4 = MIGetErrorCodeFromReplyDictionary(result4)
        XCTAssertEqual(errorCode4.rawValue, 0,
            "Error getting properties of a video frames writer.")
        // let stringResult4 = MIGetStringFromReplyDictionary(result4)
        
        let dictResult4 = MIGetDictionaryValueFromReplyDictionary(result4)
        let previousResult : NSDictionary = [
            "file" : GetMoviePathInMoviesDir(),
            "objectname" : videoWriterName,
            "objecttype" : MIMovieVideoFramesWriterKey,
            "utifiletype" : AVFileTypeQuickTimeMovie,
            "videowriterstatus" : 0,
            "canwriteframes" : false
        ]
        XCTAssertEqual(dictResult4, previousResult,
            "Properties of video frames writer different to expected.")
        
        let result5 = MIMovingImagesHandleCommand(theContext,
            closeVideoWriter)
        let errorCode5 = MIGetErrorCodeFromReplyDictionary(result5)
        XCTAssertEqual(errorCode5.rawValue, 0,
                       "Error closing video frames writer.")
        theContext.dropVariablesDictionary(variablesDict)
    }

#if os(OSX)
    func testAddingVideoWriterProRes4444PresetInput() -> Void {
        let frameDuration = [ "time" : 0.0333334 ]
        let commandsDict = [
            MIJSONKeyCommands : [
                createVideoWriterCommand,
                [
                    MIJSONKeyCommand :
                                MIJSONValueAddInputToMovieFrameWriterCommand,
                    MIJSONKeyReceiverObject : videoWriterObject,
                    MIJSONPropertyMovieVideoWriterPreset :
                            MIJSONValueMovieVideoWriterPresetProRes4444,
                    MIJSONKeySize : [ "width" : 1782, "height" : 1080 ],
                    MIJSONPropertyMovieFrameDuration : frameDuration
                ]
            ]
        ]
        let theContext = MIContext()
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0,
            "Error adding a ProRes4444 writer input to the video frame writer.")

        let result2 = MIMovingImagesHandleCommands(theContext,
            getVideoWriterProperties, nil)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
        XCTAssertEqual(errorCode2.rawValue, 0,
            "Error getting properties of a video frames writer.")
        let stringResult4 = MIGetStringFromReplyDictionary(result2)
        let previousResult = "{\"objectname\":\"test001.movievideoframeswriter\"," +
            "\"objecttype\":\"videoframeswriter\",\"videosettings\":{" +
            "\"AVVideoColorPropertiesKey\":{\"TransferFunction\":\"ITU_R_709_2\"," +
            "\"YCbCrMatrix\":\"ITU_R_709_2\",\"ColorPrimaries\":\"ITU_R_709_2\"}," +
            "\"AVVideoCodecKey\":\"ap4h\",\"AVVideoHeightKey\":1080," +
            "\"AVVideoWidthKey\":1782,\"AVVideoScalingModeKey\":" +
            "\"AVVideoScalingModeResizeAspect\"},\"frameduration\":{\"flags\":1," +
            "\"value\":200,\"timescale\":6000,\"epoch\":0},\"canwriteframes\":" +
            "true,\"file\":\"\\/Users\\/ktam\\/Movies\\/videowriter.mov\"," +
            "\"time\":{\"flags\":1,\"value\":0,\"timescale\":6000,\"epoch\"" +
            ":0},\"size\":{\"width\":1782,\"height\":1080},\"videowriterstatus\"" +
            ":0,\"utifiletype\":\"com.apple.quicktime-movie\"}"
        XCTAssertEqual(stringResult4, previousResult,
            "Different string returned from get properties of video writer")
        let closeResult = MIMovingImagesHandleCommand(theContext,
            closeVideoWriter)
        let errorCode3 = MIGetErrorCodeFromReplyDictionary(closeResult)
        XCTAssertEqual(errorCode3.rawValue, 0,
            "Error closing video frames writer.")
    }

    func testAddingVideoWriterProRes422PresetInput() -> Void {
        // let frameDuration = [ "time" : 0.0333333 ]
        let frameDurationCM = CMTimeMake(1001, 30000)
        let frameDuration = CMTimeCopyAsDictionary(frameDurationCM,
            kCFAllocatorDefault)
        let commandsDict = [
            MIJSONKeyCommands : [
                createVideoWriterCommand,
                [
                    MIJSONKeyCommand : MIJSONValueAddInputToMovieFrameWriterCommand,
                    MIJSONKeyReceiverObject : videoWriterObject,
                    MIJSONPropertyMovieVideoWriterPreset :
                                    MIJSONValueMovieVideoWriterPresetProRes422,
                    MIJSONKeySize : [ "width" : 1280, "height" : 720 ],
                    MIJSONPropertyMovieFrameDuration : frameDuration
                ]
            ]
        ]

        let result = MIMovingImagesHandleCommands(nil, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0,
            "Error adding a ProRes422 writer input to the video frame writer.")
        
        let closeResult = MIMovingImagesHandleCommand(nil, closeVideoWriter)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(closeResult)
        XCTAssertEqual(errorCode2.rawValue, 0,
            "Error closing video frames writer.")
    }
#endif

    func testAddingVideoWriterPresetJPEGInput() -> Void {
        // let frameDuration = [ "time" : 0.0333333 ]
        let frameDurationCM = CMTimeMake(1001, 30000)
        let frameDuration = CMTimeCopyAsDictionary(frameDurationCM,
            kCFAllocatorDefault)
        let commandsDict = [
            MIJSONKeyCommands : [
                createVideoWriterCommand,
                [
                    MIJSONKeyCommand : MIJSONValueAddInputToMovieFrameWriterCommand,
                    MIJSONKeyReceiverObject : videoWriterObject,
                    MIJSONPropertyMovieVideoWriterPreset :
                                MIJSONValueMovieVideoWriterPresetJPEG,
                    MIJSONKeySize : [ "width" : 960, "height" : 540 ],
                    MIJSONPropertyMovieFrameDuration : frameDuration
                ]
            ]
        ]

        let result = MIMovingImagesHandleCommands(nil, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0,
            "Error adding a JPEG writer input to the video frame writer.")
        if (errorCode != MIReplyErrorEnum.NoError)
        {
            println(MIGetStringFromReplyDictionary(result))
        }
        let closeResult = MIMovingImagesHandleCommand(nil, closeVideoWriter)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(closeResult)
        XCTAssertEqual(errorCode2.rawValue, 0,
            "Error closing video frames writer.")
    }

    func testAddingVideoWriterH264SDPresetInput() -> Void {
        // let frameDuration = [ "time" : 0.0333333 ]
        let frameDurationCM = CMTimeMake(1001, 30000)
        let frameDuration = CMTimeCopyAsDictionary(frameDurationCM,
            kCFAllocatorDefault)
        let commandsDict = [
            MIJSONKeyCommands : [
                createVideoWriterCommand,
                [
                    MIJSONKeyCommand :
                        MIJSONValueAddInputToMovieFrameWriterCommand,
                    MIJSONKeyReceiverObject : videoWriterObject,
                    MIJSONPropertyMovieVideoWriterPreset :
                                        MIJSONValueMovieVideoWriterPresetH264_SD,
                    MIJSONKeySize : [ "width" : 640, "height" : 480 ],
                    MIJSONPropertyMovieFrameDuration : frameDuration
                ]
            ]
        ]
        
        let result = MIMovingImagesHandleCommands(nil, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0,
            "Error adding a ProRes422 writer input to the video frame writer.")
        
        let closeResult = MIMovingImagesHandleCommand(nil, closeVideoWriter)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(closeResult)
        XCTAssertEqual(errorCode2.rawValue, 0,
            "Error closing video frames writer.")
    }
    
    func testAddingVideoWriterH264SDSettingsInput() -> Void {
        // let frameDuration = [ "time" : 0.0333333 ]
        let frameDurationCM = CMTimeMake(1001, 30000)
        let frameDuration = CMTimeCopyAsDictionary(frameDurationCM,
            kCFAllocatorDefault)
        
        let width = 640
        let height = 480
        let sizeDict = [ "width" : width, "height" : height ]
        
        let commandsDict = [
            MIJSONKeyCommands : [
                createVideoWriterCommand,
                [
                    MIJSONKeyCommand :
                                MIJSONValueAddInputToMovieFrameWriterCommand,
                    MIJSONKeyReceiverObject : videoWriterObject,
                    MIJSONPropertyMovieVideoWriterPreset :
                                        MIJSONValueMovieVideoWriterPresetH264_SD,
                    MIJSONKeySize : sizeDict,
                    MIJSONPropertyMovieFrameDuration : frameDuration
                ]
            ]
        ]
        
        let result = MIMovingImagesHandleCommands(nil, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0,
            "Error adding a custom h264  writer input to the video frame writer.")
        
        let result2 = MIMovingImagesHandleCommand(nil,
            getVideoWriterPropertiesAsDict)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
        XCTAssertEqual(errorCode2.rawValue, 0,
            "Error getting properties of a video frames writer.")
        
        let filePath = GetMoviePathInMoviesDir()
        
        let dictionaryRes:NSDictionary = MIGetDictionaryValueFromReplyDictionary(
            result2)
        let previousResult:NSDictionary = [
            MIJSONKeyObjectName : "test001.movievideoframeswriter",
            MIJSONKeyObjectType : "videoframeswriter",
            MIJSONPropertyFile : filePath,
            MIJSONPropertyFileType : AVFileTypeQuickTimeMovie,
            MIJSONPropertyMovieVideoWriterSettings : [
                AVVideoCodecKey : "avc1",
                AVVideoCompressionPropertiesKey : [
                    "ExpectedFrameRate" : 30,
                    "AverageBitRate" : 3145728,
                    AVVideoMaxKeyFrameIntervalKey : 30,
                    AVVideoProfileLevelKey :
                                        AVVideoProfileLevelH264BaselineAutoLevel
                ],
                AVVideoHeightKey : height,
                AVVideoWidthKey : width
            ],
            MIJSONPropertyMovieFrameDuration : [
                "epoch" : 0,
                "flags" : 1,
                "timescale" : 30000,
                "value" : 1001
            ],
            MIJSONPropertyMovieVideoWriterCanWriteFrames : true,
            MIJSONKeySize : sizeDict,
            MIJSONPropertyMovieVideoWriterStatus : 0,
            MIJSONPropertyMovieTime : [
                "epoch" : 0,
                "flags" : 1,
                "timescale" : 6000,
                "value" : 0
            ]
        ]
        // println("Dictionary Results are: \(dictionaryRes)")
        let areSame = previousResult.isEqualToDictionary(dictionaryRes)
        XCTAssert(areSame,
        "Different dicts from get properties of video writer with video input")
        
        let closeResult = MIMovingImagesHandleCommand(nil, closeVideoWriter)
        let errorCode3 = MIGetErrorCodeFromReplyDictionary(closeResult)
        XCTAssertEqual(errorCode3.rawValue, 0,
            "Error closing video frames writer.")
    }
    
    func testAddingVideoWriterH264HDSettingsInput() -> Void {
        // let frameDuration = [ "time" : 0.0333333 ]
        let frameDurationCM = CMTimeMake(1001, 30000)
        let frameDuration = CMTimeCopyAsDictionary(frameDurationCM,
            kCFAllocatorDefault)
        
        let width = 1280
        let height = 720
        let sizeDict = [ "width" : width, "height" : height ]
        
        let commandsDict = [
            MIJSONKeyCommands : [
                createVideoWriterCommand,
                [
                    MIJSONKeyCommand :
                                    MIJSONValueAddInputToMovieFrameWriterCommand,
                    MIJSONKeyReceiverObject : videoWriterObject,
                    MIJSONPropertyMovieVideoWriterPreset :
                                        MIJSONValueMovieVideoWriterPresetH264_HD,
                    MIJSONKeySize : sizeDict,
                    MIJSONPropertyMovieFrameDuration : frameDuration
                ]
            ]
        ]
        
        let result = MIMovingImagesHandleCommands(nil, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0,
            "Error adding a custom h264  writer input to the video frame writer.")

        let result2 = MIMovingImagesHandleCommand(nil,
            getVideoWriterPropertiesAsDict)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
        XCTAssertEqual(errorCode2.rawValue, 0,
            "Error getting properties of a video frames writer.")
        
        let dictResult2: NSDictionary = MIGetDictionaryValueFromReplyDictionary(
            result2)
    
        let previousDict: NSDictionary = [
            "objectname" : "test001.movievideoframeswriter",
            "objecttype" : "videoframeswriter",
            "videosettings" : [
                AVVideoCodecKey : "avc1",
                AVVideoCompressionPropertiesKey : [
                    "AllowFrameReordering" : 1,
                    "AverageBitRate" : 15585760,
                    "ExpectedFrameRate" : 30,
                    "H264EntropyMode" : "CABAC",
                    "MaxKeyFrameInterval" : 30,
                    "ProfileLevel" : "H264_High_AutoLevel"
                ],
                AVVideoHeightKey : height,
                AVVideoWidthKey : width
            ],
            MIJSONPropertyMovieFrameDuration : [
                "epoch" : 0,
                "flags" : 1,
                "timescale" : 30000,
                "value" : 1001
            ],
            MIJSONPropertyMovieVideoWriterCanWriteFrames : 1,
            MIJSONKeySize : sizeDict,
            MIJSONPropertyMovieTime : [
                "epoch" : 0,
                "flags" : 1,
                "timescale" : 6000,
                "value" : 0
            ],
            MIJSONPropertyFile : GetMoviePathInMoviesDir(),
            MIJSONPropertyMovieVideoWriterStatus : 0,
            MIJSONPropertyFileType : "com.apple.quicktime-movie"
        ]
        // println(dictResult2.description)
        let areEqual = dictResult2.isEqualToDictionary(previousDict)
        XCTAssert(areEqual,
            "result dictionary for custom video writer properties differ")
        
        let closeResult = MIMovingImagesHandleCommand(nil, closeVideoWriter)
        let errorCode3 = MIGetErrorCodeFromReplyDictionary(closeResult)
        XCTAssertEqual(errorCode2.rawValue, 0,
            "Error closing video frames writer.")
    }
    
#if !(os(iOS) && arch(x86_64))
    func testVAddingFramesToVideoInputWriter() -> Void {

        let width = 1728
        let height = 1080
        let sizeDict = [ "width" : width, "height" : height ]
        
        let numVideoSamples = 20
        let numVideoSamplesF = Float(numVideoSamples)
        let movieLength = 300 // seconds
        let movieLengthF = Float(movieLength)
        let timeScale = 600
        
        // Movie length is 300 seconds. frame duration is 300/20 = 15.0 secs.
        let frameDurationCM = CMTimeMake(
            Int64(timeScale * movieLength / numVideoSamples),
            Int32(timeScale))
        let frameDuration = CMTimeCopyAsDictionary(frameDurationCM,
            kCFAllocatorDefault)

        let addInputToMovieFrameWriterCommand = [
            MIJSONKeyCommand : MIJSONValueAddInputToMovieFrameWriterCommand,
            MIJSONKeyReceiverObject : videoWriterObject,
            MIJSONPropertyMovieVideoWriterPreset :
                                        MIJSONValueMovieVideoWriterPresetH264_HD,
            MIJSONKeySize : sizeDict,
            MIJSONPropertyMovieFrameDuration : frameDuration
        ]

        let inputMovieFilePath = testBundle.URLForResource("MetalHD",
            withExtension:"mp4")!.path!
        
        let createMovieImporterCommand = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieImporterKey,
            MIJSONKeyObjectName : "testAddingFramesToVideoInputWriter.MetalHD.mp4",
            MIJSONPropertyFile : inputMovieFilePath
        ]
        
        let movieImporterObject = [
            MIJSONKeyObjectName : "testAddingFramesToVideoInputWriter.MetalHD.mp4",
            MIJSONKeyObjectType : MIMovieImporterKey
        ]
        
        let closeMovieImporterCommand = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieImporterObject
        ]
        
        let firstVideoTrack = [
            MIJSONPropertyMovieMediaType : AVMediaTypeVideo,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        
        // An array of commands to be run before processing the frames.
        let preProcessCommands = [
            createVideoWriterCommand,
            addInputToMovieFrameWriterCommand,
        ]
        
        let finishWritingFramesCommand = [
            MIJSONKeyCommand : MIJSONValueFinishWritingFramesCommand,
            MIJSONKeyReceiverObject : videoWriterObject
        ]
        
        // An array of commands to be run after processing the frames.
        let postProcessCommands = [
            finishWritingFramesCommand
        ]
        
        // An array of commands to cleanup any objects or images in the collection
        let cleanupCommands = [
            closeVideoWriter
        ]
        
        var frameProcessInstructions : [NSDictionary] = []
        let theUUID = CFUUIDCreate(kCFAllocatorDefault)
        let imageId = CFUUIDCreateString(kCFAllocatorDefault, theUUID)
    
        for index in 0..<numVideoSamples {
            // lets calculate frame times in seconds.
            let frameTime = Float(index) * movieLengthF / numVideoSamplesF
            let commandDict:NSDictionary = [
                MIJSONKeyCommand : MIJSONValueAddImageSampleToWriterCommand,
                MIJSONKeyReceiverObject : videoWriterObject,
                MIJSONPropertyImageIdentifier : imageId,
            ]
            let frameInstructions = [
                MIJSONPropertyMovieFrameTime :
                                        [ MIJSONPropertyMovieTime : frameTime ],
                MIJSONKeyCommands : [ commandDict ]
            ]
            frameProcessInstructions.append(frameInstructions)
        }
        
        let processFramesCommand = [
            MIJSONKeyCommand : MIJSONValueProcessFramesCommand,
            MIJSONKeyReceiverObject : movieImporterObject,
            MIJSONPropertyMovieLocalContext : true,
            MIJSONPropertyMovieTracks : [ firstVideoTrack ],
            MIJSONPropertyImageIdentifier : imageId,
            MIJSONPropertyMoviePreProcess : preProcessCommands,
            MIJSONPropertyMoviePostProcess : postProcessCommands, // unneeded.
            MIJSONKeyCleanupCommands : cleanupCommands,
            MIJSONPropertyMovieProcessInstructions : frameProcessInstructions
        ]
        
        let commandsDict = [
            MIJSONKeyCommands : [
                createMovieImporterCommand,
                processFramesCommand
            ],
            MIJSONKeyCleanupCommands : [
                closeMovieImporterCommand
            ]
        ]
        let result = MIMovingImagesHandleCommands(nil, commandsDict, nil)
        let resultString = MIGetStringFromReplyDictionary(result)
        // println("===========================================================")
        // println(resultString)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error generating movie with frame duration of 15 seconds.")
        if (errorCode == MIReplyErrorEnum.NoError)
        {
            #if os(iOS)
            let moviePath = GetMoviePathInMoviesDir()

            // Now check to see if the file exists and remove if necessary.
            let fm = NSFileManager.defaultManager()
            if (fm.fileExistsAtPath(moviePath))
            {
                fm.removeItemAtPath(moviePath, error: nil)
            }
            #endif
        }
        else
        {
            println(MIGetStringFromReplyDictionary(result))
        }
    }

    func testWAddingFramesToVideoInputWriter() -> Void {
        // unlike above this tests iterating through samples, not selecting a time
        let width = 640
        let height = 360
        let sizeDict = [ "width" : width, "height" : height ]
        
        let numVideoSamples = 120
        let numVideoSamplesF = Double(numVideoSamples)
        
        // Movie length is 4 seconds. frame duration is 1001/30000.
        let frameDurationCM = CMTimeMake(
            Int64(1001),
            Int32(30000))
        let frameDuration = CMTimeCopyAsDictionary(frameDurationCM,
            kCFAllocatorDefault)

        let addInputToMovieFrameWriterCommand = [
            MIJSONKeyCommand : MIJSONValueAddInputToMovieFrameWriterCommand,
            MIJSONKeyReceiverObject : videoWriterObject,
            MIJSONPropertyMovieVideoWriterPreset :
                                        MIJSONValueMovieVideoWriterPresetH264_SD,
            MIJSONKeySize : sizeDict,
            MIJSONPropertyMovieFrameDuration : frameDuration
        ]

        let inputMovieFilePath = testBundle.URLForResource(
            "testinput-movingimages",
            withExtension:"mov")!.path!
        
        let importerName = "testAddingFramesToInputWriter.testinput-movingimages"
        let createMovieImporterCommand = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieImporterKey,
            MIJSONKeyObjectName : importerName,
            MIJSONPropertyFile : inputMovieFilePath
        ]
        
        let movieImporterObject = [
            MIJSONKeyObjectName : importerName,
            MIJSONKeyObjectType : MIMovieImporterKey
        ]
        
        let closeMovieImporterCommand = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieImporterObject
        ]
        
        let firstVideoTrack = [
            MIJSONPropertyMovieMediaType : AVMediaTypeVideo,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        
        let bitmapContextName = "testAddingFrameToVideoInputWriter.bitmapcontext"
        let bitmapObject = [
            MIJSONKeyObjectType : MICGBitmapContextKey,
            MIJSONKeyObjectName : bitmapContextName
        ]

        // On OSX/MI the default bitmap profile for a cgbitmapcontext is sRGB.
        // iOS doesn't have capability to to create a named profile.
        // The default is DeviceRGB. If you want to specify non sRGB which
        // slightly lightens the movie then you need to #if os(...).
        // MI iOS will ignore the named color profile value. I'd like to use
        // the CoreGraphics constant but it is not defined in iOS so I use
        // its actual value.
        let createBitmapContextCommand = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MICGBitmapContextKey,
            MIJSONKeyObjectName : bitmapContextName,
            MIJSONPropertyPreset : MIPlatformDefaultBitmapContext,
            MIJSONKeySize : sizeDict,
            MIJSONPropertyColorProfile : "kCGColorSpaceGenericRGB"
        ]

        // Prepare drawing a semitransparent rect, with border containing text.
        // That moves and rotates from frame to frame.
        let boxWidth = 140
        let boxHeight = 24
        let boxSize = [ "width" : boxWidth, "height" : boxHeight ]
        let boxRect = [
            "origin" : [ "x" : -boxWidth / 2, "y" : -boxHeight / 2 ],
            "size" : boxSize
        ]
        let bitmapBoxRect = [
            "origin" : [ "x" : 0, "y" : 0 ],
            "size" : boxSize
        ]
        let textRect = [
            "origin" : [
                "x" : -CGFloat(boxWidth) * 0.5,
                "y" : -CGFloat(boxHeight) * 0.5
            ],
            "size" : boxSize
        ]
        let fillColor = [
            "red" : 0.2,
            "green" : 0.3,
            "blue" : 0.6,
            "alpha" : 0.4,
            "colorcolorprofilename" : "kCGColorSpaceSRGB"
        ]
        
        let strokeColor = [
            "red" : 0.1,
            "green" : 0.2,
            "blue" : 0.3,
            "alpha" : 0.4,
            "colorcolorprofilename" : "kCGColorSpaceSRGB"
        ]
        
        let textColor = [
            "red" : 0.0,
            "green" : 0.1,
            "blue" : 0.1,
            "alpha" : 0.8,
            "colorcolorprofilename" : "kCGColorSpaceGenericRGB"
        ]

        let fillRectElement = [
            MIJSONKeyElementType : MIJSONValueRectangleFillElement,
            MIJSONKeyRect : boxRect,
            MIJSONKeyFillColor : [
                "red" : 1.0, "green" : 1.0, "blue" : 1.0, "alpha" : 0.0,
                "colorcolorprofilename" : "kCGColorSpaceSRGB"
            ]
        ]

        let cornerRadius = 10
        let fillRoundedRectElement = [
            MIJSONKeyElementType : MIJSONValueRoundedRectangleFillElement,
            MIJSONKeyRect : boxRect,
            MIJSONKeyRadius : cornerRadius,
            MIJSONKeyFillColor : fillColor
        ]
        
        let strokeRoundedRectElement = [
            MIJSONKeyElementType : MIJSONValueRoundedRectangleStrokeElement,
            MIJSONKeyRect : boxRect,
            MIJSONKeyRadius : cornerRadius,
            MIJSONKeyStrokeColor : strokeColor,
            MIJSONKeyLineWidth : 2.0
        ]
        
        let theText = "Going around"
        let fontName = "Avenir-Black"
        
        let drawTextElement = [
            MIJSONKeyElementType : MIJSONValueBasicStringElement,
            MIJSONKeyFillColor : textColor,
            MIJSONKeyStringText : theText,
            MIJSONKeyStringPostscriptFontName : fontName,
            MIJSONKeyStringFontSize : 16,
            MIJSONKeyTextAlignment : MIJSONValueTextAlignCenter,
            MIJSONKeyPoint : [
                "x" : -CGFloat(boxWidth) * 0.5,
                "y" : -CGFloat(boxHeight) * 0.5
            ],
            MIJSONKeyArrayOfPathElements : [
                [
                    "elementtype" : "pathrectangle",
                    "rect" : textRect
                ]
            ]
        ]
        
        let textBoxBitmapName = "testVideoWriter.bitmap.textboxname"
        
        let createTextBoxCommand = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MICGBitmapContextKey,
            MIJSONKeyObjectName : textBoxBitmapName,
            MIJSONPropertyPreset : MIPlatformDefaultBitmapContext,
            MIJSONKeySize : boxSize
        ]
        
        let textBoxBitmapObject = [
            MIJSONKeyObjectType : MICGBitmapContextKey,
            MIJSONKeyObjectName : textBoxBitmapName
        ]

        let textBoxImageIdentifier = "testViewWriter.textboximage"
        let assignTextBoxImageToImageCollection = [
            MIJSONKeyCommand : MIJSONValueAssignImageToCollectionCommand,
            MIJSONPropertyImageIdentifier : textBoxImageIdentifier,
            MIJSONKeyReceiverObject : textBoxBitmapObject,
        ]

        let closeTextBoxBitmapCommand = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : textBoxBitmapObject
        ]
        
        // An array of commands to be run before processing the frames.
        let preProcessCommands = [
            createVideoWriterCommand3,
            createBitmapContextCommand,
            addInputToMovieFrameWriterCommand
        ]
        
        let finishWritingFramesCommand = [
            MIJSONKeyCommand : MIJSONValueFinishWritingFramesCommand,
            MIJSONKeyReceiverObject : videoWriterObject
        ]
        
        // An array of commands to be run after processing the frames.
        let postProcessCommands = [
            finishWritingFramesCommand
        ]
        
        let closeBitmapContext = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : bitmapObject
        ]

        // An array of commands to cleanup any objects or images in the collection
        let cleanupCommands = [
            closeVideoWriter,
            closeBitmapContext
        ]
        
        let theUUID = CFUUIDCreate(kCFAllocatorDefault)
        let imageId = CFUUIDCreateString(kCFAllocatorDefault, theUUID)
        
        let frameDurationUUID = CFUUIDCreate(kCFAllocatorDefault)
        let lastFrameDurationKey = CFUUIDCreateString(kCFAllocatorDefault,
            frameDurationUUID)
        
        func xPosFromSampleIndex(#index : Int) -> Double {
            let xStart = Double(boxWidth) / 2.0
            let xDif = Double(width) -  Double(boxWidth)
            return xStart + xDif * Double(index) / (numVideoSamplesF - 1.0)
        }
        
        func yPosFromSampleIndex(#index : Int) -> Double {
            let yStart = Double(boxHeight) / 2.0
            let yDif = Double(height) - Double(boxHeight)
            let linPos = Double(index) / (numVideoSamplesF - 1.0)
            return yStart + yDif * linPos * linPos
        }
        
        func rotationFromIndex(#index : Int) -> Double {
            return 2.0 * M_PI * Double(index) / (numVideoSamplesF - 1.0)
        }
        
        var frameProcessInstructions : [NSDictionary] = []
        for index in 0..<numVideoSamples {
            let getImageFromBitmapCommand:NSDictionary = [
                MIJSONKeyCommand : MIJSONValueAddImageSampleToWriterCommand,
                MIJSONKeyReceiverObject : videoWriterObject,
                MIJSONKeySourceObject : bitmapObject,
                MIJSONPropertyMovieLastAccessedFrameDurationKey :
                                                        lastFrameDurationKey,
            ]
            
            let drawFrameToBitmapContext:NSDictionary = [
                MIJSONKeyCommand : MIJSONValueDrawElementCommand,
                MIJSONKeyReceiverObject : bitmapObject,
                MIJSONPropertyDrawInstructions : [
                    MIJSONKeyElementType : MIJSONValueDrawImage,
                    MIJSONKeyDestinationRectangle : [
                        "origin" : [ "x" : 0, "y" : 0 ],
                        "size" : sizeDict
                    ],
                    MIJSONPropertyImageIdentifier : imageId
                ]
            ]
            // println("x = \(xPosFromSampleIndex(index: index))")
            // println("y = \(yPosFromSampleIndex(index: index))")
            let drawTextBoxCommand = [
                MIJSONKeyCommand : MIJSONValueDrawElementCommand,
                MIJSONKeyReceiverObject : bitmapObject,
                MIJSONPropertyDrawInstructions : [
                    MIJSONKeyElementType : MIJSONValueArrayOfElements,
                    MIJSONValueArrayOfElements : [
                        fillRoundedRectElement,
                        strokeRoundedRectElement,
                        drawTextElement
                    ],
                    MIJSONKeyContextTransformation : [
                        [
                            MIJSONKeyTransformationType : MIJSONValueTranslate,
                            MIJSONKeyTranslation : [
                                "x" : xPosFromSampleIndex(index: index),
                                "y" : yPosFromSampleIndex(index: index)
                            ]
                        ],
                        [
                            MIJSONKeyTransformationType : MIJSONValueRotate,
                            MIJSONKeyRotation : rotationFromIndex(index: index)
                        ]
                    ]
                ]
            ]
            
            let frameInstructions = [
                MIJSONPropertyMovieFrameTime : MIJSONValueMovieNextSample,
                MIJSONKeyCommands : [
                    drawFrameToBitmapContext,
                    drawTextBoxCommand,
                    getImageFromBitmapCommand
                ]
            ]
            frameProcessInstructions.append(frameInstructions)
        }
        
        let processFramesCommand = [
            MIJSONKeyCommand : MIJSONValueProcessFramesCommand,
            MIJSONKeyReceiverObject : movieImporterObject,
            MIJSONPropertyMovieLocalContext : true,
            MIJSONPropertyMovieTracks : [ firstVideoTrack ],
            MIJSONPropertyImageIdentifier : imageId,
            MIJSONPropertyMovieLastAccessedFrameDurationKey : lastFrameDurationKey,
            MIJSONPropertyMoviePreProcess : preProcessCommands,
            MIJSONPropertyMoviePostProcess : postProcessCommands,
            MIJSONKeyCleanupCommands : cleanupCommands,
            MIJSONPropertyMovieProcessInstructions : frameProcessInstructions
        ]
        
        let commandsDict = [
            MIJSONKeyCommands : [
                createMovieImporterCommand,
                processFramesCommand
            ],
            MIJSONKeyCleanupCommands : [
                closeMovieImporterCommand
            ]
        ]
        let result = MIMovingImagesHandleCommands(nil, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error generating movie generated with copied frame durations.")

        if (errorCode == MIReplyErrorEnum.NoError)
        {
            #if os(iOS)
            let moviePath = GetMoviePathInMoviesDir(fileName: "videowriter.mp4")
            saveMovieFileToSharedPhotoLibrary(filePath: moviePath)

            // Now check to see if the file exists and delete it.
            let fm = NSFileManager.defaultManager()
            if (fm.fileExistsAtPath(moviePath))
            {
                fm.removeItemAtPath(moviePath, error: nil)
            }
            #endif
        }
        else
        {
            println(MIGetStringFromReplyDictionary(result))
        }
    }
#endif // #if !(os(iOS) && arch(x86_64)
#if os(OSX)
    func testXAddingFramesToVideoInputWriterProRes4444() -> Void {
        // unlike above this tests iterating through samples, not selecting a time
        let width = 1280
        let height = 720
        let sizeDict = [ "width" : width, "height" : height ]
        
        let numVideoSamples = 120
        let numVideoSamplesF = Double(numVideoSamples)
        
        // Movie length is 4 seconds. frame duration is 1001/30000.
        let frameDurationCM = CMTimeMake(
            Int64(1001),
            Int32(30000))
        let frameDuration = CMTimeCopyAsDictionary(frameDurationCM,
            kCFAllocatorDefault)

        let addInputToMovieFrameWriterCommand = [
            MIJSONKeyCommand : MIJSONValueAddInputToMovieFrameWriterCommand,
            MIJSONKeyReceiverObject : videoWriterObject,
            MIJSONPropertyMovieVideoWriterPreset :
                                    MIJSONValueMovieVideoWriterPresetProRes4444,
            MIJSONKeySize : sizeDict,
            MIJSONPropertyMovieFrameDuration : frameDuration
        ]

        let inputMovieFilePath = testBundle.URLForResource(
            "testinput-movingimages",
            withExtension:"mov")!.path!
        
        let importerName = "testAddingFramesToInputWriter.testinput-movingimages"
        let createMovieImporterCommand = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieImporterKey,
            MIJSONKeyObjectName : importerName,
            MIJSONPropertyFile : inputMovieFilePath
        ]

        let exPath = GetMoviePathInMoviesDir(
                    fileName: "videowriter-prores4444.mov")
        let createVideoWriterCommandLocal = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieVideoFramesWriterKey,
            MIJSONKeyObjectName : videoWriterName,
            MIJSONPropertyFile : exPath,
            MIJSONPropertyFileType : AVFileTypeQuickTimeMovie
        ]

        let movieImporterObject = [
            MIJSONKeyObjectName : importerName,
            MIJSONKeyObjectType : MIMovieImporterKey
        ]
        
        let closeMovieImporterCommand = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieImporterObject
        ]
        
        let firstVideoTrack = [
            MIJSONPropertyMovieMediaType : AVMediaTypeVideo,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        
        let bitmapContextName = "testAddingFrameToVideoInputWriter.bitmapcontext"
        let bitmapObject = [
            MIJSONKeyObjectType : MICGBitmapContextKey,
            MIJSONKeyObjectName : bitmapContextName
        ]

        let createBitmapContextCommand = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MICGBitmapContextKey,
            MIJSONKeyObjectName : bitmapContextName,
            MIJSONPropertyPreset : MIPlatformDefaultBitmapContext,
            MIJSONKeySize : sizeDict,
            MIJSONPropertyColorProfile : kCGColorSpaceGenericRGB
        ]
        
        // Prepare drawing a semitransparent rect, with border containing text.
        // That moves and rotates from frame to frame.
        let boxWidth = 240
        let boxHeight = 48
        let boxSize = [ "width" : boxWidth, "height" : boxHeight ]
        let boxRect = [
            "origin" : [ "x" : -boxWidth / 2, "y" : -boxHeight / 2 ],
            "size" : boxSize
        ]

        let fillColor = [
            "red" : 0.2,
            "green" : 0.3,
            "blue" : 0.6,
            "alpha" : 0.4,
            "colorcolorprofilename" : "kCGColorSpaceSRGB"
        ]
        
        let strokeColor = [
            "red" : 0.1,
            "green" : 0.2,
            "blue" : 0.3,
            "alpha" : 0.4,
            "colorcolorprofilename" : "kCGColorSpaceSRGB"
        ]
        
        let textColor = [
            "red" : 0.0,
            "green" : 0.1,
            "blue" : 0.1,
            "alpha" : 0.8,
            "colorcolorprofilename" : "kCGColorSpaceSRGB"
        ]

        let cornerRadius = 14
        let fillRoundedRectElement = [
            MIJSONKeyElementType : MIJSONValueRoundedRectangleFillElement,
            MIJSONKeyRect : boxRect,
            MIJSONKeyRadius : cornerRadius,
            MIJSONKeyFillColor : fillColor
        ]
        
        let strokeRoundedRectElement = [
            MIJSONKeyElementType : MIJSONValueRoundedRectangleStrokeElement,
            MIJSONKeyRect : boxRect,
            MIJSONKeyRadius : cornerRadius,
            MIJSONKeyStrokeColor : strokeColor,
            MIJSONKeyLineWidth : 2.0
        ]
        
        let theText = "Going around"
        let fontName = "Avenir-Black"
        
        let drawTextElement = [
            MIJSONKeyElementType : MIJSONValueBasicStringElement,
            MIJSONKeyRect : boxRect,
            MIJSONKeyFillColor : textColor,
            MIJSONKeyLineWidth : 2.0,
            MIJSONKeyStringText : theText,
            MIJSONKeyStringPostscriptFontName : fontName,
            MIJSONKeyStringFontSize : 24,
            MIJSONKeyPoint : [ "x" : 34 - boxWidth / 2, "y" : 16 - boxHeight / 2 ]
        ]
        
        // An array of commands to be run before processing the frames.
        let preProcessCommands = [
            createVideoWriterCommandLocal,
            createBitmapContextCommand,
            addInputToMovieFrameWriterCommand
        ]
        
        let finishWritingFramesCommand = [
            MIJSONKeyCommand : MIJSONValueFinishWritingFramesCommand,
            MIJSONKeyReceiverObject : videoWriterObject
        ]
        
        // An array of commands to be run after processing the frames.
        let postProcessCommands = [
            finishWritingFramesCommand
        ]
        
        let closeBitmapContext = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : bitmapObject
        ]
        
        // An array of commands to cleanup any objects or images in the collection
        let cleanupCommands = [
            closeVideoWriter,
            closeBitmapContext
        ]
        
        let theUUID = CFUUIDCreate(kCFAllocatorDefault)
        let imageId = CFUUIDCreateString(kCFAllocatorDefault, theUUID)
        
        let frameDurationUUID = CFUUIDCreate(kCFAllocatorDefault)
        let lastFrameDurationKey = CFUUIDCreateString(kCFAllocatorDefault,
            frameDurationUUID)
        
        func xPosFromSampleIndex(#index : Int) -> Double {
            let xStart = Double(boxWidth) / 2.0
            let xDif = Double(width) -  Double(boxWidth)
            return xStart + xDif * Double(index) / (numVideoSamplesF - 1.0)
        }
        
        func yPosFromSampleIndex(#index : Int) -> Double {
            let yStart = Double(boxHeight) / 2.0
            let yDif = Double(height) - Double(boxHeight)
            let linPos = Double(index) / (numVideoSamplesF - 1.0)
            return yStart + yDif * linPos * linPos
        }
        
        func rotationFromIndex(#index : Int) -> Double {
            return 2.0 * M_PI * Double(index) / (numVideoSamplesF - 1.0)
        }
        
        var frameProcessInstructions : [NSDictionary] = []
        for index in 0..<numVideoSamples {
            let getImageFromBitmapCommand:NSDictionary = [
                MIJSONKeyCommand : MIJSONValueAddImageSampleToWriterCommand,
                MIJSONKeyReceiverObject : videoWriterObject,
                MIJSONKeySourceObject : bitmapObject,
                MIJSONPropertyMovieLastAccessedFrameDurationKey :
                                                        lastFrameDurationKey,
            ]
            
            let drawFrameToBitmapContext:NSDictionary = [
                MIJSONKeyCommand : MIJSONValueDrawElementCommand,
                MIJSONKeyReceiverObject : bitmapObject,
                MIJSONPropertyDrawInstructions : [
                    MIJSONKeyElementType : MIJSONValueDrawImage,
                    MIJSONKeyDestinationRectangle : [
                        "origin" : [ "x" : 0, "y" : 0 ],
                        "size" : sizeDict
                    ],
                    MIJSONPropertyImageIdentifier : imageId
                ]
            ]

            let drawTextBoxCommand = [
                MIJSONKeyCommand : MIJSONValueDrawElementCommand,
                MIJSONKeyReceiverObject : bitmapObject,
                MIJSONPropertyDrawInstructions : [
                    MIJSONKeyElementType : MIJSONValueArrayOfElements,
                    MIJSONKeyBlendMode : MIJSONValueBlendModeNormal,
                    MIJSONValueArrayOfElements : [
                        fillRoundedRectElement,
                        strokeRoundedRectElement,
                        drawTextElement
                    ],
                    MIJSONKeyContextTransformation : [
                        [
                            MIJSONKeyTransformationType : MIJSONValueTranslate,
                            MIJSONKeyTranslation : [
                                "x" : xPosFromSampleIndex(index: index),
                                "y" : yPosFromSampleIndex(index: index)
                            ]
                        ],
                        [
                            MIJSONKeyTransformationType : MIJSONValueRotate,
                            MIJSONKeyRotation : rotationFromIndex(index: index)
                        ]
                    ]
                ]
            ]
            let frameInstructions = [
                MIJSONPropertyMovieFrameTime : MIJSONValueMovieNextSample,
                MIJSONKeyCommands : [
                    drawFrameToBitmapContext,
                    drawTextBoxCommand,
                    getImageFromBitmapCommand
                ]
            ]
            frameProcessInstructions.append(frameInstructions)
        }
        
        let processFramesCommand = [
            MIJSONKeyCommand : MIJSONValueProcessFramesCommand,
            MIJSONKeyReceiverObject : movieImporterObject,
            MIJSONPropertyMovieLocalContext : true,
            MIJSONPropertyMovieTracks : [ firstVideoTrack ],
            MIJSONPropertyImageIdentifier : imageId,
            MIJSONPropertyMovieLastAccessedFrameDurationKey : lastFrameDurationKey,
            MIJSONPropertyMoviePreProcess : preProcessCommands,
            MIJSONPropertyMoviePostProcess : postProcessCommands,
            MIJSONKeyCleanupCommands : cleanupCommands,
            MIJSONPropertyMovieProcessInstructions : frameProcessInstructions
        ]
        
        let commandsDict = [
            MIJSONKeyCommands : [
                createMovieImporterCommand,
                processFramesCommand
            ],
            MIJSONKeyCleanupCommands : [
                closeMovieImporterCommand
            ]
        ]
        let theContext = MIContext()
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let resultString = MIGetStringFromReplyDictionary(result)
        println("===========================================================")
        println(resultString)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error generating movie generated with copied frame durations.")
    }

    func testXAddingFramesToVideoInputWriterProRes422() -> Void {
        // unlike above this tests iterating through samples, not selecting a time
        let width = 1280
        let height = 720
        let sizeDict = [ "width" : width, "height" : height ]
        
        let numVideoSamples = 120
        let numVideoSamplesF = Double(numVideoSamples)
        
        // Movie length is 4 seconds. frame duration is 1001/30000.
        let frameDurationCM = CMTimeMake(
            Int64(1001),
            Int32(30000))
        let frameDuration = CMTimeCopyAsDictionary(frameDurationCM,
            kCFAllocatorDefault)
        
        let addInputToMovieFrameWriterCommand = [
            MIJSONKeyCommand : MIJSONValueAddInputToMovieFrameWriterCommand,
            MIJSONKeyReceiverObject : videoWriterObject,
            MIJSONPropertyMovieVideoWriterPreset :
            MIJSONValueMovieVideoWriterPresetProRes422,
            MIJSONKeySize : sizeDict,
            MIJSONPropertyMovieFrameDuration : frameDuration
        ]
        
        let inputMovieFilePath = testBundle.URLForResource(
            "testinput-movingimages",
            withExtension:"mov")!.path!
        
        let importerName = "testAddingFramesToInputWriter.testinput-movingimages"
        let createMovieImporterCommand = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieImporterKey,
            MIJSONKeyObjectName : importerName,
            MIJSONPropertyFile : inputMovieFilePath
        ]
        
        let exPath = GetMoviePathInMoviesDir(fileName: "videowriter-prores422.mov")
        let createVideoWriterCommandLocal = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieVideoFramesWriterKey,
            MIJSONKeyObjectName : videoWriterName,
            MIJSONPropertyFile : exPath,
            MIJSONPropertyFileType : AVFileTypeQuickTimeMovie
        ]
        
        let movieImporterObject = [
            MIJSONKeyObjectName : importerName,
            MIJSONKeyObjectType : MIMovieImporterKey
        ]
        
        let closeMovieImporterCommand = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieImporterObject
        ]
        
        let firstVideoTrack = [
            MIJSONPropertyMovieMediaType : AVMediaTypeVideo,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        
        let bitmapContextName = "testAddingFrameToVideoInputWriter.bitmapcontext"
        let bitmapObject = [
            MIJSONKeyObjectType : MICGBitmapContextKey,
            MIJSONKeyObjectName : bitmapContextName
        ]
        
        let createBitmapContextCommand = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MICGBitmapContextKey,
            MIJSONKeyObjectName : bitmapContextName,
            MIJSONPropertyPreset : MIPlatformDefaultBitmapContext,
            MIJSONKeySize : sizeDict,
            MIJSONPropertyColorProfile : kCGColorSpaceGenericRGB
        ]
        
        // Prepare drawing a semitransparent rect, with border containing text.
        // That moves and rotates from frame to frame.
        let boxWidth = 240
        let boxHeight = 48
        let boxSize = [ "width" : boxWidth, "height" : boxHeight ]
        let boxRect = [
            "origin" : [ "x" : -boxWidth / 2, "y" : -boxHeight / 2 ],
            "size" : boxSize
        ]

        let fillColor = [
            "red" : 0.2,
            "green" : 0.3,
            "blue" : 0.6,
            "alpha" : 0.4,
            "colorcolorprofilename" : "kCGColorSpaceSRGB"
        ]
        
        let strokeColor = [
            "red" : 0.1,
            "green" : 0.2,
            "blue" : 0.3,
            "alpha" : 0.4,
            "colorcolorprofilename" : "kCGColorSpaceSRGB"
        ]
        
        let textColor = [
            "red" : 0.0,
            "green" : 0.1,
            "blue" : 0.1,
            "alpha" : 0.8,
            "colorcolorprofilename" : "kCGColorSpaceSRGB"
        ]

        let cornerRadius = 14
        let fillRoundedRectElement = [
            MIJSONKeyElementType : MIJSONValueRoundedRectangleFillElement,
            MIJSONKeyRect : boxRect,
            MIJSONKeyRadius : cornerRadius,
            MIJSONKeyFillColor : fillColor
        ]
        
        let strokeRoundedRectElement = [
            MIJSONKeyElementType : MIJSONValueRoundedRectangleStrokeElement,
            MIJSONKeyRect : boxRect,
            MIJSONKeyRadius : cornerRadius,
            MIJSONKeyStrokeColor : strokeColor,
            MIJSONKeyLineWidth : 2.0
        ]
        
        let theText = "Going around"
        let fontName = "Avenir-Black"
        
        let drawTextElement = [
            MIJSONKeyElementType : MIJSONValueBasicStringElement,
            MIJSONKeyRect : boxRect,
            MIJSONKeyFillColor : textColor,
            MIJSONKeyLineWidth : 2.0,
            MIJSONKeyStringText : theText,
            MIJSONKeyStringPostscriptFontName : fontName,
            MIJSONKeyStringFontSize : 24,
            MIJSONKeyPoint : [ "x" : 34 - boxWidth / 2, "y" : 16 - boxHeight / 2 ]
        ]
        
        // An array of commands to be run before processing the frames.
        let preProcessCommands = [
            createVideoWriterCommandLocal,
            createBitmapContextCommand,
            addInputToMovieFrameWriterCommand
        ]
        
        let finishWritingFramesCommand = [
            MIJSONKeyCommand : MIJSONValueFinishWritingFramesCommand,
            MIJSONKeyReceiverObject : videoWriterObject
        ]
        
        // An array of commands to be run after processing the frames.
        let postProcessCommands = [
            finishWritingFramesCommand
        ]
        
        let closeBitmapContext = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : bitmapObject
        ]
        
        // An array of commands to cleanup any objects or images in the collection
        let cleanupCommands = [
            closeVideoWriter,
            closeBitmapContext
        ]
        
        let theUUID = CFUUIDCreate(kCFAllocatorDefault)
        let imageId = CFUUIDCreateString(kCFAllocatorDefault, theUUID)
        
        let frameDurationUUID = CFUUIDCreate(kCFAllocatorDefault)
        let lastFrameDurationKey = CFUUIDCreateString(kCFAllocatorDefault,
            frameDurationUUID)
        
        func xPosFromSampleIndex(#index : Int) -> Double {
            let xStart = Double(boxWidth) / 2.0
            let xDif = Double(width) -  Double(boxWidth)
            return xStart + xDif * Double(index) / (numVideoSamplesF - 1.0)
        }
        
        func yPosFromSampleIndex(#index : Int) -> Double {
            let yStart = Double(boxHeight) / 2.0
            let yDif = Double(height) - Double(boxHeight)
            let linPos = Double(index) / (numVideoSamplesF - 1.0)
            return yStart + yDif * linPos * linPos
        }
        
        func rotationFromIndex(#index : Int) -> Double {
            return 2.0 * M_PI * Double(index) / (numVideoSamplesF - 1.0)
        }
        
        var frameProcessInstructions : [NSDictionary] = []
        for index in 0..<numVideoSamples {
            let getImageFromBitmapCommand:NSDictionary = [
                MIJSONKeyCommand : MIJSONValueAddImageSampleToWriterCommand,
                MIJSONKeyReceiverObject : videoWriterObject,
                MIJSONKeySourceObject : bitmapObject,
                MIJSONPropertyMovieLastAccessedFrameDurationKey :
                lastFrameDurationKey,
            ]
            
            let drawFrameToBitmapContext:NSDictionary = [
                MIJSONKeyCommand : MIJSONValueDrawElementCommand,
                MIJSONKeyReceiverObject : bitmapObject,
                MIJSONPropertyDrawInstructions : [
                    MIJSONKeyElementType : MIJSONValueDrawImage,
                    MIJSONKeyDestinationRectangle : [
                        "origin" : [ "x" : 0, "y" : 0 ],
                        "size" : sizeDict
                    ],
                    MIJSONPropertyImageIdentifier : imageId
                ]
            ]
            
            let drawTextBoxCommand = [
                MIJSONKeyCommand : MIJSONValueDrawElementCommand,
                MIJSONKeyReceiverObject : bitmapObject,
                MIJSONPropertyDrawInstructions : [
                    MIJSONKeyElementType : MIJSONValueArrayOfElements,
                    MIJSONKeyBlendMode : MIJSONValueBlendModeNormal,
                    MIJSONValueArrayOfElements : [
                        fillRoundedRectElement,
                        strokeRoundedRectElement,
                        drawTextElement
                    ],
                    MIJSONKeyContextTransformation : [
                        [
                            MIJSONKeyTransformationType : MIJSONValueTranslate,
                            MIJSONKeyTranslation : [
                                "x" : xPosFromSampleIndex(index: index),
                                "y" : yPosFromSampleIndex(index: index)
                            ]
                        ],
                        [
                            MIJSONKeyTransformationType : MIJSONValueRotate,
                            MIJSONKeyRotation : rotationFromIndex(index: index)
                        ]
                    ]
                ]
            ]
            let frameInstructions = [
                MIJSONPropertyMovieFrameTime : MIJSONValueMovieNextSample,
                MIJSONKeyCommands : [
                    drawFrameToBitmapContext,
                    drawTextBoxCommand,
                    getImageFromBitmapCommand
                ]
            ]
            frameProcessInstructions.append(frameInstructions)
        }
        
        let processFramesCommand = [
            MIJSONKeyCommand : MIJSONValueProcessFramesCommand,
            MIJSONKeyReceiverObject : movieImporterObject,
            MIJSONPropertyMovieLocalContext : true,
            MIJSONPropertyMovieTracks : [ firstVideoTrack ],
            MIJSONPropertyImageIdentifier : imageId,
            MIJSONPropertyMovieLastAccessedFrameDurationKey : lastFrameDurationKey,
            MIJSONPropertyMoviePreProcess : preProcessCommands,
            MIJSONPropertyMoviePostProcess : postProcessCommands,
            MIJSONKeyCleanupCommands : cleanupCommands,
            MIJSONPropertyMovieProcessInstructions : frameProcessInstructions
        ]
        
        let commandsDict = [
            MIJSONKeyCommands : [
                createMovieImporterCommand,
                processFramesCommand
            ],
            MIJSONKeyCleanupCommands : [
                closeMovieImporterCommand
            ]
        ]
        let theContext = MIContext()
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let resultString = MIGetStringFromReplyDictionary(result)
        println("===========================================================")
        println(resultString)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error generating movie generated with copied frame durations.")
    }
#endif
}
