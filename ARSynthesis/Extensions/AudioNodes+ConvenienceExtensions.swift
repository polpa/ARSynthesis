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
        static var prePitchShifter = AKPitchShifter()
        static var gainModule = AKBooster()
        static var sequencerTrack = AKMusicTrack()
        static var attachedFlanger = AKFlanger()
    }

    var attachedFlanger: AKFlanger? {
        get{
            return objc_getAssociatedObject(self, &audioAddOns.attachedFlanger) as? AKFlanger ?? AKFlanger()
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioAddOns.attachedFlanger,
                                         unwrappedValue as AKFlanger?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    var sequencerTrack: AKMusicTrack? {
        get{
            return objc_getAssociatedObject(self, &audioAddOns.sequencerTrack) as? AKMusicTrack ?? AKMusicTrack()
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioAddOns.sequencerTrack,
                                         unwrappedValue as AKMusicTrack?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
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
    
    var gainModule: AKBooster? {
        get{
            return objc_getAssociatedObject(self, &audioAddOns.gainModule) as? AKBooster ?? AKBooster()
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioAddOns.gainModule,
                                         unwrappedValue as AKBooster?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    
    var prePitchShifter: AKPitchShifter? {
        get{
            return objc_getAssociatedObject(self, &audioAddOns.prePitchShifter) as? AKPitchShifter ?? AKPitchShifter()
        }
        set{
            if let unwrappedValue = newValue {
                objc_setAssociatedObject(self,
                                         &audioAddOns.prePitchShifter,
                                         unwrappedValue as AKPitchShifter?,
                                         .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }
    
    
    
}
