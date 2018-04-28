//
//  OnboardingInfoViewController.swift
//  ARSynthesis
//
//  Created by Pol Piella on 25/03/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import UIKit
import Onboard
import SwiftGifOrigin

class AddOnboardingInfoView {
    private init(){}
    static let viewController = AddOnboardingInfoView()
    var keyValue = ""
    var onBoardingView = OnboardingViewController()

    func handleOnboardingCompletion (){
        switch keyValue {
        case "intro":
            self.setupNormalRootViewController()
            break
        case "info":
            onBoardingView.dismiss(animated: true, completion: nil)
            print("I am here mate")
            break
        default:
            break
        }
    }
    
    func skip (){
        self.setupNormalRootViewController()
    }
    
    func skipInfo (){
        
    }
    
    func setupNormalRootViewController (){
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "mainVC")
        UIApplication.shared.keyWindow?.rootViewController = viewController
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "userHasOnboarded")
    }
    
    
    open func getViewController(with key: String) -> OnboardingViewController{
        var onboardingVC = OnboardingViewController()
        keyValue = key
        // Create slides
        let firstPage = OnboardingContentViewController.content(withTitle: "Welcome To The App!", body: "Welcome to an Augmented Reality sound synthesis experience!", image: UIImage(named: "image1"), buttonText: nil, action: nil)
        firstPage.bottomPadding = 10
        firstPage.iconHeight = 350
        firstPage.iconWidth = 350
        firstPage.iconImageView.loadGif(name: "equi")
        let secondPage = OnboardingContentViewController.content(withTitle: "Step 1: Detect", body: "", image: UIImage(named: "image2"), buttonText: nil, action: nil)
        secondPage.bottomPadding = 10
        secondPage.iconHeight = 550
        secondPage.iconWidth = 300
        secondPage.iconImageView.loadGif(name: "detection")
        let thirdPage = OnboardingContentViewController.content(withTitle: "Step 2: Place", body: "", image: UIImage(named: "image3"), buttonText: nil, action: nil)
        thirdPage.bottomPadding = 10
        thirdPage.iconHeight = 550
        thirdPage.iconWidth = 300
        thirdPage.iconImageView.loadGif(name: "placeNodes")
        let fourthPage = OnboardingContentViewController.content(withTitle: "Step 3: Connect", body: "", image: UIImage(named: "image4"), buttonText: nil, action: nil)
        fourthPage.bottomPadding = 10
        fourthPage.iconHeight = 550
        fourthPage.iconWidth = 300
        fourthPage.iconImageView.loadGif(name: "connectedNodes")
        let fifthPage = OnboardingContentViewController.content(withTitle: "Step 4: Add Playability", body: "", image: UIImage(named: "image4"), buttonText: "Proceed to Application", action: self.handleOnboardingCompletion)
        fifthPage.bottomPadding = 10
        fifthPage.iconHeight = 550
        fifthPage.iconWidth = 300
        fifthPage.iconImageView.loadGif(name: "sequencerAdd")
        
        // Define onboarding view controller properties
        onboardingVC = OnboardingViewController.onboard(withBackgroundImage: #imageLiteral(resourceName: "Onboarding"), contents: [firstPage, secondPage, thirdPage, fourthPage, fifthPage])
        onboardingVC.shouldFadeTransitions = true
        onboardingVC.shouldMaskBackground = false
        onboardingVC.shouldBlurBackground = false
        onboardingVC.fadePageControlOnLastPage = true
        onboardingVC.pageControl.pageIndicatorTintColor = UIColor.darkGray
        onboardingVC.pageControl.currentPageIndicatorTintColor = UIColor.white
        onboardingVC.skipButton.setTitleColor(UIColor.white, for: .normal)
        onboardingVC.fadeSkipButtonOnLastPage = true
        switch key {
        case "intro":
            onboardingVC.allowSkipping = true
            onboardingVC.skipHandler = {
                self.skip()
            }
            break
        case "info":
            onboardingVC.allowSkipping = false
            onBoardingView = onboardingVC
            break
        default:
            break
        }

        
        // Do any additional setup after loading the view.
        return onboardingVC
    }
    
}
