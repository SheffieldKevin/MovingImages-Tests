//  MovingImagesMovieEditor.swift
//  MovingImagesFramework
//
//  Copyright (c) 2015 Zukini Ltd.

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
        let result = MIMovingImagesHandleCommands(theContext, commandsDict,
            nil, nil)
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
                nil, nil)
            let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
            XCTAssertEqual(errorCode2.rawValue, 0, "Error closing movie editor.")
        }
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
        let result = MIMovingImagesHandleCommands(nil, commandsDict, nil, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0,
            "Error adding a video track to a movie editor.")
        var videoTrackID:CMPersistentTrackID = 0
        if errorCode == MIReplyErrorEnum.NoError
        {
            let resultValue = MIGetNumericReplyValueFromDictionary(result)!
            videoTrackID = resultValue.intValue
            print(resultValue.intValue)
        }

        /*
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
        */
        
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
        
        let result3 = MIMovingImagesHandleCommands(nil, commandsDict3, nil, nil)
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
        let result4 = MIMovingImagesHandleCommands(nil, commandsDict4, nil, nil)
        let errorCode4 = MIGetErrorCodeFromReplyDictionary(result4)
        XCTAssertEqual(errorCode4.rawValue,
            MIReplyErrorEnum.NoError.rawValue,
            "Error attempting to get the number of tracks in a movie editor.")
        if errorCode4 == MIReplyErrorEnum.NoError
        {
            let resultValue = MIGetNumericReplyValueFromDictionary(result4)!
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
        let result5 = MIMovingImagesHandleCommands(nil, commandsDict5, nil, nil)
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
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0, "Error creating a movie editor.")

        /*
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
        */

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
        let result3 = MIMovingImagesHandleCommands(theContext, commandsDict3,
            nil, nil)
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
        let result4 = MIMovingImagesHandleCommands(theContext, commandsDict4,
            nil, nil)
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
        let result5 = MIMovingImagesHandleCommands(theContext, commandsDict5,
            nil, nil)
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
        
        /*
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
        */
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
        let result7 = MIMovingImagesHandleCommands(theContext, commandsDict7,
            nil, nil)
        let errorCode7 = MIGetErrorCodeFromReplyDictionary(result7)
        XCTAssertEqual(errorCode7.rawValue, 0,
            "Error getting movie duration from a movie editor.")
        
        let movieDurationJSON = MIGetStringFromReplyDictionary(result7)
        XCTAssertEqual(movieDurationJSON,
            "{\"flags\":1,\"value\":0,\"timescale\":1,\"epoch\":0}",
            "Get movie duration as json returned diff")
        
        let movieDurationNumber = MIGetNumericReplyValueFromDictionary(result7)!
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
        let result8 = MIMovingImagesHandleCommands(theContext, commandsDict8,
            nil, nil)
        let errorCode8 = MIGetErrorCodeFromReplyDictionary(result8)
        XCTAssertEqual(errorCode8.rawValue, MIReplyErrorEnum.NoError.rawValue,
            "Error getting properties from a movie editor.")

        let trackID = MIGetNumericReplyValueFromDictionary(result8)!
        XCTAssertEqual(trackID.intValue, Int32(1),
            "Persistent track id should be equal to 2.")

        // lets attempt to access a track property from a track that doesn't exist
/*
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
*/
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
        let result1 = MIMovingImagesHandleCommands(context, commandsDict1, nil,
            nil)
        let resultStr1 = MIGetStringFromReplyDictionary(result1)

        let origRes1 = "{\"width\":0,\"height\":0}"
        XCTAssertEqual(resultStr1, origRes1,
            "Composition without content added should have width,height=(0,0)")
        print(resultStr1)
        
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
        
        let result2 = MIMovingImagesHandleCommands(context, commandsDict2, nil,
            nil)
        let resultStr2 = MIGetStringFromReplyDictionary(result2)
        
        let origRes2 = "{\"width\":1920,\"height\":1080}"
        XCTAssertEqual(resultStr2, origRes2,
            "Composition should have width,height=(1920,1080)")
        print(resultStr2)

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

        let result3 = MIMovingImagesHandleCommands(context, commandsDict3, nil,
            nil)
        let resultStr3 = MIGetStringFromReplyDictionary(result3)
        
        XCTAssertEqual(resultStr3, origRes1,
            "Composition without content added should have width,height=(0,0)")
        print(resultStr3)

        //
        // Add video content & confirm natural size is picked up from content.
        //
        
        // Prepare adding a track segment
        // The video data will be inserted at the begining of the track.
        let insertionTime : [String : AnyObject] = [
            kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey as String : 0,
            kCMTimeScaleKey as String : 6000,
            kCMTimeEpochKey as String : 0
        ]
        
        // Get the video frame data from 4 seconds into the imported movie
        let segmentStartTime = [
            MIJSONPropertyMovieTimeInSeconds : 4.0
        ]
        
        let segmentDurationTime : [String : AnyObject] = [
            kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey as String : 12000,
            kCMTimeScaleKey as String : 6000,
            kCMTimeEpochKey as String : 0
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
        ]

        let passthruInstructionTimeRange = [
            MIJSONPropertyMovieTimeRangeStart : insertionTime,
            MIJSONPropertyMovieTimeRangeDuration : segmentDurationTime
        ]
        
        let addPassthruInstructionCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueAddMovieInstruction,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTimeRange : passthruInstructionTimeRange,
            MIJSONPropertyMovieEditorLayerInstructions : [
                [
                    MIJSONKeyMovieEditorLayerInstructionType :
                    MIJSONValueMovieEditorPassthruInstruction,
                    MIJSONPropertyMovieTrack : videoTrackID
                ]
            ]
        ]

        let commandDict4 = [
            MIJSONKeyCommands : [
                insertSegmentCommand,
                addPassthruInstructionCommand,
                getNaturalSizeCommand
            ]
        ]
        let result4 = MIMovingImagesHandleCommands(context, commandDict4, nil,
            nil)
        let resultStr4 = MIGetStringFromReplyDictionary(result4)
        
        XCTAssertEqual(resultStr4, origRes2,
            "Composition with content should have width,height=(1920,1080)")
        print(resultStr4)
        
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
            commandDict5, nil, nil)
    
        let resultStr5 = MIGetStringFromReplyDictionary(result5)
        let origRes3 = "{\"width\":960,\"height\":540}"
        XCTAssertEqual(resultStr5, origRes3,
            "Composition with content should have width,height=(960,540)")
        print(resultStr5)
        
        //
        // Now get the natural size of the track with the added video content.
        //
        
        let getTrackNaturalSize : [String : AnyObject] = [
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
        print(resultStr6)
        
        //
        // Now confirm that the video track transform remains as identity.
        //
        
        let getTrackTransform : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONKeyAffineTransform,
            MIJSONPropertyMovieTrack : videoTrackID,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        
        let result7 = MIMovingImagesHandleCommand(context, getTrackTransform)
        let resultStr7 = MIGetStringFromReplyDictionary(result7)
        let resultDict7 = MIGetDictionaryValueFromReplyDictionary(result7)!
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
        print(resultStr7)
        
        //
        // Get the list of compatible presets
        //
        
        let getCompatiblePresets : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyMovieExportCompatiblePresets,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        let result8 = MIMovingImagesHandleCommand(context, getCompatiblePresets)
        let resultStr8 = MIGetStringFromReplyDictionary(result8)
        
        // ProRes4444 is not available, it is not a export preset option.
#if os(iOS)
    #if arch(x86_64)
        let origCompatiblePresets = "AVAssetExportPresetLowQuality " +
        "AVAssetExportPresetHighestQuality AVAssetExportPresetMediumQuality " +
        "AVAssetExportPreset1920x1080 AVAssetExportPreset1280x720 " +
        "AVAssetExportPreset960x540 AVAssetExportPreset640x480"
    #else
        let origCompatiblePresets = "AVAssetExportPresetLowQuality " +
        "AVAssetExportPreset960x540 AVAssetExportPreset640x480 " +
        "AVAssetExportPresetMediumQuality AVAssetExportPreset1920x1080 " +
        "AVAssetExportPreset1280x720 AVAssetExportPresetHighestQuality"
    #endif
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
        print(resultStr8)
        
        //
        // Get allowed export file types for a few different presets.
        //
        
        let getAllowedFileTypes  : [String : AnyObject] = [
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
        print(resultStr9)

#if os(OSX)
        let getAllowedFileTypes2 : [String : AnyObject] = [
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
        print(resultStr10)

        let getAllowedFileTypes3 : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyMovieExportTypes,
            MIJSONPropertyMovieExportPreset :
                                        AVAssetExportPresetAppleProRes422LPCM,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        
        let result11 = MIMovingImagesHandleCommand(context, getAllowedFileTypes3)
        let resultStr11 = MIGetStringFromReplyDictionary(result11)
        let origFileTypes3 = "com.apple.quicktime-movie"
        
        XCTAssertEqual(resultStr11, origFileTypes3,
            "List allowed movie export file types with the added video content")
        print(resultStr11)
#endif
        print("=====================================================")

        let movieExportPath = GetMoviePathInMoviesDir(
            "movieeditor_export1.mp4")
        
        // I expect the exported movie to be cropped to the top left corner of
        // the supplied content into the video track.
        let exportMovieCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueExportCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieExportPreset : AVAssetExportPreset1920x1080,
            MIJSONPropertyFileType : AVFileTypeMPEG4,
            MIJSONPropertyFile : movieExportPath
        ]

        let result12 = MIMovingImagesHandleCommand(context, exportMovieCommand)
        // let result12Str = MIGetStringFromReplyDictionary(result12)
        let error12 = MIGetErrorCodeFromReplyDictionary(result12)
        XCTAssertEqual(error12, MIReplyErrorEnum.NoError,
            "Error occurred when exporting the movie.")

        //
        // Now set the transform of the track to scale by 0.5.
        // Then check what happens to the track natural size.
        // Then export a second movie.
        //
        
        let scaleTransform = [
            [
                MIJSONKeyTransformationType : MIJSONValueScale,
                MIJSONKeyScale : [
                    MIJSONKeyX : 0.5,
                    MIJSONKeyY : 0.5
                ]
            ]
        ]
        
        let setTrackTransform = [
            MIJSONKeyCommand : MIJSONValueSetPropertyCommand,
            MIJSONPropertyKey : MIJSONKeyContextTransformation,
            MIJSONPropertyValue : scaleTransform,
            MIJSONPropertyMovieTrack : videoTrackID,
            MIJSONKeyReceiverObject : movieEditorObject
        ]

        let commandDict13 = [
            MIJSONKeyCommands : [
                setTrackTransform,
                getTrackNaturalSize
            ]
        ]

        let result13 = MIMovingImagesHandleCommands(context, commandDict13,
            nil, nil)
        let result13Str = MIGetStringFromReplyDictionary(result13)
        XCTAssertEqual(result13Str, origRes2,
            "Track natural size not expected.")

        let getTrackTransform2 : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONKeyAffineTransform,
            MIJSONPropertyMovieTrack : videoTrackID,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        let result14 = MIMovingImagesHandleCommand(context, getTrackTransform2)
        let resultStr14 = MIGetStringFromReplyDictionary(result14)
        let resultDict14 = MIGetDictionaryValueFromReplyDictionary(result14)!
        let origDict14 : NSDictionary = [
            MIJSONKeyAffineTransformM11 : 0.5,
            MIJSONKeyAffineTransformM12 : 0,
            MIJSONKeyAffineTransformM21 : 0,
            MIJSONKeyAffineTransformM22 : 0.5,
            MIJSONKeyAffineTransformtX : 0,
            MIJSONKeyAffineTransformtY : 0,
        ]
        XCTAssert(origDict14.isEqualToDictionary(resultDict14),
            "Track transform is unchanged after movie natural size changed")
        print(resultStr14)

        let movieExportPath2 = GetMoviePathInMoviesDir(
            "movieeditor_export2.mp4")
        
        // I expect the exported movie to be cropped to the top left corner of
        // the supplied content into the video track.
        let exportMovieCommand2 : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueExportCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieExportPreset : AVAssetExportPreset1920x1080,
            MIJSONPropertyFileType : AVFileTypeMPEG4,
            MIJSONPropertyFile : movieExportPath2
        ]
    
        let result15 = MIMovingImagesHandleCommand(context, exportMovieCommand2)
        let error15 = MIGetErrorCodeFromReplyDictionary(result15)
        XCTAssertEqual(error15, MIReplyErrorEnum.NoError,
            "Error occurred when exporting the movie.")
        
        let fullSizeDict = [
            MIJSONKeyWidth : 1920,
            MIJSONKeyHeight : 1080
        ]
        
        let setNaturalSizeToSizeCommand = [
            MIJSONKeyCommand : MIJSONValueSetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyMovieNaturalSize,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyValue : fullSizeDict
        ]
        
        let movieExportPath3 = GetMoviePathInMoviesDir(
            "movieeditor_export3.mp4")
        
        // I expect the exported movie to be cropped to the top left corner of
        // the supplied content into the video track.
        let exportMovieCommand3 = [
            MIJSONKeyCommand : MIJSONValueExportCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieExportPreset : AVAssetExportPreset1920x1080,
            MIJSONPropertyFileType : AVFileTypeMPEG4,
            MIJSONPropertyFile : movieExportPath3
        ]
        
        let cleanupCommands = [
            MIJSONKeyCommands : [
                setNaturalSizeToSizeCommand,
                exportMovieCommand3
            ],
            MIJSONKeyCleanupCommands : [
                closeMovieEditorObjectCommand,
                closeMovieImporterObjectCommand
            ]
        ]
        
        let result16 = MIMovingImagesHandleCommands(context, cleanupCommands,
            nil, nil)
        let error16 = MIGetErrorCodeFromReplyDictionary(result16)
        XCTAssertEqual(error16, MIReplyErrorEnum.NoError,
            "Error occurred when exporting the movie.")
    }
    
    func testInsertingSegmentsToAMovieEditorTrackAndExporting() -> Void {
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
            kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey as String : 0,
            kCMTimeScaleKey as String : 6000,
            kCMTimeEpochKey as String : 0
        ]
        
        // Since the duration of first segment is 2 seconds, start 2nd at 2 secs
        let insertionTime2 = [
            MIJSONPropertyMovieTimeInSeconds : 2.0
        ]
        
        // Get the video frame data from 4 seconds into the imported movie
        let segmentStartTime = [
            MIJSONPropertyMovieTimeInSeconds : 4.0
        ]

        let segment2StartTime : [String : AnyObject] = [
            kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey as String : 6000,
            kCMTimeScaleKey as String : 6000,
            kCMTimeEpochKey as String : 0
        ]
        
        let segmentDurationTime : [String : AnyObject] = [
            kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey as String : 12000,
            kCMTimeScaleKey as String : 6000,
            kCMTimeEpochKey as String : 0
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
            // MIJSONPropertyMovieAddPassthruInstruction : true
        ]

        let passthruInstructionTimeRange = [
            MIJSONPropertyMovieTimeRangeStart : insertionTime,
            MIJSONPropertyMovieTimeRangeDuration : segmentDurationTime
        ]
        
        let addPassthruInstructionCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueAddMovieInstruction,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTimeRange : passthruInstructionTimeRange,
            MIJSONPropertyMovieEditorLayerInstructions : [
                [
                    MIJSONKeyMovieEditorLayerInstructionType :
                    MIJSONValueMovieEditorPassthruInstruction,
                    MIJSONPropertyMovieTrack : videoTrackID
                ]
            ]
        ]

        let insertSegment2Command = [
            MIJSONKeyCommand : MIJSONValueInsertTrackSegment,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTrack : videoTrackID,
            MIJSONKeySourceObject : movieImporterObject,
            MIJSONPropertyMovieSourceTrack : sourceTrackID,
            MIJSONPropertyMovieSourceTimeRange : sourceSegment2TimeRange,
            MIJSONPropertyMovieInsertionTime : insertionTime2,
            // MIJSONPropertyMovieAddPassthruInstruction : true
        ]
        
        let passthruInstructionTimeRange2 = [
            MIJSONPropertyMovieTimeRangeStart : insertionTime2,
            MIJSONPropertyMovieTimeRangeDuration : segmentDurationTime
        ]
        
        let addPassthruInstructionCommand2 : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueAddMovieInstruction,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTimeRange : passthruInstructionTimeRange2,
            MIJSONPropertyMovieEditorLayerInstructions : [
                [
                    MIJSONKeyMovieEditorLayerInstructionType :
                    MIJSONValueMovieEditorPassthruInstruction,
                    MIJSONPropertyMovieTrack : videoTrackID
                ]
            ]
        ]

        // Prepare adding an empty segment in the middle of another segment.
        
        // How start time and duration are defined below can be swapped. The
        // two different ways of defining them are both valid. Now try and insert
        // an empty segment between the first and second segment.
        let emptySegmentStartTime : [String : AnyObject] = [
            kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey as String : 9000,
            kCMTimeScaleKey as String : 6000,
            kCMTimeEpochKey as String : 0
        ]
        
        let emptySegmentDuration = [
            MIJSONPropertyMovieTimeInSeconds : 0.5
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
        
        let movieExportPath = GetMoviePathInMoviesDir(
            "movieeditor_export.mp4")
        
        let theUUID = CFUUIDCreate(kCFAllocatorDefault)
        let pathSubsKey : String = CFUUIDCreateString(kCFAllocatorDefault,
            theUUID) as String
        
        let exportMovieCommand = [
            MIJSONKeyCommand : MIJSONValueExportCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieExportPreset : AVAssetExportPreset1920x1080,
            MIJSONPropertyFileType : AVFileTypeMPEG4,
            MIJSONPropertyFile : movieExportPath,
            MIJSONPropertyPathSubstitution : pathSubsKey
        ]
        
        let commandsDict1 : [String : AnyObject] = [
            MIJSONKeyCommands : [
                createMovieImporterCommand,
                createMovieEditorCommand,
                addVideoTrackToEditorCommand,
                insertSegmentCommand,
                insertSegment2Command,
                addPassthruInstructionCommand,
                addPassthruInstructionCommand2,
                exportMovieCommand,
                getVideoTrackSegmentsProperty
            ],
            MIJSONKeyVariablesDictionary : [
                pathSubsKey : movieExportPath
            ]
        ]

        let commandsDict3 = [
            MIJSONKeyCommands : [
                insertEmptySegmentCommand,
                getVideoTrackSegmentsProperty
            ]
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
        
        let context = MIContext()
        let result1 = MIMovingImagesHandleCommands(context, commandsDict1,
            nil, nil)
        let resultStr1 = MIGetStringFromReplyDictionary(result1)
        let origResult1 = "[{\"sourcetimerange\":{\"start\":{\"flags\":1," +
        "\"value\":24000,\"timescale\":6000,\"epoch\":0},\"duration\"" +
        ":{\"flags\":1,\"value\":12000,\"timescale\":6000,\"epoch\":0}}," +
        "\"targettimerange\":{\"start\":{\"flags\":1,\"value\":0,\"timescale\":" +
        "6000,\"epoch\":0},\"duration\":{\"flags\":1,\"value\":12000," +
        "\"timescale\":6000,\"epoch\":0}}},{\"sourcetimerange\":{\"start\":" +
        "{\"flags\":1,\"value\":6000,\"timescale\":6000,\"epoch\":0}," +
        "\"duration\":{\"flags\":1,\"value\":12000,\"timescale\":6000," +
        "\"epoch\":0}},\"targettimerange\":{\"start\":{\"flags\":1,\"value\":" +
        "12000,\"timescale\":6000,\"epoch\":0},\"duration\":{\"flags\":1," +
        "\"value\":12000,\"timescale\":6000,\"epoch\":0}}}]"
        XCTAssertEqual(origResult1, resultStr1,
            "Segments of the video track with no empty segments differ")
        print(resultStr1)
        print("=============================================================")

        let origResult3 = "[{\"sourcetimerange\":{\"start\":{\"flags\":1," +
        "\"value\":24000,\"timescale\":6000,\"epoch\":0},\"duration\":" +
        "{\"flags\":1,\"value\":9000,\"timescale\":6000,\"epoch\":0}}," +
        "\"targettimerange\":{\"start\":{\"flags\":1,\"value\":0," +
        "\"timescale\":6000,\"epoch\":0},\"duration\":{\"flags\":1,\"value\":" +
        "9000,\"timescale\":6000,\"epoch\":0}}},{\"sourcetimerange\":" +
        "{\"start\":{\"flags\":1,\"value\":33000,\"timescale\":6000," +
        "\"epoch\":0},\"duration\":{\"flags\":1,\"value\":3000,\"timescale\":" +
        "6000,\"epoch\":0}},\"targettimerange\":{\"start\":{\"flags\":1," +
        "\"value\":12000,\"timescale\":6000,\"epoch\":0},\"duration\":" +
        "{\"flags\":1,\"value\":3000,\"timescale\":6000,\"epoch\":0}}}," +
        "{\"sourcetimerange\":{\"start\":{\"flags\":1,\"value\":6000," +
        "\"timescale\":6000,\"epoch\":0},\"duration\":{\"flags\":1," +
        "\"value\":12000,\"timescale\":6000,\"epoch\":0}}," +
        "\"targettimerange\":{\"start\":{\"flags\":1,\"value\":15000," +
        "\"timescale\":6000,\"epoch\":0},\"duration\":{\"flags\":1," +
        "\"value\":12000,\"timescale\":6000,\"epoch\":0}}}]"
        let result3 = MIMovingImagesHandleCommands(context, commandsDict3,
            nil, nil)
        let resultStr3 = MIGetStringFromReplyDictionary(result3)
        XCTAssertEqual(origResult3, resultStr3,
            "Segments of the video track with empty segments differ")
        print("=============================================================")
        let movieExportPath2 = GetMoviePathInMoviesDir(
            "movieeditor_export_empty.mp4")
        let vars2 = [ pathSubsKey : movieExportPath2 ]
        context.appendVariables(vars2)
        let cleanupResult = MIMovingImagesHandleCommands(context,
            cleanupCommands, nil, nil)
        context.dropVariablesDictionary(vars2)
        let error4 = MIGetErrorCodeFromReplyDictionary(cleanupResult)
        XCTAssertEqual(error4.rawValue, MIReplyErrorEnum.OperationFailed.rawValue,
            "Saving a single track movie with empty track segment should fail.")
    }

    func testAddTransformTransitionAndExport() -> Void {
        let numSegments = 2
        
        // First we need to import a movie so that we have a track to insert
        let testBundle = NSBundle(forClass: MovingImagesMovieEditor.self)
        let movieURL = testBundle.URLForResource("testinput-movingimages",
            withExtension:"mov")!
        
        let movieFilePath = movieURL.path!
        let movieImporterName = "test005.movieimporter"
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
        
        let sourceTrackID = [
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        
        let closeMovieImporterObjectCommand = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieImporterObject
        ]
        
        // Now set up the movie editor.
        let movieEditorName = "test005.movieeditor"
        let videoTrack1PersistentID = 3
        let videoTrack2PersistentID = 4
        
        let createMovieEditorCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieEditorKey,
            MIJSONKeyObjectName : movieEditorName
        ]
        
        let movieEditorObject : [String : AnyObject] = [
            MIJSONKeyObjectType : MIMovieEditorKey,
            MIJSONKeyObjectName : movieEditorName
        ]
        
        let closeMovieEditorObjectCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        
        let cleanupCommands : [AnyObject] = [
            closeMovieImporterObjectCommand,
            closeMovieEditorObjectCommand
        ]
        
        // Add a video track with the persistent track id.
        let addVideoTrack1ToEditorCommand = [
            MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
            MIJSONPropertyMovieTrackID : videoTrack1PersistentID,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo
        ]
        
        let videoTrack1ID : [String : AnyObject] = [
            MIJSONPropertyMovieTrackID : videoTrack1PersistentID
        ]
        
        // Add a video track with the persistent track id returned above.
        let addVideoTrack2ToEditorCommand = [
            MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
            MIJSONPropertyMovieTrackID : videoTrack2PersistentID,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo
        ]
        
        let videoTrack2ID : [String : AnyObject] = [
            MIJSONPropertyMovieTrackID : videoTrack2PersistentID
        ]
        
        let trackList : [AnyObject] = [ videoTrack1ID, videoTrack2ID ]
        
        // Make the list of commands mutable so in the add segments iteration
        // I can just keep adding commands to the command list.
        
        var commandList: [AnyObject] = [
            createMovieImporterCommand,
            createMovieEditorCommand,
            addVideoTrack1ToEditorCommand,
            addVideoTrack2ToEditorCommand
        ]
        
        // The duration of all segments is 3 seconds.
        
        let segmentDurationTime : [String : AnyObject] = [
            kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey as String : 18000,
            kCMTimeScaleKey as String : 6000,
            kCMTimeEpochKey as String : 0
        ]
        
        func makeSourceTimeFromIndex(index: Int) -> [String : AnyObject] {
            return [
                kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                kCMTimeValueKey as String : 36000 - index * 6000,
                kCMTimeScaleKey as String : 6000,
                kCMTimeEpochKey as String : 0
            ]
        }
        
        func makeDestinationTimeFromIndex(index: Int) -> [String : AnyObject] {
            return [
                kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                kCMTimeValueKey as String : index * 12000,
                kCMTimeScaleKey as String : 6000,
                kCMTimeEpochKey as String : 0
            ]
        }
        
        func trackForIndex(index: Int) -> [String : AnyObject] {
            return trackList[index % 2] as! [String : AnyObject]
        }
        
        func makeTimeRangeStartingWith(seconds: Int) -> [String : AnyObject] {
            return [
                MIJSONPropertyMovieTimeRangeStart : [
                    kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                    kCMTimeValueKey as String : 6000 * seconds,
                    kCMTimeScaleKey as String : 6000,
                    kCMTimeEpochKey as String : 0
                ],
                MIJSONPropertyMovieTimeRangeDuration : [
                    kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                    kCMTimeValueKey as String : 6000,
                    kCMTimeScaleKey as String : 6000,
                    kCMTimeEpochKey as String : 0
                ]
            ]
        }
        
        for index in 0..<numSegments {
            let sourceTimeRange = [
                MIJSONPropertyMovieTimeRangeStart : makeSourceTimeFromIndex(index),
                MIJSONPropertyMovieTimeRangeDuration : segmentDurationTime
            ]
            let targetTime = makeDestinationTimeFromIndex(index)
            let track = trackForIndex(index)
            let insertSegmentCommand = [
                MIJSONKeyCommand : MIJSONValueInsertTrackSegment,
                MIJSONKeyReceiverObject : movieEditorObject,
                MIJSONPropertyMovieTrack : track,
                MIJSONKeySourceObject : movieImporterObject,
                MIJSONPropertyMovieSourceTrack : sourceTrackID,
                MIJSONPropertyMovieSourceTimeRange : sourceTimeRange,
                MIJSONPropertyMovieInsertionTime : targetTime
            ]
            commandList.append(insertSegmentCommand)
        }
        
        // I'm just going to set up instructions in order.
        // All instructions have a duration of 1 second. There are two additional
        // passthru only instructions, one for the first second of the video and
        // one for the last second of the video.
        
        let instructionDuration : [String : AnyObject] = [
            kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey as String : 6000,
            kCMTimeScaleKey as String : 6000,
            kCMTimeEpochKey as String : 0
        ]
        
        func makeStartTimeInSeconds(seconds: Int) -> [String : AnyObject] {
            return [
                kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                kCMTimeValueKey as String : 6000 * seconds,
                kCMTimeScaleKey as String : 6000,
                kCMTimeEpochKey as String : 0
            ]
        }
        
        func makePassthruLayerInstructionForIndex(index: Int)
            -> [NSString : AnyObject] {
                return [
                    MIJSONKeyMovieEditorLayerInstructionType :
                    MIJSONValueMovieEditorPassthruInstruction,
                    MIJSONPropertyMovieTrack : trackList[index % 2]
                ]
        }
        
        func makePassthruInstructionCommandForTrack(track: [String : AnyObject],
            startTime: Int) -> [String : AnyObject]
        {
            let passThruInstruction : [String : AnyObject] = [
                MIJSONKeyCommand : MIJSONValueAddMovieInstruction,
                MIJSONKeyReceiverObject : movieEditorObject,
                MIJSONPropertyMovieTimeRange : makeTimeRangeStartingWith(startTime),
                MIJSONPropertyMovieEditorLayerInstructions : [
                    [
                        MIJSONKeyMovieEditorLayerInstructionType :
                        MIJSONValueMovieEditorPassthruInstruction,
                        MIJSONPropertyMovieTrack : track
                    ]
                ]
            ]
            return passThruInstruction
        }
        
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(0), startTime: 0))
        
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(0), startTime: 1))
        
        // All the passthrough only instructions have been made. Now the more
        // complex instructions need to be made, these will be done one at a time.
        
        func fromTrackForIndex(index: Int) -> [String : AnyObject] {
            return trackList[index % 2] as! [String : AnyObject]
        }
        
        func toTrackForIndex(index: Int) -> [String : AnyObject] {
            return trackList[(index + 1) % 2] as! [String : AnyObject]
        }
        
        func makePassThruLayerInstructionWithTrack(track: [String : AnyObject])
            ->  [String : AnyObject] {
                return [
                    MIJSONKeyMovieEditorLayerInstructionType :
                    MIJSONValueMovieEditorPassthruInstruction,
                    MIJSONPropertyMovieTrack : track
                ]
        }

        // I need to checkout the generated video that the transformed content
        // is centred and scaled by 0.5.
        let transformTransform = [
            [
                MIJSONKeyTransformationType : MIJSONValueTranslate,
                MIJSONKeyTranslation : [
                    "x" : 0.25 * 1920.0,
                    "y" : 0.25 * 1080.0
                ]
            ],
            [
                MIJSONKeyTransformationType : MIJSONValueScale,
                MIJSONKeyScale : [ "x" : 0.5, "y" : 0.5 ]
            ]
        ]
        
        let transformLayerInstruction : [String : AnyObject] = [
            MIJSONKeyMovieEditorLayerInstructionType :
                                    MIJSONValueMovieEditorTransformInstruction,
            MIJSONPropertyMovieTrack : fromTrackForIndex(0),
            MIJSONPropertyMovieEditorInstructionValue : transformTransform,
            MIJSONPropertyMovieTime : makeStartTimeInSeconds(2)
        ]
        
        let addTransformInstructionCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueAddMovieInstruction as String,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTimeRange : makeTimeRangeStartingWith(2),
            MIJSONPropertyMovieEditorLayerInstructions : [
                transformLayerInstruction,
                makePassThruLayerInstructionWithTrack(toTrackForIndex(0))
            ]
        ]
        commandList.append(addTransformInstructionCommand)

        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(1), startTime: 3))
        
        // This is the last passthru segment to be added.
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(1), startTime: numSegments * 2))
        
        let movieExportPath = GetMoviePathInMoviesDir(
            "movieeditor_transformtransition.mov")
        
        let theUUID = CFUUIDCreate(kCFAllocatorDefault)
        let compositionMapKey = CFUUIDCreateString(kCFAllocatorDefault,
            theUUID) as String
        
        let assignCompositionMapImageToImageCollection = [
            MIJSONKeyCommand : MIJSONValueAssignImageToCollectionCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyImageIdentifier : compositionMapKey
        ]
        commandList.append(assignCompositionMapImageToImageCollection)
        
        let exportMovieCommand = [
            MIJSONKeyCommand : MIJSONValueExportCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieExportPreset : AVAssetExportPreset1920x1080,
            MIJSONPropertyFileType : AVFileTypeQuickTimeMovie,
            MIJSONPropertyFile : movieExportPath,
        ]
        commandList.append(exportMovieCommand)
        
        let videoInstructionCommands = [
            MIJSONKeyCommands : commandList,
            MIJSONKeyCleanupCommands : cleanupCommands
        ]
        
        let instructionResult = MIMovingImagesHandleCommands(nil,
            videoInstructionCommands, nil, nil)
        let defaultContext = MIContext.defaultContext()
        let theImage = defaultContext.getCGImageWithIdentifier(compositionMapKey)
        saveCGImageToAJPEGFile(theImage, baseName: "TransformCompositionMap")
        defaultContext.removeImageWithIdentifier(compositionMapKey)
        let resultStr = MIGetStringFromReplyDictionary(instructionResult)
        print("Result: \(resultStr)")
        let errorCode = MIGetErrorCodeFromReplyDictionary(instructionResult)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error occured generating and creating movie with transfrom instruct.")
        #if os(iOS) && !arch(x86_64)
            let moviePath = GetMoviePathInMoviesDir(fileName:
                "movieeditor_transformtransition.mov")
            saveMovieFileToSharedPhotoLibrary(filePath: moviePath)
            
            // Now check to see if the file exists and delete it.
            let fm = NSFileManager.defaultManager()
            if (fm.fileExistsAtPath(moviePath))
            {
                fm.removeItemAtPath(moviePath, error: nil)
            }
        #endif
    }
    
    func testAddOpacityTransitionAndExport() -> Void {
        let numSegments = 2
        
        // First we need to import a movie so that we have a track to insert
        let testBundle = NSBundle(forClass: MovingImagesMovieEditor.self)
        let movieURL = testBundle.URLForResource("testinput-movingimages",
            withExtension:"mov")!
        
        let movieFilePath = movieURL.path!
        let movieImporterName = "test006.movieimporter"
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
        
        let sourceTrackID = [
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        
        let closeMovieImporterObjectCommand = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieImporterObject
        ]
        
        // Now set up the movie editor.
        let movieEditorName = "test006.movieeditor"
        let videoTrack1PersistentID = 3
        let videoTrack2PersistentID = 4
        
        let createMovieEditorCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieEditorKey,
            MIJSONKeyObjectName : movieEditorName
        ]
        
        let movieEditorObject : [String : AnyObject] = [
            MIJSONKeyObjectType : MIMovieEditorKey,
            MIJSONKeyObjectName : movieEditorName
        ]
        
        let closeMovieEditorObjectCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        
        let cleanupCommands : [AnyObject] = [
            closeMovieImporterObjectCommand,
            closeMovieEditorObjectCommand
        ]
        
        // Add a video track with the persistent track id.
        let addVideoTrack1ToEditorCommand = [
            MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
            MIJSONPropertyMovieTrackID : videoTrack1PersistentID,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo
        ]
        
        let videoTrack1ID : [String : AnyObject] = [
            MIJSONPropertyMovieTrackID : videoTrack1PersistentID
        ]
        
        // Add a video track with the persistent track id returned above.
        let addVideoTrack2ToEditorCommand = [
            MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
            MIJSONPropertyMovieTrackID : videoTrack2PersistentID,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo
        ]
        
        let videoTrack2ID : [String : AnyObject] = [
            MIJSONPropertyMovieTrackID : videoTrack2PersistentID
        ]
        
        let trackList : [AnyObject] = [ videoTrack1ID, videoTrack2ID ]
        
        // Make the list of commands mutable so in the add segments iteration
        // I can just keep adding commands to the command list.
        
        var commandList: [AnyObject] = [
            createMovieImporterCommand,
            createMovieEditorCommand,
            addVideoTrack1ToEditorCommand,
            addVideoTrack2ToEditorCommand
        ]
        
        // The duration of all segments is 3 seconds.
        
        let segmentDurationTime : [String : AnyObject] = [
            kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey as String : 18000,
            kCMTimeScaleKey as String : 6000,
            kCMTimeEpochKey as String : 0
        ]
        
        func makeSourceTimeFromIndex(index: Int) -> [String : AnyObject] {
            return [
                kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                kCMTimeValueKey as String : 36000 - index * 6000,
                kCMTimeScaleKey as String : 6000,
                kCMTimeEpochKey as String : 0
            ]
        }
        
        func makeDestinationTimeFromIndex(index: Int) -> [String : AnyObject] {
            return [
                kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                kCMTimeValueKey as String : index * 12000,
                kCMTimeScaleKey as String : 6000,
                kCMTimeEpochKey as String : 0
            ]
        }
        
        func trackForIndex(index: Int) -> [String : AnyObject] {
            return trackList[index % 2] as! [String : AnyObject]
        }
        
        func makeTimeRangeStartingWith(seconds: Int) -> [String : AnyObject] {
            return [
                MIJSONPropertyMovieTimeRangeStart : [
                    kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                    kCMTimeValueKey as String : 6000 * seconds,
                    kCMTimeScaleKey as String : 6000,
                    kCMTimeEpochKey as String : 0
                ],
                MIJSONPropertyMovieTimeRangeDuration : [
                    kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                    kCMTimeValueKey as String : 6000,
                    kCMTimeScaleKey as String : 6000,
                    kCMTimeEpochKey as String : 0
                ]
            ]
        }
        
        for index in 0..<numSegments {
            let sourceTimeRange = [
                MIJSONPropertyMovieTimeRangeStart : makeSourceTimeFromIndex(index),
                MIJSONPropertyMovieTimeRangeDuration : segmentDurationTime
            ]
            let targetTime = makeDestinationTimeFromIndex(index)
            let track = trackForIndex(index)
            let insertSegmentCommand = [
                MIJSONKeyCommand : MIJSONValueInsertTrackSegment,
                MIJSONKeyReceiverObject : movieEditorObject,
                MIJSONPropertyMovieTrack : track,
                MIJSONKeySourceObject : movieImporterObject,
                MIJSONPropertyMovieSourceTrack : sourceTrackID,
                MIJSONPropertyMovieSourceTimeRange : sourceTimeRange,
                MIJSONPropertyMovieInsertionTime : targetTime
            ]
            commandList.append(insertSegmentCommand)
        }
        
        // I'm just going to set up instructions in order.
        // All instructions have a duration of 1 second. There are two additional
        // passthru only instructions, one for the first second of the video and
        // one for the last second of the video.
        
        let instructionDuration : [String : AnyObject] = [
            kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey as String : 6000,
            kCMTimeScaleKey as String : 6000,
            kCMTimeEpochKey as String : 0
        ]
        
        func makeStartTimeInSeconds(seconds: Int) -> [String : AnyObject] {
            return [
                kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                kCMTimeValueKey as String : 6000 * seconds,
                kCMTimeScaleKey as String : 6000,
                kCMTimeEpochKey as String : 0
            ]
        }
        
        func makePassthruLayerInstructionForIndex(index: Int)
        -> [NSString : AnyObject] {
            return [
                MIJSONKeyMovieEditorLayerInstructionType :
                MIJSONValueMovieEditorPassthruInstruction,
                MIJSONPropertyMovieTrack : trackList[index % 2]
            ]
        }
        
        func makePassthruInstructionCommandForTrack(track: [String : AnyObject],
            startTime: Int) -> [String : AnyObject]
        {
            let passThruInstruction : [String : AnyObject] = [
                MIJSONKeyCommand : MIJSONValueAddMovieInstruction,
                MIJSONKeyReceiverObject : movieEditorObject,
                MIJSONPropertyMovieTimeRange : makeTimeRangeStartingWith(startTime),
                MIJSONPropertyMovieEditorLayerInstructions : [
                    [
                        MIJSONKeyMovieEditorLayerInstructionType :
                        MIJSONValueMovieEditorPassthruInstruction,
                        MIJSONPropertyMovieTrack : track
                    ]
                ]
            ]
            return passThruInstruction
        }
        
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(0), startTime: 0))
        
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(0), startTime: 1))
        
        // All the passthrough only instructions have been made. Now the more
        // complex instructions need to be made, these will be done one at a time.
        
        func fromTrackForIndex(index: Int) -> [String : AnyObject] {
            return trackList[index % 2] as! [String : AnyObject]
        }
        
        func toTrackForIndex(index: Int) -> [String : AnyObject] {
            return trackList[(index + 1) % 2] as! [String : AnyObject]
        }
        
        func makePassThruLayerInstructionWithTrack(track: [String : AnyObject])
        ->  [String : AnyObject] {
            return [
                MIJSONKeyMovieEditorLayerInstructionType :
                MIJSONValueMovieEditorPassthruInstruction,
                MIJSONPropertyMovieTrack : track
            ]
        }
        
        // The first instruction will be an opacity instruction. Not a ramp.

        let opacityLayerInstruction : [NSString : AnyObject] = [
            MIJSONKeyMovieEditorLayerInstructionType :
                                        MIJSONValueMovieEditorOpacityInstruction,
            MIJSONPropertyMovieTrack : fromTrackForIndex(0),
            MIJSONPropertyMovieEditorInstructionValue : 0.5,
            MIJSONPropertyMovieTime : makeStartTimeInSeconds(2)
        ]
        
        let addOpacityInstructionCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueAddMovieInstruction as String,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTimeRange : makeTimeRangeStartingWith(2),
            MIJSONPropertyMovieEditorLayerInstructions : [
                opacityLayerInstruction,
            	makePassThruLayerInstructionWithTrack(toTrackForIndex(0))
            ]
        ]
        commandList.append(addOpacityInstructionCommand)
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(1), startTime: 3))

        // This is the last passthru segment to be added.
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(1), startTime: numSegments * 2))
        
        let movieExportPath = GetMoviePathInMoviesDir(
            "movieeditor_opacitytransition.mov")
        
        let theUUID = CFUUIDCreate(kCFAllocatorDefault)
        let compositionMapKey = CFUUIDCreateString(kCFAllocatorDefault,
            theUUID) as String
        
        let assignCompositionMapImageToImageCollection = [
            MIJSONKeyCommand : MIJSONValueAssignImageToCollectionCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyImageIdentifier : compositionMapKey
        ]
        commandList.append(assignCompositionMapImageToImageCollection)
        
        let exportMovieCommand = [
            MIJSONKeyCommand : MIJSONValueExportCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieExportPreset : AVAssetExportPreset1920x1080,
            MIJSONPropertyFileType : AVFileTypeQuickTimeMovie,
            MIJSONPropertyFile : movieExportPath,
        ]
        commandList.append(exportMovieCommand)
        
        let videoInstructionCommands = [
            MIJSONKeyCommands : commandList,
            MIJSONKeyCleanupCommands : cleanupCommands
        ]
        
        let instructionResult = MIMovingImagesHandleCommands(nil,
            videoInstructionCommands, nil, nil)
        let defaultContext = MIContext.defaultContext()
        let theImage = defaultContext.getCGImageWithIdentifier(compositionMapKey)
        saveCGImageToAJPEGFile(theImage, baseName: "OpacityCompositionMap")
        defaultContext.removeImageWithIdentifier(compositionMapKey)
        let resultStr = MIGetStringFromReplyDictionary(instructionResult)
        print("Result: \(resultStr)")
        let errorCode = MIGetErrorCodeFromReplyDictionary(instructionResult)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error occured generating and creating movie with opacity instruction.")
        #if os(iOS) && !arch(x86_64)
            let moviePath = GetMoviePathInMoviesDir(fileName:
                "movieeditor_opacitytransition.mov")
            saveMovieFileToSharedPhotoLibrary(filePath: moviePath)
            
            // Now check to see if the file exists and delete it.
            let fm = NSFileManager.defaultManager()
            if (fm.fileExistsAtPath(moviePath))
            {
                fm.removeItemAtPath(moviePath, error: nil)
            }
        #endif
    }

    func testAddCropRectTransitionAndExport() -> Void {
        let numSegments = 2
        
        // First we need to import a movie so that we have a track to insert
        let testBundle = NSBundle(forClass: MovingImagesMovieEditor.self)
        let movieURL = testBundle.URLForResource("testinput-movingimages",
            withExtension:"mov")!
        
        let movieFilePath = movieURL.path!
        let movieImporterName = "test007.movieimporter"
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
        
        let sourceTrackID = [
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        
        let closeMovieImporterObjectCommand = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieImporterObject
        ]
        
        // Now set up the movie editor.
        let movieEditorName = "test007.movieeditor"
        let videoTrack1PersistentID = 3
        let videoTrack2PersistentID = 4
        
        let createMovieEditorCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieEditorKey,
            MIJSONKeyObjectName : movieEditorName
        ]
        
        let movieEditorObject : [String : AnyObject] = [
            MIJSONKeyObjectType : MIMovieEditorKey,
            MIJSONKeyObjectName : movieEditorName
        ]
        
        let closeMovieEditorObjectCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        
        let cleanupCommands : [AnyObject] = [
            closeMovieImporterObjectCommand,
            closeMovieEditorObjectCommand
        ]
        
        // Add a video track with the persistent track id.
        let addVideoTrack1ToEditorCommand = [
            MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
            MIJSONPropertyMovieTrackID : videoTrack1PersistentID,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo
        ]
        
        let videoTrack1ID : [String : AnyObject] = [
            MIJSONPropertyMovieTrackID : videoTrack1PersistentID
        ]
        
        // Add a video track with the persistent track id returned above.
        let addVideoTrack2ToEditorCommand = [
            MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
            MIJSONPropertyMovieTrackID : videoTrack2PersistentID,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo
        ]
        
        let videoTrack2ID : [String : AnyObject] = [
            MIJSONPropertyMovieTrackID : videoTrack2PersistentID
        ]
        
        let trackList : [AnyObject] = [ videoTrack1ID, videoTrack2ID ]
        
        // Make the list of commands mutable so in the add segments iteration
        // I can just keep adding commands to the command list.
        
        var commandList: [AnyObject] = [
            createMovieImporterCommand,
            createMovieEditorCommand,
            addVideoTrack1ToEditorCommand,
            addVideoTrack2ToEditorCommand
        ]
        
        // The duration of all segments is 3 seconds.
        
        let segmentDurationTime : [String : AnyObject] = [
            kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey as String : 18000,
            kCMTimeScaleKey as String : 6000,
            kCMTimeEpochKey as String : 0
        ]
        
        func makeSourceTimeFromIndex(index: Int) -> [String : AnyObject] {
            return [
                kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                kCMTimeValueKey as String : 36000 - index * 6000,
                kCMTimeScaleKey as String : 6000,
                kCMTimeEpochKey as String : 0
            ]
        }
        
        func makeDestinationTimeFromIndex(index: Int) -> [String : AnyObject] {
            return [
                kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                kCMTimeValueKey as String : index * 12000,
                kCMTimeScaleKey as String : 6000,
                kCMTimeEpochKey as String : 0
            ]
        }
        
        func trackForIndex(index: Int) -> [String : AnyObject] {
            return trackList[index % 2] as! [String : AnyObject]
        }
        
        func makeTimeRangeStartingWith(seconds: Int) -> [String : AnyObject] {
            return [
                MIJSONPropertyMovieTimeRangeStart : [
                    kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                    kCMTimeValueKey as String : 6000 * seconds,
                    kCMTimeScaleKey as String : 6000,
                    kCMTimeEpochKey as String : 0
                ],
                MIJSONPropertyMovieTimeRangeDuration : [
                    kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                    kCMTimeValueKey as String : 6000,
                    kCMTimeScaleKey as String : 6000,
                    kCMTimeEpochKey as String : 0
                ]
            ]
        }
        
        for index in 0..<numSegments {
            let sourceTimeRange = [
                MIJSONPropertyMovieTimeRangeStart : makeSourceTimeFromIndex(index),
                MIJSONPropertyMovieTimeRangeDuration : segmentDurationTime
            ]
            let targetTime = makeDestinationTimeFromIndex(index)
            let track = trackForIndex(index)
            let insertSegmentCommand = [
                MIJSONKeyCommand : MIJSONValueInsertTrackSegment,
                MIJSONKeyReceiverObject : movieEditorObject,
                MIJSONPropertyMovieTrack : track,
                MIJSONKeySourceObject : movieImporterObject,
                MIJSONPropertyMovieSourceTrack : sourceTrackID,
                MIJSONPropertyMovieSourceTimeRange : sourceTimeRange,
                MIJSONPropertyMovieInsertionTime : targetTime
            ]
            commandList.append(insertSegmentCommand)
        }
        
        // I'm just going to set up instructions in order.
        // All instructions have a duration of 1 second. There are two additional
        // passthru only instructions, one for the first second of the video and
        // one for the last second of the video.
        
        let instructionDuration : [String : AnyObject] = [
            kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey as String : 6000,
            kCMTimeScaleKey as String : 6000,
            kCMTimeEpochKey as String : 0
        ]
        
        func makeStartTimeInSeconds(seconds: Int) -> [String : AnyObject] {
            return [
                kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                kCMTimeValueKey as String : 6000 * seconds,
                kCMTimeScaleKey as String : 6000,
                kCMTimeEpochKey as String : 0
            ]
        }
        
        func makePassthruLayerInstructionForIndex(index: Int)
            -> [NSString : AnyObject] {
                return [
                    MIJSONKeyMovieEditorLayerInstructionType :
                    MIJSONValueMovieEditorPassthruInstruction,
                    MIJSONPropertyMovieTrack : trackList[index % 2]
                ]
        }
        
        func makePassthruInstructionCommandForTrack(track: [String : AnyObject],
            startTime: Int) -> [String : AnyObject]
        {
            let passThruInstruction : [String : AnyObject] = [
                MIJSONKeyCommand : MIJSONValueAddMovieInstruction,
                MIJSONKeyReceiverObject : movieEditorObject,
                MIJSONPropertyMovieTimeRange : makeTimeRangeStartingWith(startTime),
                MIJSONPropertyMovieEditorLayerInstructions : [
                    [
                        MIJSONKeyMovieEditorLayerInstructionType :
                                        MIJSONValueMovieEditorPassthruInstruction,
                        MIJSONPropertyMovieTrack : track
                    ]
                ]
            ]
            return passThruInstruction
        }
        
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(0), startTime: 0))
        
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(0), startTime: 1))
        
        // All the passthrough only instructions have been made. Now the more
        // complex instructions need to be made, these will be done one at a time.
        
        func fromTrackForIndex(index: Int) -> [String : AnyObject] {
            return trackList[index % 2] as! [String : AnyObject]
        }
        
        func toTrackForIndex(index: Int) -> [String : AnyObject] {
            return trackList[(index + 1) % 2] as! [String : AnyObject]
        }
        
        func makePassThruLayerInstructionWithTrack(track: [String : AnyObject])
            ->  [String : AnyObject] {
                return [
                    MIJSONKeyMovieEditorLayerInstructionType :
                    MIJSONValueMovieEditorPassthruInstruction,
                    MIJSONPropertyMovieTrack : track
                ]
        }
        
        // The first instruction will be an opacity instruction. Not a ramp.
        let cropRect = [
            MIJSONKeySize : [
                MIJSONKeyWidth : 0.25 * 1920, // uses defined constant.
                "height" : 0.25 * 1080 // uses constant literal.
            ],
            "origin" : [
                MIJSONKeyX : 960,
                MIJSONKeyY : 540
            ]
        ]
        
        let cropLayerInstruction : [NSString : AnyObject] = [
            MIJSONKeyMovieEditorLayerInstructionType :
                                        MIJSONValueMovieEditorCropInstruction,
            MIJSONPropertyMovieTrack : fromTrackForIndex(0),
            MIJSONPropertyMovieEditorInstructionValue : cropRect,
            MIJSONPropertyMovieTime : makeStartTimeInSeconds(2)
        ]

        let addCropInstructionCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueAddMovieInstruction as String,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTimeRange : makeTimeRangeStartingWith(2),
            MIJSONPropertyMovieEditorLayerInstructions : [
                cropLayerInstruction,
                makePassThruLayerInstructionWithTrack(toTrackForIndex(0))
            ]
        ]
        commandList.append(addCropInstructionCommand)
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(1), startTime: 3))
        
        // This is the last passthru segment to be added.
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(1), startTime: numSegments * 2))
        
        let movieExportPath = GetMoviePathInMoviesDir(
            "movieeditor_croptransition.mov")
        
        let theUUID = CFUUIDCreate(kCFAllocatorDefault)
        let compositionMapKey = CFUUIDCreateString(kCFAllocatorDefault,
            theUUID) as String
        
        let assignCompositionMapImageToImageCollection = [
            MIJSONKeyCommand : MIJSONValueAssignImageToCollectionCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyImageIdentifier : compositionMapKey
        ]
        commandList.append(assignCompositionMapImageToImageCollection)
        
        let exportMovieCommand = [
            MIJSONKeyCommand : MIJSONValueExportCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieExportPreset : AVAssetExportPreset1920x1080,
            MIJSONPropertyFileType : AVFileTypeQuickTimeMovie,
            MIJSONPropertyFile : movieExportPath,
        ]
        commandList.append(exportMovieCommand)
        
        let videoInstructionCommands = [
            MIJSONKeyCommands : commandList,
            MIJSONKeyCleanupCommands : cleanupCommands
        ]
        
        let theContext = MIContext()
        let instructionResult = MIMovingImagesHandleCommands(theContext,
            videoInstructionCommands, nil, nil)
        let theImage = theContext.getCGImageWithIdentifier(compositionMapKey)
        saveCGImageToAJPEGFile(theImage, baseName: "CropCompositionMap")
        theContext.removeImageWithIdentifier(compositionMapKey)
        let resultStr = MIGetStringFromReplyDictionary(instructionResult)
        print("Result: \(resultStr)")
        let errorCode = MIGetErrorCodeFromReplyDictionary(instructionResult)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error occured generating and creating movie with crop instruction.")
        #if os(iOS) && !arch(x86_64)
            let moviePath = GetMoviePathInMoviesDir(fileName:
                "movieeditor_croptransition.mov")
            saveMovieFileToSharedPhotoLibrary(filePath: moviePath)
            
            // Now check to see if the file exists and delete it.
            let fm = NSFileManager.defaultManager()
            if (fm.fileExistsAtPath(moviePath))
            {
                fm.removeItemAtPath(moviePath, error: nil)
            }
        #endif
    }

    func testAddCropRectRamptTransitionAndExport() -> Void {
        let numSegments = 2
        
        // First we need to import a movie so that we have a track to insert
        let testBundle = NSBundle(forClass: MovingImagesMovieEditor.self)
        let movieURL = testBundle.URLForResource("testinput-movingimages",
            withExtension:"mov")!
        
        let movieFilePath = movieURL.path!
        let movieImporterName = "test007.movieimporter"
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
        
        let sourceTrackID = [
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        
        let closeMovieImporterObjectCommand = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieImporterObject
        ]
        
        // Now set up the movie editor.
        let movieEditorName = "test007.movieeditor"
        let videoTrack1PersistentID = 3
        let videoTrack2PersistentID = 4
        
        let createMovieEditorCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MIMovieEditorKey,
            MIJSONKeyObjectName : movieEditorName
        ]
        
        let movieEditorObject : [String : AnyObject] = [
            MIJSONKeyObjectType : MIMovieEditorKey,
            MIJSONKeyObjectName : movieEditorName
        ]
        
        let closeMovieEditorObjectCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieEditorObject
        ]
        
        let cleanupCommands : [AnyObject] = [
            closeMovieImporterObjectCommand,
            closeMovieEditorObjectCommand
        ]
        
        // Add a video track with the persistent track id.
        let addVideoTrack1ToEditorCommand = [
            MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
            MIJSONPropertyMovieTrackID : videoTrack1PersistentID,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo
        ]
        
        let videoTrack1ID : [String : AnyObject] = [
            MIJSONPropertyMovieTrackID : videoTrack1PersistentID
        ]
        
        // Add a video track with the persistent track id returned above.
        let addVideoTrack2ToEditorCommand = [
            MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
            MIJSONPropertyMovieTrackID : videoTrack2PersistentID,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo
        ]
        
        let videoTrack2ID : [String : AnyObject] = [
            MIJSONPropertyMovieTrackID : videoTrack2PersistentID
        ]
        
        let trackList : [AnyObject] = [ videoTrack1ID, videoTrack2ID ]
        
        // Make the list of commands mutable so in the add segments iteration
        // I can just keep adding commands to the command list.
        
        var commandList: [AnyObject] = [
            createMovieImporterCommand,
            createMovieEditorCommand,
            addVideoTrack1ToEditorCommand,
            addVideoTrack2ToEditorCommand
        ]
        
        // The duration of all segments is 3 seconds.
        
        let segmentDurationTime : [String : AnyObject] = [
            kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey as String : 18000,
            kCMTimeScaleKey as String : 6000,
            kCMTimeEpochKey as String : 0
        ]
        
        func makeSourceTimeFromIndex(index: Int) -> [String : AnyObject] {
            return [
                kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                kCMTimeValueKey as String : 36000 - index * 6000,
                kCMTimeScaleKey as String : 6000,
                kCMTimeEpochKey as String : 0
            ]
        }
        
        func makeDestinationTimeFromIndex(index: Int) -> [String : AnyObject] {
            return [
                kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                kCMTimeValueKey as String : index * 12000,
                kCMTimeScaleKey as String : 6000,
                kCMTimeEpochKey as String : 0
            ]
        }
        
        func trackForIndex(index: Int) -> [String : AnyObject] {
            return trackList[index % 2] as! [String : AnyObject]
        }
        
        func makeTimeRangeStartingWith(seconds: Int) -> [String : AnyObject] {
            return [
                MIJSONPropertyMovieTimeRangeStart : [
                    kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                    kCMTimeValueKey as String : 6000 * seconds,
                    kCMTimeScaleKey as String : 6000,
                    kCMTimeEpochKey as String : 0
                ],
                MIJSONPropertyMovieTimeRangeDuration : [
                    kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                    kCMTimeValueKey as String : 6000,
                    kCMTimeScaleKey as String : 6000,
                    kCMTimeEpochKey as String : 0
                ]
            ]
        }
        
        for index in 0..<numSegments {
            let sourceTimeRange = [
                MIJSONPropertyMovieTimeRangeStart : makeSourceTimeFromIndex(index),
                MIJSONPropertyMovieTimeRangeDuration : segmentDurationTime
            ]
            let targetTime = makeDestinationTimeFromIndex(index)
            let track = trackForIndex(index)
            let insertSegmentCommand = [
                MIJSONKeyCommand : MIJSONValueInsertTrackSegment,
                MIJSONKeyReceiverObject : movieEditorObject,
                MIJSONPropertyMovieTrack : track,
                MIJSONKeySourceObject : movieImporterObject,
                MIJSONPropertyMovieSourceTrack : sourceTrackID,
                MIJSONPropertyMovieSourceTimeRange : sourceTimeRange,
                MIJSONPropertyMovieInsertionTime : targetTime
            ]
            commandList.append(insertSegmentCommand)
        }
        
        // I'm just going to set up instructions in order.
        // All instructions have a duration of 1 second. There are two additional
        // passthru only instructions, one for the first second of the video and
        // one for the last second of the video.
        
        let instructionDuration : [String : AnyObject] = [
            kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
            kCMTimeValueKey as String : 6000,
            kCMTimeScaleKey as String : 6000,
            kCMTimeEpochKey as String : 0
        ]
        
        func makeStartTimeInSeconds(seconds: Int) -> [String : AnyObject] {
            return [
                kCMTimeFlagsKey as String : Int(CMTimeFlags.Valid.rawValue),
                kCMTimeValueKey as String : 6000 * seconds,
                kCMTimeScaleKey as String : 6000,
                kCMTimeEpochKey as String : 0
            ]
        }
        
        func makePassthruLayerInstructionForIndex(index: Int)
            -> [NSString : AnyObject] {
                return [
                    MIJSONKeyMovieEditorLayerInstructionType :
                    MIJSONValueMovieEditorPassthruInstruction,
                    MIJSONPropertyMovieTrack : trackList[index % 2]
                ]
        }
        
        func makePassthruInstructionCommandForTrack(track: [String : AnyObject],
            startTime: Int) -> [String : AnyObject]
        {
            let passThruInstruction : [String : AnyObject] = [
                MIJSONKeyCommand : MIJSONValueAddMovieInstruction,
                MIJSONKeyReceiverObject : movieEditorObject,
                MIJSONPropertyMovieTimeRange : makeTimeRangeStartingWith(startTime),
                MIJSONPropertyMovieEditorLayerInstructions : [
                    [
                        MIJSONKeyMovieEditorLayerInstructionType :
                        MIJSONValueMovieEditorPassthruInstruction,
                        MIJSONPropertyMovieTrack : track
                    ]
                ]
            ]
            return passThruInstruction
        }
        
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(0), startTime: 0))
        
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(0), startTime: 1))
        
        // All the passthrough only instructions have been made. Now the more
        // complex instructions need to be made, these will be done one at a time.
        
        func fromTrackForIndex(index: Int) -> [String : AnyObject] {
            return trackList[index % 2] as! [String : AnyObject]
        }
        
        func toTrackForIndex(index: Int) -> [String : AnyObject] {
            return trackList[(index + 1) % 2] as! [String : AnyObject]
        }
        
        func makePassThruLayerInstructionWithTrack(track: [String : AnyObject])
            ->  [String : AnyObject] {
                return [
                    MIJSONKeyMovieEditorLayerInstructionType :
                    MIJSONValueMovieEditorPassthruInstruction,
                    MIJSONPropertyMovieTrack : track
                ]
        }
        
        let startCropRect = [
            MIJSONKeySize : [
                MIJSONKeyWidth : 1920,
                "height" : 1080
            ],
            "origin" : [
                MIJSONKeyX : 0,
                MIJSONKeyY : 0
            ]
        ]

        let endCropRect = [
            MIJSONKeySize : [
                MIJSONKeyWidth : 0.05 * 1920,
                MIJSONKeyHeight : 0.05 * 1080
            ],
            MIJSONKeyOrigin : [
                MIJSONKeyX : 912,
                MIJSONKeyY : 513
            ]
        ]
        
        let cropRampLayerInstruction : [NSString : AnyObject] = [
            MIJSONKeyMovieEditorLayerInstructionType :
                                    MIJSONValueMovieEditorCropRampInstruction,
            MIJSONPropertyMovieTrack : fromTrackForIndex(0),
            MIJSONPropertyMovieEditorStartRampValue : startCropRect,
            MIJSONPropertyMovieEditorEndRampValue : endCropRect,
            MIJSONPropertyMovieTime : makeStartTimeInSeconds(2)
        ]
        
        let addCropInstructionCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueAddMovieInstruction as String,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTimeRange : makeTimeRangeStartingWith(2),
            MIJSONPropertyMovieEditorLayerInstructions : [
                cropRampLayerInstruction,
                makePassThruLayerInstructionWithTrack(toTrackForIndex(0))
            ]
        ]
        commandList.append(addCropInstructionCommand)
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(1), startTime: 3))
        
        // This is the last passthru segment to be added.
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(1), startTime: numSegments * 2))
        
        let movieExportPath = GetMoviePathInMoviesDir(
            "movieeditor_cropramptransition.mov")
        
        let theUUID = CFUUIDCreate(kCFAllocatorDefault)
        let compositionMapKey = CFUUIDCreateString(kCFAllocatorDefault,
            theUUID) as String
        
        let assignCompositionMapImageToImageCollection = [
            MIJSONKeyCommand : MIJSONValueAssignImageToCollectionCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyImageIdentifier : compositionMapKey
        ]
        commandList.append(assignCompositionMapImageToImageCollection)
        
        let exportMovieCommand = [
            MIJSONKeyCommand : MIJSONValueExportCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieExportPreset : AVAssetExportPreset1920x1080,
            MIJSONPropertyFileType : AVFileTypeQuickTimeMovie,
            MIJSONPropertyFile : movieExportPath,
        ]
        commandList.append(exportMovieCommand)
        
        let videoInstructionCommands = [
            MIJSONKeyCommands : commandList,
            MIJSONKeyCleanupCommands : cleanupCommands
        ]
        
        let theContext = MIContext()
        let instructionResult = MIMovingImagesHandleCommands(theContext,
            videoInstructionCommands, nil, nil)
        let theImage = theContext.getCGImageWithIdentifier(compositionMapKey)
        saveCGImageToAJPEGFile(theImage, baseName: "CropRampCompositionMap")
        theContext.removeImageWithIdentifier(compositionMapKey)
        let resultStr = MIGetStringFromReplyDictionary(instructionResult)
        print("Result: \(resultStr)")
        let errorCode = MIGetErrorCodeFromReplyDictionary(instructionResult)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error occured generating and creating movie with crop instruction.")
        #if os(iOS) && !arch(x86_64)
            let moviePath = GetMoviePathInMoviesDir(fileName:
            "movieeditor_croptransition.mov")
            saveMovieFileToSharedPhotoLibrary(filePath: moviePath)
            
            // Now check to see if the file exists and delete it.
            let fm = NSFileManager.defaultManager()
            if (fm.fileExistsAtPath(moviePath))
            {
            fm.removeItemAtPath(moviePath, error: nil)
            }
        #endif
    }
    
    func testAddingRampTransitionInstructionsAndExporting() -> Void {
        // First we need to import a movie so that we have a track to insert
        let numSegments = 4
        let testBundle = NSBundle(forClass: MovingImagesMovieEditor.self)
        let movieURL = testBundle.URLForResource("testinput-movingimages",
            withExtension:"mov")!
        
        let movieFilePath = movieURL.path!
        let movieImporterName = "test008.movieimporter"
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
        
        let sourceTrackID = [
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        
        let closeMovieImporterObjectCommand = [
            MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : movieImporterObject
        ]
        
        // Now set up the movie editor.
        let movieEditorName = "test008.movieeditor"
        let videoTrack1PersistentID = 3
        let videoTrack2PersistentID = 4
        
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
        
        let cleanupCommands = [
            closeMovieImporterObjectCommand,
            closeMovieEditorObjectCommand
        ]
        
        // Add a video track with the persistent track id.
        let addVideoTrack1ToEditorCommand = [
            MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
            MIJSONPropertyMovieTrackID : videoTrack1PersistentID,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo
        ]
        
        let videoTrack1ID = [
            MIJSONPropertyMovieTrackID : videoTrack1PersistentID
        ]
        
        // Add a video track with the persistent track id returned above.
        let addVideoTrack2ToEditorCommand = [
            MIJSONKeyCommand : MIJSONValueCreateTrackCommand,
            MIJSONPropertyMovieTrackID : videoTrack2PersistentID,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieMediaType : MIJSONValueMovieMediaTypeVideo
        ]
        
        let videoTrack2ID = [
            MIJSONPropertyMovieTrackID : videoTrack2PersistentID
        ]
        
        let trackList = [ videoTrack1ID, videoTrack2ID ]
        
        // Make the list of commands mutable so I can just add commands to it
        // as I go.
        
        var commandList = [
            createMovieImporterCommand,
            createMovieEditorCommand,
            addVideoTrack1ToEditorCommand,
            addVideoTrack2ToEditorCommand
        ]
        
        func makeTimeInSeconds(seconds: Int) -> [String : AnyObject] {
            return [
                String(kCMTimeFlagsKey) : Int(CMTimeFlags.Valid.rawValue),
                String(kCMTimeValueKey) : 6000 * seconds,
                String(kCMTimeScaleKey) : 6000,
                String(kCMTimeEpochKey) : 0
            ]
        }

        func makeSourceTimeFromIndex(index: Int) -> [String : AnyObject] {
            return [
                String(kCMTimeFlagsKey) : Int(CMTimeFlags.Valid.rawValue),
                String(kCMTimeValueKey) : ((numSegments - 1) - index) * 6000,
                String(kCMTimeScaleKey) : 6000,
                String(kCMTimeEpochKey) : 0
            ]
        }
        
        func makeDestinationTimeFromIndex(index: Int) -> [String : AnyObject] {
            return [
                String(kCMTimeFlagsKey) : Int(CMTimeFlags.Valid.rawValue),
                String(kCMTimeValueKey) : index * 12000,
                String(kCMTimeScaleKey) : 6000,
                String(kCMTimeEpochKey) : 0
            ]
        }
        
        func trackForIndex(index: Int) -> [String : Int] {
            return trackList[index % 2]
        }
        
        // So lets add the track segments.
        
        for index in 0..<numSegments {
            let sourceTimeRange = [
                MIJSONPropertyMovieTimeRangeStart : makeSourceTimeFromIndex(index),
                MIJSONPropertyMovieTimeRangeDuration : makeTimeInSeconds(3)
            ]
            let targetTime = makeDestinationTimeFromIndex(index)
            let track = trackForIndex(index)
            let insertSegmentCommand = [
                MIJSONKeyCommand : MIJSONValueInsertTrackSegment,
                MIJSONKeyReceiverObject : movieEditorObject,
                MIJSONPropertyMovieTrack : track,
                MIJSONKeySourceObject : movieImporterObject,
                MIJSONPropertyMovieSourceTrack : sourceTrackID,
                MIJSONPropertyMovieSourceTimeRange : sourceTimeRange,
                MIJSONPropertyMovieInsertionTime : targetTime
            ]
            commandList.append(insertSegmentCommand)
        }
        
        // Now add the composition instructions.
        // There are seven composition instructions which are just passthru
        // instructions. Lets set those up first.
        
        // All instructions have a duration of 1 second. There are two additional
        // passthru only instructions, one for the first second of the video and
        // one for the last second of the video.
        
        let instructionDuration = makeTimeInSeconds(1)
        
        func makePassthruLayerInstructionForIndex(index: Int)
        -> [NSString : AnyObject] {
            return [
                MIJSONKeyMovieEditorLayerInstructionType :
                                    MIJSONValueMovieEditorPassthruInstruction,
                MIJSONPropertyMovieTrack : trackList[index % 2]
            ]
        }

        func makeTimeRangeStartingWith(seconds: Int) -> [String : AnyObject] {
            let startTime = [
                String(kCMTimeFlagsKey) : Int(CMTimeFlags.Valid.rawValue),
                String(kCMTimeValueKey) : 6000 * seconds,
                String(kCMTimeScaleKey) : 6000,
                String(kCMTimeEpochKey) : 0
            ]
            
            let duration = [
                String(kCMTimeFlagsKey) : Int(CMTimeFlags.Valid.rawValue),
                String(kCMTimeValueKey) : 6000,
                String(kCMTimeScaleKey) : 6000,
                String(kCMTimeEpochKey) : 0
            ]
            return [
                MIJSONPropertyMovieTimeRangeStart : startTime,
                MIJSONPropertyMovieTimeRangeDuration : duration
            ]
        }
        
        func makePassthruInstructionCommandForTrack(track: [String : AnyObject],
            startTime: Int) -> [String : AnyObject]
        {
            let passThruInstruction : [String : AnyObject] = [
                MIJSONKeyCommand : MIJSONValueAddMovieInstruction,
                MIJSONKeyReceiverObject : movieEditorObject,
                MIJSONPropertyMovieTimeRange : makeTimeRangeStartingWith(startTime),
                MIJSONPropertyMovieEditorLayerInstructions : [
                    [
                        MIJSONKeyMovieEditorLayerInstructionType :
                                        MIJSONValueMovieEditorPassthruInstruction,
                        MIJSONPropertyMovieTrack : track
                    ]
                ]
            ]
            return passThruInstruction
        }
        
        var tIndex = 0
        commandList.append(makePassthruInstructionCommandForTrack(
            trackList[tIndex], startTime: tIndex * 2))

        commandList.append(makePassthruInstructionCommandForTrack(
            trackList[tIndex], startTime: tIndex * 2 + 1))

        func fromTrackForIndex(index: Int) -> [String : Int] {
            return trackList[index % 2]
        }
        
        func toTrackForIndex(index: Int) -> [String : Int] {
            return trackList[(index + 1) % 2]
        }
        
        func makePassThruLayerInstructionWithTrack(track: [String : Int])
        ->  [String : AnyObject] {
            return [
                MIJSONKeyMovieEditorLayerInstructionType :
                                    MIJSONValueMovieEditorPassthruInstruction,
                MIJSONPropertyMovieTrack : track
            ]
        }
        
        // lets start with the opacity ramp.
        
        let opacityRampLayerInstruction : [NSString : AnyObject] = [
            MIJSONKeyMovieEditorLayerInstructionType :
                                MIJSONValueMovieEditorOpacityRampInstruction,
            MIJSONPropertyMovieTrack : fromTrackForIndex(tIndex),
            MIJSONPropertyMovieEditorStartRampValue : 1.0,
            MIJSONPropertyMovieEditorEndRampValue : 0.0,
            MIJSONPropertyMovieTimeRange : makeTimeRangeStartingWith(2)
        ]
        
        let addOpacityRampInstructionCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueAddMovieInstruction as String,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTimeRange : makeTimeRangeStartingWith(2),
            MIJSONPropertyMovieEditorLayerInstructions : [
                opacityRampLayerInstruction,
                makePassThruLayerInstructionWithTrack(toTrackForIndex(tIndex))
            ]
        ]
        commandList.append(addOpacityRampInstructionCommand)
        ++tIndex
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(tIndex), startTime: tIndex * 2 + 1))

        // With the transform ramp, don't specify the time range in the layer
        // instruction because it should pick up the time range from the
        // instruction itself.
        
        // The start transform is just an identity matrix.
        let startTransform = [
            MIJSONKeyAffineTransformM11 : 1.0,
            MIJSONKeyAffineTransformM12 : 0.0,
            MIJSONKeyAffineTransformM21 : 0.0,
            MIJSONKeyAffineTransformM22 : 1.0,
            MIJSONKeyAffineTransformtX : 0.0,
            MIJSONKeyAffineTransformtY : 0.0
        ]
        
        // The end transform I'll generate using a scale and translate.
        
        let endTransform = [
            [
                MIJSONKeyTransformationType : MIJSONValueTranslate,
                MIJSONKeyTranslation : [
                    "x" : 0.75 * 1920.0,
                    "y" : 0.0
                ]
            ],
            [
                MIJSONKeyTransformationType : MIJSONValueScale,
                MIJSONKeyScale : [ "x" : 0.25, "y" : 0.25 ]
            ]
        ]
        
        let transformRampLayerInstruction : [NSString : AnyObject] = [
            MIJSONKeyMovieEditorLayerInstructionType :
                                MIJSONValueMovieEditorTransformRampInstruction,
            MIJSONPropertyMovieTrack : fromTrackForIndex(tIndex),
            MIJSONPropertyMovieEditorStartRampValue : startTransform,
            MIJSONPropertyMovieEditorEndRampValue : endTransform,
        ]
        
        let addTransformRampInstructionCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueAddMovieInstruction,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTimeRange : makeTimeRangeStartingWith(4),
            MIJSONPropertyMovieEditorLayerInstructions : [
                transformRampLayerInstruction,
                makePassThruLayerInstructionWithTrack(toTrackForIndex(tIndex))
            ]
        ]
        commandList.append(addTransformRampInstructionCommand)
        ++tIndex
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(tIndex), startTime: tIndex * 2 + 1))
        
        // Now the last ramp instruction. The crop instruction.
        // The start crop, doesn't crop anything.
        let startCrop = [
            MIJSONKeySize : [ MIJSONKeyWidth : 1920, MIJSONKeyHeight : 1080 ],
            MIJSONKeyOrigin : [ MIJSONKeyX : 0, MIJSONKeyY : 0]
        ]
        
        // The end crop is essentially empty, well not quite and centred.
        let endCrop = [
            MIJSONKeySize : [ MIJSONKeyWidth : 16, MIJSONKeyHeight : 9 ],
            MIJSONKeyOrigin : [ MIJSONKeyX : 952, MIJSONKeyY : 536]
        ]
        
        let cropRampLayerInstruction : [NSString : AnyObject] = [
            MIJSONKeyMovieEditorLayerInstructionType :
                                    MIJSONValueMovieEditorCropRampInstruction,
            MIJSONPropertyMovieTrack : fromTrackForIndex(tIndex),
            MIJSONPropertyMovieEditorStartRampValue : startCrop,
            MIJSONPropertyMovieEditorEndRampValue : endCrop,
            MIJSONPropertyMovieTimeRange : makeTimeRangeStartingWith(6)
        ]
        
        let addCropRampInstructionCommand : [String : AnyObject] = [
            MIJSONKeyCommand : MIJSONValueAddMovieInstruction as String,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTimeRange : makeTimeRangeStartingWith(6),
            MIJSONPropertyMovieEditorLayerInstructions : [
                cropRampLayerInstruction,
                makePassThruLayerInstructionWithTrack(toTrackForIndex(tIndex))
            ]
        ]
        commandList.append(addCropRampInstructionCommand)
        ++tIndex
        commandList.append(makePassthruInstructionCommandForTrack(
            trackForIndex(tIndex), startTime: tIndex * 2 + 1))

        let addEndInstructionCommand = [
            MIJSONKeyCommand : MIJSONValueAddMovieInstruction,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieTimeRange : [
                MIJSONPropertyMovieTimeRangeStart : makeTimeInSeconds(
                    numSegments * 2),
                MIJSONPropertyMovieTimeRangeDuration : instructionDuration
            ],
            MIJSONPropertyMovieEditorLayerInstructions : [
                makePassthruLayerInstructionForIndex(numSegments - 1)
            ]
        ]
        commandList.append(addEndInstructionCommand)

        let theUUID = CFUUIDCreate(kCFAllocatorDefault)
        let compositionMapKey = CFUUIDCreateString(kCFAllocatorDefault,
            theUUID) as String
        
        let assignCompositionMapImageToImageCollection = [
            MIJSONKeyCommand : MIJSONValueAssignImageToCollectionCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyImageIdentifier : compositionMapKey
        ]
        commandList.append(assignCompositionMapImageToImageCollection)

        let movieExportPath = GetMoviePathInMoviesDir(
            "movieeditor_videoramptransitions.mov")
        
        let exportMovieCommand = [
            MIJSONKeyCommand : MIJSONValueExportCommand,
            MIJSONKeyReceiverObject : movieEditorObject,
            MIJSONPropertyMovieExportPreset : AVAssetExportPreset1920x1080,
            MIJSONPropertyFileType : AVFileTypeQuickTimeMovie,
            MIJSONPropertyFile : movieExportPath,
        ]
        
        commandList.append(exportMovieCommand)
        let videoInstructionCommands = [
            MIJSONKeyCommands : commandList,
            MIJSONKeyCleanupCommands : cleanupCommands
        ]
        
        let theContext = MIContext()
        let instructionResult = MIMovingImagesHandleCommands(theContext,
            videoInstructionCommands, nil, nil)
        let theImage = theContext.getCGImageWithIdentifier(compositionMapKey)
        saveCGImageToAJPEGFile(theImage, baseName: "RampTransitionCompositionMap")
        theContext.removeImageWithIdentifier(compositionMapKey)
        let resultStr = MIGetStringFromReplyDictionary(instructionResult)
        print("Result: \(resultStr)")
        let errorCode = MIGetErrorCodeFromReplyDictionary(instructionResult)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error occured generating and creating movie with instructions.")
        #if os(iOS) && !arch(x86_64)
            let moviePath = GetMoviePathInMoviesDir(fileName:
            "movieeditor_videoramptransitions.mov")
            saveMovieFileToSharedPhotoLibrary(filePath: moviePath)
            
            // Now check to see if the file exists and delete it.
            let fm = NSFileManager.defaultManager()
            if (fm.fileExistsAtPath(moviePath))
            {
                fm.removeItemAtPath(moviePath, error: nil)
            }
        #endif
    }
}
