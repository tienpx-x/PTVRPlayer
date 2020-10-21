//
//  AppDelegate.swift
//  PTVRPlayer
//
//  Created by tienpx-1643 on 10/21/2020.
//  Copyright (c) 2020 tienpx-1643. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = UIViewController()
        window?.makeKeyAndVisible()
//        let url = URL(string: "https://www.w3schools.com/html/mov_bbb.mp4");
        let url = Bundle.main.url(forResource: "2VRひとみ座_9月0日稽古風景2-2K", withExtension: "mp4")
        let player = PTPlayer(url: url!)
        let vc = PTPlayerViewController.instantiate()
        vc.modalPresentationStyle = .fullScreen
        vc.player = player
        let rootVC = UIViewController()
        let nav = UINavigationController(rootViewController: rootVC)
        nav.navigationBar.isHidden = true
        window?.rootViewController = nav
        nav.pushViewController(vc, animated: true)
        return true
    }
    
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return .all
    }
}

