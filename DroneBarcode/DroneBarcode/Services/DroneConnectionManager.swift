//
//  DroneConnectionManager.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/22/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import DJISDK

class DroneConnectionManager: NSObject, DJISDKManagerDelegate {
    func registerWithSDK() {
        let appKey = Bundle.main.object(forInfoDictionaryKey: SDK_APP_KEY_INFO_PLIST_KEY) as? String
        
        guard appKey != nil && appKey!.isEmpty == false else {
            print("Please enter your app key in the info.plist")
            return
        }
        
        DJISDKManager.registerApp(with: self)
    }
    
    func productConnected(_ product: DJIBaseProduct?) {
        
    }
    
    func productDisconnected() {
        
    }
    
    func appRegisteredWithError(_ error: Error?) {
        print("SDK Registered with error \(error?.localizedDescription ?? "None")")
        
        DJISDKManager.startConnectionToProduct()
    }
}
