//
//  RoundedBackgroundImage.swift
//  ARSynthesis
//
//  Created by Pol Piella on 27/02/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import UIKit

class RoundedBackgroundImage: UIImageView {
    
    override func awakeFromNib() {
        
        self.layer.borderWidth = 3
        self.layer.borderColor = UIColor.black.cgColor
        self.layer.cornerRadius = 10
        
    }

}
