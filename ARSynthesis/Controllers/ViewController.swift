//
//  ViewController.swift
//  ARSynthesis
//
//  Created by Pol Piella on 2017-08-18.
//  Copyright © 2017 Pol Piella. All rights reserved.
//
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
    @IBOutlet weak var handsFreeMode: UIImageView!
    
    let log = DebuggerService.singletonDebugger.log
    let itemsArray: [String] = ["oscillator", "reverb", "delay", "lowPass", "flanger", "keyboard", "sequencer"]
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
        firstTime = true
        if (firstTime){
            nodeArray = []
        }
        setupScene()
    }
    
    func showBanner(with titleInput: String){
        let title = NSAttributedString(string: titleInput)
        let banner = StatusBarNotificationBanner(attributedTitle: title, style: .info, colors: CustomBannerColors())
        banner.show()
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

    /// This function registers all of the gesture recognizers, initializes them and adds them to the augmented reality scene.
    func registerGestureRecognizers() {
        let oneTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(removeNode))
        oneTapGestureRecognizer.numberOfTapsRequired = 1
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        oneTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(scaleNode))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
        longPressGestureRecognizer.minimumPressDuration = 0.1
        
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(oneTapGestureRecognizer)
        self.sceneView.addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    /// This function handles double tap gestures in the augmented reality scene.
    ///
    /// - Parameter sender: Double tap gesture recognizer.
    @objc func removeNode(sender: UITapGestureRecognizer){
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation)
        if !hitTest.isEmpty && !(hitTest.first?.node.nodeDescription?.elementsEqual("basePlane"))! && !(hitTest.first?.node.nodeDescription?.elementsEqual("keyboardPlane"))!{
            if (hitTest.first?.node.isHandsFreeEnabled!)!{
            }
            nodeRemove(with: (hitTest.first?.node)!)
        }
    }
    func changeCellColor(for description: String){
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
            changeCellColor(for: findSequencer)
            self.sequencerPresent = false
            sequencerArray.removeAll()
            AudioInterfaceHandler.singletonMixer.sequencer.stop()
            //Sort out the sequencer, turn it off or simply set it to zero
        } else{
            nodeToBeRemoved.removeAllLinks(scene: sceneView)//First remove all connections
            self.nodeArray.remove(at: nodeArray.index(of: nodeToBeRemoved)!) //Remove it from the array
            if nodeToBeRemoved.isEffect!{
                //This array value will be useful to check if nodes exist in the scene
                //Just do some simple user interface actions when the removed node is an effect.
                self.changeCellColor(for: nodeToBeRemoved.nodeDescription!)
            }
            if((nodeToBeRemoved.inputConnection?.isNotEmpty)! && nodeToBeRemoved.outputConnection != nil && nodeArray.contains(nodeToBeRemoved.outputConnection!)){
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
                    guard let inputNode = node.audioNodeContained else {return}
                    inputNode.disconnectOutput()
                    inputNode.connect(to: mixer)
                }
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
    
    /// This function detects any node being pinched and scales it accordingly
    ///
    /// - Parameter sender: Pinch Gesture Recognizer
    @objc func scaleNode(sender: UIPinchGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(pinchLocation)
        if !hitTest.isEmpty && !(hitTest.first?.node.nodeDescription?.elementsEqual("basePlane"))! {
            let results = hitTest.first!
            let node = results.node
            if(node.overallAmplitude! >= CGFloat(1.0) && sender.scale > 1){

            } else {
                let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
                node.runAction(pinchAction)
                node.overallAmplitude = sender.scale * node.overallAmplitude!
                AudioInterfaceHandler.singletonMixer.scaleValue(of: node, scaleValue: Double(sender.scale))
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
            if (self.selectedItem?.elementsEqual("sequencer"))! {
                if !self.sequencerPresent{
                    self.sequencerPresent = true
                    self.addSequencer(hitTestResult: hitTest.first!)
                }
            } else{
                self.addItem(hitTestResult: hitTest.first!)
            }
        } else if !hitTestItems.isEmpty && !(hitTestItems.first?.node.nodeDescription?.elementsEqual("basePlane"))! && !(hitTestItems.first?.node.nodeDescription?.elementsEqual("keyboardPlane"))! &&
            !(hitTestItems.first?.node.name?.contains(find: "."))!
            {
            self.showNodeActionSheet(with: (hitTestItems.first?.node)!)
        } else if !hitTestItems.isEmpty && (hitTestItems.first?.node.nodeDescription?.elementsEqual("keyboardPlane"))!{
            if !(self.selectedKeyboardMode.elementsEqual("sequencer")){
                showKeyboardActionSheet(with: (hitTestItems.first?.node)!)
            } 
        } else if !hitTestItems.isEmpty && (hitTestItems.first?.node.name?.contains(find: "."))!{
            guard let node = hitTestItems.first?.node else {return}
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
        case "oscillator":
            self.showBanner(with: "Could not connect")
            break
        case "reverb", "delay", "lowPass", "flanger", "distortion":
            startingNode.outputIsConnected = true
            destinationNode.inputIsConnected = true
            let linkName = "Link \(startingNode.name ?? "") | \(destinationNode.name ?? "")"
            let lineNode = LineNode(name: linkName, v1: v1, v2: v2, material: [material])
            lineNode.nodeDescription = "line"
            self.sceneView.scene.rootNode.addChildNode(lineNode)
            destinationNode.inputConnection?.append(startingNode)
            startingNode.outputConnection = destinationNode
            AudioInterfaceHandler.singletonMixer.connect(fromOutput: startingNode, toInput: destinationNode)
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
    
    func addSequencer(hitTestResult: ARHitTestResult){
        guard let selectedItem = self.selectedItem else {
            log.error("There is no selected item")
            return
        }
        let transform = hitTestResult.worldTransform
        let thirdColumn = transform.columns.3
        changeCellColor(for: "sequencer")
        if selectedItem.elementsEqual("sequencer"){
            //This will set up the sequencer
            self.sceneView.scene.rootNode.enumerateChildNodes { (node, _) in
                if (node.nodeDescription?.elementsEqual("oscillator"))!{
                    AudioInterfaceHandler.singletonMixer.sequencerSelected(node: node)
                }
            }
            var n = 0
            repeat {
                let node = SCNNode(geometry: SCNBox(width: 0.07, height: 0.08, length: 0.07, chamferRadius: 0))
                node.name = "sequencer"
                node.geometry?.firstMaterial?.diffuse.contents = UIColor.black
                node.nodeDescription = "Sequencer(\(n))"
                if n >= 0 && n<4{
                    node.position = SCNVector3Make(Float(thirdColumn.x + 0.15*(n)), thirdColumn.y, thirdColumn.z)
                    node.name = "\(n).0"
                }else if n >= 4 && n<8{
                    node.position = SCNVector3Make(Float(thirdColumn.x + 0.15*(n-4)), thirdColumn.y, thirdColumn.z + 0.15 )
                    node.name = "\(n-4).1"
                } else if n>=8 && n<12{
                    node.position = SCNVector3Make(Float(thirdColumn.x + 0.15*(n-8)), thirdColumn.y, thirdColumn.z + 0.30)
                    node.name = "\(n-8).2"
                }else {
                    node.position = SCNVector3Make(Float(thirdColumn.x + 0.15*(n-12)), thirdColumn.y, thirdColumn.z + 0.45 )
                    node.name = "\(n-12).3"
                    node.geometry?.firstMaterial?.diffuse.contents = UIColor.purple
                }
                sequencerArray.append(node)
                self.sceneView.scene.rootNode.addChildNode(node)
                n = n + 1
            }while n < 16
        }else {
            log.warning("no sequencer is selected")
        }
    }
    /// This function handles all the item addition to the augmented reality scene.
    ///
    /// - Parameter hitTestResult: This is the result array when a touch is detected.
    func addItem(hitTestResult: ARHitTestResult) {
        guard let selectedItem = self.selectedItem else {
            log.error("There is no selected item")
            return
            
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
            node.isHandsFreeEnabled = false
            node.position = SCNVector3(thirdColumn.x, thirdColumn.y + 0.05, thirdColumn.z)
            node.nodeDescription = selectedItem
            node.geometry?.materials = materials
            node.initialiseParameters()
            nodeArray.insert(node, at: currentIndex)
            self.sceneView.scene.rootNode.addChildNode(nodeArray[currentIndex])
        
            for node in nodeArray{
                    node.name = String("\(nodeArray.index(of: node)!)")
            }
            
            AudioInterfaceHandler.singletonMixer.append(node: node)
            if node.isEffect!  {
                self.changeCellColor(for: node.nodeDescription!)
                self.selectedItem = "oscillator"
            }
    }
    

    /// When a long press is detected, the pressed node rotates (360 degrees), within 10 seconds. If the press ends, the node stops rotating.
    /// - Parameter sender: Gesture recognizer to handle long presses.
    @objc func longPress(sender: UILongPressGestureRecognizer) {

        let sceneView = sender.view as! ARSCNView
        let holdLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(holdLocation)
        
        if !hitTest.isEmpty && !(hitTest.first?.node.nodeDescription?.elementsEqual("basePlane"))! && !(hitTest.first?.node.nodeDescription?.elementsEqual("keyboardPlane"))!  {
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
                } else if !startingNode.outputIsConnected! && (!destinationNode.inputIsConnected! || destinationNode.allowsMultipleInputs!){
                    self.drawLineBetweenNodes(startingNode: startingNode, destinationNode: destinationNode)
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
        } else if !hitTest.isEmpty && (hitTest.first?.node.nodeDescription?.elementsEqual("keyboardPlane"))!{
            guard let location = hitTest.first?.localCoordinates else {return}
            guard let node = hitTest.first?.node else {return}
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
                    } else if nodeDescription.elementsEqual("flanger") && (self.selectedKeyboardMode.elementsEqual("flanger")){
                        let flanger = node.audioNodeContained as! AKFlanger
                        flanger.depth = Double(normalisedDataX)
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
                    } else if nodeDescription.elementsEqual("flanger") && (self.selectedKeyboardMode.elementsEqual("flanger")){
                        
                    } else if (self.selectedKeyboardMode.elementsEqual("none")){
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
        } else {
            destinationNode.removeAllActions()
            log.error("No node has been found!")
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
        var stringArray: [String] = []
        if segue.destination is SettingsViewController
        {
            nodeArray.removeAll()
            let vc = segue.destination as? SettingsViewController
            self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                if !(node.nodeDescription?.elementsEqual(""))!{
                    stringArray.append(node.nodeDescription!)
                    nodeArray.append(node)
                }
           }
           vc?.mainMenu = stringArray
           vc?.nodeArray = self.nodeArray
        
        } else if segue.destination is OscillatorParametersViewController{
//            let vc = segue.destination as? OscillatorParametersViewController
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

// MARK: - This is a list of extension functions to avoid magic numbers and handle some of the functionality.
extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
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
        let flangerMode = UIAlertAction(title: "Flanger Control Mode", style: .default) { (action) in
            self.selectedKeyboardMode = "flanger"
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
            case "flanger":
                actionSheet.addAction(flangerMode)
                break
            default:
                break
            }
        
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
//                            let oscillator = node.audioNodeContained as! AKMorphingOscillatorBank
//                            oscillator.rampTime = 0.1
//                            oscillator.frequency = round((myData.acceleration.x + 1)/2 * 10000)
//                            oscillator.amplitude = (myData.acceleration.y + 1)/2
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
                    break
                case "mixer":
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
        } else if (node.isHandsFreeEnabled!){
            let advancedSettings = UIAlertAction(title: "Stop Hands Free", style: .default){(action) in
                self.motionManager.stopAccelerometerUpdates()
            }
            actionSheet.addAction(advancedSettings)
        }
        
        actionSheet.addAction(cancelButton)
        present(actionSheet,animated: true,completion: nil)
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
        if cell.isSelected {
            cell.backgroundColor = UIColor.purple
        } else {
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
        if self.configuration.planeDetection == .horizontal {
            node.nodeDescription = "basePlane"
            self.planeNode = planeAnchor.addPlaneDebugging()
            node.addChildNode(self.planeNode)
            self.firstPlaneDetected = true
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                self.showBanner(with: "Found a horizontal node")
            }
        if #available(iOS 11.3, *) {
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
        }
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
    }
}
