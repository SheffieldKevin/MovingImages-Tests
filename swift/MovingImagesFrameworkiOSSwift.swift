//
//  MovingImagesFrameworkiOSSwift.swift
//  MovingImagesFramework
//
//  Created by Kevin Meaney on 08/10/2014.
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

#if os(iOS)
import UIKit
import MovingImagesiOS
import Photos
#endif

import XCTest
import Foundation
import ImageIO
import AVFoundation

func GetImageFileURL() -> NSURL? {
    let fm = NSFileManager.defaultManager()
    var error:NSError?
    
    #if os(iOS)
        return fm.URLForDirectory(NSSearchPathDirectory.CachesDirectory,
        inDomain: NSSearchPathDomainMask.UserDomainMask,
        appropriateForURL: .None,
        create: false,
        error: &error)
    #else
        return fm.URLForDirectory(NSSearchPathDirectory.PicturesDirectory,
            inDomain: NSSearchPathDomainMask.UserDomainMask,
            appropriateForURL: .None,
            create: false,
            error: &error)
    #endif
}

func GetImageFilePathInPictures(fileName: String = "videowriter.mov") -> String {
    return GetImageFileURL()!.path! + "/" + fileName
}

#if os(iOS)
func saveImageFileToSharedPhotoLibrary(#filePath: String) -> Void {
    let url = NSURL.fileURLWithPath(filePath)
    
    let wait = dispatch_semaphore_create(0)
    PHPhotoLibrary.sharedPhotoLibrary().performChanges({
        let request =
            PHAssetChangeRequest.creationRequestForAssetFromImageAtFileURL(url)
        },
        completionHandler: { success, error in
            dispatch_semaphore_signal(wait)
            Void.self
    })
    dispatch_semaphore_wait(wait, DISPATCH_TIME_FOREVER)
}
#endif

class MovingImagesFrameworkiOSSwift: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }

    class func createDictionaryFromJSON(jsonFileName: NSString) -> NSDictionary {
        let testBundle = NSBundle(forClass: MovingImagesFrameworkiOSSwift.self)
        let jsonURL = testBundle.URLForResource(jsonFileName,
                                                withExtension:"json")!
        let inStream = NSInputStream(URL: jsonURL)!
        inStream.open()
        var jsonReadingError:NSError?
        let container:[NSString : NSObject] =
        NSJSONSerialization.JSONObjectWithStream(inStream,
            options: NSJSONReadingOptions.allZeros,
            error: &jsonReadingError) as [NSString : NSObject]
        return container
    }

    func testHandleGetVersionCommand() -> Void {
        let commandDict = [ MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyVersion ]
        let resultDict = MIMovingImagesHandleCommand(nil, commandDict)
        let resultString = MIGetStringFromReplyDictionary(resultDict)
        XCTAssertEqual(resultString, "0.3a", "Version numbers differ")
    }

    func testHandleGet0NumberOfObjectCommand() -> Void {
        let commandDict = [ MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyNumberOfObjects ]
        let resultDict = MIMovingImagesHandleCommand(nil, commandDict)
        let resultString = MIGetStringFromReplyDictionary(resultDict)
        XCTAssertEqual(resultString, "0", "Number of objects differ")
    }

    func testHandleCreateBitmapContextAndGetPropertiesCommand() -> Void {
        // Create the bitmap context
        let commandDict = [ MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MICGBitmapContextKey,
            MIJSONKeyObjectName : "my.test.bitmapcontext",
            MIJSONKeySize : [
                MIJSONKeyHeight : 200,
                MIJSONKeyWidth : 400
            ],
            MIJSONPropertyPreset : MIAlphaPreMulFirstRGB8bpc32bppInteger
        ]
        let resultDict = MIMovingImagesHandleCommand(nil, commandDict)

        // Creating the context should have worked, check that here.
        let errorCode = MIGetErrorCodeFromReplyDictionary(resultDict)
        XCTAssertEqual(errorCode.rawValue, 0,
                       "Expected no error creating bitmap context")
        let objectReference = MIGetNumericReplyValueFromDictionary(resultDict)
        
        // Get properties from the context, first get the height.
        let getWidthDict = [ MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONKeyReceiverObject :
                            [ MIJSONKeyObjectReference : objectReference],
            MIJSONPropertyKey : MIJSONKeyHeight ]
        let heightResultDict = MIMovingImagesHandleCommand(nil, getWidthDict)

        // Check that there was no error getting the context height.
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(heightResultDict)
        XCTAssertEqual(errorCode2.rawValue, 0, "Expected no error getting height")
        let contextHeight = MIGetNumericReplyValueFromDictionary(heightResultDict)
        XCTAssertEqual(contextHeight.integerValue, 200)

        // Lets now refer to the context by type and name, and get the preset.
        // The preset should be the same as that used to create the context
        let getPresetDict = [ MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
            MIJSONKeyReceiverObject :
              [ MIJSONKeyObjectType : MICGBitmapContextKey,
                MIJSONKeyObjectName : "my.test.bitmapcontext" ],
                  MIJSONPropertyKey : MIJSONPropertyPreset ]
        let presetResultDict = MIMovingImagesHandleCommand(nil, getPresetDict)
        let errorCode3 = MIGetErrorCodeFromReplyDictionary(presetResultDict)
        XCTAssertEqual(errorCode3.rawValue, 0,
                                "Expected no error getting context preset");
        let preset = MIGetStringFromReplyDictionary(presetResultDict)!
        XCTAssertEqual(MIAlphaPreMulFirstRGB8bpc32bppInteger, preset,
                            "Context preset different to preset used to create")

        // Close the object at end of this so as not to break other tests.
        MIMovingImagesHandleCommand(nil,
        [ MIJSONKeyCommand : MIJSONValueCloseCommand, MIJSONKeyReceiverObject :
                            [ MIJSONKeyObjectReference : objectReference ]])
    }

    func testCleanupCommandsClosesObject() -> Void {
        let createBitmapContext = [ MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MICGBitmapContextKey,
            MIJSONKeyObjectName : "my.test.bitmapcontext",
            MIJSONKeySize : [
                MIJSONKeyHeight : 200,
                MIJSONKeyWidth : 400
            ],
            MIJSONPropertyPreset : MIAlphaPreMulFirstRGB8bpc32bppInteger
        ]
        let bitmapObject = [ MIJSONKeyObjectType : MICGBitmapContextKey,
            MIJSONKeyObjectName : "my.test.bitmapcontext"]
        let closeCommand = [ MIJSONKeyCommand : MIJSONValueCloseCommand,
            MIJSONKeyReceiverObject : bitmapObject ]
        let theCommands = [ MIJSONKeyCommands : [ createBitmapContext ],
            MIJSONKeyCleanupCommands : [ closeCommand] ]
        let resultDict = MIMovingImagesHandleCommands(nil, theCommands, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(resultDict)
        XCTAssertEqual(errorCode.rawValue, 0,
                                        "Error creating/close bitmap context")
        let getNumObjectsCommand = [ MIJSONKeyCommand :
                                            MIJSONValueGetPropertyCommand,
            MIJSONPropertyKey : MIJSONPropertyNumberOfObjects,
            MIJSONKeyObjectType : MICGBitmapContextKey
        ]
        let numResultsDict = MIMovingImagesHandleCommand(nil, getNumObjectsCommand)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(numResultsDict)
        XCTAssertEqual(errorCode2.rawValue, 0,
                        "Error getting number of bitmap context objects")
        let numObjects = MIGetNumericReplyValueFromDictionary(numResultsDict)
        XCTAssertEqual(numObjects.integerValue, 0,
                        "Closeing bitmap object failed")
    }

// Test the shape drawing performance into a bitmap context.
// The ruby code that generated the json is below
/*
    #!/usr/bin/env ruby
    
    require 'moving_images'
    
    include MovingImages
    
    module MovingImagesPerformance
    def self.create_drawarrayofequationrectanglescommand(receiver_object,
    number_of_rectangles: 100)
    arrayofelements = MIDrawElement.new(:arrayofelements)
    number_of_rectangles.times do
    drawrectangle_element = MIDrawElement.new(:fillpath)
    rounded_rect_path = MIPath.new
    the_rect = MIShapes.make_rectangle(xloc: "10 + $xloc + 100 * #{Random.rand}",
    yloc: "10 + $yloc + 100 * #{Random.rand}",
    width: "40 + $width + 300 * #{Random.rand}",
    height: "30 + $height + 200 * #{Random.rand}")
    radiuses = [ "1 + $radius1 + 10.0 * #{Random.rand}",
    "1 + $radius2 + 10.0 * #{Random.rand}",
    "1 + $radius3 + 10.0 * #{Random.rand}",
    "1 + $radius4 + 10.0 * #{Random.rand}" ]
    rounded_rect_path.add_roundedrectangle_withradiuses(the_rect,
    radiuses: radiuses)
    drawrectangle_element.arrayofpathelements = rounded_rect_path
    drawrectangle_element.startpoint = MIShapes.make_point(0, 0)
    drawrectangle_element.fillcolor = MIColor.make_rgbacolor(
    Random.rand, Random.rand, Random.rand)
    arrayofelements.add_drawelement_toarrayofelements(drawrectangle_element)
    end
    CommandModule.make_drawelement(receiver_object,
    drawinstructions: arrayofelements)
    end
    end
    
    smig_commands = CommandModule::SmigCommands.new
    bitmap_object = smig_commands.make_createbitmapcontext(addtocleanup: true)
    draw_cmd = MovingImagesPerformance.create_drawarrayofequationrectanglescommand(
    bitmap_object, number_of_rectangles: 10)
    variables_dict = { xloc: 30.0, yloc: 20.0,
    width: 40.0, height: 30,
    radius1: 2.0, radius2: 4.0,
    radius3: 8.0, radius4: 16.0 }
    smig_commands.add_command(draw_cmd)
    smig_commands.variables = variables_dict
    
    jsonString = JSON.pretty_generate(smig_commands.commandshash)
    filePath = "/Users/ktam/Documents/draw_elements.json"
    open(filePath, 'w') { |f| f.puts jsonString }
*/
    func testRoundedRectShapeDrawingPerformance() {
        let commandDict = MovingImagesFrameworkiOSSwift.createDictionaryFromJSON(
                            "draw_elements")
        self.measureBlock() {
            let commandResult = MIMovingImagesHandleCommands(nil, commandDict, nil)
        }
    }

    func testRoundedRectShapeDrawingUsingAMIContext() {
        let commandDict = MovingImagesFrameworkiOSSwift.createDictionaryFromJSON(
            "draw_elements")
        let theContext:MIContext = MICreateContext()
        let commandResult = MIMovingImagesHandleCommands(theContext, commandDict,
            nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(commandResult)
        XCTAssertEqual(errorCode.rawValue, 0,
            "Error running commands in context")
    }


    func testDrawingCIBloomCIFilter() {
        let tempDict = MovingImagesFrameworkiOSSwift.createDictionaryFromJSON(
            "coreimage_cibloom")
        
        let fileURL = makeURLFromNamedFile("DSCN0724", fileExtension: "JPG")
        let filePath = fileURL.path!
        let outPath = GetImageFilePathInPictures(fileName: "DSCN0724CIBloom.jpg")
        let variablesDict = [
            "test.inputimage.coreimage.cibloom" : filePath,
            "test.outputimage.coreimage.cibloom" : outPath
        ]
        
        let commandDict:[String : AnyObject] = [
            "commands" : tempDict["commands"]!,
            "runasynchronously" : false,
            "variables" : variablesDict
        ]
        let theContext:MIContext = MICreateContext()
        let commandResult = MIMovingImagesHandleCommands(theContext, commandDict,
            nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(commandResult)
        XCTAssertEqual(errorCode.rawValue, 0,
            "Error using the CIBloom filter.")
        if (errorCode == MIReplyErrorEnum.NoError)
        {
            #if os(iOS)
                saveImageFileToSharedPhotoLibrary(filePath: outPath)
                
                // Now check to see if the file exists and delete it.
                let fm = NSFileManager.defaultManager()
                if (fm.fileExistsAtPath(outPath))
                {
                    fm.removeItemAtPath(outPath, error: nil)
                }
            #endif
        }
        else
        {
            println(MIGetStringFromReplyDictionary(commandResult))
        }

    }

    // Check that running commands asynchronously works as expected.
    // The input json data was generated using a ruby script very similar to the
    // one for the performance measurement test. The difference being the number
    // of rectangles drawn is 400 instead of 200 and run_asynchronously was set
    // to try for the smig_commands object:
    // smig_commands.run_asynchronously = true
    // The performance is quite slow. There are 11 equations to be evaluated for
    // each rounded rectangle to be drawn. Drawing round cornered rectangles
    // without 11 equations to evaluate is about 10 times faster.
    func testAsynchronousShapeDrawing() -> Void {
        let container = MovingImagesFrameworkiOSSwift.createDictionaryFromJSON(
                                                "drawelements_asynchronous")
        let expectation = self.expectationWithDescription(
                                    "Rounded rectangle with equation drawing")
        MIMovingImagesHandleCommands(nil, container) {
            (replyDict: [NSObject : AnyObject]!) -> Void in
            let result = MIGetErrorCodeFromReplyDictionary(replyDict)
            XCTAssert(result == MIReplyErrorEnum.NoError,
                "Drawing rounded rectangle with equations failed")
            expectation.fulfill()
        }
        self.waitForExpectationsWithTimeout(2.0, handler:nil)
    }

// The ruby code that generated the draw_bundleimage1/2 json is below
/*
#!/usr/bin/env ruby

require 'moving_images'

include MovingImages

smig_commands = CommandModule::SmigCommands.new
bitmap_object = smig_commands.make_createbitmapcontext(addtocleanup: false,
                                          size: MIShapes.make_size(908, 681),
                                          name: :movingimages_framework_test)

jsonString = JSON.pretty_generate(smig_commands.commandshash)
filePath = File.expand_path("~/Documents/draw_bundleimage1.json")
open(filePath, 'w') { |f| f.puts jsonString }
*/
    
/*
#!/usr/bin/env ruby

require 'moving_images'

include MovingImages

module MovingImagesPerformance
  def self.create_drawbundleimage_command(bitmap_object, imageident: "")
    image_identifier = SmigIDHash.make_bundle_imageidentifier(imagename)    
    draw_image_element = MIDrawImageElement.new()
    draw_image_element.set_imagecollection_imagesource(identifier: imageident)
    draw_image_element.destinationrectangle = MIShapes.make_rectangle(
                                                xloc: 0,
                                                yloc: 0,
                                                width: 908,
                                                height: 681)
    CommandModule.make_drawelement(bitmap_object,
                                   drawinstructions: draw_image_element)
  end
end

smig_commands = CommandModule::SmigCommands.new
bitmap_object = SmigIDHash.make_objectid(objecttype: :bitmapcontext,
                                         objectname: :movingimages_framework_test)

draw_cmd = MovingImagesPerformance.create_drawbundleimage_command(bitmap_object,
                    imageident: "yvs.movingimages.framework.tests.imageident1")
smig_commands.add_command(draw_cmd)

jsonString = JSON.pretty_generate(smig_commands.commandshash)
filePath = File.expand_path("~/Documents/draw_bundleimage2.json")
open(filePath, 'w') { |f| f.puts jsonString }
*/

    func testDrawingABundleImage() -> Void {
        let commandDict1 = MovingImagesFrameworkiOSSwift.createDictionaryFromJSON(
                                                "draw_bundleimage1")
        let result = MIMovingImagesHandleCommands(nil, commandDict1, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0, "Error creating the bitmap context")
        let objectDict = ["objecttype":"bitmapcontext",
            "objectname":"movingimages_framework_test"]
        
        let theContext = MIContext.defaultContext()
        let imageID = "yvs.movingimages.framework.tests.imageident1"
        let image = createCGImageFromNamedJPEGImage("curlycat")
        theContext.assignCGImage(image, identifier: imageID)
        let commandDict2 = MovingImagesFrameworkiOSSwift.createDictionaryFromJSON(
                                                "draw_bundleimage2")
        let result2 = MIMovingImagesHandleCommands(theContext, commandDict2, nil)
        theContext.removeImageWithIdentifier(imageID)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
        XCTAssertEqual(errorCode2.rawValue, 0, "Error drawing bundle image.")
    }

    //MARK: Testing the movie importer object and class
    func testGetMovieAudioVisualImportTypes() -> Void {
        let commandsDict = [
            "commands" : [
                [
                    "command" : "getproperty",
                    "objecttype" : "movieimporter",
                    "propertykey" : "movieimporttypes"
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(nil, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0,
                        "Error getting list movie import types")
        let resultString = MIGetStringFromReplyDictionary(result)
#if os(iOS)
        let testString = "dyn.agq80c6durvy0g2pyrf106p52fz01a3phsz3g2 " +
                         "dyn.age81s3pcs34hk dyn.age804qpb " +
                         "dyn.agq80c7perf1w88brry4ha " +
                         "public.avi public.aifc-audio public.aac-audio " +
                         "public.mpeg-4 public.m3u-playlist " +
                         "dyn.agq80c7perf1w865dsb0hg com.apple.m4v-video " +
                         "public.au-audio dyn.agq80c7perf1w88brqru0q " +
                         "public.aiff-audio com.apple.quicktime-movie " +
                         "dyn.age8046p0 com.apple.mpeg-4-ringtone " +
                         "com.microsoft.waveform-audio public.mp2 " +
                         "dyn.agq80c6durvy0g2pyrf106p5rsa4a public.pls-playlist " +
                         "dyn.agq80c7perf1w82pbqr2a com.apple.m4a-audio " +
                         "public.3gpp2 org.3gpp.adaptive-multi-rate-audio " +
                         "public.ac3-audio com.apple.coreaudio-format " +
                         "public.mp3 dyn.age81q7dy dyn.agq81k3p2su11q7dy " +
                         "com.apple.protected-mpeg-4-audio " +
                         "dyn.agq80c7perf1w88brry4ge dyn.age8046db " +
                         "dyn.age804qxb dyn.agq80c7perf1w88brs7u1q " +
                         "dyn.age8046bv public.3gpp com.apple.itunes.audible " +
                         "public.mpeg-4-audio"
#else
        let testString = "public.mpeg dyn.agq81q4peqz1w88brrz2de7a dyn.agq80c6durvy0g2pyrf106p5rsa4a public.dv-movie public.pls-playlist dyn.age804qxb dyn.agq80c6durvy0g2pyrf106p52fz01a3phsz3g2 public.aifc-audio com.apple.mpeg-4-ringtone dyn.agq80c7perf1w865dsb0hg com.microsoft.waveform-audio public.3gpp public.3gpp2 dyn.age81s3pcs34hk dyn.agq80c7perf1w88brry4ge dyn.agq80c7perf1w88brs7u1q dyn.agq81q4peqz1w85pugf3u public.avi dyn.agq81q4peqz1w85mwsv3u dyn.agq80c7perf1w88brqru0q com.apple.itunes.audible public.aac-audio dyn.age80455e dyn.age81q7dy dyn.agq81q4peqz1w85pugm4a dyn.age8046p0 dyn.age8047dx public.m3u-playlist com.apple.quicktime-movie public.aiff-audio dyn.agq81q4peqz1w88brrz2gn33w dyn.agq80c7perf1w82pbqr2a com.apple.m4v-video org.3gpp.adaptive-multi-rate-audio dyn.age8046db dyn.agq81q4peqz1w85pugm2a dyn.agq81q4peqz1w83d0 com.apple.coreaudio-format com.apple.itunes.m3u-playlist com.apple.m4a-audio com.apple.itunes.mp2 public.mpeg-4-audio dyn.age804qxysq dyn.agq81k3p2su11q7dy dyn.age81q55c public.mpeg-2-video dyn.age8046bv public.mpeg-4 public.mp2 dyn.agq81q4peqz1w88brry3hk62 dyn.age804qpb public.mp3 dyn.age804qxy public.au-audio public.mpeg-2-transport-stream public.ac3-audio dyn.agq80c7perf1w88brry4ha dyn.agq81q4peqz1w88brrz2dc62 com.apple.protected-mpeg-4-audio com.apple.itunes.pls-playlist dyn.agq81q4peqz1w88brrz2de6a"
#endif
        XCTAssert(resultString == testString, "Different list of movie types: " +
            resultString)
    }

    func testGetMovieAudioVisualMovieImportTypes() -> Void {
        let commandsDict = [
            "commands" : [
                [
                    "command" : "getproperty",
                    "objecttype" : "movieimporter",
                    "propertykey" : "movieimportmimetypes"
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(nil, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0,
                       "Error getting list movie import types")
        let resultString = MIGetStringFromReplyDictionary(result)
#if os(iOS)
        let testString = "audio/aacp video/3gpp2 audio/mpeg3 audio/mp3 " +
                         "audio/x-caf audio/mpeg video/quicktime audio/x-mpeg3 " +
                         "video/mp4 audio/wav video/avi audio/scpls audio/mp4 " +
                         "audio/x-mpg video/x-m4v audio/x-wav audio/x-aiff " +
                         "application/vnd.apple.mpegurl video/3gpp text/vtt " +
                         "audio/x-mpeg audio/wave audio/x-m4r audio/x-mp3 " +
                         "audio/AMR audio/aiff audio/3gpp2 audio/aac audio/mpg " +
                         "audio/mpegurl audio/x-m4b application/mp4 " +
                         "audio/x-m4p audio/x-scpls audio/x-mpegurl " +
                         "audio/x-aac audio/3gpp audio/basic audio/x-m4a " +
                         "application/x-mpegurl"
#else
        let testString = "video/mp4 video/x-m4v video/mpg audio/x-m4r " +
            "audio/AMR video/x-mpg video/3gpp2 video/mp2p video/mp1s audio/mpeg " +
            "video/x-mp2p video/x-mp1s audio/scpls audio/wave video/x-mp2t " +
            "video/x-mpeg2 audio/mpeg3 video/mpeg audio/aac video/x-m2ts " +
            "audio/x-caf video/mp2t audio/3gpp application/x-mpegurl " +
            "application/mp4 audio/mp3 video/avi application/vnd.apple.mpegurl " +
            "audio/mp4 audio/x-aiff audio/mpg video/x-mpeg video/dv video/3gpp " +
            "video/mpeg2 audio/x-mpg audio/x-mpeg audio/3gpp2 audio/x-aac " +
            "audio/x-wav video/quicktime audio/x-mp3 audio/x-mpegurl audio/x-mpeg3 " +
            "audio/x-m4a audio/x-m4p audio/mpegurl video/m2ts audio/aacp " +
            "audio/x-m4b audio/aiff audio/x-scpls audio/basic audio/wav text/vtt"
#endif
        XCTAssert(resultString == testString,
                  "Different list of movie mime types " + resultString)
    }

    func testGetMovieMediaTypesAndCharacteristics() -> Void {
        let commandsDict = [
            "commands" : [
                [
                    "command" : "getproperty",
                    "objecttype" : "movieimporter",
                    "propertykey" : MIJSONPropertyMovieMediaTypes
                ]
            ]
        ]
        let result = MIMovingImagesHandleCommands(nil, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0,
            "Error getting list movie import types")
        let resultString = MIGetStringFromReplyDictionary(result)
        let testString = "soun clcp meta muxx sbtl text tmcd vide"
        XCTAssert(resultString == testString,
            "Different list of movie media types " + resultString)

        let commandsDict2 = [
            "commands" : [
                [
                    "command" : "getproperty",
                    "objecttype" : "movieimporter",
                    "propertykey" : MIJSONPropertyMovieMediaCharacteristics
                ]
            ]
        ]
        let result2 = MIMovingImagesHandleCommands(nil, commandsDict2, nil)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
        XCTAssertEqual(errorCode2.rawValue, 0,
            "Error getting list movie import types")
        let resultString2 = MIGetStringFromReplyDictionary(result2)
        let testString2 = "AVMediaCharacteristicAudible " +
            "public.subtitles.forced-only " +
            "public.accessibility.describes-music-and-sound " +
            "public.accessibility.describes-video public.easy-to-read " +
            "AVMediaCharacteristicFrameBased public.auxiliary-content " +
            "public.main-program-content AVMediaCharacteristicLegible " +
            "public.accessibility.transcribes-spoken-dialog " +
            "AVMediaCharacteristicVisual"
        XCTAssert(resultString2 == testString2,
            "Different list of movie media characteristics " + resultString2)
    }
    
    func testLoadingAMovieFileAndClosingMovieImporter() -> Void {
        let testBundle = NSBundle(forClass: MovingImagesFrameworkiOSSwift.self)
        let movieURL = testBundle.URLForResource("410_clip4", withExtension:"mov")!

        let filePath = movieURL.path!
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCreateCommand,
                    MIJSONKeyObjectType : MIMovieImporterKey,
                    MIJSONPropertyFile : filePath,
                    MIJSONKeyObjectName : "test001.movie"
                ],
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieMetadata,
                    MIJSONKeyReceiverObject : [
                        MIJSONKeyObjectType : MIMovieImporterKey,
                        MIJSONKeyObjectName : "test001.movie"
                    ]
                ]
            ]
        ]
        let theContext = MIContext()
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0,
            "Error creating or getting properties of a movie file")
        let resultString = MIGetStringFromReplyDictionary(result)
       
        // Now close the movie importer object and its asset.
        let commandsDict2 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCloseCommand,
                    MIJSONKeyReceiverObject : [
                        MIJSONKeyObjectType : MIMovieImporterKey,
                        MIJSONKeyObjectName : "test001.movie"
                    ]
                ]
            ]
        ]
        let result2 = MIMovingImagesHandleCommands(theContext, commandsDict2,
            nil)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
        XCTAssertEqual(errorCode2.rawValue, 0,
            "Error closing the movie importer object")
        
        // Lets try running that command again, we should get an error.
        let result25 = MIMovingImagesHandleCommands(theContext, commandsDict2,
            nil)
        let errorCode25 = MIGetErrorCodeFromReplyDictionary(result25)
        XCTAssertEqual(errorCode25.rawValue, 246,
            "Error closing the movie importer object")
        let strResult25 = MIGetStringFromReplyDictionary(result25)
        // println(strResult25) // "Error: Invalid receiver object"

        // Now check that we have closed all objects in the context
        let commandsDict3 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyNumberOfObjects
                ]
            ]
        ]
        let result3 = MIMovingImagesHandleCommands(theContext, commandsDict3,
            nil)
        let errorCode3 = MIGetErrorCodeFromReplyDictionary(result3)
        XCTAssertEqual(errorCode3, MIReplyErrorEnum.NoError,
            "Error getting number of objects")
        let resultValue3 = MIGetNumericReplyValueFromDictionary(result3)
        XCTAssertEqual(resultValue3.integerValue, 0,
            "Number of objects should be zero")
    }

    func testLoadingAMovieFileUsingSubstitutedPath() -> Void {
        let testBundle = NSBundle(forClass: MovingImagesFrameworkiOSSwift.self)
        let movieURL = testBundle.URLForResource("410_clip4", withExtension:"mov")!
        
        let filePath = movieURL.path!
        let pathSubstitutionKey = "test001.pathsubstitution.movie"
        let commandsDict = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCreateCommand,
                    MIJSONKeyObjectType : MIMovieImporterKey,
                    // MIJSONPropertyFile : filePath,
                    MIJSONPropertyPathSubstitution : pathSubstitutionKey,
                    MIJSONKeyObjectName : "test001.movie"
                ],
                [
                    MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                    MIJSONPropertyKey : MIJSONPropertyMovieMetadata,
                    MIJSONKeyReceiverObject : [
                        MIJSONKeyObjectType : MIMovieImporterKey,
                        MIJSONKeyObjectName : "test001.movie"
                    ]
                ]
            ]
        ]
        let theContext = MIContext()
        let variables = [ pathSubstitutionKey : filePath ]
        theContext.appendVariables(variables)
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssertEqual(errorCode.rawValue, 0,
            "Error creating or getting properties of a movie file")
        let resultString = MIGetStringFromReplyDictionary(result)
        
        // Now close the movie importer object and its asset.
        let commandsDict2 = [
            MIJSONKeyCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCloseCommand,
                    MIJSONKeyReceiverObject : [
                        MIJSONKeyObjectType : MIMovieImporterKey,
                        MIJSONKeyObjectName : "test001.movie"
                    ]
                ]
            ]
        ]
        let result2 = MIMovingImagesHandleCommands(theContext, commandsDict2,
            nil)
        let errorCode2 = MIGetErrorCodeFromReplyDictionary(result2)
        XCTAssertEqual(errorCode2.rawValue, 0,
            "Error closing the movie importer object")
    }

    func testGetPixelData() -> Void {
        let bitmapObject = [
            MIJSONKeyObjectType : MICGBitmapContextKey,
            MIJSONKeyObjectName : "testGetPixelData.context"
        ]
        
        let bitmapSize = [
            "width" : 4,
            "height" : 1
        ]
        
        let fillColor = [
            MIJSONKeyRed : 0.8,
            MIJSONKeyGreen : 0.3,
            MIJSONKeyBlue : 0.1,
            MIJSONKeyAlpha : 1.0,
            MIJSONKeyColorColorProfileName : "kCGColorSpaceSRGB"
        ]
        
        let drawRect = [
            MIJSONKeySize : bitmapSize,
            MIJSONKeyOrigin : [ "x" : 0, "y" : 0 ]
        ]
        
        let pixelDataRect = [
            MIJSONKeySize : [ MIJSONKeyWidth : 1, MIJSONKeyHeight : 1],
            MIJSONKeyOrigin : [ MIJSONKeyX : 0, MIJSONKeyY : 0 ]
        ]
        
        let drawElement = [
            MIJSONKeyElementType : MIJSONValueRectangleFillElement,
            MIJSONKeyFillColor : fillColor,
            MIJSONKeyRect : drawRect
        ]
        
        let createBitmapCommand = [
            MIJSONKeyCommand : MIJSONValueCreateCommand,
            MIJSONKeyObjectType : MICGBitmapContextKey,
            MIJSONKeyObjectName : "testGetPixelData.context",
            MIJSONPropertyPreset : MIAlphaPreMulBGRA8bpc32bppInteger,
            MIJSONKeySize : bitmapSize
        ]
        
        let drawRectCommand = [
            MIJSONKeyCommand : MIJSONValueDrawElementCommand,
            MIJSONPropertyDrawInstructions : drawElement,
            MIJSONKeyReceiverObject : bitmapObject
        ]
        
        let getPixelDataCommand = [
            MIJSONKeyCommand : MIJSONValueGetPixelDataCommand,
            MIJSONKeyReceiverObject : bitmapObject,
            MIJSONKeyGetDataType : MIJSONPropertyDictionaryObject,
            MIJSONPropertyValue : pixelDataRect
        ]
        
        let commandsDict = [
            MIJSONKeyCommands : [
                createBitmapCommand,
                drawRectCommand,
                getPixelDataCommand
            ],
            MIJSONKeyCleanupCommands : [
                [
                    MIJSONKeyCommand : MIJSONValueCloseCommand,
                    MIJSONKeyReceiverObject : bitmapObject
                ]
            ]
        ]
        let theContext = MIContext()
        let result = MIMovingImagesHandleCommands(theContext, commandsDict, nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        let resStr = MIGetStringFromReplyDictionary(result)
        
        #if os(iOS)
        let previousRes = "{\"pixeldata\":[[0,0,26,77,204,255]],\"contextinfo\"" +
                ":{\"alphainfo\":8194,\"bitspercomponent\":8,\"colorspace\":" +
                "\"DeviceRGB\",\"bitsperpixel\":32},\"columnnames\":" +
                "[\"x\",\"y\",\"Blue\",\"Green\",\"Red\",\"Alpha\"]}"
        #else
        let previousRes = "{\"pixeldata\":[[0,0,26,77,204,255]],\"contextinfo\"" +
            ":{\"alphainfo\":8194,\"bitspercomponent\":8,\"colorspace\":" +
            "\"kCGColorSpaceSRGB\",\"bitsperpixel\":32},\"columnnames\":" +
            "[\"x\",\"y\",\"Blue\",\"Green\",\"Red\",\"Alpha\"]}"
        #endif
        println(resStr)

        XCTAssertEqual(resStr, previousRes,
            "Returned a different pixel data result to original.")
    }
}
