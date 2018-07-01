//
//  Text_ProtectorUITests.swift
//  Text ProtectorUITests
//
//  Created by Eric Lewis on 6/24/18.
//  Copyright © 2018 Eric Lewis Innovations, LLC. All rights reserved.
//

import XCTest

class Text_ProtectorUITests: XCTestCase {
        
    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        setupSnapshot(app)
        XCUIApplication().launch()

    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        // Use recording to get started writing UI tests.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
}
