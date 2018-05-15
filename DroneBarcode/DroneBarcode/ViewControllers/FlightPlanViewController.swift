//
//  FlightPlanViewController.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/23/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import DJISDK
import CoreLocation
import UIKit

class FlightPlanViewController: UIViewController, DJIFlightControllerDelegate, FlightControlCallback {
    let steps = [1, 0]
    var index = 0
    
    func onCommandSuccess() {
        self.fetchCamera()?.startShootPhoto(completion: { (error) in
            if error != nil {
                self.logTextView.text = self.logTextView.text + "\nShoot Photo: " + (error?.localizedDescription)!
            } else {
//                switch self.steps[self.index] {
//                    case 0:
//                        self.flightPlanner.changePitch()
//                        break
//                    case 1:
//                        self.flightPlanner.turn()
//                        break
//                    default:
//                        break
//                }
//
//                self.index += 1
            }
        })
    }
    
    func onError(error: Error?) {
        if error != nil {
            self.logTextView.text = self.logTextView.text + "\nFlight Control: " + (error?.localizedDescription)!
        } else {
            self.logTextView.text = self.logTextView.text + "\nUnknown Error has occured"
        }
    }
    
    private var appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var statusLabel: UILabel!
    
    private var loadingAlert: UIAlertController!
    
    private var flightPlanner: FlightPlanner!
    private var flightController: DJIFlightController?
    
    override func viewWillAppear(_ animated: Bool) {
        DJISDKManager.keyManager()?.startListeningForChanges(on: DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)!, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            if newValue != nil {
                let newLocationValue = newValue!.value as! CLLocation
                
                let altitude = Utils.metersToFeet(newLocationValue.altitude)
                
                self.latitudeLabel.text = String(format:"Lat: %.4f", newLocationValue.coordinate.latitude)
                self.longitudeLabel.text = String(format:"Long: %.4f", newLocationValue.coordinate.longitude)
                self.altitudeLabel.text = String(format:"Alt: %.1f ft", altitude)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.flightController = (DJISDKManager.product() as? DJIAircraft)?.flightController
        
        // Change default measurement systems to make the drone easier to control
        self.flightController?.isVirtualStickAdvancedModeEnabled = true
        self.flightController?.rollPitchControlMode = DJIVirtualStickRollPitchControlMode.velocity
        self.flightController?.yawControlMode = DJIVirtualStickYawControlMode.angle
        self.flightController?.rollPitchCoordinateSystem = DJIVirtualStickFlightCoordinateSystem.body
        self.flightController?.delegate = self
        
        self.flightPlanner = FlightPlanner(flightController: self.flightController!, callback: self)
        
        // Make sure the camera is pointing straight ahead
        DJISDKManager.product()?.gimbal?.rotate(with: DJIGimbalRotation(pitchValue: 0, rollValue: 0, yawValue: 0, time: 1, mode: DJIGimbalRotationMode.absoluteAngle), completion: { (error) in
            if error != nil {
                self.logTextView.text = self.logTextView.text + "\nGimbal: " + (error?.localizedDescription)!
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.missionControl()?.removeListener(self)
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    
    private var firstLoad = false
    
    // DJIFlightControllerDelegate
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        if !self.firstLoad {
            self.firstLoad = true
            self.flightPlanner.setUpParameters(initialYaw: state.attitude.yaw)
            
            var message = ""
            if self.flightController?.yawControlMode == .angle {
                message += "Yaw = Angle, "
            } else {
                message += "Yaw = Angular Velocity, "
            }
            
            if self.flightController?.rollPitchControlMode == .velocity {
                message += "RollPitch = Velocity, "
            } else {
                message += "RollPitch = Angle, "
            }
            
            if self.flightController?.rollPitchCoordinateSystem == .body {
                message += "Coordinate System = Body"
            } else {
                message += "Coordinate System = Ground"
            }
            
            if state.isUltrasonicBeingUsed {
                self.logTextView.text = self.logTextView.text + "\nIsUltrasonicBeingUsed: \(state.isUltrasonicBeingUsed)"
            }
            
            self.logTextView.text = self.logTextView.text + "\nController State: " + message
            self.logTextView.text = self.logTextView.text + "\nController State Info: \(state.attitude.yaw)"
        }
    }
    
    @IBAction func stop(_ sender: Any?) {
        self.flightController?.setVirtualStickModeEnabled(false, withCompletion: nil)
    }
    
    @IBAction func turn(_ sender: Any?) {
        self.flightPlanner.turn()
    }
    
    @IBAction func increasePitch(_ sender: Any?) {
        self.flightPlanner.changePitch()
    }
    
    @IBAction func startFlight(_ sender: Any?) {
        self.flightController?.setVirtualStickModeEnabled(true, withCompletion: { (error) in
            if error != nil {
                self.logTextView.text = self.logTextView.text + "\nVSME: " + (error?.localizedDescription)!
            } else {
                self.flightController?.startTakeoff(completion: { (error) in
                    if error != nil {
                        self.logTextView.text = self.logTextView.text + "\nST: " + (error?.localizedDescription)!
                    } else {
                        self.firstLoad = false
                        
//                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 10, execute: {
//                            self.onCommandSuccess()
//                        })
                    }
                })
            }
        })
    }
    
    //MARK: - Helpers
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
