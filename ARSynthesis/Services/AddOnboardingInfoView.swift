//
//  OnboardingInfoViewController.swift
//  ARSynthesis
//
//  Created by Pol Piella on 25/03/2018.
//  Copyright © 2018 Pol Piella. All rights reserved.
//

import UIKit
import Onboard

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
        let firstPage = OnboardingContentViewController.content(withTitle: "Welcome To The App!", body: "This app is part of a research project conducted at The University of York, AR Synthesis.", image: UIImage(named: "image1"), buttonText: nil, action: nil)
        
        let secondPage = OnboardingContentViewController.content(withTitle: "Step 1: Structure", body: "First of all, select a node and wait for a horizontal plane to be detected.", image: UIImage(named:"image2"), buttonText: nil, action: nil)
        
        let thirdPage = OnboardingContentViewController.content(withTitle: "Step 2: Connections", body: "Connect oscillator nodes to effects to create the oscillator structure. Do this by simply dragging from one node to the next one.", image: UIImage(named: "image3"), buttonText: nil, action: nil)
        
        let fourthPage = OnboardingContentViewController.content(withTitle: "Step 3: Gestures", body: "1 tap - launch settings, 2 taps - remove node", image: UIImage(named: "image4"), buttonText: nil, action: nil)
        
        let fifthPage = OnboardingContentViewController.content(withTitle: "Step 4: Playing", body: "Add a sequencer or a vertical keyboard to start playing.", image: UIImage(named: "image4"), buttonText: "Proceed to Application", action: self.handleOnboardingCompletion)
        
        
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
