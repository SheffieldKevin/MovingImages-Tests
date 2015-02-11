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
        
        let result2 = MIMovingImagesHandleCommands(nil, commandsDict2, nil)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
        XCTAssertEqual(errorCode2.rawValue, 0,
            "Error adding an audio track to a movie editor.")
        
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
            XCTAssertEqual(resultValue.integerValue, 3,
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
        
        let result2 = MIMovingImagesHandleCommands(theContext, commandsDict2, nil)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
        XCTAssertEqual(errorCode2.rawValue, 0,
            "Error adding an audio track to a movie editor.")
        
        // Now add a video track with the persistent track id returned above.
        // This should produce an error as the track id is already used.
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
            "\"test003.movieeditor\",\"numberoftracks\":2,\"objectreference\"" +
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
            "2,\"languagecode\":\"\",\"languagetag\":\"\",\"affinetransform\"" +
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
        XCTAssertEqual(trackID.intValue, Int32(2),
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
        let result9 = MIMovingImagesHandleCommands(theContext, commandsDict9, nil)
        let errorCode9 = MIGetErrorCodeFromReplyDictionary(result9)
        XCTAssertEqual(errorCode9.rawValue,
            MIReplyErrorEnum.OperationFailed.rawValue,
            "Error getting properties from a movie editor.")
    }
}
