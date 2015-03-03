//  MovingImagesMovieEditor.swift
//  MovingImagesFramework
//
//  Created by Kevin Meaney on 06/01/2015.
//  Copyright (c) 2015 Apple Inc. All rights reserved.

import Foundation
import ImageIO

#if os(iOS)
    import UIKit
    import MovingImagesiOS
#endif

import AVFoundation
import XCTest

class MovingImagesMovieEditor: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testCreatingAndClosingAMovieEditor() -> Void {
        let movieEditorName = "test001.movieeditor"
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCreateCommand,
                    MIJSONKeyObjectType : MIMovieEditorKey,
                    MIJSONKeyObjectName : movieEditorName
                ]
            ]
        ]
        let theContext = MIContext()
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0, "Error creating a movie editor.")
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
            XCTAssertEqual(errorCode.rawValue, 0, "Error closing movie editor.")
        }
        let resultString = MIGetStringFromReplyDictionary(result)
    }
    
    func testAddingAudioAndVideoTracksToAMovieEditor() -> Void {
        // We first need to create the movie editor.
        // Do all the commands in the default context.
        let movieEditorName = "test002.movieeditor"
        let movieEditorObject = [
            MIJSONKeyObjectType : MIMovieEditorKey,
            MIJSONKeyObjectName : movieEditorName
        ]
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCreateCommand,
                    MIJSONKeyObjectType : MIMovieEditorKey,
                    MIJSONKeyObjectName : movieEditorName
                ],
                [
                    MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
                    MIJSONKeyReceiverObject : movieEditorObject,
                    MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(nil, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0,
            "Error adding a video track to a movie editor.")
        var videoTrackID:CMPersistentTrackID = 0
        if errorCode == MIReplyErrorEnum.NoError
        {
            let resultValue = MIGetNumericReplyValueFromDictionary(result)
            videoTrackID = resultValue.intValue
            println(resultValue.intValue)
        }

        // Now add an audio track to the movie editor. Should be error free.
        let commandsDict2 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
                    MIJSONKeyReceiverObject : movieEditorObject,
                    MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeAudio
                ]
            ]
        ]
        
        // Version 1.0 of MovingImages will not manipulate audio tracks.
        // So adding audio tracks has been dropped for now.
        // let result2 = MIMovingImagesHandleCommands(nil, commandsDict2, nil)
        // let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
        // XCTAssertEqual(errorCode2.rawValue, 0,
        //    "Error adding an audio track to a movie editor.")
        
        // Now add a video track with the persistent track id returned above.
        // This should produce an error as the track id is already used.
        let commandsDict3 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
                    MIJSONKeyReceiverObject : movieEditorObject,
                    MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo,
                    MIJSONPropertyMovieTrackID : Int(videoTrackID)
                ]
            ]
        ]
        
        let result3 = MIMovingImagesHandleCommands(nil, commandsDict3, nil)
        let errorCode3 = MIGetErrorCodeFromReplyDictionary(result3)
        XCTAssertEqual(errorCode3.rawValue,
            MIReplyErrorEnum.NoError.rawValue,
            "Should be able to create a track even when track id is taken.")
        
        // We should have three tracks by now. Check that.
        let commandsDict4 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONKeyReceiverObject : movieEditorObject,
                    MIJSONPropertyKey : MIJSONPropertyMovieNumberOfTracks,
                ]
            ]
        ]
        let result4 = MIMovingImagesHandleCommands(nil, commandsDict4, nil)
        let errorCode4 = MIGetErrorCodeFromReplyDictionary(result4)
        XCTAssertEqual(errorCode4.rawValue,
            MIReplyErrorEnum.NoError.rawValue,
            "Error attempting to get the number of tracks in a movie editor.")
        if errorCode4 == MIReplyErrorEnum.NoError
        {
            let resultValue = MIGetNumericReplyValueFromDictionary(result4)
            XCTAssertEqual(resultValue.integerValue, 2,
                "The number of tracks should be 3")
        }
        
        // Now close the movie editor
        let commandsDict5 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCloseCommand,
                    MIJSONKeyReceiverObject : movieEditorObject,
                ]
            ]
        ]
        let result5 = MIMovingImagesHandleCommands(nil, commandsDict5, nil)
        let errorCode5 = MIGetErrorCodeFromReplyDictionary(result5)
        XCTAssertEqual(errorCode5.rawValue, MIReplyErrorEnum.NoError.rawValue,
            "Error closing the movie editor object.")
    }
    
    func testGetPropertiesFromAMovieEditorAndTracks() -> Void {
        let movieEditorName = "test003.movieeditor"
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCreateCommand,
                    MIJSONKeyObjectType : MIMovieEditorKey,
                    MIJSONKeyObjectName : movieEditorName
                ]
            ]
        ]
        
        let movieEditorObject = [
            MIJSONKeyObjectType : MIMovieEditorKey,
            MIJSONKeyObjectName : movieEditorName
        ]

        let theContext = MIContext()
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0, "Error creating a movie editor.")

        // Now add an audio track to the movie editor. Should be error free.
        let commandsDict2 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
                    MIJSONKeyReceiverObject : movieEditorObject,
                    MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeAudio
                ]
            ]
        ]
        
        // let result2 = MIMovingImagesHandleCommands(theContext,
        //     commandsDict2, nil)
        // let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
        // XCTAssertEqual(errorCode2.rawValue, 0,
        //    "Error adding an audio track to a movie editor.")
        
        // Now add a video track.
        let commandsDict3 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
                    MIJSONKeyReceiverObject : movieEditorObject,
                    MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo,
                ]
            ]
        ]
        let result3 = MIMovingImagesHandleCommands(theContext, commandsDict3, nil)
        let errorCode3 = MIGetErrorCodeFromReplyDictionary(result3)
        XCTAssertEqual(errorCode3.rawValue, 0,
            "Error adding an video track to a movie editor.")
        
        let videoTrackID = [
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        
        let commandsDict4 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertiesCommand,
                    MIJSONKeyReceiverObject : movieEditorObject,
                    MIJSONKeySaveResultsType : MIJSONPropertyJSONString
                ]
            ]
        ]
        let result4 = MIMovingImagesHandleCommands(theContext, commandsDict4, nil)
        let errorCode4 = MIGetErrorCodeFromReplyDictionary(result4)
        XCTAssertEqual(errorCode4.rawValue, 0,
            "Error getting properties from a movie editor.")
        
        let propertiesJSON = MIGetStringFromReplyDictionary(result4)
        XCTAssertEqual(propertiesJSON,
            "{\"objecttype\":\"movieeditor\",\"objectname\":" +
            "\"test003.movieeditor\",\"numberoftracks\":1,\"objectreference\"" +
            ":0,\"metadataformats\":\"\",\"duration\":{\"flags\":1,\"value\"" +
            ":0,\"timescale\":1,\"epoch\":0}}",
            "Get movie editor properties as json returned diff")
        
        let commandsDict5 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertiesCommand,
                    MIJSONKeyReceiverObject : movieEditorObject,
                    MIJSONKeySaveResultsType : MIJSONPropertyJSONString,
                    MIJSONPropertyMovieTrack : videoTrackID
                ]
            ]
        ]
        let result5 = MIMovingImagesHandleCommands(theContext, commandsDict5, nil)
        let errorCode5 = MIGetErrorCodeFromReplyDictionary(result5)
        XCTAssertEqual(errorCode5.rawValue, 0,
            "Error getting properties from a movie editor.")
        
        let trackPropertiesJSON = MIGetStringFromReplyDictionary(result5)
        XCTAssertEqual(trackPropertiesJSON,
            "{\"naturalsize\":{\"width\":0,\"height\":0},\"minframeduration\"" +
            ":{\"flags\":0,\"value\":0,\"timescale\":0,\"epoch\":0}," +
            "\"mediatype\":\"vide\",\"timerange\":{\"start\":{\"flags\":0," +
            "\"value\":0,\"timescale\":0,\"epoch\":0},\"duration\":{\"flags\"" +
            ":0,\"value\":0,\"timescale\":0,\"epoch\":0}},\"trackid\":" +
            "1,\"languagecode\":\"\",\"languagetag\":\"\",\"affinetransform\"" +
            ":{\"m12\":0,\"m21\":0,\"m22\":1,\"tY\":0,\"m11\":1,\"tX\":" +
            "0},\"requiresframereordering\":false,\"trackenabled\":true," +
            "\"framerate\":0}",
            "Get video track properties as json returned diff")
        
        let audioTrackID = [
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeAudio,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        
        let commandsDict6 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertiesCommand,
                    MIJSONKeyReceiverObject : movieEditorObject,
                    MIJSONKeySaveResultsType : MIJSONPropertyJSONString,
                    MIJSONPropertyMovieTrack : audioTrackID
                ]
            ]
        ]
/*
        // Getting property of an audio track in video editor.
        // No longer possible.
        let result6 = MIMovingImagesHandleCommands(theContext, commandsDict6, nil)
        let errorCode6 = MIGetErrorCodeFromReplyDictionary(result6)
        XCTAssertEqual(errorCode6.rawValue, 0,
           "Error getting properties from a movie editor.")

        let audioTrackPropertiesJSON = MIGetStringFromReplyDictionary(result6)
        XCTAssertEqual(audioTrackPropertiesJSON,
            "{\"preferredvolume\":1,\"mediatype\":\"soun\",\"timerange\":" +
            "{\"start\":{\"flags\":0,\"value\":0,\"timescale\":0,\"epoch\":0}" +
            ",\"duration\":{\"flags\":0,\"value\":0,\"timescale\":0,\"epoch\"" +
            ":0}},\"trackid\":1,\"languagecode\":\"\",\"languagetag\":\"\"" +
            ",\"trackenabled\":true}",
            "Get video track properties as json returned diff")
*/
        let commandsDict7 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONKeyReceiverObject : movieEditorObject,
                    MIJSONPropertyKey : MIJSONPropertyMovieDuration
                ]
            ]
        ]
        let result7 = MIMovingImagesHandleCommands(theContext, commandsDict7, nil)
        let errorCode7 = MIGetErrorCodeFromReplyDictionary(result7)
        XCTAssertEqual(errorCode7.rawValue, 0,
            "Error getting movie duration from a movie editor.")
        
        let movieDurationJSON = MIGetStringFromReplyDictionary(result7)
        XCTAssertEqual(movieDurationJSON,
            "{\"flags\":1,\"value\":0,\"timescale\":1,\"epoch\":0}",
            "Get movie duration as json returned diff")
        
        let movieDurationNumber = MIGetNumericReplyValueFromDictionary(result7)
        XCTAssertEqual(movieDurationNumber.doubleValue, 0.0,
            "Get movie duration as json returned diff")

        let commandsDict8 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONKeyReceiverObject : movieEditorObject,
                    MIJSONPropertyKey : MIJSONPropertyMovieTrackID,
                    MIJSONPropertyMovieTrack : videoTrackID
                ]
            ]
        ]
        let result8 = MIMovingImagesHandleCommands(theContext, commandsDict8, nil)
        let errorCode8 = MIGetErrorCodeFromReplyDictionary(result8)
        XCTAssertEqual(errorCode8.rawValue, MIReplyErrorEnum.NoError.rawValue,
            "Error getting properties from a movie editor.")

        let trackID = MIGetNumericReplyValueFromDictionary(result8)
        XCTAssertEqual(trackID.intValue, Int32(1),
            "Persistent track id should be equal to 2.")

        // lets attempt to access a track property from a track that doesn't exist
        let notATrackID = [
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeAudio,
            MIJSONPropertyMovieTrackIndex : 1
        ]
        let commandsDict9 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONKeyReceiverObject : movieEditorObject,
                    MIJSONPropertyKey : MIJSONPropertyMovieTrackID,
                    MIJSONPropertyMovieTrack : notATrackID
                ]
            ]
        ]
/*
        // uncomment after audio track functionality added.
        let result9 = MIMovingImagesHandleCommands(theContext, commandsDict9, nil)
        let errorCode9 = MIGetErrorCodeFromReplyDictionary(result9)
        XCTAssertEqual(errorCode9.rawValue,
            MIReplyErrorEnum.OperationFailed.rawValue,
            "Error getting properties from a movie editor.")
*/
    }
    
    func testGetCompatibleExportPresetsForEditorWithContent() -> Void {
        // First we need to import a movie so that we have a track to insert
        // Setting up various inputs.
        let testBundle = NSBundle(forClass: MovingImagesMovieImporter.self)
        let movieURL = testBundle.URLForResource("testinput-movingimages",
            withExtension:"mov")!
        
        let movieFilePath = movieURL.path!
        let movieImporterName = "test004.movieimporter"
        let createMovieImporterCommand = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieImporterKey,
            MIJSONKeyObjectName : movieImporterName,
            MIJSONPropertyFile : movieFilePath
        ]
        
        let movieImporterObject = [
            MIJSONKeyObjectType : MIMovieImporterKey,
            MIJSONKeyObjectName : movieImporterName
        ]
        
        let closeMovieImporterObjectCommand = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieImporterObject
        ]
        
        let movieEditorName = "test004.movieeditor"
        let videoTrackPersistentID = 3
        
        let createMovieEditorCommand = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieEditorKey,
            MIJSONKeyObjectName : movieEditorName
        ]
        
        let movieEditorObject = [
            MIJSONKeyObjectType : MIMovieEditorKey,
            MIJSONKeyObjectName : movieEditorName
        ]
        
        let closeMovieEditorObjectCommand = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        
        // Add a video track with the persistent track id returned above.
        let addVideoTrackToEditorCommand = [
            MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
            MIJSONPropertyMovieTrackID : videoTrackPersistentID,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo
        ]
        
        let getNaturalSizeCommand = [
            MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyMovieNaturalSize,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        
        let videoTrackID = [
            MIJSONPropertyMovieTrackID : videoTrackPersistentID
        ]
        
        let commandsDict1 = [
            MIJSONKeyCommands : [
                createMovieImporterCommand,
                createMovieEditorCommand,
                addVideoTrackToEditorCommand,
                getNaturalSizeCommand
            ]
        ]

        // After running the listed commands above check that the natural size
        // is 0,0 as we've not added any content yet or specified the natural size.
        let context = MIContext()
        let result1 = MIMovingImagesHandleCommands(context, commandsDict1, nil)
        let resultStr1 = MIGetStringFromReplyDictionary(result1)

        let origRes1 = "{\"width\":0,\"height\":0}"
        XCTAssertEqual(resultStr1, origRes1,
            "Composition without content added should have width,height=(0,0)")
        println(resultStr1)
        
        //
        // Now set the natural size and then check that the assignment has taken.
        //
        let sizeDict = [
            MIJSONKeyWidth : 1920,
            MIJSONKeyHeight : 1080
        ]
        
        let setNaturalSizeCommand = [
            MIJSONKeyCommand : MIJSONValueSetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyMovieNaturalSize,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyValue : sizeDict
        ]
        
        let commandsDict2 = [
            MIJSONKeyCommands : [
                setNaturalSizeCommand,
                getNaturalSizeCommand,
            ]
        ]
        
        let result2 = MIMovingImagesHandleCommands(context, commandsDict2, nil)
        let resultStr2 = MIGetStringFromReplyDictionary(result2)
        
        let origRes2 = "{\"width\":1920,\"height\":1080}"
        XCTAssertEqual(resultStr2, origRes2,
            "Composition should have width,height=(1920,1080)")
        println(resultStr2)

        //
        // Now set the natural size back to 0,0 and check the assignment has taken.
        //
        let zeroSizeDict = [
            MIJSONKeyWidth : 0.0,
            MIJSONKeyHeight : 0.0
        ]
        
        let setNaturalSizeTo00Command = [
            MIJSONKeyCommand : MIJSONValueSetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyMovieNaturalSize,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyValue : zeroSizeDict
        ]

        let commandsDict3 = [
            MIJSONKeyCommands : [
                setNaturalSizeTo00Command,
                getNaturalSizeCommand,
            ]
        ]

        let result3 = MIMovingImagesHandleCommands(context, commandsDict3, nil)
        let resultStr3 = MIGetStringFromReplyDictionary(result3)
        
        XCTAssertEqual(resultStr3, origRes1,
            "Composition without content added should have width,height=(0,0)")
        println(resultStr3)

        //
        // Add video content & confirm natural size is picked up from content.
        //
        
        // Prepare adding a track segment
        // The video data will be inserted at the begining of the track.
        let insertionTime : [String : AnyObject] = [
            kCMTimeFlagsKey : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey : 0,
            kCMTimeScaleKey : 6000,
            kCMTimeEpochKey : 0
        ]
        
        // Get the video frame data from 4 seconds into the imported movie
        let segmentStartTime = [
            MIJSONPropertyMovieTime : 4.0
        ]
        
        let segmentDurationTime : [String : AnyObject] = [
            kCMTimeFlagsKey : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey : 12000,
            kCMTimeScaleKey : 6000,
            kCMTimeEpochKey : 0
        ]
        
        let sourceTrackID = [
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        
        let sourceSegmentTimeRange = [
            MIJSONPropertyMovieTimeRangeStart : segmentStartTime,
            MIJSONPropertyMovieTimeRangeDuration : segmentDurationTime
        ]
        
        let insertSegmentCommand = [
            MIJSONKeyCommand : MIJSONValueInsertTrackSegment,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTrack : videoTrackID,
            MIJSONKeySourceObject : movieImporterObject,
            MIJSONPropertyMovieSourceTrack : sourceTrackID,
            MIJSONPropertyMovieSourceTimeRange : sourceSegmentTimeRange,
            MIJSONPropertyMovieInsertionTime : insertionTime,
            MIJSONPropertyMovieAddPassthruInstruction : true
        ]

        let commandDict4 = [
            MIJSONKeyCommands : [
                insertSegmentCommand,
                getNaturalSizeCommand
            ]
        ]
        let result4 = MIMovingImagesHandleCommands(context,
            commandDict4, nil)
        let resultStr4 = MIGetStringFromReplyDictionary(result4)
        
        XCTAssertEqual(resultStr4, origRes2,
            "Composition with content should have width,height=(1920,1080)")
        println(resultStr4)
        
        //
        // Now specify the natural size & check that overrides size from content.
        //
        
        let halfSizeDict = [
            MIJSONKeyWidth : 960,
            MIJSONKeyHeight : 540
        ]
        
        let setNaturalSizeToHalfSizeCommand = [
            MIJSONKeyCommand : MIJSONValueSetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyMovieNaturalSize,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyValue : halfSizeDict
        ]
        
        let commandDict5 = [
            MIJSONKeyCommands : [
                setNaturalSizeToHalfSizeCommand,
                getNaturalSizeCommand
            ]
        ]
        
        let result5 = MIMovingImagesHandleCommands(context,
            commandDict5, nil)
    
        let resultStr5 = MIGetStringFromReplyDictionary(result5)
        let origRes3 = "{\"width\":960,\"height\":540}"
        XCTAssertEqual(resultStr5, origRes3,
            "Composition with content should have width,height=(960,540)")
        println(resultStr5)
        
        //
        // Now get the natural size of the track with the added video content.
        //
        
        let getTrackNaturalSize = [
            MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyMovieNaturalSize,
            MIJSONPropertyMovieTrack : videoTrackID,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        
        // The video track natural size should be same as content added.
        let result6 = MIMovingImagesHandleCommand(context, getTrackNaturalSize)
        let resultStr6 = MIGetStringFromReplyDictionary(result6)
        XCTAssertEqual(resultStr6, origRes2,
            "Track with segment added should have width,height=(1920,1080)")
        println(resultStr6)
        
        //
        // Now confirm that the video track transform remains as identity.
        //
        
        let getTrackTransform = [
            MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyMovieTrackAffineTransform,
            MIJSONPropertyMovieTrack : videoTrackID,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        
        let result7 = MIMovingImagesHandleCommand(context, getTrackTransform)
        let resultStr7 = MIGetStringFromReplyDictionary(result7)
        let resultDict7 = MIGetDictionaryValueFromReplyDictionary(result7)
        let origDict7 : NSDictionary = [
            MIJSONKeyAffineTransformM11 : 1,
            MIJSONKeyAffineTransformM12 : 0,
            MIJSONKeyAffineTransformM21 : 0,
            MIJSONKeyAffineTransformM22 : 1,
            MIJSONKeyAffineTransformtX : 0,
            MIJSONKeyAffineTransformtY : 0,
        ]
        XCTAssert(origDict7.isEqualToDictionary(resultDict7),
            "Track transform is unchanged after movie natural size changed")
        println(resultStr7)
        
        //
        // Get the list of compatible presets
        //
        
        let getCompatiblePresets = [
            MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyMovieExportCompatiblePresets,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        let result8 = MIMovingImagesHandleCommand(context, getCompatiblePresets)
        let resultStr8 = MIGetStringFromReplyDictionary(result8)
        
        // ProRes4444 is not available, it is not a export preset option.
#if os(iOS)
        let origCompatiblePresets = "AVAssetExportPresetLowQuality " +
        "AVAssetExportPresetHighestQuality AVAssetExportPresetMediumQuality " +
        "AVAssetExportPreset1920x1080 AVAssetExportPreset1280x720 " +
        "AVAssetExportPreset960x540 AVAssetExportPreset640x480"
#else
        let origCompatiblePresets = "AVAssetExportPresetAppleM4VWiFi " +
        "AVAssetExportPresetAppleM4V480pSD AVAssetExportPresetAppleM4V1080pHD " +
        "AVAssetExportPresetAppleM4VCellular AVAssetExportPreset1920x1080 " +
        "AVAssetExportPreset1280x720 AVAssetExportPreset640x480 " +
        "AVAssetExportPresetAppleM4ViPod AVAssetExportPreset3840x2160 " +
        "AVAssetExportPresetAppleM4VAppleTV AVAssetExportPresetAppleM4V720pHD " +
        "AVAssetExportPreset960x540 AVAssetExportPresetAppleProRes422LPCM"
#endif
        XCTAssertEqual(resultStr8, origCompatiblePresets,
        "List of compatible presets for composition with video content differs")
        println(resultStr8)
        
        //
        // Get allowed export file types for a few different presets.
        //
        
        let getAllowedFileTypes = [
            MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyMovieExportTypes,
            MIJSONPropertyMovieExportPreset : AVAssetExportPreset1920x1080,
            MIJSONKeyReceiverObject : movieEditorObject
        ]

        let result9 = MIMovingImagesHandleCommand(context, getAllowedFileTypes)
        let resultStr9 = MIGetStringFromReplyDictionary(result9)
        let origFileTypes = "com.apple.quicktime-movie public.mpeg-4"
        
        XCTAssertEqual(resultStr9, origFileTypes,
            "List allowed movie export file types with the added video content")
        println(resultStr9)

#if os(OSX)
        let getAllowedFileTypes2 = [
            MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyMovieExportTypes,
            MIJSONPropertyMovieExportPreset : AVAssetExportPresetAppleM4VCellular,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        
        let result10 = MIMovingImagesHandleCommand(context, getAllowedFileTypes2)
        let resultStr10 = MIGetStringFromReplyDictionary(result10)
        let origFileTypes2 = "com.apple.m4v-video"
        
        XCTAssertEqual(resultStr10, origFileTypes2,
            "List allowed movie export file types with the added video content")
        println(resultStr10)

        let getAllowedFileTypes3 = [
            MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyMovieExportTypes,
            MIJSONPropertyMovieExportPreset : AVAssetExportPresetAppleProRes422LPCM,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        
        let result11 = MIMovingImagesHandleCommand(context, getAllowedFileTypes3)
        let resultStr11 = MIGetStringFromReplyDictionary(result11)
        let origFileTypes3 = "com.apple.quicktime-movie"
        
        XCTAssertEqual(resultStr11, origFileTypes3,
            "List allowed movie export file types with the added video content")
        println(resultStr11)
#endif
        println("=====================================================")

        let movieExportPath = GetMoviePathInMoviesDir(
            fileName: "movieeditor_export1.mp4")
        
        let exportMovieCommand = [
            MIJSONKeyCommand : MIJSONValueExportCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieExportPreset : AVAssetExportPreset1920x1080,
            MIJSONPropertyFileType : AVFileTypeMPEG4,
            MIJSONPropertyFile : movieExportPath
        ]
        

        let cleanupCommands = [
            MIJSONKeyCommands : [
                exportMovieCommand
            ],
            MIJSONKeyCleanupCommands : [
                closeMovieEditorObjectCommand,
                closeMovieImporterObjectCommand
            ]
        ]
        
        let cleanupResult = MIMovingImagesHandleCommands(context, cleanupCommands,
            nil)
    }
    
    func testInsertingSegmentsToAMovieEditorTrack() -> Void {
        // First we need to import a movie so that we have a track to insert
        let testBundle = NSBundle(forClass: MovingImagesMovieImporter.self)
        let movieURL = testBundle.URLForResource("testinput-movingimages",
            withExtension:"mov")!
        
        let movieFilePath = movieURL.path!
        let movieImporterName = "test004.movieimporter"
        let createMovieImporterCommand = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieImporterKey,
            MIJSONKeyObjectName : movieImporterName,
            MIJSONPropertyFile : movieFilePath
        ]

        let movieImporterObject = [
            MIJSONKeyObjectType : MIMovieImporterKey,
            MIJSONKeyObjectName : movieImporterName
        ]

        let closeMovieImporterObjectCommand = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieImporterObject
        ]

        let movieEditorName = "test004.movieeditor"
        let videoTrackPersistentID = 3

        let createMovieEditorCommand = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieEditorKey,
            MIJSONKeyObjectName : movieEditorName
        ]

        let movieEditorObject = [
            MIJSONKeyObjectType : MIMovieEditorKey,
            MIJSONKeyObjectName : movieEditorName
        ]
        
        let closeMovieEditorObjectCommand = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        
        // Add a video track with the persistent track id returned above.
        let addVideoTrackToEditorCommand = [
            MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
            MIJSONPropertyMovieTrackID : videoTrackPersistentID,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo
        ]
        
        let videoTrackID = [
            MIJSONPropertyMovieTrackID : videoTrackPersistentID
        ]
        
        // Prepare adding a track segment
        
        // The video data will be inserted at the begining of the track.
        let insertionTime : [String : AnyObject] = [
            kCMTimeFlagsKey : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey : 0,
            kCMTimeScaleKey : 6000,
            kCMTimeEpochKey : 0
        ]
        
        // Since the duration of first segment is 2 seconds, start 2nd at 2 secs
        let insertionTime2 = [
            MIJSONPropertyMovieTime : 2.0
        ]
        
        // Get the video frame data from 4 seconds into the imported movie
        let segmentStartTime = [
            MIJSONPropertyMovieTime : 4.0
        ]

        let segment2StartTime : [String : AnyObject] = [
            kCMTimeFlagsKey : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey : 6000,
            kCMTimeScaleKey : 6000,
            kCMTimeEpochKey : 0
        ]
        
        let segmentDurationTime : [String : AnyObject] = [
            kCMTimeFlagsKey : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey : 12000,
            kCMTimeScaleKey : 6000,
            kCMTimeEpochKey : 0
        ]
        
        let sourceSegmentTimeRange = [
            MIJSONPropertyMovieTimeRangeStart : segmentStartTime,
            MIJSONPropertyMovieTimeRangeDuration : segmentDurationTime
        ]
        
        let sourceSegment2TimeRange = [
            MIJSONPropertyMovieTimeRangeStart : segment2StartTime,
            MIJSONPropertyMovieTimeRangeDuration : segmentDurationTime
        ]
        
        let sourceTrackID = [
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo,
            MIJSONPropertyMovieTrackIndex : 0
        ]

        let insertSegmentCommand = [
            MIJSONKeyCommand : MIJSONValueInsertTrackSegment,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTrack : videoTrackID,
            MIJSONKeySourceObject : movieImporterObject,
            MIJSONPropertyMovieSourceTrack : sourceTrackID,
            MIJSONPropertyMovieSourceTimeRange : sourceSegmentTimeRange,
            MIJSONPropertyMovieInsertionTime : insertionTime,
            MIJSONPropertyMovieAddPassthruInstruction : true
        ]

        let insertSegment2Command = [
            MIJSONKeyCommand : MIJSONValueInsertTrackSegment,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTrack : videoTrackID,
            MIJSONKeySourceObject : movieImporterObject,
            MIJSONPropertyMovieSourceTrack : sourceTrackID,
            MIJSONPropertyMovieSourceTimeRange : sourceSegment2TimeRange,
            MIJSONPropertyMovieInsertionTime : insertionTime2,
            MIJSONPropertyMovieAddPassthruInstruction : true
        ]

        // Prepare adding an empty segment in the middle of another segment.
        
        // How start time and duration are defined below can be swapped. The
        // two different ways of defining them are both valid. Now try and insert
        // an empty segment between the first and second segment.
        let emptySegmentStartTime : [String : AnyObject] = [
            kCMTimeFlagsKey : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey : 12000,
            kCMTimeScaleKey : 6000,
            kCMTimeEpochKey : 0
        ]
        
        let emptySegmentDuration = [
            MIJSONPropertyMovieTime : 0.5
        ]
        
        let emptySegmentTimeRange = [
            MIJSONPropertyMovieTimeRangeStart : emptySegmentStartTime,
            MIJSONPropertyMovieTimeRangeDuration : emptySegmentDuration
        ]
        
        // Insert an empty segment into the video track.
        let insertEmptySegmentCommand = [
            MIJSONKeyCommand : MIJSONValueInsertEmptyTrackSegment,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTrack : videoTrackID,
            MIJSONPropertyMovieTimeRange : emptySegmentTimeRange
        ]
        
        let getVideoTrackSegmentsProperty = [
            MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyMovieTrackSegmentMappings,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTrack : videoTrackID
        ]
        
        let commandsDict1 = [
            MIJSONKeyCommands : [
                createMovieImporterCommand,
                createMovieEditorCommand,
                addVideoTrackToEditorCommand,
                insertSegmentCommand,
                insertSegment2Command,
                getVideoTrackSegmentsProperty
            ]
        ]

        let movieExportPath = GetMoviePathInMoviesDir(
            fileName: "movieeditor_export.mp4")

        let exportMovieCommand = [
            MIJSONKeyCommand : MIJSONValueExportCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieExportPreset : AVAssetExportPreset1920x1080,
            MIJSONPropertyFileType : AVFileTypeMPEG4,
            MIJSONPropertyFile : movieExportPath
        ]
        
        let commandsDict3 = [
            MIJSONKeyCommands : [
                insertEmptySegmentCommand,
                getVideoTrackSegmentsProperty
            ]
        ]

        let cleanupCommands = [
            MIJSONKeyCommands : [ ],
            MIJSONKeyCleanupCommands : [
                closeMovieEditorObjectCommand,
                closeMovieImporterObjectCommand
            ]
        ]
        
        let context = MIContext()
        let result1 = MIMovingImagesHandleCommands(context, commandsDict1, nil)
        let resultStr1 = MIGetStringFromReplyDictionary(result1)
        println(resultStr1)
        println("=====================================================")
        let result2 = MIMovingImagesHandleCommand(context, exportMovieCommand)
        println("\(result2)")
        let result3 = MIMovingImagesHandleCommands(context, commandsDict1, nil)
        let resultStr3 = MIGetStringFromReplyDictionary(result3)
        println(resultStr3)
        println("=====================================================")
        
        let cleanupResult = MIMovingImagesHandleCommands(context,
            cleanupCommands, nil)
    }
}
