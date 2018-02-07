//
//  SettingsViewController.swift
//  ARSynthesis
//
//  Created by Pol Piella on 07/02/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import UIKit
import ARKit

class SettingsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet var settingsCollectionView: UICollectionView!
    let mainMenu = ["osc", "reverb", "delay",]
    var mainMenuTest: [String] = []
    var nodeArray: [SCNNode]!
    var sceneView = ARSCNView()
    var passSession = ARSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(mainMenuTest.isEmpty){
            mainMenuTest.append("empty")
        } else {
            //It is not empty
        }
        settingsCollectionView.delegate = self
        settingsCollectionView.dataSource = self
        // Do any additional setup after loading the view.
    }

    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mainMenuTest.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "customCell", for: indexPath) as! modifiedCollectionViewCell
        cell.settingsCellImage.setImage(UIImage(named: mainMenuTest[indexPath.row]), for: UIControlState.normal)
        cell.settingsCellLabel.text = mainMenuTest[indexPath.row].capitalized
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.destination is ViewController
        {
            let vc = segue.destination as? ViewController
            vc?.passSession = self.passSession
            vc?.firstTime = false
            vc?.nodeArray = self.nodeArray
      
        }
    }


}
