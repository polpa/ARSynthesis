//
//  RoundedPopUp.swift
//  ARSynthesis
//
//  Created by Pol Piella on 12/02/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import UIKit

class RoundedPopUp: UIView {
    
    override func awakeFromNib() {
        layer.borderWidth = 3
        layer.masksToBounds = true
        layer.cornerRadius = 10
    }
    
}
