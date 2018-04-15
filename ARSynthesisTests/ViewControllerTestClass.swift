//
//  ViewControllerTestClass.swift
//  ARSynthesisTests
//
//  Created by Pol Piella on 24/02/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import XCTest
import ARKit
@testable import ARSynthesis

class ViewControllerTestClass: XCTestCase {
    let vc = ARViewController()
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func testDeltaModulusCalculations(){
        //Test to asser that the horizontal distance calculation works.
        let relative = SCNVector3Make(0, 2, 2)
        let anchor = SCNVector3Make(0, 4, 4)
        XCTAssertEqual(vc.deltaModulusCalculation(relative: relative, anchor: anchor), 2)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
