//
//  File.swift
//  Ikea
//
//  Created by Pol Piella on 25/01/2018.
//  Copyright © 2018 Rayan Slim. All rights reserved.
//

import Foundation
import AudioKit

class AudioMixer{
    var oscillatorArray: [AKOscillator] = []
    var effectsArray: [AKNode] = []
    var mixer = AKMixer()
    var effectsMixer = AKMixer()
    init(){
        mixer.start()
        effectsMixer.start()
        AudioKit.output = mixer
        AudioKit.start()
    }
    /// This function adds an oscillator to the oscillator array.
    ///
    /// - Parameter index: Current oscillator array's index.
    open func appendOscillator(index: Int){
        oscillatorArray.append(AKOscillator(waveform: AKTable(.sine)))
        oscillatorArray[index].start()
        oscillatorArray[index].play()
        for oscillator in oscillatorArray{
            oscillator.connect(to: mixer)
        }
    }
    /// This function removes an oscillator from the array.
    ///
    /// - Parameter index: Current oscillator array's index.
    open func removeOscillator(index: Int){
        print(index)
        oscillatorArray[index].stop()
        oscillatorArray.remove(at: index)
    }
    open func scaleOscillatorAmplitude(index: Int, scalingFactor: Double){
        oscillatorArray[index].amplitude = oscillatorArray[index].amplitude * scalingFactor
    }
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

