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
    private var left: Float = 0.0
    private var right: Float = 0.0
    private var back: Float = 0.0
    private var forward: Float = 0.0
    private var up: Float = 0.0
    private var down: Float = 0.0
    
    @IBOutlet weak var labelForward: UILabel!
    @IBOutlet weak var labelBack: UILabel!
    @IBOutlet weak var labelLeft: UILabel!
    @IBOutlet weak var labelRight: UILabel!
    @IBOutlet weak var labelUp: UILabel!
    @IBOutlet weak var labelDown: UILabel!
    
    @IBOutlet weak var forwardSlider: UISlider!
    @IBOutlet weak var backSlider: UISlider!
    @IBOutlet weak var leftSlider: UISlider!
    @IBOutlet weak var rightSlider: UISlider!
    @IBOutlet weak var upSlider: UISlider!
    @IBOutlet weak var downSlider: UISlider!
    
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
    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var yawLabel: UILabel!
    @IBOutlet weak var rollLabel: UILabel!
    
    private var loadingAlert: UIAlertController!
    
    private var flightPlanner: FlightPlanner!
    private var flightController: DJIFlightController?
    
    override func viewWillAppear(_ animated: Bool) {
        // Location changes (Lat/Lng + Altitude)
        DJISDKManager.keyManager()?.startListeningForChanges(on: DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)!, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            if newValue != nil {
                let newLocationValue = newValue!.value as! CLLocation
                let altitude = Utils.metersToFeet(newLocationValue.altitude)
                
                self.latitudeLabel.text = String(format:"Lat: %.4f", newLocationValue.coordinate.latitude)
                self.longitudeLabel.text = String(format:"Long: %.4f", newLocationValue.coordinate.longitude)
                self.altitudeLabel.text = String(format:"Alt: %.1f ft", altitude)
            }
        }
        
        // Attitude changes (RPY)
        DJISDKManager.keyManager()?.startListeningForChanges(on: DJIFlightControllerKey(param: DJIFlightControllerParamAttitude)!, withListener: self, andUpdate: { (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
                if newValue != nil {
                let attitude = newValue!.value as! DJISDKVector3D
                self.pitchLabel.text = String(format:"Pitch: %.2f", attitude.y)
                self.yawLabel.text = String(format:"Yaw: %.2f", attitude.z)
                self.rollLabel.text = String(format:"Roll: %.2f", attitude.x)
            }
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.flightController = (DJISDKManager.product() as? DJIAircraft)?.flightController
        
        // Change default measurement systems to make the drone easier to control
        self.flightController?.isVirtualStickAdvancedModeEnabled = true
        self.flightController?.rollPitchControlMode = DJIVirtualStickRollPitchControlMode.velocity
        self.flightController?.yawControlMode = DJIVirtualStickYawControlMode.angle
        self.flightController?.rollPitchCoordinateSystem = DJIVirtualStickFlightCoordinateSystem.ground
        self.flightController?.delegate = self
        
        // Enable collision avoidance (not all models)
        self.flightController?.flightAssistant?.setCollisionAvoidanceEnabled(true, withCompletion: {(err) in
            if err == nil {
                self.logTextView.text = self.logTextView.text + "\nSet collision avoidance."
            } else {
                self.logTextView.text = self.logTextView.text + "\nCould not set collision avoidance: " + err!.localizedDescription
            }
        })
        
        // Enable upwards avoidance
        self.flightController?.flightAssistant?.setUpwardsAvoidanceEnabled(true, withCompletion: {(err) in
            if err == nil {
                self.logTextView.text = self.logTextView.text + "\nSet upwards avoidance."
            } else {
                self.logTextView.text = self.logTextView.text + "\nCould not set upwards avoidance: " + err!.localizedDescription
            }
        })
        
        // Enable vision positioning
        self.flightController?.setVisionAssistedPositioningEnabled(true, withCompletion: { (err) in
            if err == nil {
                self.logTextView.text = self.logTextView.text + "\nSet vision assisted positioning."
            } else {
                self.logTextView.text = self.logTextView.text + "\nCould not set vision assisted positioning: " + err!.localizedDescription
            }
        })

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
    
    
    //MARK: Buttons
    @IBAction func rightBtnClick(_ sender: Any) {
        self.flightPlanner.rightShort(value: self.right, callback: {(msg) in
            DispatchQueue.main.async {
                self.logTextView.text = self.logTextView.text + "\n" + msg
            }
        })
    }
    
    @IBAction func leftBtnClick(_ sender: Any) {
        self.flightPlanner.leftShort(value: self.left, callback: {(msg) in
            DispatchQueue.main.async {
                self.logTextView.text = self.logTextView.text + "\n" + msg
            }
        })
    }
    
    @IBAction func forwardBtnClick(_ sender: Any) {
        self.flightPlanner.forwardShort(value: self.forward, callback: {(msg) in
            DispatchQueue.main.async {
                self.logTextView.text = self.logTextView.text + "\n" + msg
            }
        })
    }
    
    @IBAction func backBtnClick(_ sender: Any) {
        self.flightPlanner.backwardShort(value: self.back, callback: {(msg) in
            DispatchQueue.main.async {
                self.logTextView.text = self.logTextView.text + "\n" + msg
            }
        })
    }
    
    @IBAction func upClicked(_ sender: Any) {
        self.flightPlanner.up(value: self.up, callback: { (msg) in
            DispatchQueue.main.async {
                self.logTextView.text = self.logTextView.text + "\n" + msg
            }
        })
    }
    
    @IBAction func downClicked(_ sender: Any) {
        self.flightPlanner.down(value: self.down, callback: { (msg) in
            DispatchQueue.main.async {
                self.logTextView.text = self.logTextView.text + "\n" + msg
            }
        })
    }
    
    
    //MARK: Sliders
    @IBAction func sliderForward(_ sender: Any) {
        self.forward = forwardSlider.value
        self.labelForward.text = String(format: "F: %2.2f", self.forward)
    }
    
    @IBAction func sliderBack(_ sender: Any) {
        self.back = backSlider.value
        self.labelBack.text = String(format: "B: %2.2f", self.back)
    }
    
    @IBAction func sliderLeft(_ sender: Any) {
        self.left = leftSlider.value
        self.labelLeft.text = String(format: "L: %2.2f", self.left)
    }
    
    @IBAction func sliderRight(_ sender: Any) {
        self.right = rightSlider.value
        self.labelRight.text = String(format: "R: %2.2f", self.right)
    }
    
    @IBAction func sliderUp(_ sender: Any) {
        self.up = upSlider.value
        self.labelUp.text = String(format: "U: %2.2f", self.up)
    }
    
    @IBAction func sliderDown(_ sender: Any) {
        self.down = downSlider.value
        self.labelDown.text = String(format: "D: %2.2f", self.down)
    }
}
