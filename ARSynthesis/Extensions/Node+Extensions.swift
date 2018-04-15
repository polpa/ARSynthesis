
import ObjectiveC
import UIKit
import Foundation
import ARKit
import AudioKit

// MARK: - This file extends the functionality of NSNodes from ARKit to include some key parameters for interconnection.
extension SCNNode{
    
    private struct audioNodeProperties{
        static var allowsMultipleInputs:Bool = true //oscillators don't allow inputs
        static var outputIsConnected:Bool = false
        static var inputIsConnected:Bool = false
        static var isEffect:Bool = false
        static var adsrIsVisible: Bool = false
        static var nodeDescription: String = ""
        static var isLinkedBy: String = ""
        static var inputConnection: SCNNode = SCNNode()
        static var outputConnection: SCNNode = SCNNode()
        static var audioNodeContained: [AKNode] = []
        static var overallAmplitude: CGFloat = 1.0
        static var sides: [Any?] = []
        static var isHandsFreeEnabled:Bool = false
        static var width:CGFloat = 0.0
        static var height: CGFloat = 0.0
        static var mode: String = ""
    }
    
    func removeAllLinks(scene: ARSCNView) {
        scene.scene.rootNode.enumerateChildNodes { (node, stop) in
            let keyStringPath = "Link"
            if(node.name != nil){
                let currentName = node.name
                //removeAllLinksContainingTheName
                if (currentName?.containsIgnoringCase(find: keyStringPath))! && (currentName?.containsIgnoringCase(find: self.name!))! {
                    node.removeFromParentNode()
                }
            }
           
        }
    }
    
    
    func initialiseParameters() {
        switch self.nodeDescription! {
        case "reverb", "delay", "lowPass", "flanger", "distortion":
            self.inputIsConnected = false
            self.allowsMultipleInputs = true
            self.outputIsConnected = false
            self.isEffect = true
            break
        case "oscillator":
            self.inputIsConnected = false
            self.outputIsConnected = false
            self.allowsMultipleInputs = false
            self.isEffect = false
            break
        default:
            break
        }
        
    }
    
    var isHandsFreeEnabled: Bool? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.isHandsFreeEnabled) as? Bool ?? true
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.isHandsFreeEnabled,
                                         unwrappedValue as Bool?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    var adsrIsVisible: Bool? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.adsrIsVisible) as? Bool ?? false
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.adsrIsVisible,
                                         unwrappedValue as Bool?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    var mode: String? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.mode) as? String ?? "none"
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.mode,
                                         unwrappedValue as String?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    var sides: [Any]? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.sides) as? [Any] ?? [SCNMaterial()]
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.sides,
                                         unwrappedValue as [Any]?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    var overallAmplitude: CGFloat? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.overallAmplitude) as? CGFloat ?? 1.0
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.overallAmplitude,
                                         unwrappedValue as CGFloat?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    var width: Float? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.width) as? Float ?? 1.0
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.width,
                                         unwrappedValue as Float?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    var height: Float? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.height) as? Float ?? 1.0
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.height,
                                         unwrappedValue as Float?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    
    
    var audioNodeContained: AKNode? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.audioNodeContained) as? AKNode ?? AKNode()
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.audioNodeContained,
                                         unwrappedValue as AKNode?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    var inputConnection: [SCNNode]? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.inputConnection) as? [SCNNode] ?? []
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.inputConnection,
                                         unwrappedValue as [SCNNode]?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    var outputConnection: SCNNode? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.outputConnection) as? SCNNode ?? nil
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.outputConnection,
                                         unwrappedValue as SCNNode?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    var isLinkedBy: String? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.isLinkedBy) as? String ?? ""
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.isLinkedBy,
                                         unwrappedValue as NSString?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    var nodeDescription: String? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.nodeDescription) as? String ?? ""
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.nodeDescription,
                                         unwrappedValue as NSString?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    var allowsMultipleInputs: Bool? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.allowsMultipleInputs) as? Bool ?? true
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.allowsMultipleInputs,
                                         unwrappedValue as Bool?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    var isEffect: Bool? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.isEffect) as? Bool ?? false
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.isEffect,
                                         unwrappedValue as Bool?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    var inputIsConnected: Bool? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.inputIsConnected) as? Bool ?? false
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.inputIsConnected,
                                         unwrappedValue as Bool?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    var outputIsConnected: Bool? {
        get{
            return objc_getAssociatedObject(self, &audioNodeProperties.outputIsConnected) as? Bool ?? false
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioNodeProperties.outputIsConnected,
                                         unwrappedValue as Bool?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    
}
