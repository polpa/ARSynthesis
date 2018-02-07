//
//  SettingsViewController.swift
//  ARSynthesis
//
//  Created by Pol Piella on 07/02/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    @IBOutlet var settingsCollectionView: UICollectionView!
    let mainMenu = ["osc", "reverb", "delay",]
    var mainMenuTest: [String] = []
    
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


}
