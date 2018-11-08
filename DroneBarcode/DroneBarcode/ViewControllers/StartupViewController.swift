//
//  StartupViewController.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/22/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import UIKit
import DJISDK

class StartupViewController: UIViewController {
    private var appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var openButton: UIButton!
    
    private var down = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.resetUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        guard let connectedKey = DJIProductKey(param: DJIParamConnection) else {
            print("Error creating the connectedKey")
            return;
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            DJISDKManager.keyManager()?.startListeningForChanges(on: connectedKey, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue : DJIKeyedValue?) in
                if newValue != nil {
                    self.handleConnectionResult(isConnected: (newValue?.boolValue)!)
                }
            })
            
            DJISDKManager.keyManager()?.getValueFor(connectedKey, withCompletion: { (value:DJIKeyedValue?, error:Error?) in
                if let unwrappedValue = value {
                    self.handleConnectionResult(isConnected: unwrappedValue.boolValue)
                }
            })
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    
    // Connection UI
    func showDroneConnected() {
        self.setUpCamera()
        
        self.statusLabel.text = "Status: Connected"
        
        self.modelLabel.text = "Model: \((DJISDKManager.product()?.model)!)"
        self.openButton.isEnabled = true;
        self.openButton.alpha = 1.0;
    }
    
    private func resetUI() {
        self.title = "Drone Barcode"
        self.statusLabel.text = "Status: Trying to connect..."
        self.modelLabel.text = "Model: Unavailable"
        self.openButton.isEnabled = false
    }
    
    private func handleConnectionResult(isConnected: Bool) {
        DispatchQueue.main.async {
            if isConnected {
                self.productConnected()
            } else {
                self.productDisconnected()
            }
        }
    }
    
    private func productConnected() {
        guard DJISDKManager.product() != nil else {
            let alert = UIAlertController(title: "Error", message: "Product is connected but cannot be retrieved", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return;
        }
        
        self.statusLabel.text = "Status: Connecting..."
        
        let controller = (DJISDKManager.product() as? DJIAircraft)?.flightController
        
        controller?.setVisionAssistedPositioningEnabled(true, withCompletion: { (error) in
            if error != nil {
                // Handle error
            } else {
                self.showDroneConnected()
            }
        })
    }
    
    private func productDisconnected() {
        self.statusLabel.text = "Status: No Product Connected"
        self.modelLabel.text = "Model: Unavailable"
        
        self.openButton.isEnabled = false;
        self.openButton.alpha = 0.8;
    }
    
    // Camera Settings
    private func setUpCamera() {
        self.fetchCamera()?.setContrast(3, withCompletion: { (error) in
            if (error != nil) {
                let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
    
    private func fetchCamera() -> DJICamera? {
        if (DJISDKManager.product() == nil) {
            return nil
        }
        
        if (DJISDKManager.product() is DJIAircraft) {
            return (DJISDKManager.product() as? DJIAircraft)?.camera
        }
        
        return nil
    }
    
}
