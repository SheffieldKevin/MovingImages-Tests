//  MovingImagesShadowDrawingTests.swift
//  MovingImagesFramework
//
//  Created by Kevin Meaney on 02/02/2015.
//  Copyright (c) 2015 Apple Inc. All rights reserved.

import Foundation
import CoreText

#if os(iOS)
    import UIKit
    import Photos
    import MobileCoreServices
    import MovingImagesiOS
#endif

import AVFoundation
import XCTest

/**
 To make image files to compare against, set comparingImages to false. If
 comparingImages is true comparisons will be done and new images won't be
 exported as files.
*/
let comparingImages = true

let bitmapName = "drawshadowtest.bitmap"

let redColour = [
    MIJSONKeyRed : 0.8,
    MIJSONKeyGreen : 0.3,
    MIJSONKeyBlue : 0.1,
    MIJSONKeyAlpha : 1.0,
    MIJSONKeyColorColorProfileName : "kCGColorSpaceGenericRGB"
]

let blueColour = [
    MIJSONKeyRed : 0.1,
    MIJSONKeyGreen : 0.2,
    MIJSONKeyBlue : 0.8,
    MIJSONKeyAlpha : 1.0,
    MIJSONKeyColorColorProfileName : "kCGColorSpaceGenericRGB"
]

let greenColour = [
    MIJSONKeyRed : 0.2,
    MIJSONKeyGreen : 0.9,
    MIJSONKeyBlue : 0.1,
    MIJSONKeyAlpha : 1.0,
    MIJSONKeyColorColorProfileName : "kCGColorSpaceGenericRGB"
]

let bitmapSize = [
    MIJSONKeyWidth : 640,
    MIJSONKeyHeight : 480
]

let drawWidth = 180
let drawHeight = 180

let drawSize = [
    MIJSONKeyWidth : drawWidth,
    MIJSONKeyHeight : drawHeight
]

let bitmapObject = [
    MIJSONKeyObjectType : MICGBitmapContextKey,
    MIJSONKeyObjectName : bitmapName,
]

let createBitmapContextCommand = [
    MIJSONKeyCommand : MIJSONValueCreateCommand,
    MIJSONKeyObjectType : MICGBitmapContextKey,
    MIJSONKeyObjectName : bitmapName,
    MIJSONPropertyPreset : MIPlatformDefaultBitmapContext,
    MIJSONKeySize : bitmapSize
]

let createBitmapContextCommand2 = [
    MIJSONKeyCommand : MIJSONValueCreateCommand,
    MIJSONKeyObjectType : MICGBitmapContextKey,
    MIJSONKeyObjectName : bitmapName,
    MIJSONPropertyPreset : MIPlatformDefaultBitmapContext,
    MIJSONKeySize : [ MIJSONKeyWidth : 400, MIJSONKeyHeight : 400 ]
]

let closeBitmapContextCommand = [
    MIJSONKeyCommand : MIJSONValueCloseCommand,
    MIJSONKeyReceiverObject : bitmapObject
]

class MovingImagesShadowDrawingTests: XCTestCase {
    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    let drawBlueCircle = [
        MIJSONKeyElementType : MIJSONValueOvalFillElement,
        MIJSONKeyFillColor : blueColour,
        MIJSONKeyRect : [
            MIJSONKeySize : drawSize,
            MIJSONKeyOrigin : [ MIJSONKeyX : 120, MIJSONKeyY : 30 ]
        ]
    ]
    
    let drawGreenRoundedCornerSquare = [
        MIJSONKeyElementType : MIJSONValueRoundedRectangleFillElement,
        MIJSONKeyFillColor : greenColour,
        MIJSONKeyRect : [
            MIJSONKeySize : drawSize,
            MIJSONKeyOrigin : [ MIJSONKeyX : 240, MIJSONKeyY : 150 ]
        ],
        MIJSONKeyRadiuses : [
            5.0, 10.0, 20.0, 30.0
        ] // bottom right is first and then anti-clockwise
    ]
    
    let drawRedSquare = [
        MIJSONKeyElementType : MIJSONValueRectangleFillElement,
        MIJSONKeyFillColor : redColour,
        MIJSONKeyRect : [
            MIJSONKeySize : drawSize,
            MIJSONKeyOrigin : [ MIJSONKeyX : 360, MIJSONKeyY : 270 ]
        ]
    ]

    let shadowColour = [
        MIJSONKeyRed : 0,
        MIJSONKeyGreen : 0,
        MIJSONKeyBlue : 0,
        MIJSONKeyAlpha : 1,
        MIJSONKeyColorColorProfileName : "kCGColorSpaceGenericRGB"
    ]
    
    let shadowOffset = [ MIJSONKeyWidth : 6, MIJSONKeyHeight : -10 ]
    
    func testDrawingArrayOfItemsWithShadow() -> Void {
        let drawElement = [
            MIJSONKeyElementType : MIJSONValueArrayOfElements,
            MIJSONKeyArrayOfElements : [
                drawBlueCircle,
                drawRedSquare,
                drawGreenRoundedCornerSquare
            ],
            MIJSONKeyShadow : [
                MIJSONKeyBlur : 10,
                MIJSONKeyShadowOffset : shadowOffset,
                MIJSONKeyFillColor : shadowColour
            ]
        ]
        // writeJSONToFile(drawElement)
        let drawElementCommand = [
            MIJSONKeyCommand : MIJSONValueDrawElementCommand,
            MIJSONKeyReceiverObject : bitmapObject,
            MIJSONPropertyDrawInstructions : drawElement
        ]
        
        let imageIdentifier = "shapecollection.withshadow"
        let assignImageToCollectionCommand = [
            MIJSONKeyCommand : MIJSONValueAssignImageToCollectionCommand,
            MIJSONKeyReceiverObject : bitmapObject,
            MIJSONPropertyImageIdentifier : imageIdentifier
        ]
        
        let commandInstructions = [
            MIJSONKeyCommands : [
                createBitmapContextCommand,
                drawElementCommand,
                assignImageToCollectionCommand
            ],
            MIJSONKeyCleanupCommands : [
                closeBitmapContextCommand
            ]
        ]
        
        let theContext = MIContext()
        let result = MIMovingImagesHandleCommands(theContext, commandInstructions,
            nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssert(MIReplyErrorEnum.NoError == errorCode, "Failed to create image")
        let theImage = theContext.getCGImageWithIdentifier(imageIdentifier)
        let baseName = "DrawingShapesWithShadow"
        if errorCode == MIReplyErrorEnum.NoError
        {
            if comparingImages
            {
                let namedImageName = makeFileName(baseName: baseName)
                let origImage = createCGImageFromNamedPNGImage(namedImageName)
                let imageDiff = compareImages(image1: origImage, image2: theImage)
                // println("Max image difference: \(imageDiff)")
                XCTAssert(imageDiff < 2, "Image file \(namedImageName) different")
            }
            else
            {
                saveCGImageToAPNGFile(theImage, baseName: baseName)
            }
        }
        else
        {
            println(MIGetStringFromReplyDictionary(result))
        }
    }
    
    func testDrawingALinearGradientWithShadow() -> Void {
        let linearGradientWidth = 360
        let linearGradientHeight = 360
        let linearGradientLeftEdge = 140
        let linearGradientBottomEdge = 60
        
        let rectOrigin = [
            MIJSONKeyX : linearGradientLeftEdge,
            MIJSONKeyY : linearGradientBottomEdge
        ]
        
        let rectSize = [
            MIJSONKeyWidth : linearGradientWidth,
            MIJSONKeyHeight : linearGradientHeight
        ]
        
        // Drawing a linear gradient that changes vertically.
        let startPoint = [
            MIJSONKeyX : linearGradientLeftEdge + linearGradientWidth / 2,
            MIJSONKeyY : linearGradientBottomEdge
        ]
        
        let endPoint = [
            MIJSONKeyX : linearGradientLeftEdge + linearGradientWidth / 2,
            MIJSONKeyY : linearGradientBottomEdge + linearGradientHeight
        ]
        
        let linearGradientLine = [
            MIJSONKeyStartPoint : startPoint,
            MIJSONKeyEndPoint : endPoint
        ]
        
        let startColour = greenColour
        let endColour = redColour
        let theColours = [ startColour, endColour ]
        let locations = [ 0, 1 ]
        
        let pathElements = [
            [
                MIJSONKeyElementType : MIJSONValuePathRectangle,
                MIJSONKeyRect : [
                    MIJSONKeySize : rectSize, MIJSONKeyOrigin : rectOrigin
                ]
            ]
        ]
        
        let drawElement = [
            MIJSONKeyElementType : MIJSONValueLinearGradientFill,
            MIJSONKeyLine : linearGradientLine,
            MIJSONKeyArrayOfColors : theColours,
            MIJSONKeyArrayOfLocations : locations,
            
            // The following start point relates to the array of paths.
            MIJSONKeyStartPoint : rectOrigin,
            MIJSONKeyArrayOfPathElements : pathElements,
            
            // Now add the shadow.
            MIJSONKeyShadow : [
                MIJSONKeyBlur : 10,
                MIJSONKeyShadowOffset : shadowOffset,
                MIJSONKeyFillColor : shadowColour
            ]
        ]

        let drawElementCommand = [
            MIJSONKeyCommand : MIJSONValueDrawElementCommand,
            MIJSONKeyReceiverObject : bitmapObject,
            MIJSONPropertyDrawInstructions : drawElement
        ]
        
        let imageIdentifier = "lineargradient.withshadow"
        let assignImageToCollectionCommand = [
            MIJSONKeyCommand : MIJSONValueAssignImageToCollectionCommand,
            MIJSONKeyReceiverObject : bitmapObject,
            MIJSONPropertyImageIdentifier : imageIdentifier
        ]
        
        let commandInstructions = [
            MIJSONKeyCommands : [
                createBitmapContextCommand,
                drawElementCommand,
                assignImageToCollectionCommand
            ],
            MIJSONKeyCleanupCommands : [
                closeBitmapContextCommand
            ]
        ]
        
        let theContext = MIContext()
        let result = MIMovingImagesHandleCommands(theContext, commandInstructions,
            nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssert(MIReplyErrorEnum.NoError == errorCode, "Failed to create image")
        if errorCode == MIReplyErrorEnum.NoError
        {
            let theImage = theContext.getCGImageWithIdentifier(imageIdentifier)
            let baseName = "LinearGradientFillWithShadow"
            if comparingImages
            {
                let namedImageName = makeFileName(baseName: baseName)
                let origImage = createCGImageFromNamedPNGImage(namedImageName)
                let imageDiff = compareImages(image1: origImage, image2: theImage)
                // println("Max image difference: \(imageDiff)")
                XCTAssert(imageDiff < 2,
                    "Image file \(namedImageName) different: \(imageDiff)")
            }
            else
            {
                saveCGImageToAPNGFile(theImage, baseName: baseName)
            }
        }
        else
        {
            println(MIGetStringFromReplyDictionary(result))
        }
    }

    func testDrawingARadialGradientWithShadow() -> Void {
        let radius1 = 50
        let center1 = [
            MIJSONKeyX : 240,
            MIJSONKeyY : 160
        ]
        
        let radius2 = 150
        let center2 = [
            MIJSONKeyX : 410,
            MIJSONKeyY : 260
        ]
        
        let startColour = blueColour
        let endColour = redColour
        let theColours = [ startColour, endColour ]
        let locations = [ 0, 1 ]
        
        let drawElement = [
            MIJSONKeyElementType : MIJSONValueRadialGradientFill,
            MIJSONKeyCenterPoint : center1,
            MIJSONKeyCenterPoint2 : center2,
            MIJSONKeyRadius : radius1,
            MIJSONKeyRadius2 : radius2,
            MIJSONKeyArrayOfColors : theColours,
            MIJSONKeyArrayOfLocations : locations,

            // Now add the shadow.
            MIJSONKeyShadow : [
                MIJSONKeyBlur : 10,
                MIJSONKeyShadowOffset : shadowOffset,
                MIJSONKeyFillColor : shadowColour
            ]
        ]
        
        let drawElementCommand = [
            MIJSONKeyCommand : MIJSONValueDrawElementCommand,
            MIJSONKeyReceiverObject : bitmapObject,
            MIJSONPropertyDrawInstructions : drawElement
        ]
        
        let imageIdentifier = "radialgradient.withshadow"
        let assignImageToCollectionCommand = [
            MIJSONKeyCommand : MIJSONValueAssignImageToCollectionCommand,
            MIJSONKeyReceiverObject : bitmapObject,
            MIJSONPropertyImageIdentifier : imageIdentifier
        ]
        
        let commandInstructions = [
            MIJSONKeyCommands : [
                createBitmapContextCommand,
                drawElementCommand,
                assignImageToCollectionCommand
            ],
            MIJSONKeyCleanupCommands : [
                closeBitmapContextCommand
            ]
        ]
        
        let theContext = MIContext()
        let result = MIMovingImagesHandleCommands(theContext, commandInstructions,
            nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssert(MIReplyErrorEnum.NoError == errorCode, "Failed to create image")
        if errorCode == MIReplyErrorEnum.NoError
        {
            let theImage = theContext.getCGImageWithIdentifier(imageIdentifier)
            let baseName = "RadialGradientFillWithShadow"
            if comparingImages
            {
                let namedImageName = makeFileName(baseName: baseName)
                let origImage = createCGImageFromNamedPNGImage(namedImageName)
                let imageDiff = compareImages(image1: origImage, image2: theImage)
                // println("Max image difference: \(imageDiff)")
                XCTAssert(imageDiff < 2, "Image file \(namedImageName) different")
            }
            else
            {
                saveCGImageToAPNGFile(theImage, baseName: baseName)
            }
        }
        else
        {
            println(MIGetStringFromReplyDictionary(result))
        }
    }

    // This demonstrates adding an inner shadow to a rectangle by stroking
    // a rectangle with the blur radius the same as the stroke width and
    // clipping the stroked rectangle out of the draw element. This is
    // drawn on top of a blue circle to demonstrate how the shadow is applied.
    func testStrokingAClippedRectangleWithShadowOverACircle() -> Void {

        let xOrigin = 100
        let yOrigin = 100
        let blurWidth = 10
        let strokeWidth = 10

        let rectOrigin = [
            MIJSONKeyX : xOrigin,
            MIJSONKeyY : yOrigin
        ]
        
        let circleRect = [
            MIJSONKeyOrigin : [
                MIJSONKeyX : xOrigin - blurWidth,
                MIJSONKeyY : yOrigin - blurWidth
            ],
            MIJSONKeySize : [
                MIJSONKeyWidth : drawWidth + 2 * blurWidth,
                MIJSONKeyHeight : drawHeight + 2 * blurWidth
            ]
        ]
        
        let drawCircleElement = [
            MIJSONKeyElementType : MIJSONValueOvalFillElement,
            MIJSONKeyFillColor : blueColour,
            MIJSONKeyRect : circleRect
        ]
        
        let drawCircleCommand = [
            MIJSONKeyCommand : MIJSONValueDrawElementCommand,
            MIJSONKeyReceiverObject : bitmapObject,
            MIJSONPropertyDrawInstructions : drawCircleElement
        ]
        
        let clipRect = [
            MIJSONKeyOrigin : [
                MIJSONKeyX : xOrigin + strokeWidth / 2,
                MIJSONKeyY : yOrigin + strokeWidth / 2
            ],
            MIJSONKeySize : [
                MIJSONKeyWidth : drawWidth - strokeWidth,
                MIJSONKeyHeight : drawHeight - strokeWidth
            ]
        ]
        
        let clipPath = [
            [
                MIJSONKeyElementType : MIJSONValuePathRectangle,
                MIJSONKeyRect : clipRect
            ]
        ]
        
        let drawElement = [
            MIJSONKeyElementType : MIJSONValueRectangleStrokeElement,
            MIJSONKeyLineWidth : 10.0,
            MIJSONKeyRect : [
                MIJSONKeySize : drawSize,
                MIJSONKeyOrigin : rectOrigin
            ],
            MIJSONKeyStrokeColor : redColour,
            
            // Now add the clipping rectangle. Start point is ignored coz
            // first path element is a rectangle. Still required. The stroke
            // path is the inside edge of the stroked rectangle.
            MIJSONKeyClippingpath : [
               MIJSONKeyStartPoint : [ MIJSONKeyX : 0, MIJSONKeyY : 0 ],
               MIJSONKeyArrayOfPathElements : clipPath
            ],
            
            // Now add the shadow.
            MIJSONKeyShadow : [
                MIJSONKeyBlur : 10,
                MIJSONKeyShadowOffset : [
                    MIJSONKeyWidth : 0,
                    MIJSONKeyHeight : 0 ],
                MIJSONKeyFillColor : shadowColour
            ]
        ]
        
        let drawElementCommand = [
            MIJSONKeyCommand : MIJSONValueDrawElementCommand,
            MIJSONKeyReceiverObject : bitmapObject,
            MIJSONPropertyDrawInstructions : drawElement
        ]
        
        let imageIdentifier = "strokerectwithshadow.withshadow"
        let assignImageToCollectionCommand = [
            MIJSONKeyCommand : MIJSONValueAssignImageToCollectionCommand,
            MIJSONKeyReceiverObject : bitmapObject,
            MIJSONPropertyImageIdentifier : imageIdentifier
        ]
        
        let commandInstructions = [
            MIJSONKeyCommands : [
                createBitmapContextCommand2,
                drawCircleCommand,
                drawElementCommand,
                assignImageToCollectionCommand
            ],
            MIJSONKeyCleanupCommands : [
                closeBitmapContextCommand
            ]
        ]
        
        let theContext = MIContext()
        let result = MIMovingImagesHandleCommands(theContext, commandInstructions,
            nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssert(MIReplyErrorEnum.NoError == errorCode, "Failed to create image")
        if errorCode == MIReplyErrorEnum.NoError
        {
            let theImage = theContext.getCGImageWithIdentifier(imageIdentifier)
            let baseName = "StrokeRectangleWithShadowOverOval"
            if comparingImages
            {
                let namedImageName = makeFileName(baseName: baseName)
                let origImage = createCGImageFromNamedPNGImage(namedImageName)
                let imageDiff = compareImages(image1: origImage, image2: theImage)
                // println("Max image difference: \(imageDiff)")
                XCTAssert(imageDiff < 2, "Image file \(namedImageName) different")
            }
            else
            {
                saveCGImageToAPNGFile(theImage, baseName: baseName)
            }
        }
        else
        {
            println(MIGetStringFromReplyDictionary(result))
        }
    }

    // Demonstrate the drawing of a path with a fill and inner shadow
    func testFillAPathWithInnerShadow() -> Void {
        // Basically drawing a gold star with a inner shadow.
        
        // Drawing a linear gradient that changes vertically.
        let startPoint = [
            MIJSONKeyX : 130,
            MIJSONKeyY : 100
        ]
        
        let goldColour = [
            MIJSONKeyRed : 1.0,
            MIJSONKeyGreen : 0.85,
            MIJSONKeyBlue : 0.19,
            MIJSONKeyColorColorProfileName : "kCGColorSpaceGenericRGB"
        ]

        let blackColour = [
            MIJSONKeyRed : 0.0,
            MIJSONKeyGreen : 0.0,
            MIJSONKeyBlue : 0.0,
            MIJSONKeyColorColorProfileName : "kCGColorSpaceGenericRGB"
        ]

        let whiteColour = [
            MIJSONKeyRed : 1.0,
            MIJSONKeyGreen : 1.0,
            MIJSONKeyBlue : 1.0,
            MIJSONKeyColorColorProfileName : "kCGColorSpaceGenericRGB"
        ]
        
        let fillColour = goldColour
        let shadowColour = blackColour // whiteColour
        
        let pathElements = [
            [
                MIJSONKeyElementType : MIJSONValuePathLine,
                MIJSONKeyEndPoint : [ MIJSONKeyX : 157, MIJSONKeyY : 175 ]
            ],
            [
                MIJSONKeyElementType : MIJSONValuePathLine,
                MIJSONKeyEndPoint : [ MIJSONKeyX : 100, MIJSONKeyY : 220 ]
            ],
            [
                MIJSONKeyElementType : MIJSONValuePathLine,
                MIJSONKeyEndPoint : [ MIJSONKeyX : 175, MIJSONKeyY : 220 ]
            ],
            [
                MIJSONKeyElementType : MIJSONValuePathLine,
                MIJSONKeyEndPoint : [ MIJSONKeyX : 200, MIJSONKeyY : 300 ]
            ],
            [
                MIJSONKeyElementType : MIJSONValuePathLine,
                MIJSONKeyEndPoint : [ MIJSONKeyX : 225, MIJSONKeyY : 220 ]
            ],
            [
                MIJSONKeyElementType : MIJSONValuePathLine,
                MIJSONKeyEndPoint : [ MIJSONKeyX : 300, MIJSONKeyY : 220 ]
            ],
            [
                MIJSONKeyElementType : MIJSONValuePathLine,
                MIJSONKeyEndPoint : [ MIJSONKeyX : 243, MIJSONKeyY : 175 ]
            ],
            [
                MIJSONKeyElementType : MIJSONValuePathLine,
                MIJSONKeyEndPoint : [ MIJSONKeyX : 270, MIJSONKeyY : 100 ]
            ],
            [
                MIJSONKeyElementType : MIJSONValuePathLine,
                MIJSONKeyEndPoint : [ MIJSONKeyX : 200, MIJSONKeyY : 150 ]
            ],
            [
                MIJSONKeyElementType : MIJSONValueCloseSubPath,
            ]
        ]
        
        let drawElement = [
            MIJSONKeyElementType : MIJSONValuePathFillInnerShadowElement,
            MIJSONKeyFillColor : fillColour,
            // The following start point relates to the array of paths.
            MIJSONKeyStartPoint : startPoint,
            MIJSONKeyArrayOfPathElements : pathElements,
            
            // Now add the shadow.
            MIJSONKeyInnerShadow : [
                MIJSONKeyBlur : 10,
                MIJSONKeyShadowOffset : [ MIJSONKeyWidth : 0, MIJSONKeyHeight : 0],
                MIJSONKeyFillColor : shadowColour
            ]
        ]
        
        let drawElementCommand = [
            MIJSONKeyCommand : MIJSONValueDrawElementCommand,
            MIJSONKeyReceiverObject : bitmapObject,
            MIJSONPropertyDrawInstructions : drawElement
        ]
        
        let imageIdentifier = "fillpath.withinnershadow"
        let assignImageToCollectionCommand = [
            MIJSONKeyCommand : MIJSONValueAssignImageToCollectionCommand,
            MIJSONKeyReceiverObject : bitmapObject,
            MIJSONPropertyImageIdentifier : imageIdentifier
        ]
        
        let commandInstructions = [
            MIJSONKeyCommands : [
                createBitmapContextCommand2,
                drawElementCommand,
                assignImageToCollectionCommand
            ],
            MIJSONKeyCleanupCommands : [
                closeBitmapContextCommand
            ]
        ]
        
        let theContext = MIContext()
        let result = MIMovingImagesHandleCommands(theContext, commandInstructions,
            nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssert(MIReplyErrorEnum.NoError == errorCode, "Failed to create image")
        if errorCode == MIReplyErrorEnum.NoError
        {
            let theImage = theContext.getCGImageWithIdentifier(imageIdentifier)

            let baseName = "FillPathWithInnerShadow"
            if comparingImages
            {
                let namedImageName = makeFileName(baseName: baseName)
                let origImage = createCGImageFromNamedPNGImage(namedImageName)
                let imageDiff = compareImages(image1: origImage, image2: theImage)
                // println("Max image difference: \(imageDiff)")
                XCTAssert(imageDiff < 2, "Image file \(namedImageName) different")
            }
            else
            {
                saveCGImageToAPNGFile(theImage, baseName: baseName)
            }
        }
        else
        {
            println(MIGetStringFromReplyDictionary(result))
        }
    }

    func testFillTextWithInnerShadow() -> Void {
        // Drawing a bold system font with font size of 27.
        
        // Drawing a linear gradient that changes vertically.
        let startPoint = [
            MIJSONKeyX : 40,
            MIJSONKeyY : 200
        ]
        
        let darkGrayColour = [
            MIJSONKeyRed : 0.1,
            MIJSONKeyGreen : 0.1,
            MIJSONKeyBlue : 0.1,
            MIJSONKeyColorColorProfileName : "kCGColorSpaceGenericRGB"
        ]
        
        let whiteColour = [
            MIJSONKeyRed : 1.0,
            MIJSONKeyGreen : 1.0,
            MIJSONKeyBlue : 1.0,
            MIJSONKeyColorColorProfileName : "kCGColorSpaceGenericRGB"
        ]
        
        let fillColour = redColour
        let shadowColour = darkGrayColour
        // let shadowColour = whiteColour
        
        let drawElement = [
            MIJSONKeyElementType : MIJSONValueBasicStringElement,
            MIJSONKeyFillColor : fillColour,
            MIJSONKeyStringText : "Inner Shadow Text",
            MIJSONKeyUIFontType : MIJSONValueUIFontEmphasizedSystem,
            MIJSONKeyStringFontSize : 60,
            // The following start point relates to the array of paths.
            MIJSONKeyPoint : startPoint,
            
            // Now add the shadow.

            MIJSONKeyInnerShadow : [
                MIJSONKeyBlur : 6,
                MIJSONKeyShadowOffset : [
                    MIJSONKeyWidth : 2.0,
                    MIJSONKeyHeight : -2.0
                ],
                MIJSONKeyFillColor : shadowColour
            ]
        ]
        
        let drawElementCommand = [
            MIJSONKeyCommand : MIJSONValueDrawElementCommand,
            MIJSONKeyReceiverObject : bitmapObject,
            MIJSONPropertyDrawInstructions : drawElement
        ]
        
        let imageIdentifier = "drawtext.withinnershadow"
        let assignImageToCollectionCommand = [
            MIJSONKeyCommand : MIJSONValueAssignImageToCollectionCommand,
            MIJSONKeyReceiverObject : bitmapObject,
            MIJSONPropertyImageIdentifier : imageIdentifier
        ]
        
        let commandInstructions = [
            MIJSONKeyCommands : [
                createBitmapContextCommand,
                drawElementCommand,
                assignImageToCollectionCommand
            ],
            MIJSONKeyCleanupCommands : [
                closeBitmapContextCommand
            ]
        ]
        
        let theContext = MIContext()
        let result = MIMovingImagesHandleCommands(theContext, commandInstructions,
            nil)
        let errorCode = MIGetErrorCodeFromReplyDictionary(result)
        XCTAssert(MIReplyErrorEnum.NoError == errorCode, "Failed to create image")
        
        if errorCode == MIReplyErrorEnum.NoError
        {
            let theImage = theContext.getCGImageWithIdentifier(imageIdentifier)
            let baseName = "DrawTextWithInnerShadow"
            if comparingImages
            {
                let namedImageName = makeFileName(baseName: baseName)
                let origImage = createCGImageFromNamedPNGImage(namedImageName)
                let imageDiff = compareImages(image1: origImage, image2: theImage)
                // println("Max image difference: \(imageDiff)")
                XCTAssert(imageDiff < 2, "Image file \(namedImageName) different")
            }
            else
            {
                saveCGImageToAPNGFile(theImage, baseName: baseName)
            }
        }
        else
        {
            println(MIGetStringFromReplyDictionary(result))
        }
    }
}