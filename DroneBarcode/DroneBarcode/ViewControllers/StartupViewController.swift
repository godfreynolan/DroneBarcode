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
    weak var appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
    
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var modelLabel: UILabel!
    @IBOutlet weak var openButton: UIButton!
    
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
    
    private func handleConnectionResult(isConnected: Bool) {
        DispatchQueue.main.async {
            if isConnected {
                self.productConnected()
            } else {
                self.productDisconnected()
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    
    private func resetUI() {
        self.title = "Drone Barcode"
        self.statusLabel.text = "Status: Trying to connect..."
        self.modelLabel.text = "Model: Unavailable"
        self.openButton.isEnabled = false
    }
    
    private func productConnected() {
        guard let newProduct = DJISDKManager.product() else {
            let alert = UIAlertController(title: "Error", message: "Product is connected but DJISDKManager.product is nil -> something is wrong", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            print("Product is connected but DJISDKManager.product is nil -> something is wrong")
            return;
        }
        
        self.statusLabel.text = "Status: Connected"
        
        //Updates the product's model
        self.modelLabel.text = "Model: \((newProduct.model)!)"
        self.openButton.isEnabled = true;
        self.openButton.alpha = 1.0;
    }
    
    private func productDisconnected() {
        self.statusLabel.text = "Status: No Product Connected"
        self.modelLabel.text = "Model: Unavailable"
        
        self.openButton.isEnabled = false;
        self.openButton.alpha = 0.8;
    }
}
