//
//  DebuggerService.swift
//  ARSynthesis
//
//  Created by Pol Piella on 26/02/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//
import Foundation
import SwiftyBeaver

class DebuggerService{
    let log = SwiftyBeaver.self
    let console = ConsoleDestination()
    private init(){}
    static let singletonDebugger = DebuggerService()
    
    func initialise(){
        self.log.addDestination(console)
        console.levelColor.verbose = "🛠"
        console.levelColor.debug = "💻"
        console.levelColor.info = "💁🏻‍♂️"
        console.levelColor.warning = "⚠️"
        console.levelColor.error = "☠️"
    }
}
