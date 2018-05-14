import Foundation
import AudioKit

// MARK: - This class adds the necessary AudioKit Audio Components to create a suitable AKNode.
extension AKNode{
    
    private struct audioAddOns{
        static var attachedMixer = AKMixer()
        static var prePitchShifter = AKPitchShifter()
        static var gainModule = AKBooster()
        static var sequencerTrack = AKMusicTrack()
        static var attachedFlanger = AKFlanger()
    }

    /// This is a module attached to the AKNode, giving a hint to adding a flanger as future work.
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

    /// This will be amed at oscillators, which need to have an embedded sequencer track in order to play.
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

    /// This variable is aimed at effect nodes and handles all of the unlimited input connections to these.
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
    
    /// This is a module which can prevent clipping if necessary but turning down the gain of the sound chain at any point.
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

    
    /// In order to change the pitch in an efficient manner, a pitch shifter is attached to the AKNode. 
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
