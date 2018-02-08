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
    init(){
        mixer.start()
        effectsMixer.start()
        AudioKit.output = mixer
        AudioKit.start()
    }
    open func scaleValue(of: SCNNode){
        
        
    }
    /// This function adds an oscillator to the oscillator array.
    ///
    /// - Parameter index: Current oscillator array's index.
    open func appendOscillator(oscillator: AKOscillator){
        oscillator.start()
        oscillator.amplitude = 0.5
        oscillator.connect(to: mixer)
    }
    
    open func conect(fromOutput: SCNNode, toInput: SCNNode){
        fromOutput.audioNodeContained?.disconnectOutput()
    }
    /// This function removes an oscillator from the array.
    ///
    /// - Parameter index: Current oscillator array's index.
    open func removeOscillator(oscillator: AKOscillator){
        oscillator.disconnectOutput()
        oscillator.stop()
    }
    /// This function scales the amplitude of an oscillator whenever, called with the pinchGestureRecognizer.
    ///
    /// - Parameters:
    ///   - index: Current oscillator array's index.
    ///   - scalingFactor: Amplitude Scaling Factor.
    open func scaleOscillatorAmplitude(osc: AKOscillator, scalingFactor: Double){
        osc.amplitude = osc.amplitude * scalingFactor
    }
    
    open func connectToReverb(startingNode: SCNNode, destinationNode: SCNNode){
        startingNode.audioNodeContained?.disconnectOutput()
        let destinationNodeReverb = destinationNode.audioNodeContained as! AKReverb
        startingNode.audioNodeContained?.connect(to: destinationNodeReverb)
        destinationNodeReverb.connect(to: mixer)
    }
    open func appendReverb(reverb: AKReverb){
        reverb.start()
        reverb.dryWetMix = 0.7
        reverb.loadFactoryPreset(.cathedral)
    }
    /// This function adds an effect to the effects array.
    ///
    /// - Parameters:
    ///   - effectName: Effect Type
    ///   - index: Current effect array's index.
    open func appendEffect(effectName: String, index: Int){
        switch effectName {
        case "Reverb":
            let reverb = AKReverb()
            reverb.start()
            reverb.dryWetMix = 1
            reverb.loadFactoryPreset(.cathedral)
            mixer.disconnectOutput()
            mixer.connect(to: reverb)
            effectsMixer.disconnectInput()
            reverb.connect(to: effectsMixer)
            AudioKit.output = effectsMixer
            break
        default:
            break
        }
    }
}

