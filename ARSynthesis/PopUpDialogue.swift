

import Foundation
import PopupDialog
class Dialog{
    init() {
        func showStandardDialog(animated: Bool = true) {
            
            // Prepare the popup
            let title = "THIS IS A DIALOG WITHOUT IMAGE"
            let message = "If you don't pass an image to the default dialog, it will display just as a regular dialog. Moreover, this features the zoom transition"
            
            // Create the dialog
            let popup = PopupDialog(title: title,
                                    message: message,
                                    buttonAlignment: .horizontal,
                                    transitionStyle: .zoomIn,
                                    gestureDismissal: true,
                                    hideStatusBar: true) {
                                        print("Completed")
            }
            
            // Create first button
            let buttonOne = CancelButton(title: "CANCEL") {
            }
            
            // Create second button
            let buttonTwo = DefaultButton(title: "OK") {
            }
            
            // Add buttons to dialog
            popup.addButtons([buttonOne, buttonTwo])
            
            // Present dialog
            popup.present(popup, animated: animated, completion: nil)
        }
        
    }
    
    
}
