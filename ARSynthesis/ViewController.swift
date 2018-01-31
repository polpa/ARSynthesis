//
//  ViewController.swift
//  ARSynthesis
//
//  Created by Pol Piella on 2017-08-18.
//  Copyright © 2017 Pol Piella. All rights reserved.
//

import UIKit
import ARKit
import SceneKit
import AudioKit
import PopupDialog
import SVProgressHUD

class ViewController: UIViewController, UICollectionViewDataSource , UICollectionViewDelegate, ARSCNViewDelegate{
    var mixer: AudioMixer!
    let itemsArray: [String] = ["oscillator", "reverb"]
    var nodeArray: [SCNNode] = []
    var effectArray: [SCNNode] = []
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var selectedItem: String?
    override func viewDidLoad() {
        super.viewDidLoad()
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
        DispatchQueue.main.async{
            self.showStandardDialog()
        }

    }
    
    func showStandardDialog(animated: Bool = true) {
        
        // Prepare the popup
        let title = "WELCOME TO ARSYNTHESIS"
        let message = "Please be aware that, for a good and safe AR experience, one must always watch its environment and not use it while conducting potentially hazardous situations"
        
        // Create the dialog
        let popup = PopupDialog(title: title,
                                message: message,
                                buttonAlignment: .horizontal,
                                transitionStyle: .zoomIn,
                                gestureDismissal: true,
                                hideStatusBar: true) {
                                    print("Completed")
        }
        
        // Create first button
        let buttonOne = CancelButton(title: "OK") {
            SVProgressHUD.show(withStatus: "Trying to detect plane, please and move around to find a horizontal surface")
        }
        
        // Add buttons to dialog
        popup.addButtons([buttonOne])
        
        // Present dialog
        self.present(popup, animated: animated, completion: nil)
    }
    
    func registerGestureRecognizers() {
        let oneTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        oneTapGestureRecognizer.numberOfTapsRequired = 1
        let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        doubleTapGestureRecognizer.numberOfTapsRequired = 2
        oneTapGestureRecognizer.require(toFail: doubleTapGestureRecognizer)
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(rotate))
        longPressGestureRecognizer.minimumPressDuration = 0.1
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(oneTapGestureRecognizer)
        self.sceneView.addGestureRecognizer(doubleTapGestureRecognizer)
    }
    
    @objc func doubleTapped(sender: UITapGestureRecognizer){
        //This recognises the number of touches
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation)
        if !hitTest.isEmpty{
            self.sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                if node == hitTest.first?.node {
                    let caseName = node.geometry?.name!
                    switch caseName! {
                    case "box":
                        self.mixer.removeOscillator(index: nodeArray.index(of: node)!)
                        self.nodeArray.remove(at: nodeArray.index(of: node)!)
                        node.removeFromParentNode()
                        break
                    case "pyramid":
                        self.effectArray.remove(at: effectArray.index(of: node)!)
                        node.removeFromParentNode()
                        break
                    default:
                        break
                    }

                }
            }
        }
        
    }
    @objc func pinch(sender: UIPinchGestureRecognizer) {

        let sceneView = sender.view as! ARSCNView
        let pinchLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(pinchLocation)
        if !hitTest.isEmpty {
            let results = hitTest.first!
            let node = results.node
            let nodeIndex = nodeArray.index(of: node)
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
            node.runAction(pinchAction)
            //This works!!
            mixer.scaleOscillatorAmplitude(index: nodeIndex!, scalingFactor: Double(sender.scale))
            sender.scale = 1.0
        }
    }
    
    open func volume (x: CGFloat, y: CGFloat, z: CGFloat) -> Double{
        return Double(x*y*z)
    }
    
    @objc func tapped(sender: UITapGestureRecognizer) {
        //Recognises the tap, associated with the tap gesture recognizer and checks if it is in a plane.
        let sceneView = sender.view as! ARSCNView
        let tapLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        let hitTestItems = sceneView.hitTest(tapLocation)
       if !hitTest.isEmpty{
        if hitTestItems.isEmpty {
            self.addItem(hitTestResult: hitTest.first!)
        } else if (!hitTestItems.isEmpty) {
            var modulusArray: [Double] = []
            sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
                if node.name != nil && node.name != (hitTestItems.first?.node.name){
                    var i = 0
                    //When pressing on a node, the closest neighbor is found.
                    let positionNode1 = node.position
                    let positionNode2 = hitTestItems.first?.node.position
                    modulusArray.append(deltaModulusCalculation(input: positionNode1, measured: positionNode2!))
                    node.name = String(deltaModulusCalculation(input: positionNode1, measured: positionNode2!))
                    print(node.name!)
                    i = i + 1
                }
            }
            if !modulusArray.isEmpty{
                let minimum = String(describing: modulusArray.min()!)
                print(minimum)
                let closestNode = self.sceneView.scene.rootNode.childNode(withName: minimum, recursively: true)
                closestNode?.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
            }

            }
        }
    }

    func deltaModulusCalculation (input:SCNVector3, measured: SCNVector3) -> Double{
        var modulus: Double = 0
        let squaredX = Double(pow(Double(input.x - measured.x), Double(2)))
        let squaredZ = Double(pow(Double(input.z - measured.z), Double(2)))
        modulus = Double(sqrt(squaredX + squaredZ))
        return modulus
    }
    
    func addItem(hitTestResult: ARHitTestResult) {
        if let selectedItem = self.selectedItem {
            print(selectedItem)
            let scene = SCNScene(named: "Models.scnassets/\(selectedItem).scn")
            let node = (scene?.rootNode.childNode(withName: selectedItem, recursively: false))!
            node.name = "\(selectedItem)"
            let transform = hitTestResult.worldTransform
            let thirdColumn = transform.columns.3
            node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
            let effectIndex = effectArray.count
            let currentIndex = nodeArray.count

            switch selectedItem {
            case "oscillator":
                nodeArray.insert(node, at: currentIndex)
                self.sceneView.scene.rootNode.addChildNode(nodeArray[currentIndex])
                for node in nodeArray{
                    node.name = String("\(nodeArray.index(of: node)!)")
                }
                print(currentIndex)
                mixer.appendOscillator(index: currentIndex)
                break
            case "reverb":
                effectArray.insert(node, at: effectIndex)
                self.sceneView.scene.rootNode.addChildNode(effectArray[effectIndex])
                for node in effectArray{
                    node.name = String("\(effectArray.index(of: node)!)")
                }
                print("HEYHO")
                mixer.appendEffect(effectName: "Reverb", index: effectArray.index(of: node)!)
                break
            default:
                break
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsArray.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "item", for: indexPath) as! itemCell
        cell.itemLabel.text = self.itemsArray[indexPath.row]
        return cell
    }
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        self.selectedItem = itemsArray[indexPath.row]
        cell?.backgroundColor = UIColor.purple
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        //Handles the case where an item is deselected.
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.black
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        DispatchQueue.main.async{
            SVProgressHUD.dismiss()
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor){
        guard anchor is ARPlaneAnchor else {return}
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor){
        guard anchor is ARPlaneAnchor else {return}
    }
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
    }
    
    @objc func rotate(sender: UILongPressGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let holdLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(holdLocation)
        if !hitTest.isEmpty {
            let result = hitTest.first!
            if sender.state == .began {
                let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 10)
                let forever = SCNAction.repeatForever(rotation)
                result.node.runAction(forever)
            }else if sender.state == .changed{
                if(result.node.eulerAngles.y >= (2 * .pi))
                {
                    result.node.eulerAngles.y = 0
                }
                decodeEulerAngles(angleValues: result.node.eulerAngles.y)
            } else if sender.state == .ended {
                result.node.removeAllActions()
            }
        }
    }
    func decodeEulerAngles(angleValues: Float){
        if (angleValues <= .pi/2){
            print("WAVEFORM 1")
        } else if (angleValues > (.pi/2) && angleValues <= .pi){
            print("WAVEFORM 2")
        } else if (angleValues > .pi && angleValues <= ((3 * .pi)/2)){
            print("WAVEFORM 3")
        } else if (angleValues > ((3 * .pi)/2) && angleValues <= 2 * .pi) {
            print("WAVEFORM 4")
        }
    }
    
}

extension Int {
    
    var degreesToRadians: Double { return Double(self) * .pi/180}
}



