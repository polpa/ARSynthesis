//
//  ARPlane+Extensions.swift
//  ARSynthesis
//
//  Created by Pol Piella on 06/02/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import Foundation
import ARKit
extension ARPlaneAnchor{
    private struct audioNodeProperties{

    }
    func addPlaneDebugging() -> SCNNode{
        let width = self.extent.x
        let height = self.extent.z
        let planeDebugNode = SCNNode(geometry: SCNPlane(width: CGFloat(width), height: CGFloat(height)))
        planeDebugNode.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
        planeDebugNode.geometry?.firstMaterial?.isDoubleSided = true
        planeDebugNode.eulerAngles = SCNVector3(90.degreesToRadians,0,0)
        planeDebugNode.position = SCNVector3(self.center.x,
                                             self.center.y,
                                             self.center.z)
        planeDebugNode.nodeDescription = "basePlane"
        return planeDebugNode
    }
    func updatePlaneDebugging(parentNode: SCNNode) -> SCNNode{
        parentNode.enumerateChildNodes{ (childNode, _) in
            childNode.removeFromParentNode()
        }
        let width = self.extent.x
        let height = self.extent.z
        let planeDebugNode = SCNNode(geometry: SCNPlane(width: CGFloat(width), height: CGFloat(height)))
        planeDebugNode.geometry?.firstMaterial?.diffuse.contents = UIColor.darkGray
        planeDebugNode.geometry?.firstMaterial?.isDoubleSided = true
        planeDebugNode.eulerAngles = SCNVector3(90.degreesToRadians,0,0)
        planeDebugNode.position = SCNVector3(self.center.x,
                                             self.center.y,
                                             self.center.z)
        planeDebugNode.nodeDescription = "basePlane"
        return planeDebugNode
    }
    
    
}
