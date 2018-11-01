//
//  AppDelegate.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/21/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import UIKit
import Firebase
import ScanditBarcodeScanner

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private let APP_KEY = "AclceybBOrb/Dx8+gDEcWhARENDRBdFqcFAW9zNenGu6ZP542mg5gtcx8DLXQnwkfkWVBjN5tWfkWuPquWYae6JOddHkYcMwMRdZ4sltlotSTClDoC2JwUANEP4nNSd6FNMlTODtElIYdkbiSP5GG0pPO3839JEJejQImmsiggeaqmqWBBu9u/19oUK+WC4BGnuy70aWfplWs2E0ATusfgA8fKe3WzEHPi7UXvyhnGFH4VjemXjj0w+yq8/PezIco0PiKtTIpZIpL2d0Cc5RRdwDymizpcefNY3NFJxsnTyB3RTz2Q6OEzKRgJUmFzFAlVwtaY20Q7ZRcXfvk2jBOufNd3q5h2w0pktI7MtoHF8V6ywgrTcmeNC7J/E3667QGYlSa5H/NDGPMDwwFZCom0Ms6Mz/AX6vTIaNiLeEY+9FsTQ397YvACros4L04EHTbCw95E7UEQ8vo33AFrdSrIlTg8FLwvF3TF8OCVyU3UOswwvsJ4IftJvHIkS6xtsk3GJ09DsIxAGdEirrbAc6FBT7G2n/JoC7I7tmxxI+UkE62pcQ+0mSgejWayOlpUVAn1yZEPgoSsvaGpiBjlzMnDb+59TzTWPKdLqyivws/8Bmve/1BMR7cxOPUOKhCX/gwUOB362Pwlxml8K0+fxZMf2YmthhPVXOJMjO3noaJT+rICw9JPkJBw6McaExZ+2h3am0dzWH3Bc+qedT4FDtqJHZbwkRzBPz6czjJFEDoSEpYxwnbZpGdX3NsFp59OfEhJ+vMdOp9C+uLDjvshxKWCv57ee7+g+RsDWDw+Uulw=="

    private let droneConnectionManager = DroneConnectionManager()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        self.droneConnectionManager.registerWithSDK()
        UIApplication.shared.isIdleTimerDisabled = true
        SBSLicense.setAppKey(APP_KEY)
        FirebaseApp.configure()
        
        return true
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

