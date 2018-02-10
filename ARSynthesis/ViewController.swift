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

/// This class handles the main user interface.
class ViewController: UIViewController, UICollectionViewDataSource , UICollectionViewDelegate, ARSCNViewDelegate{
    //These are only initialised once!!!
    var nodeArray: [SCNNode]!
    
    var mixer: AudioMixer!
    var firstTime: Bool!
    var overAllScale: CGFloat = 1
    let itemsArray: [String] = ["oscillator", "reverb", "delay"]
    var collectionCells: [UICollectionViewCell] = []
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var selectedItem: String?
    var destinationNode = SCNNode()
    var startingNode = SCNNode()
    var passSession: ARSession!
    override func viewDidLoad() {
        super.viewDidLoad()
        firstTime = true
        if (firstTime){
            nodeArray = []
        }
        mixer = AudioMixer()
        self.configuration.planeDetection = .horizontal
        self.sceneView.session.run(configuration)
        self.itemsCollectionView.dataSource = self
        self.itemsCollectionView.delegate = self
        self.sceneView.delegate = self
        self.registerGestureRecognizers()
        self.sceneView.autoenablesDefaultLighting = true
    }

    override func viewDidAppear(_ animated: Bool) {
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
    
    func showFaultyConnectionDialog(animated: Bool = true) {
        let popup = PopupDialog(identifier: "Faulty Connection")
        let cancelButton = CancelButton(title: "OK") {
        }
        popup.addButtons([cancelButton])
        self.present(popup, animated: animated, completion: nil)
    }
    
    func showMisplacementDialog(animated: Bool = true){
        let popup = PopupDialog(identifier: "misplaced")
        let cancelButton = CancelButton(title: "OK") {
        }
        popup.addButtons([cancelButton])
        self.present(popup, animated: animated, completion: nil)
    }
    
    /// This function registers all of the gesture recognizers, initializes them and adds them to the augmented reality scene.
    func registerGestureRecognizers() {
        let oneTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        oneTapGestureRecognizer.numberOfTapsRequired = 1
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        oneTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
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
    @objc func doubleTapped(sender: UITapGestureRecognizer){
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation)
        if !hitTest.isEmpty && !(hitTest.first?.node.nodeDescription?.elementsEqual("basePlane"))!{
            self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                if node == hitTest.first?.node {
                    node.removeAllLinks(scene: sceneView)
                    self.nodeArray.remove(at: nodeArray.index(of: node)!)
                    if node.isEffect! {
                        //This array value will be useful to check if nodes exist in the scene
                        let index = itemsArray.index(of: node.nodeDescription!)
                        let cell = collectionCells[index!]
                        cell.isUserInteractionEnabled = true
                        cell.backgroundColor = UIColor.black
                    }
                    if((node.inputConnection?.isNotEmpty)! && node.outputConnection != nil && nodeArray.contains(node.outputConnection!)){
                        for input in node.inputConnection!{
                            drawLineBetweenNodes(startingNode: input, destinationNode: node.outputConnection!)
                            mixer.connect(fromOutput: input, toInput: node.outputConnection!)
                        }
                    } else{
                        
                    }
                    mixer.remove(node: node)
                    node.removeFromParentNode()
                }
            }
        }
    }
    
    /// This function detects any node being pinched and scales it accordingly
    ///
    /// - Parameter sender: Pinch Gesture Recognizer
    @objc func pinch(sender: UIPinchGestureRecognizer) {
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
                mixer.scaleValue(of: node, scaleValue: Double(sender.scale))
                //mixer.scaleOscillatorAmplitude(osc: node.audioNodeContained as! AKOscillator, scalingFactor: Double(sender.scale))
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
            self.addItem(hitTestResult: hitTest.first!)
        } else if (!hitTestItems.isEmpty && !(hitTestItems.first?.node.nodeDescription?.elementsEqual("basePlane"))!) {
            var _: [Double] = []
//                if node.name != nil && node.name != (hitTestItems.first?.node.name){
//                    //When pressing on a node, the closest neighbor is found.
//                    let positionNode1 = node.position
//                    let positionNode2 = hitTestItems.first?.node.position
//                    modulusArray.append(deltaModulusCalculation(relative:positionNode1, anchor: positionNode2!))
//                    node.name = String(deltaModulusCalculation(relative:  positionNode1, anchor: positionNode2!))
//                    if deltaModulusCalculation(relative:  positionNode1, anchor: positionNode2!) > 0 {
//                    }
//
//                }
//            }
//            if !modulusArray.isEmpty{
//                let minimum = String(describing: modulusArray.min()!)
//                let closestNode = self.sceneView.scene.rootNode.childNode(withName: minimum, recursively: true)
//                closestNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
//                drawLineBetweenNodes(startingNode: (hitTestItems.first?.node)!, destinationNode: closestNode!)
//            }
            }
        }
    }
    
    func drawLineBetweenNodes (startingNode: SCNNode, destinationNode: SCNNode){
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.white
        material.specular.contents = UIColor.white
        let v1 = startingNode.position
        let v2 = destinationNode.position
        switch destinationNode.nodeDescription! {
        case "oscillator":
            self.showFaultyConnectionDialog()
            break
        case "reverb", "delay":
            startingNode.outputIsConnected = true
            destinationNode.inputIsConnected = true
            let linkName = "Link \(startingNode.name ?? "") | \(destinationNode.name ?? "")"
            let lineNode = LineNode(name: linkName, v1: v1, v2: v2, material: [material])
            lineNode.nodeDescription = "line"
            self.sceneView.scene.rootNode.addChildNode(lineNode)
            destinationNode.inputConnection?.append(startingNode)
            startingNode.outputConnection = destinationNode
            mixer.connect(fromOutput: startingNode, toInput: destinationNode)
            //mixer.connectToReverb(startingNode: startingNode, destinationNode: destinationNode)
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
    /// This function handles all the item addition to the augmented reality scene.
    ///
    /// - Parameter hitTestResult: This is the result array when a touch is detected.
    func addItem(hitTestResult: ARHitTestResult) {
        if let selectedItem = self.selectedItem {
            let scene = SCNScene(named: "Models.scnassets/itemShape.scn")
            let node = (scene?.rootNode.childNode(withName: "itemShape", recursively: false))!
            node.name = "\(selectedItem)"
            let transform = hitTestResult.worldTransform
            let thirdColumn = transform.columns.3
            node.position = SCNVector3(thirdColumn.x, thirdColumn.y + 0.05, thirdColumn.z)
            let currentIndex = nodeArray.count
            let sides = [UIColor.black,UIColor.black,UIColor.black,UIColor.black,UIImage(named:"\(selectedItem).png"),UIColor.black] as [Any]
            let materials = sides.map { (side) -> SCNMaterial in
                    let material = SCNMaterial()
                    material.diffuse.contents = side
                    material.locksAmbientWithDiffuse = true
                    return material
                }
                node.nodeDescription = selectedItem
                node.geometry?.materials = materials
                node.initialiseParameters()
                nodeArray.insert(node, at: currentIndex)
                self.sceneView.scene.rootNode.addChildNode(nodeArray[currentIndex])
                for node in nodeArray{
                    node.name = String("\(nodeArray.index(of: node)!)")
                }
                mixer.append(node: node)
                if node.isEffect!{
                    let cellIndex = itemsArray.index(of: selectedItem)
                    let cell = collectionCells[cellIndex!]
                    cell.isUserInteractionEnabled = false
                    cell.isSelected = false
                    cell.backgroundColor = UIColor.red
                    self.selectedItem = "oscillator"
                }
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! itemCell
        cell.itemLabel.text = self.itemsArray[indexPath.row]
        collectionCells.append(cell)
        return cell
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
    }
    /// This function is called whenever an item in the collection view is deselected.
    ///
    /// - Parameters:
    ///   - collectionView: View that holds the collection of cells.
    ///   - indexPath: Index for each row/column
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        if (cell?.isUserInteractionEnabled)!{
            cell?.backgroundColor = UIColor.black
        } else {
            cell?.backgroundColor = UIColor.red
        }
    }
    /// This renderer calls this function every time a plane is detected and added.
    ///
    /// - Parameters:
    ///   - renderer: Scene Renderer
    ///   - node: Plane added
    ///   - anchor: Anchor for the plane
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else {return}
        node.addChildNode(planeAnchor.addPlaneDebugging())
        DispatchQueue.main.async{
           SVProgressHUD.dismiss()
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
        node.addChildNode(planeAnchor.updatePlaneDebugging(parentNode: node))
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
    
    /// When a long press is detected, the pressed node rotates (360 degrees), within 10 seconds. If the press ends, the node stops rotating.
    /// - Parameter sender: Gesture recognizer to handle long presses.
    @objc func longPress(sender: UILongPressGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let holdLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(holdLocation)
        if !hitTest.isEmpty && !(hitTest.first?.node.nodeDescription?.elementsEqual("basePlane"))! {
            destinationNode = (hitTest.first?.node)!
            if(destinationNode.eulerAngles.y >= (2 * .pi))
            {
                destinationNode.eulerAngles.y = 0
            }
            if sender.state == .began {
                let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 5)
                let forever = SCNAction.repeatForever(rotation)
                destinationNode.runAction(forever)
                startingNode = destinationNode
            }else if sender.state == .changed{
                if destinationNode == startingNode{
                } else if !startingNode.outputIsConnected! && (!destinationNode.inputIsConnected! || destinationNode.allowsMultipleInputs!){
                    self.drawLineBetweenNodes(startingNode: startingNode, destinationNode: destinationNode)
                } else {
                }
            } else if sender.state == .ended {
                destinationNode.removeAllActions()
            } else if sender.state == .failed{
                destinationNode.removeAllActions()
            }
        } else {
            destinationNode.removeAllActions()
        }
    }

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
        }
    }
    
}


// MARK: - This is a list of extension functions to avoid magic numbers and handle some of the functionality.
extension Int {
    var degreesToRadians: Double { return Double(self) * .pi/180}
}



