//
//  AudioMixer.swift
//  ARSynthesis
//
//  Created by Pol Piella on 25/01/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import Foundation
import AudioKit
import ARKit

/// This is the core Audio Processing class.
class AudioMixer{
    var oscillatorArray: [AKOscillator] = []
    var effectsArray: [AKNode] = []
    var mixer = AKMixer()
    var effectsMixer = AKMixer()
    var strung: String = ""
    /// Class initializer
    private init(){}
    static let singletonMixer = AudioMixer()

    func initialize(){
        mixer.start()
        effectsMixer.start()
        AudioKit.output = mixer
        AudioKit.start()
    }
    open func scaleValue(of: SCNNode, scaleValue: Double){
        switch of.nodeDescription! {
        case "reverb":
            let reverb = of.audioNodeContained as! AKReverb
            reverb.dryWetMix = reverb.dryWetMix * scaleValue
            break
        case "oscillator":
            let osc = of.audioNodeContained as! AKOscillator
            osc.amplitude = osc.amplitude * scaleValue
            break
        case "delay":
            let delay = of.audioNodeContained as! AKDelay
            delay.dryWetMix = delay.dryWetMix * scaleValue
            break
        default:
            break
        }
        
        
    }
    /// This function adds an oscillator to the oscillator array.
    ///
    /// - Parameter index: Current oscillator array's index.
    open func appendOscillator(oscillator: AKOscillator){
        oscillator.start()
        oscillator.amplitude = 0.5
        oscillator.connect(to: mixer)
    
    }
    
    open func connect(fromOutput: SCNNode, toInput: SCNNode){
        switch toInput.nodeDescription! {
        case "reverb":
            fromOutput.audioNodeContained?.disconnectOutput()
            fromOutput.audioNodeContained?.connect(to: (toInput.audioNodeContained?.attachedMixer)!)
            break
        case "delay":
            fromOutput.audioNodeContained?.disconnectOutput()
            fromOutput.audioNodeContained?.connect(to: (toInput.audioNodeContained?.attachedMixer)!)
            break
        default:
            break
        }
        //fromOutput.audioNodeContained?.connect(to: t)
    }
    /// This function removes an oscillator from the array.
    ///
    /// - Parameter index: Current oscillator array's index.
    open func removeOscillator(oscillator: AKOscillator){
        oscillator.disconnectOutput()
        oscillator.stop()
    }
    open func append(node: SCNNode){
        switch node.nodeDescription! {
        case "oscillator":
            let oscillator = AKOscillator(waveform: AKTable(.sawtooth))
            oscillator.start()
            oscillator.amplitude = 0.5
            oscillator.connect(to: mixer)
            node.audioNodeContained = oscillator
            break
        case "reverb":
            let effectInputMixer = AKMixer()
            let reverb = AKReverb()
            reverb.start()
            reverb.dryWetMix = 1
            reverb.loadFactoryPreset(.cathedral)
            reverb.connect(to: mixer)
            node.audioNodeContained = reverb
            node.audioNodeContained?.attachedMixer = effectInputMixer
            node.audioNodeContained?.attachedMixer?.connect(to: reverb)
            break
        case "delay":
            let effectInputMixer = AKMixer()
            let delay = AKDelay()
            delay.start()
            delay.dryWetMix = 1
            delay.time = 0.3
            delay.feedback = 0.5
            delay.connect(to: mixer)
            node.audioNodeContained = delay
            node.audioNodeContained?.attachedMixer = effectInputMixer
            node.audioNodeContained?.attachedMixer?.connect(to: delay)
            break
        default:
            break
        }
        
    }
    open func remove(node: SCNNode){
            node.audioNodeContained?.disconnectOutput()
    }
}

