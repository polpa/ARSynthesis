//
//  PopUpDialog+Extensions.swift
//  ARSynthesis
//
//  Created by Pol Piella on 05/02/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import Foundation
import PopupDialog
extension PopupDialog {
    public convenience init(identifier: String) {
        var message = ""
        var title = ""
        switch identifier {
        case "intro":
            title = "WELCOME TO ARSYNTHESIS"
            message = "Please be aware that, for a good and safe AR experience, one must always watch its environment and not use it while conducting potentially hazardous situations"
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
