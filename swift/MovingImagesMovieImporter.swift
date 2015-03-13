//
//  MovingImagesMovieImporter.swift
//  MovingImagesFramework
//
//  Created by Kevin Meaney on 01/12/2014.
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

import Foundation
import ImageIO

#if os(iOS)
import UIKit
import MovingImagesiOS
#endif

import AVFoundation
import XCTest

let movieImporterName = "test001.movie"
let testBundle = NSBundle(forClass: MovingImagesMovieImporter.self)

class MovingImagesMovieImporter: XCTestCase {
    let theContext = MIContext()
    
    let movieURL = testBundle.URLForResource("410_clip4", withExtension:"mov")!
    
    let receiverObject = [ MIJSONKeyObjectType : MIMovieImporterKey,
                           MIJSONKeyObjectName : movieImporterName ]

    let trackIdentDict = [
        MIJSONPropertyMovieMediaCharacteristic : AVMediaCharacteristicVisual,
        MIJSONPropertyMovieTrackIndex : 0
    ]

    override func setUp() {
        super.setUp()
        
        let filePath = movieURL.path!
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCreateCommand,
                    MIJSONKeyObjectType : MIMovieImporterKey,
                    MIJSONPropertyFile : filePath,
                    MIJSONKeyObjectName : movieImporterName
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
                                            "Error createing movie importer")
    }
    
    override func tearDown() {
        // Now close the movie importer object and its asset.
        let commandsDict2 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCloseCommand,
                    MIJSONKeyReceiverObject : receiverObject
                ]
            ]
        ]
        let result2 = MIMovingImagesHandleCommands(theContext, commandsDict2,
            nil)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
        // We confirm that this works in a different test. But just do the check
        // anyway.
        XCTAssertEqual(errorCode2.rawValue, 0,
            "Error closing the movie importer object")
        super.tearDown()
    }
    
    func testGetMovieImporterObjectReference() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONKeyObjectReference,
                    MIJSONKeyReceiverObject : receiverObject
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting object reference of movie importer object")
        let resultValue = MIGetNumericReplyValueFromDictionary(result)!
        XCTAssertEqual(resultValue.integerValue, 0,
            "Movie importer object reference should be zero")
        // Since we have the movie importer object's reference get the
        // object name and object type.
        
        let receiverObject2 = [
            MIJSONKeyObjectReference : resultValue
        ]

        let commandsDict2 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONKeyObjectName,
                    MIJSONKeyReceiverObject : receiverObject2
                ]
            ]
        ]
        let result2 = MIMovingImagesHandleCommands(theContext, commandsDict2, nil)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
        XCTAssertEqual(errorCode2, MIReplyErrorEnum.NoError,
            "Error getting object name of movie importer object")
        let resultValue2 = MIGetStringFromReplyDictionary(result2)
        XCTAssertEqual(resultValue2, movieImporterName,
            "Movie importer object name should be name created with")

        let commandsDict3 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONKeyObjectType,
                    MIJSONKeyReceiverObject : receiverObject2
                ]
            ]
        ]
        let result3 = MIMovingImagesHandleCommands(theContext, commandsDict3, nil)
        let errorCode3 = MIGetErrorCodeFromReplyDictionary(result3)
        XCTAssertEqual(errorCode3, MIReplyErrorEnum.NoError,
            "Error getting object type of movie importer object")
        let resultValue3 = MIGetStringFromReplyDictionary(result3)
        XCTAssertEqual(resultValue3, String(MIMovieImporterKey),
            "Movie importer object type should be name created with")
    }

    func testGettingMovieMetadata() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieMetadata,
                    MIJSONKeyReceiverObject : receiverObject
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting movie metadata")
        let resultString = MIGetStringFromReplyDictionary(result)
        
        // A demonstration that you can save to your desktop from simulator.
        // resultString.writeToFile("/Users/ktam/Desktop/410_clip4_metadata.json",
        //    atomically: true, encoding: NSUTF8StringEncoding, error: nil)
        
        let jsonURL = testBundle.URLForResource("410_clip4_metadata",
            withExtension:"json")!
        let testResult = NSString(contentsOfFile: jsonURL.path!,
            encoding: NSUTF8StringEncoding, error: nil)!
        
        XCTAssert(resultString == testResult, "Metadata returned diff: " +
            resultString)
    }
    
    func testGettingNumberOfTracksInMovie() -> Void {
        // Now find out how many tracks in the movie asset. There should be 2
        // tracks, 1 video, 1 audio.
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieNumberOfTracks,
                    MIJSONKeyReceiverObject : receiverObject
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting number of tracks from a movie file")
        let resultValue = MIGetNumericReplyValueFromDictionary(result)!
        XCTAssertEqual(resultValue.integerValue, 2,
            "Number of tracks returned not equal to 2, the expected value")
    }

    func testGettingNumberOfFrameBasedTracksInMovie() -> Void {
        // Now find out how many tracks in the movie asset are frame based.
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieNumberOfTracks,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieMediaCharacteristic :
                                            AVMediaCharacteristicFrameBased
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting number of tracks from a movie file")
        let resultValue = MIGetNumericReplyValueFromDictionary(result)!
        XCTAssertEqual(resultValue.integerValue, 1,
            "Number of frame based tracks returned not equal to 1")
    }

    func testGetMovieDurationAsADictionaryRepresentation() -> Void {
        // Now get the movie duration as a JSON representation.
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieDuration,
                    MIJSONKeyReceiverObject : receiverObject
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting movie duration")
        let resultValue = MIGetStringFromReplyDictionary(result)
        let testResult = "{\"flags\":1,\"value\":6000,\"timescale\":600,\"epoch\":0}"
        XCTAssert(resultValue == testResult,
            "The movie length JSON representation different: " + resultValue)
    }

    func testGetMovieMetadataFormats() -> Void {
        // Now get the metadata formats.
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieMetadataFormats,
                    MIJSONKeyReceiverObject : receiverObject
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting number of tracks from a movie file")
        let resultValue = MIGetStringFromReplyDictionary(result)
        let testResult = "com.apple.quicktime.mdta com.apple.itunes " +
            "com.apple.quicktime.udta"
        XCTAssert(resultValue == testResult,
            "The movie metadata formats are different: " + resultValue)
    }

    func testGetMetadataThatConformsToAFormat() -> Void {
        // Now get the metadata that conforms to a metadata format.
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieMetadata,
                    MIJSONPropertyMovieMetadataFormats : "com.apple.itunes",
                    MIJSONKeyReceiverObject : receiverObject
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
                            "Error getting number of tracks from a movie file")
        let resultValue = MIGetStringFromReplyDictionary(result)
        let testResult = "[{\"key\":\"@cmt\",\"keyspace\":\"itsk\",\"stringValue\"" +
            ":\"iTunes metadata: Exported to preset AVAssetExportPreset640x480 " +
        "using avexporter at: 23 Nov 2014 13:05\"}]"
        XCTAssert(resultValue == testResult,
            "The metadata for format \"com.apple.itunes\" is diff: " + resultValue)
    }

    func testGetPropertiesFromAMovieImporter() -> Void {
        // Now get the movie importer object properties
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertiesCommand,
                    MIJSONKeySaveResultsType : MIJSONPropertyDictionaryObject,
                    MIJSONKeyReceiverObject : receiverObject
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting properties of a movie importer object.")
        let resultValue = MIGetDictionaryValueFromReplyDictionary(result)!
        let objectName:String = resultValue[MIJSONKeyObjectName] as! String
        XCTAssert(objectName == "test001.movie", "Object name different")
        let objectType:String = resultValue[MIJSONKeyObjectType] as! String
        XCTAssert(objectType == MIMovieImporterKey, "Object type different")
        let numTracks = resultValue[MIJSONPropertyMovieNumberOfTracks] as! NSNumber
        XCTAssert(numTracks.integerValue == 2, "Number of tracks should be 2")
    }
    
    func testGetPersistentTrackIDFromFirstVideoTrack() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieTrackID,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting a video track's persistent track id.")
        let numericResult = MIGetNumericReplyValueFromDictionary(result)!
        XCTAssertEqual(numericResult.integerValue, 2, "Persistent track ID diff")
    }
    
    func testGetTrackMediaTypeFromFirstVideoTrack() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieMediaType,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting media type of a track from a movie file")
        let mediaType = MIGetStringFromReplyDictionary(result)
        XCTAssertEqual(mediaType, "vide",
            "Media type returned is different: " + mediaType)
    }

    func testGetTrackFormatsFirstVideoTrack() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieMetadataFormats,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting formats from the first video track of a movie file")
        let formats = MIGetStringFromReplyDictionary(result)
        XCTAssertEqual(formats, "com.apple.quicktime.udta",
            "Format returned is different")
    }

    func testGetIsFirstVideoTrackEnabled() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieTrackEnabled,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting whether the first video track is enabled.")
        let isEnabledStr = MIGetStringFromReplyDictionary(result)
        XCTAssertEqual(isEnabledStr, "YES",
            "First video track is enabled is different")
        let isEnabled = MIGetNumericReplyValueFromDictionary(result)!
        XCTAssertEqual(isEnabled.boolValue, true, "isEnabled should be true")
    }

    func testGetFirstVideoTrackTimeRange() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieTimeRange,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting the time range of first video track in movie.")
        let trackTimeRange = MIGetStringFromReplyDictionary(result)
        XCTAssertEqual(trackTimeRange,
            "{\"start\":{\"flags\":1,\"value\":0,\"timescale\":600," +
            "\"epoch\":0},\"duration\":{\"flags\":1,\"value\":6000,\"timescale\"" +
            ":600,\"epoch\":0}}",
            "Track time range is different")
    }

    func testGetFirstVideoTrackLanguageCode() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieLanguageCode,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting language code of first video track in movie.")
        let languageCode = MIGetStringFromReplyDictionary(result)
        XCTAssertEqual(languageCode, "eng",
            "Language code is different")
    }

    func testGetFirstVideoTrackExtendedLanguageTag() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieExtendedLanguageTag,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting language code of first video track in movie.")
        let languageTag = MIGetStringFromReplyDictionary(result)
        XCTAssertEqual(languageTag, "",
            "Language tag is different")
    }

    func testGetFirstAudioTrackExtendedLanguageTag() -> Void {
        let audioTrackIdentDict = [
            MIJSONPropertyMovieMediaCharacteristic : AVMediaCharacteristicAudible,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieExtendedLanguageTag,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : audioTrackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting language code of first audio track in movie.")
        let languageTag = MIGetStringFromReplyDictionary(result)
        XCTAssertEqual(languageTag, "",
            "Language tag of audio track is different")
    }
    
    func testGetFirstVideoTrackNaturalSize() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieTrackNaturalSize,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting natural size of first video track in movie.")
        let naturalSize = MIGetStringFromReplyDictionary(result)
        XCTAssertEqual(naturalSize,
            "{\"width\":576,\"height\":360}",
            "Natural size is different")
    }

    func testGetFirstAudioTrackNaturalSize() -> Void {
        let audioTrackIdentDict = [
            MIJSONPropertyMovieMediaCharacteristic : AVMediaCharacteristicAudible,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieTrackNaturalSize,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : audioTrackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.InvalidProperty,
            "A track that is audible shouldn't have a natural size.")
    }

    func testGetFirstVideoTrackAffineTransform() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONKeyAffineTransform,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting affine transform of first video track in movie.")
        let affineTransform = MIGetStringFromReplyDictionary(result)
        XCTAssertEqual(affineTransform,
            "{\"m12\":0,\"m21\":0,\"m22\":1,\"tY\":0,\"m11\":1,\"tX\":0}",
            "Affine transform for first video track of movie is different")
    }

    func testGetFirstAudioTrackPreferredVolume() -> Void {
        let audioTrackIdentDict = [
            MIJSONPropertyMovieMediaCharacteristic : AVMediaCharacteristicAudible,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONKeyMovieTrackPreferredVolume,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : audioTrackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Failed for getting the preferred volume of an audio track.")
        let volume = MIGetNumericReplyValueFromDictionary(result)!
        XCTAssertEqual(volume.doubleValue, 1.0000,
            "The preferred volume of the audible track should be 1.")
    }

    func testGetFirstVideoTrackFrameRate() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieTrackNominalFrameRate,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Failed to getting the video track's nominal frame rate.")
        let nomFrameRate = MIGetNumericReplyValueFromDictionary(result)!
        XCTAssertEqual(nomFrameRate.doubleValue, 24.0,
            "The nominal frame rate of the first video track is different.")
    }

    func testGetFirstVideoTrackMinFrameDuration() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieTrackMinFrameDuration,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Assertion failed for getting the video track's min frame duration.")
        let minFrameDur = MIGetStringFromReplyDictionary(result)
        XCTAssertEqual(minFrameDur,
            "{\"flags\":1,\"value\":25,\"timescale\":600,\"epoch\":0}",
            "The min frame duration of the first video track is different.")
    }

    func testGetFirstVideoTrackRequiresFrameReordering() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey :
                                MIJSONPropertyMovieTrackRequiresFrameReordering,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting whether frames will need reordering.")
        let isEnabledStr = MIGetStringFromReplyDictionary(result)
        XCTAssertEqual(isEnabledStr, "NO",
            "First video track requires frame reodering is different")
        let isEnabled = MIGetNumericReplyValueFromDictionary(result)!
        XCTAssertEqual(isEnabled.boolValue, false, "frame reordering should be false")
    }

    func testGetFirstVideoTrackSegmentsTimeMappings() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieTrackSegmentMappings,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil);
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Assertion failed for getting the video track's segment mappings.")
        let mappings = MIGetStringFromReplyDictionary(result)
        XCTAssertEqual(mappings,
            "[{\"sourcetimerange\":{\"start\":{\"flags\":1,\"value\":0," +
            "\"timescale\":600,\"epoch\":0},\"duration\":{\"flags\":1,\"value\"" +
            ":6000,\"timescale\":600,\"epoch\":0}},\"targettimerange\":{\"start\"" +
            ":{\"flags\":1,\"value\":0,\"timescale\":600,\"epoch\":0},\"duration\"" +
            ":{\"flags\":1,\"value\":6000,\"timescale\":600,\"epoch\":0}}}]",
            "The segments mappings are different.")
    }

    func testGetVideoTrackMovieMetadataFormats() -> Void {
        // Now get the metadata formats.
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieMetadataFormats,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting number of tracks from a movie file")
        let resultValue = MIGetStringFromReplyDictionary(result)
        let testResult = "com.apple.quicktime.udta"
        XCTAssert(resultValue == testResult,
            "The movie metadata formats are different: " + resultValue)
    }

    func testGetVideoTrackMetadataThatConformsToAFormat() -> Void {
        // Now get the metadata that conforms to a metadata format.
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieMetadata,
                    MIJSONPropertyMovieMetadataFormats :
                                            "com.apple.quicktime.udta",
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting number of tracks from a movie file")
        let resultValue = MIGetStringFromReplyDictionary(result)
        let testResult = "[{\"key\":\"Omud\",\"keyspace\":\"udta\"}]"
        XCTAssert(resultValue == testResult,
            "The metadata for format \"com.apple.quicktime.udta\" is diff: " +
            resultValue)
    }

    func testGetVideoTrackMetadata() -> Void {
        // Now get the metadata that conforms to a metadata format.
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieMetadata,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting number of tracks from a movie file")
        let resultValue = MIGetStringFromReplyDictionary(result)
        let testResult = "[{\"key\":\"Omud\",\"keyspace\":\"udta\"}]"
        XCTAssert(resultValue == testResult,
            "The metadata for format \"com.apple.quicktime.udta\" is diff: " +
            resultValue)
    }

    func testGetAudioTrackMovieMetadataFormats() -> Void {
        // Now get the metadata formats.
        let audioTrackIdentDict = [
            MIJSONPropertyMovieMediaCharacteristic : AVMediaCharacteristicAudible,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieMetadataFormats,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : audioTrackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting metadata formats from audio track")
        let resultValue = MIGetStringFromReplyDictionary(result)
        let testResult = "com.apple.quicktime.udta"
        XCTAssert(resultValue == testResult,
            "The movie metadata formats are different: " + resultValue)
    }
    
    func testGetAudioTrackMetadataThatConformsToAFormat() -> Void {
        // Now get the metadata that conforms to a metadata format.
        let audioTrackIdentDict = [
            MIJSONPropertyMovieMediaCharacteristic : AVMediaCharacteristicAudible,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieMetadata,
                    MIJSONPropertyMovieMetadataFormats :
                                                "com.apple.quicktime.udta",
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : audioTrackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting metadata for format.")
        let resultValue = MIGetStringFromReplyDictionary(result)
        let testResult = "[{\"key\":\"Omud\",\"keyspace\":\"udta\"}]"
        XCTAssert(resultValue == testResult,
            "The metadata for format \"com.apple.quicktime.udta\" is diff: " +
            resultValue)
    }

    func testGetAudioTrackMetadata() -> Void {
        // Now get the metadata that conforms to a metadata format.
        let audioTrackIdentDict = [
            MIJSONPropertyMovieMediaCharacteristic : AVMediaCharacteristicAudible,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieMetadata,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : audioTrackIdentDict
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting audio track metadata from a movie file")
        let resultValue = MIGetStringFromReplyDictionary(result)
        let testResult = "[{\"key\":\"Omud\",\"keyspace\":\"udta\"}]"
        XCTAssert(resultValue == testResult,
            "The metadata for format \"com.apple.quicktime.udta\" is diff: " +
            resultValue)
    }

    func testGetVideoTrackProperties() -> Void {
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertiesCommand,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : trackIdentDict,
                    MIJSONKeySaveResultsType : MIJSONPropertyJSONString
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting video track properties")
        let resultValue = MIGetStringFromReplyDictionary(result)
        let jsonURL = testBundle.URLForResource("410_clip4_videotrack_properties",
            withExtension:"json")!
        let testResult = NSString(contentsOfFile: jsonURL.path!,
            encoding: NSUTF8StringEncoding, error: nil)!
        XCTAssert(resultValue == testResult,
            "The properties for the first video track is diff: " +
            resultValue)
    }

    func testGetAudioTrackProperties() -> Void {
        let audioTrackIdentDict = [
            MIJSONPropertyMovieMediaCharacteristic : AVMediaCharacteristicAudible,
            MIJSONPropertyMovieTrackIndex : 0
        ]
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertiesCommand,
                    MIJSONKeyReceiverObject : receiverObject,
                    MIJSONPropertyMovieTrack : audioTrackIdentDict,
                    MIJSONKeySaveResultsType : MIJSONPropertyJSONString
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting audio track properties")
        let resultValue = MIGetStringFromReplyDictionary(result)
        let jsonURL = testBundle.URLForResource("410_clip4_audiotrack_properties",
            withExtension:"json")!
        let testResult = NSString(contentsOfFile: jsonURL.path!,
            encoding: NSUTF8StringEncoding, error: nil)!
        XCTAssert(resultValue == testResult,
            "The properties for the first audio track is diff: " +
            resultValue)
    }

    func testGetMovieFrameAt5Secs() -> Void {
        let frameTime = CMTimeMake(3000, 600)
        let frameTimeDict = CMTimeCopyAsDictionary(frameTime, kCFAllocatorDefault)
        let options = [
            MIJSONPropertyMovieFrameTime : frameTimeDict
        ]
        let frameGrab = MICGImageFromObjectAndOptions(
                        theContext, receiverObject, options, nil)!
        let theImage = createCGImageFromNamedFile("FrameAt5Secs",
            fileExtension:"png")!
        let sameMeta = doImagesHaveSameMeta(image1: frameGrab.CGImage()!,
            image2: theImage)
        XCTAssert(sameMeta,
                        "Frame grab and image should have same basic meta data")
        #if os(OSX)
        if sameMeta {
            let theDiff = compareImages(image1: frameGrab.CGImage()!,
                image2: theImage)
            XCTAssert(theDiff < 54,
                                "Images have different pixel values \(theDiff)")
        }
        #endif
    }

    func testGetMovieFrameAt5Secs2() -> Void {
        let frameTime = 5.0
        let options = [
            MIJSONPropertyMovieFrameTime : [ MIJSONPropertyMovieTime : frameTime ]
        ]
        let frameGrab = MICGImageFromObjectAndOptions(
            theContext, receiverObject, options, nil)!
        let theImage = createCGImageFromNamedFile("FrameAt5Secs",
            fileExtension:"png")!
        let sameMeta = doImagesHaveSameMeta(image1: frameGrab.CGImage()!,
            image2: theImage)
        XCTAssert(sameMeta,
            "Frame grab and image should have same basic meta data")
        #if os(OSX)
        if sameMeta {
            let theDiff = compareImages(image1: frameGrab.CGImage()!,
                image2: theImage)
            XCTAssert(theDiff < 54,
                                "Images have different pixel values \(theDiff)")
        }
        #endif
    }

    func testGetMovieFrameFromTrackAt5Secs() -> Void {
        let frameTime = 5.0
        let tracks = [ trackIdentDict ]
        let options : [NSString : AnyObject] = [
            MIJSONPropertyMovieFrameTime : [ MIJSONPropertyMovieTime : frameTime ],
            MIJSONPropertyMovieTracks : tracks
        ]
        let frameGrab = MICGImageFromObjectAndOptions(
            theContext, receiverObject, options, nil)!
        let theImage = createCGImageFromNamedFile("FrameAt5Secs",
                                    fileExtension:"png")!
        let sameMeta = doImagesHaveSameMeta(image1: frameGrab.CGImage()!,
            image2: theImage)
        XCTAssert(sameMeta,
            "Frame grab and image should have same basic meta data")
        #if os(OSX)
        if sameMeta {
            let theDiff = compareImages(image1: frameGrab.CGImage()!,
                image2: theImage)
            XCTAssert(theDiff < 54,
                "Images have different pixel values \(theDiff)")
        }
        #endif
    }

    func testGetMovieFrameNextSample3Times() -> Void {
        let frameTime = 0.0
        let tracks = [ trackIdentDict ]
        let options : [NSString : AnyObject] = [
            MIJSONPropertyMovieFrameTime : MIJSONValueMovieNextSample,
            MIJSONPropertyMovieTracks : tracks
        ]

        let frameGrab = MICGImageFromObjectAndOptions(
            theContext, receiverObject, options, nil)
        let frameGrab2 = MICGImageFromObjectAndOptions(
            theContext, receiverObject, options, nil)
        let frameGrab3 = MICGImageFromObjectAndOptions(
            theContext, receiverObject, options, nil)
        
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieCurrentTime,
                    MIJSONKeyReceiverObject : receiverObject
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode, MIReplyErrorEnum.NoError,
            "Error getting object reference of movie importer object")
        let resultString = MIGetStringFromReplyDictionary(result)
        #if os(iOS) && arch(arm64)
        XCTAssertEqual(resultString, "{\"flags\":1,\"value\":7500," +
        "\"timescale\":90000,\"epoch\":0}", resultString)
        #else
        XCTAssertEqual(resultString, "{\"flags\":3,\"value\":7500," +
            "\"timescale\":90000,\"epoch\":0}", resultString)
        #endif
    }
}
