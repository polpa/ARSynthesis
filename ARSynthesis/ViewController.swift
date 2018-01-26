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
    let itemsArray: [String] = ["oscillator", "mixer", "sequencer", "reverb"]
    @IBOutlet weak var itemsCollectionView: UICollectionView!
    @IBOutlet weak var sceneView: ARSCNView!
    let configuration = ARWorldTrackingConfiguration()
    var i = 0
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

        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
            let pinchAction = SCNAction.scale(by: sender.scale, duration: 0)
            node.runAction(pinchAction)
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
        print(hitTestItems.isEmpty)
        if(hitTestItems.isNotEmpty){
            print(hitTestItems.first?.node.name)
        }
       if !hitTest.isEmpty{
        if hitTestItems.isEmpty || hitTestItems.first?.node.name == nil{
            self.addItem(hitTestResult: hitTest.first!)
        } else if hitTestItems.first?.node.name != nil {
            print(hitTestItems.first?.node.name!)
            let node = self.sceneView.scene.rootNode.childNode(withName: (hitTestItems.first?.node.name)!, recursively: true) //Recursively means that it looks through all the scene to find the node with the given name, otherwise it just gets the inmediate child
            node?.removeFromParentNode()
            mixer.removeOscillator(index: Int((hitTestItems.first?.node.name)!)!)
            i = i-1
        }
        }
    }
    
    func addItem(hitTestResult: ARHitTestResult) {
        if let selectedItem = self.selectedItem {
            let scene = SCNScene(named: "Models.scnassets/\(selectedItem).scn")
            let node = (scene?.rootNode.childNode(withName: selectedItem, recursively: false))!
            node.name = "\(i)"
            let transform = hitTestResult.worldTransform
            let thirdColumn = transform.columns.3
            node.position = SCNVector3(thirdColumn.x, thirdColumn.y, thirdColumn.z)
            self.sceneView.scene.rootNode.addChildNode(node)
            if selectedItem.elementsEqual("oscillator") {
                mixer.appendOscillator(index: i)
                i = i + 1
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
        cell?.backgroundColor = UIColor.green
    }
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.orange
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else {return}
        print("Plane has been detected")
        DispatchQueue.main.async{
            self.planeDetectionLabel.text = "Plane Detected!"
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor){
        guard anchor is ARPlaneAnchor else {return}
        print("plane is updating")
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor){
        guard anchor is ARPlaneAnchor else {return}
    }
    
    @objc func rotate(sender: UILongPressGestureRecognizer) {
        let sceneView = sender.view as! ARSCNView
        let holdLocation = sender.location(in: sceneView)
        let hitTest = sceneView.hitTest(holdLocation)
        print(hitTest.isEmpty)
        if !hitTest.isEmpty {
            let result = hitTest.first!
            if sender.state == .began {
                let rotation = SCNAction.rotateBy(x: 0, y: CGFloat(360.degreesToRadians), z: 0, duration: 10)
                let forever = SCNAction.repeatForever(rotation)
                result.node.runAction(forever)
                print(result.node.eulerAngles)
            } else if sender.state == .ended {
                result.node.removeAllActions()
            }
        }
        
        
    }
    
}

extension Int {
    
    var degreesToRadians: Double { return Double(self) * .pi/180}
}



