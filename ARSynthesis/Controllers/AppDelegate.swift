//
//  AppDelegate.swift
//  Ikea
//
//  Created by Rayan Slim on 2017-08-18.
//  Copyright © 2017 Rayan Slim. All rights reserved.
//

import UIKit
import Onboard

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        AudioInterfaceHandler.singletonMixer.initialize()
        DebuggerService.singletonDebugger.initialise()
        let defaults = UserDefaults.standard
        let userHasOnboardedOnce = defaults.bool(forKey: "userHasOnboarded")
        print(userHasOnboardedOnce)
        if userHasOnboardedOnce == true{
            self.setupNormalRootViewController()
       } else {
            print("Hello")
            self.window?.rootViewController = AddOnboardingInfoView.viewController.getViewController(with: "intro")
        }
        //let onboardingVC = OnboardingInfoViewController()
        // Override point for customization after application launch.
        return true
    }
    
    
    func setupNormalRootViewController (){
        let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = mainStoryboard.instantiateViewController(withIdentifier: "mainVC") 
        UIApplication.shared.keyWindow?.rootViewController = viewController
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "userHasOnboarded")
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}



