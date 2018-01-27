//
//  ViewController.swift
//  Ikea
//
//  Created by Rayan Slim on 2017-08-18.
//  Copyright © 2017 Rayan Slim. All rights reserved.
//

import UIKit
import ARKit
import AudioKit

class ViewController: UIViewController, UICollectionViewDataSource , UICollectionViewDelegate, ARSCNViewDelegate{
    
    var mixer: AudioMixer!
    @IBOutlet var planeDetectionLabel: UILabel!
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
    
    func registerGestureRecognizers() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(rotate))
        longPressGestureRecognizer.minimumPressDuration = 0.1
        self.sceneView.addGestureRecognizer(longPressGestureRecognizer)
        self.sceneView.addGestureRecognizer(pinchGestureRecognizer)
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
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
            //Recursively means that it looks through all the scene to find the node with the given name, otherwise it just gets the inmediate child
            let node = self.sceneView.scene.rootNode.childNode(withName: (hitTestItems.first?.node.name)!, recursively: true)
            removeGivenNode(node: node)
            
        }
        }
    }
    
    func removeGivenNode (node: SCNNode!){
        let name = node?.geometry?.name!
        node?.removeFromParentNode()
        print(name!)
        switch name! {
        case "box":
            let currentIndex = nodeArray.index(of: node!)
            mixer.removeOscillator(index: currentIndex!)
            nodeArray.remove(at: currentIndex!)
            break
        case "pyramid":
            let currentIndex = effectArray.index(of: node!)
            effectArray.remove(at: currentIndex!)
            break
        default:
            break
        }
        
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
                mixer.appendEffect(effectName: "Reverb", index: effectArray.index(of: node)!)
                print("This is the reverb Module")
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
            self.planeDetectionLabel.text = "Plane Detected!"
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor){
        guard anchor is ARPlaneAnchor else {return}
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor){
        guard anchor is ARPlaneAnchor else {return}
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



