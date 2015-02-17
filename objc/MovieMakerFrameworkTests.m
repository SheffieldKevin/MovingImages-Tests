//
//  MovingImagesFrameworkTests.m
//  MovingImagesFrameworkTests
//
//  Created by Kevin Meaney on 01/10/2014.
//  Copyright (c) 2014 Apple Inc. All rights reserved.
//

/*
 The main tests are all written in ruby. See testing/runtests in the folder
 containing the project file. To run the ruby tests you'll need to install the
 moving_images ruby gem. This can be done using the MovingImages application
 which installs all the MovingImages components.
 
 These tests are my first tentative steps into using Xcode's XCTest framework.
 
 As well as testing the top level interface to using the MovingImages framework
 I'm also trying out the performance tests and asynchronous testing parts of
 of the XCTest framework.
*/

@import XCTest;

#import <MovingImages/MovingImages.h>
#import "MIReplyDictionary.h"

@interface MovingImagesFrameworkTests : XCTestCase

@end

@implementation MovingImagesFrameworkTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

// Get the MovingImages version number. Confirm it is what we expect.
- (void)testHandleGetVersionCommand
{
    NSDictionary *commandDict;
    commandDict = @{ MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                     MIJSONPropertyKey : MIJSONPropertyVersion };
    NSDictionary *resultDict = MIMovingImagesHandleCommand(nil, commandDict);
    NSString *resultString = MIGetStringFromReplyDictionary(resultDict);
    
    XCTAssertEqualObjects(resultString, @"0.3a", @"Version numbers differ");
}

// Get the number of existing objects and confirm that it is zero.
- (void)testHandleGet0NumberOfObjectsCommand
{
    NSDictionary *commandDict;
    commandDict = @{ MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                     MIJSONPropertyKey : MIJSONPropertyNumberOfObjects };
    NSDictionary *resultDict = MIMovingImagesHandleCommand(nil, commandDict);
    NSString *resultString = MIGetStringFromReplyDictionary(resultDict);
    
    XCTAssertEqualObjects(resultString, @"0", @"Number of objects differ");
}

// Determine if we can create a bitmap context. Then get properties about
// the bitmap context. Not checking object reference numbers as they can
// vary depending on the order that the tests are run.
- (void)testHandleCreateBitmapContextAndGetPropertiesCommand
{
    // Create the bitmap context
    NSDictionary *commandDict;
    commandDict = @{ MIJSONKeyCommand : MIJSONValueCreateCommand,
                     MIJSONKeyObjectType : MICGBitmapContextKey,
                     MIJSONKeyObjectName : @"my.test.bitmapcontext",
                     MIJSONKeySize : @{
                         MIJSONKeyHeight : @(200),
                         MIJSONKeyWidth : @(400)
                     },
                     MIJSONPropertyPreset :
                                    MIAlphaPreMulFirstRGB8bpc32bppInteger};
    
    // Creating the context should have worked, check that here.
    NSDictionary *resultDict = MIMovingImagesHandleCommand(nil, commandDict);
    MIReplyErrorEnum errorCode = MIGetErrorCodeFromReplyDictionary(resultDict);
    XCTAssertEqual(errorCode, 0, "Expected no error creating bitmap context");
    NSNumber *objectReference = MIGetNumericReplyValueFromDictionary(resultDict);

    // Get properties from the context, first get the height.
    commandDict = @{ MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                     MIJSONKeyReceiverObject :
                         @{ MIJSONKeyObjectReference : objectReference },
                     MIJSONPropertyKey : MIJSONKeyHeight };
    resultDict = MIMovingImagesHandleCommand(nil, commandDict);

    // Check that there was no error getting the context height.
    errorCode = MIGetErrorCodeFromReplyDictionary(resultDict);
    XCTAssertEqual(errorCode, 0, "Expected no error getting context height");
    NSNumber *contextHeight = MIGetNumericReplyValueFromDictionary(resultDict);
    // Now check that the context height is same as what we created context.
    XCTAssertEqual(contextHeight.integerValue, 200);
    
    // Lets now refer to the context by type and name, and get the preset.
    // The preset should be the same as that used to create the context
    commandDict = @{ MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                     MIJSONKeyReceiverObject :
                         @{ MIJSONKeyObjectType : MICGBitmapContextKey,
                            MIJSONKeyObjectName : @"my.test.bitmapcontext" },
                     MIJSONPropertyKey : MIJSONPropertyPreset };
    resultDict = MIMovingImagesHandleCommand(nil, commandDict);
    errorCode = MIGetErrorCodeFromReplyDictionary(resultDict);
    XCTAssertEqual(errorCode, 0, "Expected no error getting context preset");
    NSString *preset = MIGetStringFromReplyDictionary(resultDict);
    XCTAssertEqualObjects(MIAlphaPreMulFirstRGB8bpc32bppInteger, preset,
                          @"Context preset different to preset used to create");

    // Close the object at end of this so as not to break other tests.
    MIMovingImagesHandleCommand(nil, @{ MIJSONKeyCommand : MIJSONValueCloseCommand,
                                   MIJSONKeyReceiverObject :
                                   @{ MIJSONKeyObjectReference :
                                        objectReference }});
}

// Determine that the list of bitmap context presets is what we expect.
- (void)testHandleGetListOfPresetsCommand
{
    NSDictionary *commandDict;
    commandDict = @{ MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                     MIJSONKeyObjectType : MICGBitmapContextKey,
                     MIJSONPropertyKey : MIJSONPropertyPresets };
    NSDictionary *resultDict;
    resultDict = MIMovingImagesHandleCommand(nil, commandDict);
    
    // First check whether an error occurred when asking for the list of presets
    MIReplyErrorEnum errorCode = MIGetErrorCodeFromReplyDictionary(resultDict);
    XCTAssertEqual(errorCode, 0, "Error getting list of bitmap presets");
#if TARGET_OS_IPHONE
    const char *cStrPresets = "AlphaOnly8bpcInt Gray8bpcInt Gray16bpcInt Gray32bpcFloat "\
    "AlphaSkipFirstRGB8bpcInt AlphaSkipLastRGB8bpcInt AlphaPreMulFirstRGB8bpcInt "\
    "AlphaPreMulBGRA8bpcInt AlphaPreMulLastRGB8bpcInt PlatformDefaultBitmapContext";
#else
    const char *cStrPresets = "AlphaOnly8bpcInt Gray8bpcInt Gray16bpcInt "\
    "Gray32bpcFloat AlphaSkipFirstRGB8bpcInt AlphaSkipLastRGB8bpcInt "\
    "AlphaPreMulFirstRGB8bpcInt AlphaPreMulBGRA8bpcInt AlphaPreMulLastRGB8bpcInt "\
    "AlphaPreMulLastRGB16bpcInt AlphaSkipLastRGB16bpcInt "\
    "AlphaSkipLastRGB32bpcFloat AlphaPreMulLastRGB32bpcFloat CMYK8bpcInt "\
    "CMYK16bpcInt CMYK32bpcFloat PlatformDefaultBitmapContext";
#endif
    NSString *presets = [[NSString alloc] initWithCString:cStrPresets
                                                 encoding:NSUTF8StringEncoding];
    NSString *resultString = MIGetStringFromReplyDictionary(resultDict);
    XCTAssertEqualObjects(presets, resultString, "List of presets differs");
}

// Test that the cleanup commands are run.
- (void)testCleanupCommandsClosesObject
{
    NSDictionary *createBitmapContext;
    createBitmapContext = @{ MIJSONKeyCommand : MIJSONValueCreateCommand,
                             MIJSONKeyObjectType : MICGBitmapContextKey,
                             MIJSONKeyObjectName : @"my.test.bitmapcontext",
                             MIJSONKeySize: @{
                                 MIJSONKeyHeight : @(200),
                                 MIJSONKeyWidth : @(400)
                             },
                             MIJSONPropertyPreset :
                                        MIAlphaPreMulFirstRGB8bpc32bppInteger};
    NSDictionary *dictionaryObject;
    dictionaryObject = @{ MIJSONKeyObjectType : MICGBitmapContextKey,
                          MIJSONKeyObjectName : @"my.test.bitmapcontext" };
    NSDictionary *closeCommand;
    closeCommand = @{ MIJSONKeyCommand : MIJSONValueCloseCommand,
                      MIJSONKeyReceiverObject : dictionaryObject };
    NSDictionary *theCommands;
    theCommands = @{ MIJSONKeyCommands : @[ createBitmapContext ],
                     MIJSONKeyCleanupCommands : @[ closeCommand ] };
    NSDictionary *resultDict;
    resultDict = MIMovingImagesHandleCommands(nil, theCommands, nil);

    // First check whether an error occurred when asking for the list of presets
    MIReplyErrorEnum errorCode = MIGetErrorCodeFromReplyDictionary(resultDict);
    XCTAssertEqual(errorCode, 0, "Error creating/close bitmap context");
    
    // Now ask for the number of bitmap context objects and see if that number
    // is zero.
    NSDictionary *commandDict;
    commandDict = @{ MIJSONKeyCommand : MIJSONValueGetPropertyCommand,
                     MIJSONPropertyKey : MIJSONPropertyNumberOfObjects,
                     MIJSONKeyObjectType : MICGBitmapContextKey };
    resultDict = MIMovingImagesHandleCommand(nil, commandDict);
    errorCode = MIGetErrorCodeFromReplyDictionary(resultDict);
    XCTAssertEqual(errorCode, 0, "Error getting number of bitmap context objects");
    NSNumber *numObjects = MIGetNumericReplyValueFromDictionary(resultDict);
    XCTAssertEqual(numObjects.integerValue, 0, "Closing bitmap object failed.");
}

// Test the shape drawing performance into a bitmap context.
// The ruby code that generated the json is below
/*
#!/usr/bin/env ruby

require 'moving_images'

include MovingImages

module MovingImagesPerformance
    def self.create_drawarrayofequationrectanglescommand(receiver_object,
        number_of_rectangles: 500)
        arrayofelements = MIDrawElement.new(:arrayofelements)
        number_of_rectangles.times do
            drawrectangle_element = MIDrawElement.new(:fillpath)
            rounded_rect_path = MIPath.new
            the_rect = MIShapes.make_rectangle(xloc: "10 + 100 * $xloc_random",
            yloc: "10 + 100 * $yloc_random",
            width: "40 + 300 * $width_random",
            height: "30 + 200 * $height_random")
            radiuses = [ "1 + 20.0 * $radius1", "1 + 20.0 * $radius2",
            "1 + 20.0 * $radius3", "1 + 20.0 * $radius4" ]
            rounded_rect_path.add_roundedrectangle_withradiuses(the_rect,
            radiuses: radiuses)
            drawrectangle_element.arrayofpathelements = rounded_rect_path
            drawrectangle_element.startpoint = MIShapes.make_point(0, 0)
            drawrectangle_element.fillcolor = MIColor.make_rgbacolor(
            Random.rand, Random.rand, Random.rand)
            variables_dict = { xloc_random: Random.rand, yloc_random: Random.rand,
            width_random: Random.rand, height_random: Random.rand,
            radius1: Random.rand, radius2: Random.rand,
            radius3: Random.rand, radius4: Random.rand }
            drawrectangle_element.variables = variables_dict
            arrayofelements.add_drawelement_toarrayofelements(drawrectangle_element)
        end
        CommandModule.make_drawelement(receiver_object,
                                                drawinstructions: arrayofelements)
    end
end

smig_commands = CommandModule::SmigCommands.new
bitmap_object = smig_commands.make_createbitmapcontext(addtocleanup: true)
draw_cmd = MovingImagesPerformance.create_drawarrayofequationrectanglescommand(
bitmap_object, number_of_rectangles: 200)
smig_commands.add_command(draw_cmd)

jsonString = JSON.pretty_generate(smig_commands.commandshash)
filePath = File.expand_path("~/Documents/draw_elements.json")
open(filePath, 'w') { |f| f.puts jsonString }
*/
- (void)testRoundedRectShapeDrawingPerformance
{
    NSBundle *testBundle;
    testBundle = [NSBundle bundleForClass:[MovingImagesFrameworkTests class]];
    NSURL *jsonURL;
    jsonURL = [testBundle URLForResource:@"draw_elements" withExtension:@"json"];
    id container;
    NSDictionary *dictionary;
    NSInputStream *inStream;
    inStream = [[NSInputStream alloc] initWithURL:jsonURL];
    [inStream open];
    container = [NSJSONSerialization JSONObjectWithStream:inStream
                                                  options:0
                                                    error:nil];
    if (container && [container isKindOfClass:[NSDictionary class]])
        dictionary = container;

    [self measureBlock:^{
        MIMovingImagesHandleCommands(nil, dictionary, nil);
    }];
}

- (void)testRoundedRectShapeDrawingInCreatedContext
{
    NSBundle *testBundle;
    testBundle = [NSBundle bundleForClass:[MovingImagesFrameworkTests class]];
    NSURL *jsonURL;
    jsonURL = [testBundle URLForResource:@"draw_elements" withExtension:@"json"];
    id container;
    NSDictionary *dictionary;
    NSInputStream *inStream;
    inStream = [[NSInputStream alloc] initWithURL:jsonURL];
    [inStream open];
    container = [NSJSONSerialization JSONObjectWithStream:inStream
                                                  options:0
                                                    error:nil];
    if (container && [container isKindOfClass:[NSDictionary class]])
        dictionary = container;
    
    MIContext *context = MICreateContext();
    NSDictionary *results = MIMovingImagesHandleCommands(context, dictionary, nil);
    // First check whether an error occurred when asking for the list of presets
    MIReplyErrorEnum errorCode = MIGetErrorCodeFromReplyDictionary(results);
    XCTAssertEqual(errorCode, 0, "Error drawing rounded rects in a MIContext");
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
-(void)testAsynchronousShapeDrawing
{
    NSBundle *testBundle;
    testBundle = [NSBundle bundleForClass:[MovingImagesFrameworkTests class]];
    NSURL *jsonURL;
    jsonURL = [testBundle URLForResource:@"drawelements_asynchronous"
                           withExtension:@"json"];
    id container;
    NSDictionary *dictionary;
    NSInputStream *inStream;
    inStream = [[NSInputStream alloc] initWithURL:jsonURL];
    [inStream open];
    container = [NSJSONSerialization JSONObjectWithStream:inStream
                                                  options:0
                                                    error:nil];
    if (container && [container isKindOfClass:[NSDictionary class]])
        dictionary = container;

    XCTestExpectation *expectation = [self expectationWithDescription:
                                      @"Rounded rectangle with equation drawing"];
    MIMovingImagesHandleCommands(nil, dictionary, ^(NSDictionary *reply) {
        MIReplyErrorEnum result = MIGetErrorCodeFromReplyDictionary(reply);
        XCTAssert(result == MIReplyErrorNoError);
        [expectation fulfill];
    });
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

@end
