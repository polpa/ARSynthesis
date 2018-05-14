import Foundation
import PopupDialog

// MARK: - This is an extension to the popup dialog to change the initialiser to a more convenient one, where a string identifies the kind of popup dialog and hence changes the messages using a switch/case statement.
extension PopupDialog {
    
    public convenience init(identifier: String) {
        var message = ""
        var title = ""
        switch identifier {
        case "intro":
            title = "WELCOME TO ARSYNTHESIS"
            message = "Please be aware that, for a good and safe AR experience, one must always watch its environment and not use it while conducting potentially hazardous situations"
            break
        case "Faulty Connection":
            title = "Connection not made!"
            message = "An oscillator can't be connected to another oscillator. Try another connection. Hint: Could connect it to an effect."
            break
        case "misplaced":
            title = "Nodes must be placed on a plane."
            message = "Please ensure the node is placed on a plane before attempting another connection."
            break
        default:
            break
        }
        
        self.init(title: title,
                  message: message,
                  buttonAlignment: .horizontal,
                  transitionStyle: .zoomIn,
                  gestureDismissal: true,
                  hideStatusBar: true)
    }
}
