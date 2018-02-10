//
//  AudioNodes+ConvenienceExtensions.swift
//  ARSynthesis
//
//  Created by Pol Piella on 10/02/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import Foundation
import AudioKit
extension AKNode{
    private struct audioAddOns{
        static var attachedMixer = AKMixer()
    }
    
    var attachedMixer: AKMixer? {
        get{
            return objc_getAssociatedObject(self, &audioAddOns.attachedMixer) as? AKMixer ?? AKMixer()
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioAddOns.attachedMixer,
                                         unwrappedValue as AKMixer?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    
    
}
