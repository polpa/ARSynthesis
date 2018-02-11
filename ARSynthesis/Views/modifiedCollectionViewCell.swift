//
//  modifiedCollectionViewCell.swift
//  ARSynthesis
//
//  Created by Pol Piella on 07/02/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import UIKit
import ARKit

class modifiedCollectionViewCell: UICollectionViewCell {
    @IBOutlet var settingsCellImage: UIButton!
    @IBOutlet var settingsCellLabel: UILabel!
    var nodeContained: SCNNode = SCNNode()
    
    @IBAction func pressedButton(_ sender: UIButton) {
        print(nodeContained.nodeDescription!)
        nodeContained.audioNodeContained?.disconnectOutput()
        
    }
    
    
    
    
}
