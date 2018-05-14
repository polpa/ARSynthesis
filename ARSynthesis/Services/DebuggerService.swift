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
