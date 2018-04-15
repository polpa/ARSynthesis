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
        planeDebugNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.50)
        planeDebugNode.geometry?.firstMaterial?.isDoubleSided = true
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
        planeDebugNode.geometry?.firstMaterial?.diffuse.contents = UIColor.white.withAlphaComponent(0.50)
        planeDebugNode.geometry?.firstMaterial?.isDoubleSided = true
        planeDebugNode.eulerAngles = SCNVector3(90.degreesToRadians,0,0)
        planeDebugNode.position = SCNVector3(self.center.x,
                                             self.center.y,
                                             self.center.z)
        planeDebugNode.nodeDescription = "basePlane"
        return planeDebugNode
    }
    
    func addSequencerPlane() -> SCNNode{
        let width = self.extent.x
        let height = self.extent.z
        let sequencerPlaneNode = SCNNode(geometry: SCNPlane(width: CGFloat(width), height: CGFloat(height)))
        sequencerPlaneNode.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
        sequencerPlaneNode.geometry?.firstMaterial?.isDoubleSided = true
        sequencerPlaneNode.eulerAngles = SCNVector3(0, 0, 0)
        sequencerPlaneNode.position = SCNVector3(self.center.x, self.center.y, self.center.z)
        sequencerPlaneNode.nodeDescription = "sequencerPlane"
        return sequencerPlaneNode
    }
    
    func updateSequencerPlane(parentNode: SCNNode) -> SCNNode{
        parentNode.enumerateChildNodes{ (childNode, _) in
            childNode.removeFromParentNode()
        }
        let width = self.extent.x
        let height = self.extent.z
        let sequencerPlaneNode = SCNNode(geometry: SCNPlane(width: CGFloat(width), height: CGFloat(height)))
        sequencerPlaneNode.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
        sequencerPlaneNode.geometry?.firstMaterial?.isDoubleSided = true
        sequencerPlaneNode.eulerAngles = SCNVector3(90.degreesToRadians,0,0)
        sequencerPlaneNode.position = SCNVector3(self.center.x,
                                             self.center.y,
                                             self.center.z)
        sequencerPlaneNode.nodeDescription = "sequencerPlane"
        return sequencerPlaneNode
    }
    
    func addKeyboardPlane() -> SCNNode{
        let width = self.extent.x
        let height = self.extent.z
        let keyboardPlaneNode = SCNNode(geometry: SCNPlane(width: CGFloat(width),
                                                        height: CGFloat(height)))
        keyboardPlaneNode.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan.withAlphaComponent(0.50)
        keyboardPlaneNode.geometry?.firstMaterial?.isDoubleSided = true
        keyboardPlaneNode.eulerAngles = SCNVector3(90.degreesToRadians,
                                                0,
                                                0)
        keyboardPlaneNode.position = SCNVector3(self.center.x,
                                             self.center.y,
                                             self.center.z)
        keyboardPlaneNode.nodeDescription = "keyboardPlane"
        return keyboardPlaneNode
    }
    
    
    func updateKeyboardDebugging(parentNode: SCNNode, selectedFunction: String) -> SCNNode{
        parentNode.enumerateChildNodes{ (childNode, _) in
            childNode.removeFromParentNode()
        }
        let width = self.extent.x
        let height = self.extent.z
        let planeDebugNode = SCNNode(geometry: SCNPlane(width: CGFloat(width), height: CGFloat(height)))
        planeDebugNode.geometry?.firstMaterial?.diffuse.contents = UIColor.cyan.withAlphaComponent(0.50)
        planeDebugNode.geometry?.firstMaterial?.isDoubleSided = true
        planeDebugNode.eulerAngles = SCNVector3(90.degreesToRadians,0,0)
        planeDebugNode.position = SCNVector3(self.center.x,
                                             self.center.y,
                                             self.center.z)
        planeDebugNode.nodeDescription = "keyboardPlane"
        
        return planeDebugNode
    }
    
    
}
