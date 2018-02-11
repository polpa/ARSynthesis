//
//  ARHandler.swift
//  ARSynthesis
//
//  Created by Pol Piella on 11/02/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import ARKit

class ARHandler{
    var arScene = ARSCNView()
    var collectionCells: [UICollectionViewCell] = []
    private init (){}
    static let arHandler = ARHandler()
    
}
