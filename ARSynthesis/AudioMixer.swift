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
        mixer.connect(input: effectsMixer)
        effectsMixer.start()
        AudioKit.output = effectsMixer
        AudioKit.start()
    }
    
    open func appendOscillator(index: Int){
        oscillatorArray.append(AKOscillator(waveform: AKTable(.sine)))
        oscillatorArray[index].start()
        oscillatorArray[index].play()
        oscillatorArray[index].connect(to: mixer)
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
            reverb.dryWetMix = 1
            reverb.start()
            reverb.loadFactoryPreset(.cathedral)
            effectsArray.append(reverb)
            mixer.setOutput(to: AKReverb(effectsArray[index]))
            AKReverb(effectsArray[index]).connect(to: effectsMixer)
            break
        default:
            break
        }
        
    }
    
}

