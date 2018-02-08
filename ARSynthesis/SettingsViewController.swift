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
    var mainMenu: [String] = []
    var nodeArray: [SCNNode]!
    @IBOutlet var popUpView: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        if(mainMenu.isEmpty){
            mainMenu.append("empty")
        } else {
            //It is not empty
        }
        settingsCollectionView.delegate = self
        settingsCollectionView.dataSource = self
        // Do any additional setup after loading the view.
    }
    
    @IBAction func showActionSheet(_ sender: UIButton) {
        let actionSheet = UIAlertController(title: "ARSynthesizer",
                                            message: "If you need support you can either email-us or fill in one of the feedback forms",
                                            preferredStyle: .actionSheet)
        let cancelButton = UIAlertAction(title: "Cancel", style: .cancel){(action) in
            print("Cancel Button")
        }
        let emailButton = UIAlertAction(title: "Email me for support!", style: .default){(action) in
            let email = "info@polpiellamusic.com"
            if let url = URL(string: "mailto:\(email)") {
                UIApplication.shared.open(url)
            }
        }
        let feedbackButton = UIAlertAction(title: "Give some feedback!", style: .default){(action) in
            let webpage = "https://www.surveymonkey.co.uk/r/GJK5CNR"
            if let url = URL(string: webpage) {
                UIApplication.shared.open(url)
            }
        }
        actionSheet.addAction(feedbackButton)
        actionSheet.addAction(cancelButton)
        actionSheet.addAction(emailButton)
        present(actionSheet,animated: true,completion: nil)
    }
    
    @IBAction func closePopUp(_ sender: UIButton) {
        dismiss(animated: true, completion: nil)
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
