//
//  OscillatorParametersViewController.swift
//  ARSynthesis
//
//  Created by Pol Piella on 25/02/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import UIKit
import AudioKit
import ARKit

class OscillatorParametersViewController: UIViewController {
    var nodeToModify = SCNNode()
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    @IBAction func closePopUp(_ sender: UIButton) {
        DebuggerService.singletonDebugger.log.info("Closing PopUp")
        self.view.removeFromSuperview()
    }
    @IBAction func pitchShiftUp(_ sender: UIButton) {
        AudioInterfaceHandler.singletonMixer.detunePlusOne(with: nodeToModify)
    }
    @IBAction func pitchShiftDown(_ sender: UIButton) {
        AudioInterfaceHandler.singletonMixer.detuneMinusOne(with: nodeToModify)
    }
    @IBAction func setWaveform(_ sender: UIButton) {
        guard let oscillator = nodeToModify.audioNodeContained as? AKMorphingOscillatorBank else {return}
        switch sender.tag {
        case 1:
            oscillator.index = 3
            break
        case 2:
            oscillator.index = 0
            break
        case 3:
            oscillator.index = 1
            break
        case 4:
            oscillator.index = 2
            break
        default:
            break
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
