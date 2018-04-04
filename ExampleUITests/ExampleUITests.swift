//
//  ExampleUITests.swift
//  ExampleUITests
//
//  Created by Alejandro Ruperez Hernando on 26/2/18.
//  Copyright © 2018 alexruperez. All rights reserved.
//

import XCTest

class ExampleUITests: XCTestCase {

    let app = XCUIApplication()
    let duration: TimeInterval = 3
        
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app.launch()
    }
    
    func testButton() {
        app.buttons.firstMatch.press(forDuration: duration)
        sleep(UInt32(duration))
    }

    func testButtonThenDrag() {
        app.buttons.firstMatch.press(forDuration: duration, thenDragTo: app.otherElements.firstMatch)
        sleep(UInt32(duration))
    }
    
}
