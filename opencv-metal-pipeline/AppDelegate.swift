//
//  AppDelegate.swift
//  opencv-metal-pipeline
//
//  Created by Bartłomiej Nowak on 11.02.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
    ) -> Bool {
        
        let storyboard = UIStoryboard(name: "VideoFeed", bundle: nil)
        let controller = storyboard.instantiateInitialViewController() as! VideoFeedViewController
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = controller
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }
}

