import UIKit
import ARKit
import AudioKit
import PopupDialog
import SVProgressHUD
import CoreMotion
import SwiftyBeaver
import Onboard
import NotificationBannerSwift

/// This class handles the main user interface.
class ARViewController: UIViewController{
    
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var planeDetectionButton: UIButton!
    @IBOutlet weak var initialPresetButton: UIButton!
    @IBOutlet weak var removeAllButton: UIButton!
    
    let log = DebuggerService.singletonDebugger.log
    let itemsArray: [String] = ["oscillator", "sequencer", "reverb", "delay", "lowPass", "vibrato", "keyboard"]
    var sequencerArray: [SCNNode] = []
    var configuration = ARWorldTrackingConfiguration()
    var nodeArray: [SCNNode]!
    var firstTime: Bool!
    var overAllScale: CGFloat = 1
    var collectionCells: [UICollectionViewCell] = []
    var selectedItem: String?
    var destinationNode = SCNNode()
    var startingNode = SCNNode()
    var firstPlaneDetected: Bool = false
    var motionManager = CMMotionManager()
    var planeNode = SCNNode()
    var selectedKeyboardMode = "none"
    var sequencerPresent = false
    var minimumPlacementHeight = 0.0
    var currentOscillator = AKMorphingOscillatorBank()
    var planeIsEmpty = true
    
    /// This method sets up the scene configuration when the view is loaded.
    fileprivate func setupScene() {
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.itemsCollectionView.dataSource = self
        self.itemsCollectionView.delegate = self
        self.sceneView.delegate = self
        self.registerGestureRecognizers()
        self.sceneView.autoenablesDefaultLighting = true
        ARHandler.arHandler.arScene = self.sceneView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialPresetButton.isUserInteractionEnabled = false
        selectedItem = "oscillator"
        firstTime = true
        if (firstTime){
            nodeArray = []
        }
        setupScene()
    }
    
    /// Turns off plane detection from the session.
    ///
    /// - Parameter sender: Stop Plane Detection Button.
    @IBAction func stopPlaneDetection(_ sender: UIButton) {
        switch planeDetectionButton.title(for: .normal) {
        case "Stop Detecting":
            stopPlaneDetection()
            break
        case "Detect Plane":
            resetPlaneDetection()
            break
        default:
            break
        }
    }
    
    /// Adds a basic structure to get the user started.
    ///
    /// - Parameter sender: Get Started button.
    @IBAction func addInitialNodes(_ sender: UIButton) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            if (node.nodeDescription?.elementsEqual("basePlane"))!{
                if node.height! != Float(1.0) && node.width != Float(1.0){
                    if node.width! >= Float(0.5) || node.height! >= Float(0.5) && planeIsEmpty == true{
                        log.verbose("I am ready to do stuff here")
                        let scene = SCNScene(named: "Models.scnassets/itemShape.scn")
                        let oscillatorNode = (scene?.rootNode.childNode(withName: "itemShape", recursively: false))!
                        let currentIndex = nodeArray.count
                        let sides = [UIColor.white,
                                     UIColor.white,
                                     UIColor.white,
                                     UIColor.white,
                                     UIImage(named:"oscillator.png") ?? UIImage(),UIColor.black]
                            as [Any]
                        let materials = sides.map { (side) -> SCNMaterial in
                            let material = SCNMaterial()
                            material.diffuse.contents = side
                            material.locksAmbientWithDiffuse = true
                            return material
                        }
                        oscillatorNode.name = "oscillator"
                        oscillatorNode.nodeDescription = "oscillator"
                        oscillatorNode.chainContainsSampler = false
                        oscillatorNode.isHandsFreeEnabled = false
                        oscillatorNode.position = SCNVector3(node.position.x, node.position.y + 0.1, node.position.z)
                        oscillatorNode.geometry?.materials = materials
                        oscillatorNode.initialiseParameters()
                        nodeArray.insert(oscillatorNode, at: currentIndex)
                        self.sceneView.scene.rootNode.addChildNode(nodeArray[currentIndex])
                        AudioInterfaceHandler.singletonMixer.append(node: oscillatorNode)
                        for node in nodeArray{
                            node.name = String("\(nodeArray.index(of: node)!)")
                        }
                        
                        let secondScene = SCNScene(named: "Models.scnassets/itemShape.scn")
                        let reverbNode = (secondScene?.rootNode.childNode(withName: "itemShape", recursively: false))!
                        let currentIndex2 = nodeArray.count
                        let sidesReverb = [UIColor.white,
                                     UIColor.white,
                                     UIColor.white,
                                     UIColor.white,
                                     UIImage(named:"reverb.png") ?? UIImage(),UIColor.black]
                            as [Any]
                        let materialsReverb = sidesReverb.map { (side) -> SCNMaterial in
                            let material = SCNMaterial()
                            material.diffuse.contents = side
                            material.locksAmbientWithDiffuse = true
                            return material
                        }
                        reverbNode.name = "reverb"
                        reverbNode.nodeDescription = "reverb"
                        reverbNode.chainContainsSampler = false
                        reverbNode.isHandsFreeEnabled = false
                        reverbNode.position = SCNVector3(node.position.x + 0.2, node.position.y + 0.1, node.position.z)
                        reverbNode.geometry?.materials = materialsReverb
                        reverbNode.initialiseParameters()
                        nodeArray.insert(reverbNode, at: currentIndex2)
                        self.sceneView.scene.rootNode.addChildNode(nodeArray[currentIndex2])
                        AudioInterfaceHandler.singletonMixer.append(node: reverbNode)
                        for node in nodeArray{
                            node.name = String("\(nodeArray.index(of: node)!)")
                        }
                        self.drawLineBetweenNodes(startingNode: oscillatorNode, destinationNode: reverbNode)
                        let vector = SCNVector3(node.position.x, node.position.y, node.position.y)
                        addSequencerInitial(position: vector)
                        initialPresetButton.isUserInteractionEnabled = false
                    }
                }
            }
        }
    }
    
    /// Function to add a sequencer when the get started button is started.
    ///
    /// - Parameter position: Position where the sequencer is to be placed.
    func addSequencerInitial(position: SCNVector3){
        updateInteractionOfCell(for: "oscillator")
        updateInteractionOfCell(for: "sequencer")
        AudioInterfaceHandler.singletonMixer.sequencerSelected()
        var n = 0
        repeat {
            let node = SCNNode(geometry: SCNBox(width: 0.07, height: 0.08, length: 0.07, chamferRadius: 0))
            node.name = "sequencer"
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.black
            node.nodeDescription = "Sequencer(\(n))"
            if n >= 0 && n<4{
                node.position = SCNVector3Make(Float(position.x + 0.2*(n)), position.y + 0.15, position.z)
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
                node.name = "\(n).0"
            }else if n >= 4 && n<8{
                node.position = SCNVector3Make(Float(position.x + 0.2*(n-4)), position.y + 0.35, position.z)
                node.name = "\(n-4).1"
            } else if n>=8 && n<12{
                node.position = SCNVector3Make(Float(position.x + 0.2*(n-8)), position.y + 0.50, position.z)
                node.name = "\(n-8).2"
            }else {
                node.position = SCNVector3Make(Float(position.x + 0.2*(n-12)), position.y + 0.65, position.z)
                node.name = "\(n-12).3"
            }
            sequencerArray.append(node)
            self.sceneView.scene.rootNode.addChildNode(node)
            n = n + 1
        }while n < 16
    }
    
    /// Restarts plane detection.
    func resetPlaneDetection(){
        self.sceneView.session.pause()
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(self.configuration)
        planeDetectionButton.setTitle("Stop Detecting", for: .normal)
        DispatchQueue.main.async{
             SVProgressHUD.show(withStatus: "Trying to detect plane, please and move around to find a horizontal surface")
        }
    }
    
    /// Stops plane detection.
    func stopPlaneDetection(){
        self.sceneView.session.pause()
        self.configuration.planeDetection = []
        self.sceneView.session.run(self.configuration)
        planeDetectionButton.setTitle("Detect Plane", for: .normal)
        if SVProgressHUD.isVisible(){
            SVProgressHUD.dismiss()
        }
    }
    
    /// Shows a banner (Notification) showns at the top of the scene to give some feedback to the user. 
    ///
    /// - Parameter titleInput: Title.
    func showBanner(with titleInput: String){
        let title = NSAttributedString(string: titleInput)
        let banner = StatusBarNotificationBanner(attributedTitle: title, style: .info, colors: CustomBannerColors())
        if banner.isDisplaying{
            banner.dismiss()
            banner.show()
        } else {
            banner.show()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        ARHandler.arHandler.collectionCells = self.collectionCells
            if(firstTime){
                firstTime = false
                DispatchQueue.main.async{
                    self.showStandardDialog()
                }
            } else{
            }
    }

    /// Presents a warning pop up dialogue whenever this function is called.
    /// This is using a pod called PopupDialog, and the code has been inspired from the documentation examples.
    /// - Parameter animated: True to allow the presentation animation.
    func showStandardDialog(animated: Bool = true) {
        let popup = PopupDialog(identifier: "intro")
        let cancelButton = CancelButton(title: "OK") {
            SVProgressHUD.show(withStatus: "Trying to detect plane, please and move around to find a horizontal surface")
        }
        popup.addButtons([cancelButton])
        self.present(popup, animated: animated, completion: nil)
    }
    
    /// When the user presses on the remove all button, all nodes are removed from the scene.
    ///
    /// - Parameter sender: Remove All Nodes from the scene.
    @IBAction func removeAllNodes(_ sender: UIButton) {
        var foundSequencer = false
        var sequencerNode = SCNNode()
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            switch node.nodeDescription {
            case "oscillator", "reverb", "delay", "lowPass", "vibrato":
                nodeRemove(with: node)
                break
            default:
                if (node.nodeDescription?.contains(find: "Sequencer"))!{
                foundSequencer = true
                sequencerNode = node
                } else {}
                break
            }
        }
        if foundSequencer{
            nodeRemove(with: sequencerNode)
        } else {}
    }
    
    /// This function registers all of the gesture recognizers, initializes them and adds them to the augmented reality scene.
    func registerGestureRecognizers() {
        let oneTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(removeNode))
        let addOscillatorADSR = UITapGestureRecognizer(target: self, action: #selector(ADSR))
        oneTapGestureRecognizer.numberOfTapsRequired = 1
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        addOscillatorADSR.numberOfTapsRequired = 3
        oneTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        doubleTapGestureRecognizer.require(toFail: addOscillatorADSR)
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(scaleNode))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        longPressGestureRecognizer.minimumPressDuration = 0.1
        let doubleLongPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(doubleLongPress))
        doubleLongPressGestureRecognizer.minimumPressDuration = 0.6
        doubleLongPressGestureRecognizer.numberOfTouchesRequired = 2
        
        self.sceneView.addGestureRecognizer(addOscillatorADSR)
        self.sceneView.addGestureRecognizer(doubleLongPressGestureRecognizer)
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(oneTapGestureRecognizer)
        self.sceneView.addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    /// Tapping three times on an oscillator adds an ADSR structure to it.
    ///
    /// - Parameter sender: Tap Gesture Recogniser.
    @objc func ADSR(sender: UITapGestureRecognizer){
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation)
        guard let node = hitTest.first?.node else {return}
        guard let nodeName = node.name else {return}
        guard let nodeDescription = node.nodeDescription else {return}
        
        if !hitTest.isEmpty && nodeDescription.elementsEqual("oscillator") && !node.adsrIsVisible!{
            
            //Attack Node
            let nodeAttackMinus = SCNNode(geometry: SCNBox(width: 0.06, height: 0.06, length: 0.06, chamferRadius: 0))
            nodeAttackMinus.geometry?.firstMaterial?.diffuse.contents = UIColor.purple.withAlphaComponent(0.75)
            nodeAttackMinus.position = SCNVector3Make(node.position.x - 0.1, node.position.y, node.position.z)
            nodeAttackMinus.name = "\(nodeName)/a"
            nodeAttackMinus.nodeDescription = "\(nodeName)/nodeAttackMinus"
            sceneView.scene.rootNode.addChildNode(nodeAttackMinus)
            let nodeAttackPlus = SCNNode(geometry: SCNBox(width: 0.06, height: 0.06, length: 0.06, chamferRadius: 0))
            nodeAttackPlus.geometry?.firstMaterial?.diffuse.contents = UIColor.purple.withAlphaComponent(0.75)
            nodeAttackPlus.position = SCNVector3Make(node.position.x - 0.2, node.position.y, node.position.z)
            nodeAttackPlus.name = "\(nodeName)/a"
            nodeAttackPlus.nodeDescription = "\(nodeName)/nodeAttackPlus"
            sceneView.scene.rootNode.addChildNode(nodeAttackPlus)
            
            //Decay Node
            let nodeDecayMinus = SCNNode(geometry: SCNBox(width: 0.06, height: 0.06, length: 0.06, chamferRadius: 0))
            nodeDecayMinus.geometry?.firstMaterial?.diffuse.contents = UIColor.purple.withAlphaComponent(0.75)
            nodeDecayMinus.position = SCNVector3Make(node.position.x, node.position.y, node.position.z - 0.1)
            nodeDecayMinus.name = "\(nodeName)/a"
            nodeDecayMinus.nodeDescription = "\(nodeName)/nodeDecayMinus"
            sceneView.scene.rootNode.addChildNode(nodeDecayMinus)
            let nodeDecayPlus = SCNNode(geometry: SCNBox(width: 0.06, height: 0.06, length: 0.06, chamferRadius: 0))
            nodeDecayPlus.geometry?.firstMaterial?.diffuse.contents = UIColor.purple.withAlphaComponent(0.75)
            nodeDecayPlus.position = SCNVector3Make(node.position.x, node.position.y, node.position.z - 0.2)
            nodeDecayPlus.name = "\(nodeName)/a"
            nodeDecayPlus.nodeDescription = "\(nodeName)/nodeDecayPlus"
            sceneView.scene.rootNode.addChildNode(nodeDecayPlus)
            
            //Release Node
            let nodeReleaseMinus = SCNNode(geometry: SCNBox(width: 0.06, height: 0.06, length: 0.06, chamferRadius: 0))
            nodeReleaseMinus.geometry?.firstMaterial?.diffuse.contents = UIColor.purple.withAlphaComponent(0.75)
            nodeReleaseMinus.position = SCNVector3Make(node.position.x + 0.1, node.position.y, node.position.z)
            nodeReleaseMinus.name = "\(nodeName)/a"
            nodeReleaseMinus.nodeDescription = "\(nodeName)/nodeReleaseMinus"
            sceneView.scene.rootNode.addChildNode(nodeReleaseMinus)
            let nodeReleasePlus = SCNNode(geometry: SCNBox(width: 0.06, height: 0.06, length: 0.06, chamferRadius: 0))
            nodeReleasePlus.geometry?.firstMaterial?.diffuse.contents = UIColor.purple.withAlphaComponent(0.75)
            nodeReleasePlus.position = SCNVector3Make(node.position.x + 0.2, node.position.y, node.position.z)
            nodeReleasePlus.name = "\(nodeName)/a"
            nodeReleasePlus.nodeDescription = "\(nodeName)/nodeReleasePlus"
            sceneView.scene.rootNode.addChildNode(nodeReleasePlus)
            node.adsrIsVisible = true
            
        } else if !hitTest.isEmpty && nodeDescription.elementsEqual("oscillator") && node.adsrIsVisible!{
            self.sceneView.scene.rootNode.enumerateChildNodes { (subNode, _) in
                if let subNodeName = subNode.name{
                    if (subNodeName.elementsEqual("\(nodeName)/a")){
                        subNode.removeFromParentNode()
                    }
                } else {
                    log.error("Could not compute node Name!!")
                }

            }
            node.adsrIsVisible = false
        }
    }
    
    /// This handles double long presses and it is not yet implemented (Future Work).
    ///
    /// - Parameter sender: Long Press Gesture Recogniser.
    @objc func doubleLongPress(sender: UITapGestureRecognizer){
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation)
        
        if !hitTest.isEmpty && (hitTest.first?.node.nodeDescription?.elementsEqual("oscillator"))!{
            //currentOscillator = hitTest.first?.node.audioNodeContained as! AKMorphingOscillatorBank
            
        } else {
            log.verbose("ended")
            //currentOscillator.vibratoRate = Double(tapLocation.x/100)
        }
    }
    
    /// This function handles double tap gestures in the augmented reality scene.
    ///
    /// - Parameter sender: Double tap gesture recognizer.
    @objc func removeNode(sender: UITapGestureRecognizer){
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation)
        if !hitTest.isEmpty && !(hitTest.first?.node.nodeDescription?.elementsEqual("basePlane"))! && !(hitTest.first?.node.nodeDescription?.elementsEqual("keyboardPlane"))! && !(hitTest.first?.node.nodeDescription?.contains(find: "/"))!{
            if (hitTest.first?.node.isHandsFreeEnabled!)!{
            }
            nodeRemove(with: (hitTest.first?.node)!)
        }
    }
    
    /// Updates the user interaction of the cell button. It determines whether the cell can be selected or not.
    ///
    /// - Parameter description: Description of the cell that is to be modified.
    func updateInteractionOfCell(for description: String){
        let index = itemsArray.index(of: description)
        let cell = collectionCells[index!]
        if cell.isUserInteractionEnabled{
            cell.isUserInteractionEnabled = false
            cell.backgroundColor = UIColor.red
        } else {
            cell.isUserInteractionEnabled = true
            cell.backgroundColor = UIColor.black
        }
    }
    
    /// This function is called everytime that a node has to be removed from the scene.
    ///
    /// - Parameter nodeToBeRemoved: Node that is to be removed.
    func nodeRemove(with nodeToBeRemoved: SCNNode){
        if (nodeToBeRemoved.name?.contains(find: "."))!{
            for node in sequencerArray {
                node.removeFromParentNode()
                node.audioNodeContained?.sequencerTrack?.clear()
            }
            let findSequencer = "sequencer"
            updateInteractionOfCell(for: "oscillator")
            updateInteractionOfCell(for: findSequencer)
            self.sequencerPresent = false
            sequencerArray.removeAll()
            AudioInterfaceHandler.singletonMixer.sequencer.stop()
            //Sort out the sequencer, turn it off or simply set it to zero
        } else{
            if (nodeToBeRemoved.nodeDescription?.elementsEqual("oscillator"))! && nodeToBeRemoved.adsrIsVisible! {
                guard let nodeName = nodeToBeRemoved.name else {return}
                self.sceneView.scene.rootNode.enumerateChildNodes { (subNode, _) in
                    if let subNodeName = subNode.name{
                        if (subNodeName.elementsEqual("\(nodeName)/a")){
                            subNode.removeFromParentNode()
                        }
                    } else {
                        log.error("Could not compute node Name!!")
                    }
                    
                }
            }
            if (nodeToBeRemoved.nodeDescription?.elementsEqual("drums"))!{
                updateInteractionOfCell(for: "drums")
            }
            nodeToBeRemoved.removeAllLinks(scene: sceneView)//First remove all connections
            self.nodeArray.remove(at: nodeArray.index(of: nodeToBeRemoved)!) //Remove it from the array
            if ((nodeToBeRemoved.inputConnection?.isNotEmpty)! && nodeToBeRemoved.outputConnection != nil && nodeArray.contains(nodeToBeRemoved.outputConnection!)){
                //MARK: This is the situation where the node that is to be removed has input connections but is not connected
                //to any other node (it is not the end of the chain), Also checks that the output connection is still contained by the
                //node array
                for input in nodeToBeRemoved.inputConnection!{
                    input.outputIsConnected = true
                    drawLineBetweenNodes(startingNode: input, destinationNode: nodeToBeRemoved.outputConnection!)
                    AudioInterfaceHandler.singletonMixer.connect(fromOutput: input, toInput: nodeToBeRemoved.outputConnection!)
                }
                
            } else if !nodeToBeRemoved.outputIsConnected! && (nodeToBeRemoved.inputConnection?.isNotEmpty)! {
                //MARK: THis is only called when the node that is being removed is the "last node" before the output
                //
                let mixer = AudioInterfaceHandler.singletonMixer.mixer
                guard let inputConnections = nodeToBeRemoved.inputConnection else {return}
                for node in inputConnections {
                    //MARK: There needs to be some handling when this point in the chain is hit. First of all, the input connections
                    //status have to be reset.
                    node.outputIsConnected = false
                    if (node.nodeDescription?.elementsEqual("oscillator"))!{
                        guard let inputNode = node.audioNodeContained else {return}
                        inputNode.prePitchShifter?.disconnectOutput()
                        inputNode.connect(to: mixer)
                    } else if !(node.nodeDescription?.elementsEqual("vibrato"))!{
                        guard let inputNode = node.audioNodeContained else {return}
                        inputNode.disconnectOutput()
                        inputNode.connect(to: mixer)
                    }
                }
            }
            if (nodeToBeRemoved.nodeDescription?.elementsEqual("vibrato"))!{
                let oscillator = nodeToBeRemoved.outputConnection?.audioNodeContained as! AKMorphingOscillatorBank
                oscillator.vibratoDepth = 0
                oscillator.vibratoRate = 0
            }
            nodeToBeRemoved.inputConnection?.removeAll()
            if let indexToRemove = nodeToBeRemoved.outputConnection?.inputConnection?.index(of: nodeToBeRemoved)
            {
                nodeToBeRemoved.outputConnection?.inputConnection?.remove(at: indexToRemove)
                nodeToBeRemoved.outputConnection = nil
            } else {
                log.error("No index could be computed for that value")
            }
            AudioInterfaceHandler.singletonMixer.remove(node: nodeToBeRemoved)
            nodeToBeRemoved.removeFromParentNode()
        }
    }
    
    /// Checks whether the scene is empty or not.
    ///
    /// - Returns: Returns a boolean, true if the scene is empty and false if the scene has any element.
    func sceneIsEmpty() -> Bool{
        var isEmpty = true
        sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            if node.name != nil{
                return isEmpty = false
            }
        }
        return isEmpty
    }
    
    /// This function detects any node being pinched and scales it accordingly
    ///
    /// - Parameter sender: Pinch Gesture Recognizer
    @objc func scaleNode(sender: UIPinchGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(pinchLocation)
        if !hitTest.isEmpty                                                         //Condition
            && !(hitTest.first?.node.nodeDescription?.elementsEqual("basePlane"))!  //Condition
            && !(hitTest.first?.node.nodeDescription?.elementsEqual("line"))! {     //Condition
            let results = hitTest.first!
            let node = results.node
            if(node.overallAmplitude! >= CGFloat(1.0) && sender.scale > 1) {

            } else {
                let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
                node.runAction(pinchAction)
                node.overallAmplitude = sender.scale * node.overallAmplitude!
                AudioInterfaceHandler.singletonMixer.scaleValue(of: node, scaleValue: Double(node.overallAmplitude!))
            }
            sender.scale = 1.0
        } else {
            
        }
    }

    /// This function deals with all of the single tapping in the ARSCNView.
    ///
    /// - Parameter sender: This is the tap gesture recognizer
    @objc func tapped(sender: UITapGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        let hitTestItems = sceneView.hitTest(tapLocation)
       if !hitTest.isEmpty {
        if !hitTestItems.isEmpty && (hitTestItems.first?.node.nodeDescription?.elementsEqual("basePlane"))! {
            initialPresetButton.isUserInteractionEnabled = false
            if (self.selectedItem?.elementsEqual("sequencer"))! {
                if !self.sequencerPresent{
                    self.sequencerPresent = true
                    self.addSequencer(hitTestResult: hitTest.first!)
                }
            } else{
                self.addItem(hitTestResult: hitTest.first!)
            }
        } else if !hitTestItems.isEmpty && !(hitTestItems.first?.node.nodeDescription?.elementsEqual("basePlane"))! && !(hitTestItems.first?.node.nodeDescription?.elementsEqual("keyboardPlane"))! &&
            !(hitTestItems.first?.node.name?.contains(find: "."))! &&
            !(hitTestItems.first?.node.name?.contains(find: "/"))!
            {
            self.showNodeActionSheet(with: (hitTestItems.first?.node)!)
        } else if !hitTestItems.isEmpty && (hitTestItems.first?.node.nodeDescription?.elementsEqual("keyboardPlane"))!{
            if !(self.selectedKeyboardMode.elementsEqual("sequencer")) && !(hitTestItems.first?.node.nodeDescription?.contains(find: "/"))!{
                showKeyboardActionSheet(with: (hitTestItems.first?.node)!)
            } 
        } else if !hitTestItems.isEmpty && (hitTestItems.first?.node.name?.contains(find: "."))!{
            guard let node = hitTestItems.first?.node else {return}
            print("I should be here")
            _ = sequencerArray.index(of: node)
            if node.geometry?.firstMaterial?.diffuse.contents as! UIColor == UIColor.black{
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
                AudioInterfaceHandler.singletonMixer.sequenceValue(buttonTag: node.name!)
                let row = node.name?.components(separatedBy: ".")[0]
                for sequencerNode in sequencerArray{
                    let examinedRow = sequencerNode.name?.components(separatedBy: ".")[0]
                    if node.name != sequencerNode.name && row == examinedRow{
                        sequencerNode.geometry?.firstMaterial?.diffuse.contents = UIColor.black
                    }
                }
            } else {
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.black
                AudioInterfaceHandler.singletonMixer.removeFromSequence(buttonTag: node.name!)
            }
        } else if (hitTestItems.first?.node.nodeDescription?.contains(find: "/"))!{
            guard let nodeName = hitTestItems.first?.node.nodeDescription else {return}
            let parameterName = nodeName.split(separator: "/")
            log.verbose(parameterName[1])
            switch parameterName[1]{
            case "nodeDecayMinus":
                let node = sceneView.scene.rootNode.childNode(withName: String(parameterName[0]), recursively: true)
                let audioNode = node?.audioNodeContained as! AKMorphingOscillatorBank
                log.verbose(audioNode.decayDuration)
                if audioNode.decayDuration >= 0.25 {
                    audioNode.decayDuration = audioNode.decayDuration - 0.25
                } else {
                    audioNode.decayDuration = 0.0
                }
                break
            case "nodeDecayPlus":
                let node = sceneView.scene.rootNode.childNode(withName: String(parameterName[0]), recursively: true)
                let audioNode = node?.audioNodeContained as! AKMorphingOscillatorBank
                if audioNode.decayDuration <= 0.75{
                    audioNode.decayDuration = audioNode.decayDuration + 0.25
                } else {
                    audioNode.decayDuration = 1.0
                }
                break
            case "nodeReleaseMinus":
                let node = sceneView.scene.rootNode.childNode(withName: String(parameterName[0]), recursively: true)
                let audioNode = node?.audioNodeContained as! AKMorphingOscillatorBank
                log.verbose(audioNode.releaseDuration)
                if audioNode.releaseDuration >= 0.25{
                    audioNode.releaseDuration = audioNode.releaseDuration - 0.25
                } else {
                    audioNode.releaseDuration = 0.0
                }
                break
            case "nodeReleasePlus":
                let node = sceneView.scene.rootNode.childNode(withName: String(parameterName[0]), recursively: true)
                let audioNode = node?.audioNodeContained as! AKMorphingOscillatorBank
                if audioNode.releaseDuration <= 1.75{
                    audioNode.releaseDuration = audioNode.releaseDuration + 0.25
                } else {
                    audioNode.releaseDuration = 2.0
                }
                break
            case "nodeAttackMinus":
                let node = sceneView.scene.rootNode.childNode(withName: String(parameterName[0]), recursively: true)
                let audioNode = node?.audioNodeContained as! AKMorphingOscillatorBank
                if audioNode.attackDuration >= 0.25{
                    audioNode.attackDuration = audioNode.attackDuration - 0.25
                } else {
                    audioNode.attackDuration = 0.0
                }
                break
            case "nodeAttackPlus":
                let node = sceneView.scene.rootNode.childNode(withName: String(parameterName[0]), recursively: true)
                let audioNode = node?.audioNodeContained as! AKMorphingOscillatorBank
                if audioNode.attackDuration <= 0.75{
                    audioNode.attackDuration = audioNode.attackDuration + 0.25
                } else {
                    audioNode.attackDuration = 1.0
                }
                break
            default:
                break
            }

        }
       } else if !hitTestItems.isEmpty && (hitTestItems.first?.node.name?.contains(find: "."))!{
        guard let node = hitTestItems.first?.node else {return}
        print("I should be here")
        _ = sequencerArray.index(of: node)
        if node.geometry?.firstMaterial?.diffuse.contents as! UIColor == UIColor.black{
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
            AudioInterfaceHandler.singletonMixer.sequenceValue(buttonTag: node.name!)
            let row = node.name?.components(separatedBy: ".")[0]
            for sequencerNode in sequencerArray{
                let examinedRow = sequencerNode.name?.components(separatedBy: ".")[0]
                if node.name != sequencerNode.name && row == examinedRow{
                    sequencerNode.geometry?.firstMaterial?.diffuse.contents = UIColor.black
                }
            }
        } else {
            node.geometry?.firstMaterial?.diffuse.contents = UIColor.black
            AudioInterfaceHandler.singletonMixer.removeFromSequence(buttonTag: node.name!)
        }
        }
    }
    
    /// This method allows the user to draw a line between two nodes, if the connection is possible. 
    ///
    /// - Parameters:
    ///   - startingNode: Node that determines the starting point of the connection.
    ///   - destinationNode: Node that determines the end point of the connection.
    func drawLineBetweenNodes (startingNode: SCNNode, destinationNode: SCNNode){
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.specular.contents = UIColor.white
        let v1 = startingNode.position
        let v2 = destinationNode.position
        switch destinationNode.nodeDescription! {
        case "oscillator","drums":
            if (startingNode.nodeDescription?.elementsEqual("vibrato"))!{
                destinationNode.inputIsConnected = true
                startingNode.audioNodeContained = destinationNode.audioNodeContained as! AKMorphingOscillatorBank
                let linkName = "Link \(startingNode.name ?? "") | \(destinationNode.name ?? "")"
                let lineNode = LineNode(name: linkName, v1: v1, v2: v2, material: [material])
                lineNode.nodeDescription = "line"
                destinationNode.inputConnection?.append(startingNode)
                startingNode.outputConnection = destinationNode
                self.sceneView.scene.rootNode.addChildNode(lineNode)
                self.showBanner(with: "Connected to input")
                let oscillator = destinationNode.audioNodeContained as! AKMorphingOscillatorBank
                oscillator.vibratoRate = 6
                oscillator.vibratoDepth = 4
            }else {
                self.showBanner(with: "Could not connect")
            }
            break
        case "reverb", "delay", "lowPass", "distortion":
            if (startingNode.nodeDescription?.elementsEqual("vibrato"))!{
                self.showBanner(with: "Could not connect")
            } else if !startingNode.chainContainsSampler! {
                startingNode.outputIsConnected = true
                destinationNode.inputIsConnected = true
                let linkName = "Link \(startingNode.name ?? "") | \(destinationNode.name ?? "")"
                let lineNode = LineNode(name: linkName, v1: v1, v2: v2, material: [material])
                lineNode.nodeDescription = "line"
                self.sceneView.scene.rootNode.addChildNode(lineNode)
                destinationNode.inputConnection?.append(startingNode)
                startingNode.outputConnection = destinationNode
                AudioInterfaceHandler.singletonMixer.connect(fromOutput: startingNode, toInput: destinationNode)
            }
            break
        case "vibrato":
            self.showBanner(with: "Could not connect")
            break
        default:
            break
        }
    }
    
    /// Calculates the modulus of the horizontal distance between two nodes (audio modules) and returns a Double. This can then be used to find the nearest neighbor.
    /// - Parameters:
    ///   - relative: Input different vectors to find their distance relative to the anchored value
    ///   - anchor: This is the anchored node, all the measurements are relative to this node.
    /// - Returns: Modulus of the horizontal distance between relative and anchor.
    func deltaModulusCalculation (relative:SCNVector3, anchor: SCNVector3) -> Double{
        var modulus: Double = 0
        let squaredX = Double(pow(Double(relative.x - anchor.x), Double(2)))
        let squaredZ = Double(pow(Double(relative.z - anchor.z), Double(2)))
        modulus = Double(sqrt(squaredX + squaredZ))
        return modulus
    }
    
    /// Adds a sequencer to the scene.
    ///
    /// - Parameter hitTestResult: Hit test result from the user's press.
    func addSequencer(hitTestResult: ARHitTestResult){
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        updateInteractionOfCell(for: "oscillator")
        updateInteractionOfCell(for: "sequencer")
        AudioInterfaceHandler.singletonMixer.sequencerSelected()
            var n = 0
            repeat {
                let node = SCNNode(geometry: SCNBox(width: 0.07, height: 0.08, length: 0.07, chamferRadius: 0))
                node.name = "sequencer"
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.black
                node.nodeDescription = "Sequencer(\(n))"
                if n >= 0 && n<4{
                    node.position = SCNVector3Make(Float(thirdColumn.x + 0.2*(n)), thirdColumn.y + 0.15, thirdColumn.z)
                    node.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
                    node.name = "\(n).0"
                }else if n >= 4 && n<8{
                    node.position = SCNVector3Make(Float(thirdColumn.x + 0.2*(n-4)), thirdColumn.y + 0.35, thirdColumn.z)
                    node.name = "\(n-4).1"
                } else if n>=8 && n<12{
                    node.position = SCNVector3Make(Float(thirdColumn.x + 0.2*(n-8)), thirdColumn.y + 0.50, thirdColumn.z)
                    node.name = "\(n-8).2"
                }else {
                    node.position = SCNVector3Make(Float(thirdColumn.x + 0.2*(n-12)), thirdColumn.y + 0.65, thirdColumn.z)
                    node.name = "\(n-12).3"
                }
                sequencerArray.append(node)
                self.sceneView.scene.rootNode.addChildNode(node)
                n = n + 1
            }while n < 16
    }
    
    /// This function handles all the item addition to the augmented reality scene.
    ///
    /// - Parameter hitTestResult: This is the result array when a touch is detected.
    func addItem(hitTestResult: ARHitTestResult) {
        guard let selectedItem = self.selectedItem else {
            log.error("There is no selected item")
            return
        }
        if selectedItem.elementsEqual("drums"){
            self.updateInteractionOfCell(for: "drums")
        }
    
        
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
            let scene = SCNScene(named: "Models.scnassets/itemShape.scn")
            let node = (scene?.rootNode.childNode(withName: "itemShape", recursively: false))!
            let currentIndex = nodeArray.count
            let sides = [UIColor.white,
                         UIColor.white,
                         UIColor.white,
                         UIColor.white,
                         UIImage(named:"\(selectedItem).png") ?? UIImage(),UIColor.black]
                         as [Any]
            let materials = sides.map { (side) -> SCNMaterial in
                let material = SCNMaterial()
                material.diffuse.contents = side
                material.locksAmbientWithDiffuse = true
                return material
            }
            
            node.name = "\(selectedItem)"
            node.chainContainsSampler = false
            node.isHandsFreeEnabled = false
            node.position = SCNVector3(thirdColumn.x, thirdColumn.y + 0.1, thirdColumn.z)
            node.nodeDescription = selectedItem
            node.geometry?.materials = materials
            node.initialiseParameters()
            nodeArray.insert(node, at: currentIndex)
            self.sceneView.scene.rootNode.addChildNode(nodeArray[currentIndex])
        
            for node in nodeArray{
                    node.name = String("\(nodeArray.index(of: node)!)")
            }
        if !(node.nodeDescription?.elementsEqual("vibrato"))!{
            AudioInterfaceHandler.singletonMixer.append(node: node)
        } else {
            var oscArray: [SCNNode] = []
            var modulusDistanceArray: [Double] = []
            var valuesDictionary: [Double:SCNNode] = [:]
            for nodeRelative in nodeArray{
                if (nodeRelative.nodeDescription?.elementsEqual("oscillator"))!{
                    valuesDictionary.updateValue(nodeRelative, forKey: deltaModulusCalculation(relative: nodeRelative.position, anchor: node.position))
                    oscArray.append(nodeRelative)
                    modulusDistanceArray.append(deltaModulusCalculation(relative: nodeRelative.position, anchor: node.position))
                }
            }
            guard let minimumValue = modulusDistanceArray.min() else {return}
            let destinationNode = valuesDictionary[minimumValue]
            self.drawLineBetweenNodes(startingNode: node, destinationNode: destinationNode!)

        }
    }
    
    /// Shows the information Onboarding view controller, to provide some extra guidance to the user when needed.
    ///
    /// - Parameter sender: Info Button.
    @IBAction func showInfoView(_ sender: UIButton) {
        var progressWasVisible = false
        let infoVC = AddOnboardingInfoView.viewController.getViewController(with: "info")
        self.present(infoVC, animated: true) {
            if SVProgressHUD.isVisible() {
                SVProgressHUD.dismiss()
                progressWasVisible = true
            } else {
                progressWasVisible = false
            }
        }
        if infoVC.isBeingDismissed {
            infoVC.dismiss(animated: true) {
                if progressWasVisible {
                    self.showStandardDialog()
                }
            }
        }
    }
    
    /// When a long press is detected, the pressed node rotates (360 degrees), within 10 seconds. If the press ends, the node stops rotating.
    /// - Parameter sender: Gesture recognizer to handle long presses.
    @objc func longPress(sender: UILongPressGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let holdLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(holdLocation)
        if !hitTest.isEmpty && !(hitTest.first?.node.nodeDescription?.elementsEqual("basePlane"))! && !(hitTest.first?.node.nodeDescription?.elementsEqual("keyboardPlane"))! && sender.numberOfTouches == 1 {
            destinationNode = (hitTest.first?.node)!
            switch sender.state {
            case .began:
                let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 5)
                let forever = SCNAction.repeatForever(rotation)
                destinationNode.runAction(forever)
                startingNode = destinationNode
                break
            case .changed:
                if destinationNode == startingNode{
                    //This happens whenever the long press stays unchanged, on the node.
                } else if !startingNode.outputIsConnected! && (!destinationNode.inputIsConnected! || destinationNode.allowsMultipleInputs!) {
                    if (startingNode.inputConnection?.contains(destinationNode))!{
                    } else {
                        self.drawLineBetweenNodes(startingNode: startingNode, destinationNode: destinationNode)
                        destinationNode.removeAllActions()
                    }

                } else {
                }
                break
            case .ended:
                destinationNode.removeAllActions()
                break
            case .failed:
                destinationNode.removeAllActions()
                break
            default:
                break
            }
            
        } else if !hitTest.isEmpty && (hitTest.first?.node.nodeDescription?.elementsEqual("keyboardPlane"))! && sender.numberOfTouches == 1{
            //Decode the functions for the keyboard long press!!
            guard let location = hitTest.first?.localCoordinates else {return}
            guard let node = hitTest.first?.node else {return}
            //Normalise the data of the long press
            let normalisedDataX = ((location.x + node.width!/2)/node.width!)
            switch sender.state {
            case .began:
                sceneView.scene.rootNode.enumerateChildNodes { (node, _)  in
                    guard let nodeDescription = node.nodeDescription else {return}
                    if nodeDescription.elementsEqual("oscillator") && (self.selectedKeyboardMode.elementsEqual("oscillator")){
                        let oscillator = node.audioNodeContained as! AKMorphingOscillatorBank
                        oscillator.play(noteNumber: 1, velocity: 60, frequency: Double(normalisedDataX*3000))
                    } else if nodeDescription.elementsEqual("reverb") && (self.selectedKeyboardMode.elementsEqual("reverb")) {
                        let reverb = node.audioNodeContained as! AKReverb
                        reverb.dryWetMix = Double(normalisedDataX)
                    } else if nodeDescription.elementsEqual("delay") && (self.selectedKeyboardMode.elementsEqual("delay")){
                        let delay = node.audioNodeContained as! AKDelay
                        delay.time = Double(normalisedDataX)
                    } else if nodeDescription.elementsEqual("lowPass") && (self.selectedKeyboardMode.elementsEqual("lowPass")){
                        let lowPass = node.audioNodeContained as! AKMoogLadder
                        lowPass.cutoffFrequency = Double(normalisedDataX * 15000)
                    } else if nodeDescription.elementsEqual("vibrato") && (self.selectedKeyboardMode.elementsEqual("vibrato")){

                    } else if (self.selectedKeyboardMode.elementsEqual("sequencer")){
                        self.selectedKeyboardMode = "none"
                    }
                }
                break
            case .changed:
                sceneView.scene.rootNode.enumerateChildNodes { (node, _)  in
                    guard let nodeDescription = node.nodeDescription else {return}
                    if nodeDescription.elementsEqual("oscillator") && (self.selectedKeyboardMode.elementsEqual("oscillator")){
                        let oscillator = node.audioNodeContained as! AKMorphingOscillatorBank
                        oscillator.stop(noteNumber: 1)
                        oscillator.play(noteNumber: 1, velocity: 60, frequency: Double(normalisedDataX * 3000))
                    } else if nodeDescription.elementsEqual("reverb") && (self.selectedKeyboardMode.elementsEqual("reverb")) {
                        let reverb = node.audioNodeContained as! AKReverb
                        reverb.dryWetMix = Double(normalisedDataX)
                        log.info(reverb.dryWetMix)
                    } else if nodeDescription.elementsEqual("delay") && (self.selectedKeyboardMode.elementsEqual("delay")){
                        let delay = node.audioNodeContained as! AKDelay
                        delay.time = Double(normalisedDataX)
                    } else if nodeDescription.elementsEqual("lowPass") && (self.selectedKeyboardMode.elementsEqual("lowPass")){
                        let lowPass = node.audioNodeContained as! AKMoogLadder
                        lowPass.cutoffFrequency = Double(normalisedDataX * 15000)
                    } else if nodeDescription.elementsEqual("vibrato") && (self.selectedKeyboardMode.elementsEqual("vibrato")){
                        let oscillator = node.audioNodeContained as! AKMorphingOscillatorBank
                        oscillator.vibratoRate = Double(normalisedDataX)
                    }  else if (self.selectedKeyboardMode.elementsEqual("none")){
                      log.warning("No keyboard mode was selected, hence the keyboard will not have any functionality")
                    }
                }
                break
            case .ended:
                sceneView.scene.rootNode.enumerateChildNodes { (node, _)  in
                    guard let nodeDescription = node.nodeDescription else {return}
                    if nodeDescription.elementsEqual("oscillator") && (self.selectedKeyboardMode.elementsEqual("oscillator")){
                        let oscillator = node.audioNodeContained as! AKMorphingOscillatorBank
                        oscillator.stop(noteNumber: 1)
                    } else {
                    }
                }
                break
            default:
                break
            }
        } else if sender.numberOfTouches == 2 && (hitTest.first?.node.nodeDescription?.elementsEqual("oscillator"))!{
            log.error("No node has been found!")
            currentOscillator = hitTest.first?.node.audioNodeContained as! AKMorphingOscillatorBank
        } else if !hitTest.isEmpty && sender.numberOfTouches == 1 && (hitTest.first?.node.nodeDescription?.contains(find: "/"))!{
            
        } else {
            if sender.numberOfTouches == 1{
                destinationNode.removeAllActions()
            } else if sender.numberOfTouches == 2{
                log.verbose(sender.location(in: self.view))
                sender.allowableMovement = 30
            }
            
        }
    }

    /// Get the new view controller using segue.destinationViewController.
    /// Pass the selected object to the new view controller.
    /// sceneView.session.pause()
    ///
    /// - Parameters:
    ///   - segue: The link between storyboard elements (i.e. ViewControllers)
    ///   - sender: The segue triger
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        //sceneView.session.pause()
        var _: [String] = []
        
        if segue.destination is OscillatorParametersViewController{
        }
    }
    
    /// This function scans the augmented reality scene in order to find all the visible nodes.
    ///
    /// - Returns: Returns an array of strings containing the different node descriptions
    func findContainedAudioNodes() -> [String]{
        var nodeList: [String] = []
        self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
            guard let audioNodeName = node.nodeDescription else {return}
            if !nodeList.contains(audioNodeName) && !audioNodeName.isEmpty && !audioNodeName.elementsEqual("keyboardPlane") && !audioNodeName.elementsEqual("basePlane"){
                nodeList.append(audioNodeName)
            }
        }
        return nodeList
    }
    
}

extension Double {
    var degreesToRadians: Double {return (Double(self * Double.pi/180))}

}


// MARK: - This extension adds the different needed delegates to the view controller class.
extension ARViewController: UICollectionViewDataSource, UICollectionViewDelegate, ARSCNViewDelegate, UIPopoverPresentationControllerDelegate{
    
    func showKeyboardActionSheet(with node: SCNNode){
        let actionSheet = UIAlertController(title: "Keyboard Actions",
                                            message: "Chose the desired effect for the keyboard",
                                            preferredStyle: .actionSheet)
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let playerMode = UIAlertAction(title: "Player Mode", style: .default) { (action) in
            self.selectedKeyboardMode = "oscillator"
        }

        let delayMode = UIAlertAction(title: "Delay Control Mode", style: .default) { (action) in
            self.selectedKeyboardMode = "delay"
        }
        let filterMode = UIAlertAction(title: "Filter Control Mode", style: .default) { (action) in
            self.selectedKeyboardMode = "lowPass"
        }
        let reverbMode = UIAlertAction(title: "Reverb Control Mode", style: .default) { (action) in
            self.selectedKeyboardMode = "reverb"
        }
        let vibratoMode = UIAlertAction(title: "vibrato Control Mode", style: .default) { (action) in
            self.selectedKeyboardMode = "vibrato"
        }

        for name in findContainedAudioNodes(){
            switch name {
            case "oscillator":
                actionSheet.addAction(playerMode)
                break
            case "reverb":
                actionSheet.addAction(reverbMode)
                break
            case "delay":
                actionSheet.addAction(delayMode)
                break
            case "lowPass":
                actionSheet.addAction(filterMode)
                break
            case "vibrato":
                actionSheet.addAction(vibratoMode)
                break
            default:
                break
            }
        
        }
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        actionSheet.addAction(cancelButton)
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    /// When tapped, an action sheet pops up to select the desired action.
    ///
    /// - Parameter node: tapped node.
    func showNodeActionSheet(with node: SCNNode) {
        let actionSheet = UIAlertController(title: "ARSynthesizer",
                                            message: "Action for node",
                                            preferredStyle: .actionSheet)
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel){(action) in
        }
        if (!node.isHandsFreeEnabled!){
            let advancedSettings = UIAlertAction(title: "Hands Free Mode", style: .default){(action) in
                switch node.nodeDescription! {
                case "oscillator":
                    self.motionManager.stopAccelerometerUpdates()
                    self.showBanner(with: "Hands Free Mode")
                    self.motionManager.accelerometerUpdateInterval = 0.1
                    self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
                        if data != nil
                        {
                            let oscillator = node.audioNodeContained as! AKMorphingOscillatorBank
                            let normalisedPitchBend = (round((data?.acceleration.y)! + 1)/2) * 6
                            oscillator.rampTime = 0.01
                            oscillator.pitchBend = normalisedPitchBend * 4
                            self.log.verbose(normalisedPitchBend)
                        }else {
                            self.log.error("There was an error getting the data from the accelerometer")
                        }
                    }
                    node.isHandsFreeEnabled = true
                    break
                case "reverb":
                    self.motionManager.stopAccelerometerUpdates()
                    self.showBanner(with: "Hands Free Mode Enabled")
                    self.motionManager.accelerometerUpdateInterval = 0.1
                    self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
                        if let myData = data
                        {
                            let reverb = node.audioNodeContained as! AKReverb
                            reverb.dryWetMix = (myData.acceleration.y + 1)/2
                        }else {
                            self.log.error("There was an error getting the data from the accelerometer")
                        }
                    }
                    node.isHandsFreeEnabled = true
                    break
                case "delay":
                    self.motionManager.stopAccelerometerUpdates()
                    self.showBanner(with: "Hands Free Mode Enabled")
                    self.motionManager.accelerometerUpdateInterval = 0.01
                    self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
                        if let myData = data
                        {
                            let delay = node.audioNodeContained as! AKDelay
                            delay.dryWetMix = (myData.acceleration.y + 1)/2
                        }else {
                            self.log.error("There was an error getting the data from the accelerometer")
                        }
                    }
                    node.isHandsFreeEnabled = true
                    break
                case "vibrato":
                    self.motionManager.stopAccelerometerUpdates()
                    self.showBanner(with: "Hands Free Mode Enabled")
                    self.motionManager.accelerometerUpdateInterval = 0.01
                    self.motionManager.startAccelerometerUpdates(to: OperationQueue.current!) { (data, error) in
                        if let myData = data
                        {
                            let oscillator = node.audioNodeContained as! AKMorphingOscillatorBank
                            oscillator.vibratoRate = ((myData.acceleration.y + 1)/2) * 10
                        }else {
                            self.log.error("There was an error getting the data from the accelerometer")
                        }
                    }
                    node.isHandsFreeEnabled = true
                    break
                default:
                    break
                }
            }
            if (node.nodeDescription?.elementsEqual("oscillator"))!{
                let jumpToAdvancedSettings = UIAlertAction(title: "Show Advanced Settings", style: .default) { (action) in
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "settingsView") as? OscillatorParametersViewController
                    vc?.nodeToModify = node
                    self.addChildViewController(vc!)
                    vc?.view.frame = self.view.frame
                    self.view.addSubview((vc?.view)!)
                    vc?.didMove(toParentViewController: self)
                }
                actionSheet.addAction(jumpToAdvancedSettings)
            }
            actionSheet.addAction(advancedSettings)
        } else if (node.isHandsFreeEnabled!) && !(node.nodeDescription?.contains(find: "/"))!{
            let advancedSettings = UIAlertAction(title: "Stop Hands Free", style: .default){(action) in
                self.motionManager.stopAccelerometerUpdates()
            }
            actionSheet.addAction(advancedSettings)
        }
        
        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
            popoverController.permittedArrowDirections = []
        }
        
        actionSheet.addAction(cancelButton)
        if !(node.nodeDescription?.contains(find: "/"))!{
            present(actionSheet,animated: true,completion: nil)
        }
        node.isHandsFreeEnabled = false
    }
    
    /// This function is called whenever an item in the collection view is deselected.
    ///
    /// - Parameters:
    ///   - collectionView: View that holds the collection of cells.
    ///   - indexPath: Index for each row/column
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        if let cell = collectionView.cellForItem(at: indexPath) as? CustomItemCell  {
            if (cell.isUserInteractionEnabled){
                cell.backgroundColor = UIColor.black
            } else {
                cell.backgroundColor = UIColor.red
            }
            if indexPath.row == itemsArray.index(of: "keyboard") {
                //If keyboard is deselected, then change to default plane detection (Horizontal).
                DispatchQueue.main.async {
                    if SVProgressHUD.isVisible(){
                        SVProgressHUD.dismiss()
                    }
                }
                log.debug("Finished Vertical Detection")
                self.sceneView.session.pause()
                self.configuration.planeDetection = .horizontal
                self.sceneView.session.run(self.configuration)
            }
        } else {
            log.error("The cell is not ready for interaction, could not be visible.")
        }
    }
    
    /// This function is called whenever an item in the collection view is selected.
    ///
    /// - Parameters:
    ///   - collectionView: View that holds the collection of cells.
    ///   - indexPath: Index for each row/column
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        self.selectedItem = itemsArray[indexPath.row]
        cell?.backgroundColor = UIColor.purple
        if self.selectedItem == "keyboard"{
            if #available(iOS 11.3, *) {
                self.sceneView.session.pause()
                self.configuration.planeDetection = .vertical
                self.sceneView.session.run(self.configuration)
                log.verbose("Session is running")
                DispatchQueue.main.async{
                    if SVProgressHUD.isVisible() {
                        SVProgressHUD.dismiss()
                        SVProgressHUD.show(withStatus: "Trying to detect vertical Plane")
                    }else {
                        SVProgressHUD.show(withStatus: "Trying to detect vertical Plane")
                    }
                }
                } else {
                let versionErrorMessage = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
                let alertController = UIAlertController(title: "Version Error!",
                                                        message: "This function is only available for iOS 11.3 or newer, please update if possible",
                                                        preferredStyle: .alert)
                alertController.addAction(versionErrorMessage)
                self.present(alertController, animated: true, completion: nil)
            }

        } else if self.selectedItem == "sequencer"{

        }
    }
    
    /// This function defines the number of items in the collection view when it is loaded.
    /// - Parameters:
    ///   - collectionView: Main view handling all items.
    ///   - section: Number of items in the collection view.
    /// - Returns: Number of values in the collection view.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsArray.count
    }
    
    /// This function handles all of cell functions, such as label, background, etc.
    ///
    /// - Parameters:
    ///   - collectionView: View that holds all of the items.
    ///   - indexPath: Index for each row/column
    /// - Returns: It returns the cell and sets the label
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! CustomItemCell
        if cell.isSelected && cell.isUserInteractionEnabled{
            cell.backgroundColor = UIColor.purple
        } else if !cell.isSelected && !cell.isUserInteractionEnabled {
            cell.backgroundColor = UIColor.red
        } else if !cell.isSelected && cell.isUserInteractionEnabled{
            cell.backgroundColor = UIColor.black
        }
        cell.itemLabel.text = self.itemsArray[indexPath.row]
        collectionCells.append(cell)
        return cell
    }
    
    /// This renderer calls this function every time a plane is detected and added.
    ///
    /// - Parameters:
    ///   - renderer: Scene Renderer
    ///   - node: Plane added
    ///   - anchor: Anchor for the plane
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        log.verbose(self.configuration.planeDetection)
        if self.configuration.planeDetection == .horizontal {
            node.nodeDescription = "basePlane"
            node.width = planeAnchor.extent.x
            node.height = planeAnchor.extent.z
            self.planeNode = planeAnchor.addPlaneDebugging()
            node.addChildNode(self.planeNode)
            self.firstPlaneDetected = true
            DispatchQueue.main.async {
                self.initialPresetButton.isUserInteractionEnabled = true
                SVProgressHUD.dismiss()
                self.showBanner(with: "Found a horizontal node")
            }
        }
        if #available(iOS 11.3, *) {
            log.verbose("Vertical Plane Detected")
            if self.configuration.planeDetection == .vertical && self.selectedItem == "keyboard"{
                    node.nodeDescription = "keyboardPlane"
                    self.planeNode = planeAnchor.addKeyboardPlane()
                    node.width = planeAnchor.extent.x
                    node.height = planeAnchor.extent.y
                    node.addChildNode(self.planeNode)
                    DispatchQueue.main.async {
                        SVProgressHUD.dismiss()
                        self.showBanner(with: "Found a Keyboard Plane")
                }
            }
        } else {
            // Fallback on earlier versions
            log.verbose("Wrong iOS Version!")
        }
    }
    
    /// This renderer calls this function every time an already detected plane is updated
    ///
    /// - Parameters:
    ///   - renderer: Scene Renderer
    ///   - node: Plane being updated
    ///   - anchor: Anchor for the plane
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor){
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        switch node.nodeDescription! {
        case "basePlane":
            node.width = planeAnchor.extent.x
            node.height = planeAnchor.extent.z
            node.addChildNode(planeAnchor.updatePlaneDebugging(parentNode: node))
            break
        case "keyboardPlane":
            node.width = planeAnchor.extent.x
            node.height = planeAnchor.extent.y
            node.addChildNode(planeAnchor.updateKeyboardDebugging(parentNode: node, selectedFunction: self.selectedKeyboardMode))
            break
        default:
            break
        }
    }
    
    /// This renderer calls this function every time an already detected plane is removed
    ///
    /// - Parameters:
    ///   - renderer: Scene Renderer
    ///   - node: Plane being removed
    ///   - anchor: Anchor for the plane
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor){
        guard anchor is ARPlaneAnchor else {return}
    }
    
    /// This renderer calls this function at a rate of frames per second (60).
    ///
    /// - Parameters:
    ///   - renderer: Scene Renderer
    ///   - time: Frames Per Second (times this function is called every second. (60)
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if sceneIsEmpty(){
            DispatchQueue.main.async{
                self.removeAllButton.isUserInteractionEnabled = false
                self.initialPresetButton.isUserInteractionEnabled = true
            }
        } else {
            DispatchQueue.main.async {
                self.removeAllButton.isUserInteractionEnabled = true
                self.initialPresetButton.isUserInteractionEnabled = false
            }
        }
    }
}
