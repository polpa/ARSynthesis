import UIKit
import AudioKit
import ARKit

/// This is the view controller swift class that handles all of the user interaction for the parameters view.
class OscillatorParametersViewController: UIViewController {
    
    var nodeToModify = SCNNode()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    /// This closes the popup when the close button is pressed.
    ///
    /// - Parameter sender: Close Button.
    @IBAction func closePopUp(_ sender: UIButton) {
        DebuggerService.singletonDebugger.log.info("Closing PopUp")
        self.view.removeFromSuperview()
    }
    
    /// Shifts the pitch up by one semitone.
    ///
    /// - Parameter sender: +1 Button.
    @IBAction func pitchShiftUp(_ sender: UIButton) {
        AudioInterfaceHandler.singletonMixer.detunePlusOne(with: nodeToModify)
    }
    
    /// Shifts the pitch down by one semitone.
    ///
    /// - Parameter sender: -1 Button.
    @IBAction func pitchShiftDown(_ sender: UIButton) {
        AudioInterfaceHandler.singletonMixer.detuneMinusOne(with: nodeToModify)
    }
    
    /// Sets the waveform to: square, sine, triangle or sawtooth.
    ///
    /// - Parameter sender: Different waveform buttons.
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
}
