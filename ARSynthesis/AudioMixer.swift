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
    var emptyEffect = AKReverb()
    
    init(){
        mixer.start()
        effectsMixer.start()
        mixer.connect(to: emptyEffect)
        emptyEffect.start()
        emptyEffect.dryWetMix = 0
        emptyEffect.connect(to: effectsMixer)
        AudioKit.output = effectsMixer
        AudioKit.start()
    }
    
    open func appendOscillator(index: Int){
        //This WORKS!
        oscillatorArray.append(AKOscillator(waveform: AKTable(.sine)))
        oscillatorArray[index].start()
        oscillatorArray[index].play()
        for oscillator in oscillatorArray{
            oscillator.connect(to: mixer)
        }
    }
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
        case "reverb":
            print("This is basically adding a reverb to the scene")
            let reverb = AKReverb()
            effectsArray.append(reverb)
            AKReverb(effectsArray[index]).start()
            AKReverb(effectsArray[index]).dryWetMix = 1
            AKReverb(effectsArray[index]).loadFactoryPreset(.cathedral)
            for effect in effectsArray{
                mixer.connect(to: AKReverb(effect))
                effect.connect(to: effectsMixer)
            }
            break
        default:
            break
        }
    }
    
}

