
import ObjectiveC
import UIKit
import Foundation

// MARK: - This file extends the functionality of NSNodes from ARKit to include some key parameters for interconnection.
extension NSObject{
    private struct audioNodeProperties{
        static var allowsMultipleInputs:Bool = true //oscillators don't allow inputs
        static var outputIsConnected:Bool = false
        static var inputIsConnected:Bool = false
        static var nodeDescription: String = ""
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
