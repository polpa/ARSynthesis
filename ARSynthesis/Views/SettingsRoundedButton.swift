//
//  SettingsRoundedButton.swift
//  ARSynthesis
//
//  Created by Pol Piella on 27/02/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import UIKit

class SettingsRoundedButton: UIButton {
    
    override func awakeFromNib() {
        self.layer.borderWidth = 3
        self.layer.masksToBounds = true
        self.layer.cornerRadius = 3
        
    }

}
