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

        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()
        
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testGenerateScreenshots() {
        let app = XCUIApplication()
        
        if app.alerts.count > 0 {
            app.alerts.element(boundBy: 0).buttons.element(boundBy: 1).tap()
        }
        
        let cells = app.tables.cells
        XCTAssertEqual(cells.count, 9, "found instead: \(cells.debugDescription)")
        snapshot("0Launch")
        
        cells.element(boundBy: 4).tap()
        for _ in 1...7 {
            app.navigationBars.buttons.element(boundBy: 1).tap()
            app.alerts.textFields.element(boundBy: 0).typeText("415\(randomNumberWith(digits:7))")
            app.alerts.buttons.element(boundBy: 1).tap()
            sleep(2)
        }
        
        app.navigationBars.buttons.element(boundBy: 1).tap()
        app.alerts.textFields.element(boundBy: 0).typeText("4158675309")
        snapshot("1BlockAlert")
        app.alerts.buttons.element(boundBy: 1).tap()
        app.navigationBars.buttons.element(boundBy: 0).tap()
        
        cells.element(boundBy: 5).tap()
        app.textViews.element(boundBy: 0).tap()
        app.textViews.element(boundBy: 0).typeText("Ringtone Club: Gr8 new polys direct to your mobile every week!")
        sleep(2)
        snapshot("2ReportSMS")
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }
    
    func randomNumberWith(digits:Int) -> Int {
        let min = Int(pow(Double(10), Double(digits-1))) - 1
        let max = Int(pow(Double(10), Double(digits))) - 1
        return Int(Range(uncheckedBounds: (min, max)))
    }
}

extension Int {
    init(_ range: Range<Int> ) {
        let delta = range.lowerBound < 0 ? abs(range.lowerBound) : 0
        let min = UInt32(range.lowerBound + delta)
        let max = UInt32(range.upperBound   + delta)
        self.init(Int(min + arc4random_uniform(max - min)) - delta)
    }
}
