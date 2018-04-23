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

class AudioInterfaceHandler {
    
    var oscillatorArray: [AKMorphingOscillatorBank] = []
    var effectsArray: [AKNode] = []
    var mixer = AKMixer()
    var effectsMixer = AKMixer()
    var sequencer = AKSequencer()
    var strung: String = ""
    let log = DebuggerService.singletonDebugger.log
    let duration = AKDuration(beats: 4)
    private init(){}
    static let singletonMixer = AudioInterfaceHandler()

    func initialize(){
        sequencer.setLength(duration)
        sequencer.setTempo(248)
        sequencer.enableLooping(duration)
        mixer.start()
        effectsMixer.start()
        AudioKit.output = mixer
        do {
            try AudioKit.start()
        } catch {
            AKLog("AudioKit did not start!")
        }
    }
    
    /// This node takes care of scaling multiple nodes.
    ///
    /// - Parameters:
    ///   - of: Node to be scaled
    ///   - scaleValue: Scaling Value, used in the switch statement to scale the value of the audio contained node.
    open func scaleValue(of: SCNNode, scaleValue: Double){
        switch of.nodeDescription! {
        case "reverb":
            let reverb = of.audioNodeContained as! AKReverb
            reverb.dryWetMix = scaleValue
            print(reverb.dryWetMix)
            //THIS WORKS
            break
        case "oscillator":
            let gainController = of.audioNodeContained?.gainModule!
            gainController?.gain = scaleValue
            //THIS WORKS
            break
        case "delay":
            let delay = of.audioNodeContained as! AKDelay
            delay.dryWetMix = scaleValue
            //THIS WORKS
            break
        case "lowPass":
            let lowPass = of.audioNodeContained as! AKMoogLadder
            let temporal = scaleValue * 1000
            lowPass.cutoffFrequency = temporal
            //THIS WORKS
            break
        case "vibrato":
            let node =  of.outputConnection!
            let oscillator = node.audioNodeContained as! AKMorphingOscillatorBank
            let temporalOne = scaleValue
            let temporalTwo = scaleValue * 10
            oscillator.vibratoDepth = temporalOne
            oscillator.vibratoRate = temporalTwo
            break
        default:
            break
        }
    }
    
    open func detuneMinusOne(with node: SCNNode){
        guard let pitchShifter = node.audioNodeContained?.prePitchShifter else {return}
        pitchShifter.shift = pitchShifter.shift - 1.0
    }
    
    open func detunePlusOne(with node: SCNNode){
        guard let pitchShifter = node.audioNodeContained?.prePitchShifter else {return}
        pitchShifter.shift = pitchShifter.shift + 1.0
    }
    
    open func connect(fromOutput: SCNNode, toInput: SCNNode){
        log.verbose(!((fromOutput.nodeDescription?.isEmpty)!))
        log.verbose(!(fromOutput.nodeDescription?.contains(find: "plane"))!)
        log.verbose(!((toInput.nodeDescription?.isEmpty)!))
        log.verbose(!(toInput.nodeDescription?.contains(find: "plane"))!)
        if !((fromOutput.nodeDescription?.isEmpty)!)
            && !(fromOutput.nodeDescription?.contains(find: "plane"))!
            && !((toInput.nodeDescription?.isEmpty)!)
            && !(toInput.nodeDescription?.contains(find: "plane"))! {
            log.verbose("Connection was succesful")
            if (fromOutput.nodeDescription?.elementsEqual("oscillator"))!{
                log.verbose("Oscillator was succesfully connected")
                fromOutput.audioNodeContained?.prePitchShifter?.disconnectOutput()
                fromOutput.audioNodeContained?.prePitchShifter?.connect(to: (toInput.audioNodeContained?.attachedMixer)!)
            } else {
                log.verbose("Effect was succesfully connected")
                fromOutput.audioNodeContained?.disconnectOutput()
                fromOutput.audioNodeContained?.connect(to: (toInput.audioNodeContained?.attachedMixer)!)
            }
        }

    }
    
    open func sequencerSelected(){
        sequencer.play()
        log.verbose("Num. of sequencer tracks: \(sequencer.tracks.count)")
    }
    
    open func append(node: SCNNode){
        switch node.nodeDescription! {
        case "oscillator":
            let pitchShifter = AKPitchShifter()
            let oscillator = AKMorphingOscillatorBank(waveformArray: [AKTable(.sine), AKTable(.triangle), AKTable(.sawtooth), AKTable(.square)])
            let gainControl = AKBooster()
            oscillator.vibratoDepth = 12
            oscillator.vibratoRate = 0
            gainControl.start()
            gainControl.gain = 1
            pitchShifter.start()
            oscillator.connect(to: gainControl)
            gainControl.connect(to: pitchShifter)
            pitchShifter.connect(to: mixer)
            oscillatorArray.append(oscillator)
            node.audioNodeContained = oscillator
            node.audioNodeContained?.prePitchShifter = pitchShifter
            node.audioNodeContained?.gainModule = gainControl
            let midiNode = AKMIDINode(node: node.audioNodeContained as! AKPolyphonicNode)
            let track = sequencer.newTrack()!
            track.setMIDIOutput(midiNode.midiIn)
            node.audioNodeContained?.sequencerTrack = track
            let isPlaying = sequencer.isPlaying
            sequencer.stop()
            self.initialiseTrack(with: track)
            if isPlaying{
                log.verbose("stop and play")
                sequencer.play()
            } else {
                sequencer.stop()
                sequencer.enableLooping(duration)
            }
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
        case "vibrato":
//            let effectInputMixer = AKMixer()
//            let vibrato = AKvibrato()
//            vibrato.start()
//            vibrato.dryWetMix = 0.5
//            vibrato.depth = 1
//            vibrato.feedback = 0.6
//            vibrato.frequency = 10
//            vibrato.connect(to: mixer)
//            node.audioNodeContained = vibrato
//            node.audioNodeContained?.attachedMixer = effectInputMixer
//            node.audioNodeContained?.attachedMixer?.connect(to: vibrato)
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
        case "lowPass":
            let effectInputMixer = AKMixer()
            let lowPass = AKMoogLadder()
            lowPass.start()
            lowPass.cutoffFrequency = 20000
            lowPass.connect(to: mixer)
            node.audioNodeContained = lowPass
            node.audioNodeContained?.attachedMixer = effectInputMixer
            node.audioNodeContained?.attachedMixer?.connect(to: lowPass)
            break
        default:
            break
        }
        
    }
    
    private func restartSequencer(){
        
        
    }
    private func initialiseTrack (with track: AKMusicTrack){
        track.clear()
        track.add(noteNumber: 60, velocity: 60, position: AKDuration(beats: 0), duration: AKDuration(beats: 1))
        track.add(noteNumber: 60, velocity: 60, position: AKDuration(beats: 1), duration: AKDuration(beats: 1))
        track.add(noteNumber: 60, velocity: 60, position: AKDuration(beats: 2), duration: AKDuration(beats: 1))
        track.add(noteNumber: 60, velocity: 60, position: AKDuration(beats: 3), duration: AKDuration(beats: 1))
    }

    open func removeFromSequence(buttonTag: String){
        let theSequencerTag = buttonTag
        let row: Int = Int(theSequencerTag.components(separatedBy: ".")[0])!
        for track in sequencer.tracks{
            track.clearRange(start: AKDuration(beats: Double(row)), duration: AKDuration(beats: Double(row + 1)))
        }
        
    }
    
    open func sequenceValue(buttonTag: String){
        let theSequencerTag = buttonTag
        var row: Int = 0
        var freq: Int = 0
        switch theSequencerTag {
        case "0.0", "1.0", "2.0", "3.0":
            let components: [String] = theSequencerTag.components(separatedBy: ".")
            row = Int(components[0])!
            freq = 60
            break
        case "0.1", "1.1", "2.1", "3.1":
            let components: [String] = theSequencerTag.components(separatedBy: ".")
            row = Int(components[0])!
            freq = 63
            break
        case "0.2", "1.2", "2.2" ,"3.2":
            let components: [String] = theSequencerTag.components(separatedBy: ".")
            row = Int(components[0])!
            freq = 65
            break
        case "0.3", "1.3", "2.3", "3.3":
            let components: [String] = theSequencerTag.components(separatedBy: ".")
            row = Int(components[0])!
            freq = 67
            break
        default:
            break
        }
        for track in sequencer.tracks{
            track.clearRange(start: AKDuration(beats: Double(row)), duration: AKDuration(beats: row+1))
            track.add(noteNumber: MIDINoteNumber(freq), velocity: 64, position: AKDuration(beats: Double(row)), duration: AKDuration(beats: 1))
        }
    }
    
    open func remove(node: SCNNode){
        if (node.nodeDescription?.elementsEqual("oscillator"))! {
            if (node.inputConnection?.isNotEmpty)!{
                let oscillator = node.audioNodeContained as! AKMorphingOscillatorBank
                oscillator.stop(noteNumber: 1)
                oscillator.disconnectOutput()
                node.audioNodeContained?.prePitchShifter?.disconnectOutput()
                node.audioNodeContained?.prePitchShifter = nil
                node.audioNodeContained = nil
                let tag = sequencer.tracks.index { (track) -> Bool in
                    var bool = false
                    if track.internalMusicTrack == node.audioNodeContained?.sequencerTrack?.internalMusicTrack {
                        bool = true
                    } else {
                        bool = false
                    }
                    return bool
                }
                sequencer.tracks.remove(at: tag!)
                log.verbose(sequencer.tracks.count)
            } else {
                let oscillator = node.audioNodeContained as! AKMorphingOscillatorBank
                oscillator.stop(noteNumber: 1)
                oscillator.disconnectOutput()
                node.audioNodeContained?.prePitchShifter?.disconnectOutput()
                node.audioNodeContained?.prePitchShifter = nil
                node.audioNodeContained = nil
                //node.audioNodeContained?.sequencerTrack?.clear()
                let tag = sequencer.tracks.index { (track) -> Bool in
                    var bool = false
                    if track.internalMusicTrack == node.audioNodeContained?.sequencerTrack?.internalMusicTrack {
                        bool = true
                    } else {
                        bool = false
                    }
                    return bool
                }
                sequencer.tracks.remove(at: tag!)
                log.verbose(sequencer.tracks.count)
            }

        }else if (node.nodeDescription?.elementsEqual("vibrato"))! {

        } else {
            node.audioNodeContained?.disconnectOutput()
            node.audioNodeContained = nil
        }
    }
}

