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
//        let url = Bundle.main.url(forResource: "2VRひとみ座_9月0日稽古風景2-2K", withExtension: "mp4")
        let vc = PTPlayerViewController.instantiate()
        let list = ListVideo(items: [Video(id: 0, title: "2VRひとみ座_9月0日稽古風景2-2K", duration: "", url: "https://d1lxqoxi2ki8o3.cloudfront.net/video_convert/484/MP4/484_video.mp4"),Video(id: 1, title: "Big Buck Bunny", duration: "", url: "https://d1lxqoxi2ki8o3.cloudfront.net/videos/2VR%E3%81%B2%E3%81%A8%E3%81%BF%E5%BA%A7_9%E6%9C%880%E6%97%A5%E7%A8%BD%E5%8F%A4%E9%A2%A8%E6%99%AF2-4K.mp4")])
//        let list = ListVideo(items: [Video(id: 1, title: "Big Buck Bunny", duration: "", url: "https://multiplatform-f.akamaihd.net/i/multi/will/bunny/big_buck_bunny_,640x360_400,640x360_700,640x360_1000,950x540_1500,.f4v.csmil/master.m3u8")])
        vc.videos = list
        let player = PTPlayer(url: URL(string: list.items[0].url)!)
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
        switch window?.tag ?? 0 {
        case 999:
            return .landscapeRight
        case 99:
            return .all
        default:
            return .portrait
        }
    }
}

