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
    let mainMenuTest: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        settingsCollectionView.delegate = self
        settingsCollectionView.dataSource = self
        // Do any additional setup after loading the view.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return mainMenu.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "customCell", for: indexPath) as! modifiedCollectionViewCell
        cell.settingsCellImage.setImage(UIImage(named: mainMenu[indexPath.row]), for: UIControlState.normal)
        cell.settingsCellLabel.text = mainMenu[indexPath.row].capitalized
        return cell
    }


}
