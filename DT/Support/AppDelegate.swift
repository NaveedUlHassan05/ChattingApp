//
//  AppDelegate.swift
//  DT
//
//  Created by Apple on 09/11/2021.
//

import UIKit
import Firebase
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    //MARK:- Firebase Configuration..
    override init() {
        FirebaseApp.configure()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "isFirstTime") == nil {
            defaults.set("No", forKey:"isFirstTime")
            defaults.set("", forKey:"userEmail")
            defaults.set(false, forKey:"isPartialSignup")
            defaults.set(false, forKey:"isCompleteSignup")
        }
        
        setupKeyboard()
        setupInitialVC()
        return true
    }
    
    //MARK:- IQKeyboard Manager attriubtes..
    func setupKeyboard() {
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.enableAutoToolbar = true
        IQKeyboardManager.shared.toolbarTintColor = .lightGray
    }
    
    //MARK:- Setup Initial VC..
    func setupInitialVC() {
        let userdefaults = UserDefaults.standard
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        var initialVC = storyboard.instantiateViewController(identifier: "OnboardingVC")
        if userdefaults.bool(forKey: "isPartialSignup") {
            initialVC = storyboard.instantiateViewController(identifier: "extraSignupVC")
            self.window?.rootViewController = UINavigationController(rootViewController: initialVC)
        }else if userdefaults.bool(forKey: "isCompleteSignup"){
            initialVC = storyboard.instantiateViewController(identifier: "Tabbar")
            self.window?.rootViewController = UINavigationController(rootViewController: initialVC)
        }else {
            self.window?.rootViewController = UINavigationController(rootViewController: initialVC)
        }
        self.window?.makeKeyAndVisible()
    }
    
}

