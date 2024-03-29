import DJISDK
import DJIWidget
import CoreLocation
import UIKit

class FlightPlanViewController: UIViewController, DJIGimbalDelegate, DJIFlightControllerDelegate, FlightControlCallback, DJIRemoteControllerDelegate, DJIVideoFeedListener {
    let steps = [1, 0]
    var index = 0
    private var left: Float = 0.0
    private var right: Float = 0.0
    private var back: Float = 0.0
    private var forward: Float = 0.0
    private var up: Float = 0.0
    private var down: Float = 0.0
    private var lastYaw: Float = 0.0
    private var recorder: FlightRecorder = FlightRecorder()
    private var gimbal: DJIGimbal?
    
    private var appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
    
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var altitudeLabel: UILabel!
    @IBOutlet weak var logTextView: UITextView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var pitchLabel: UILabel!
    @IBOutlet weak var yawLabel: UILabel!
    @IBOutlet weak var rollLabel: UILabel!
    @IBOutlet weak var cameraView: UIView!
    
    private var loadingAlert: UIAlertController!
    
    private var flightPlanner: FlightPlanner!
    private var flightController: DJIFlightController?
    
    override func viewWillAppear(_ animated: Bool) {
        // Location changes (Lat/Lng + Altitude)
        DJISDKManager.keyManager()?.startListeningForChanges(on: DJIFlightControllerKey(param: DJIFlightControllerParamAircraftLocation)!, withListener: self) { [unowned self] (oldValue: DJIKeyedValue?, newValue: DJIKeyedValue?) in
            if newValue != nil {
                let newLocationValue = newValue!.value as! CLLocation
                self.latitudeLabel.text = String(format: "Lat: %.4f", newLocationValue.coordinate.latitude)
                self.longitudeLabel.text = String(format: "Long: %.4f", newLocationValue.coordinate.longitude)
            }
        }
        
        // Get stick updates.
        (DJISDKManager.product() as! DJIAircraft).remoteController?.delegate = self
        (DJISDKManager.product() as! DJIAircraft).gimbal?.delegate = self
        
        setupVideoPreviewer()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.logTextView.layoutManager.allowsNonContiguousLayout = false //needed for auto scrolling to bottom
        self.flightController = (DJISDKManager.product() as? DJIAircraft)?.flightController
        self.gimbal = (DJISDKManager.product() as? DJIAircraft)?.gimbal
        
        // Change default measurement systems to make the drone easier to control
        self.flightController?.isVirtualStickAdvancedModeEnabled = true
        self.flightController?.rollPitchControlMode = .velocity
        self.flightController?.yawControlMode = .angle
        self.flightController?.verticalControlMode = .velocity
        self.flightController?.rollPitchCoordinateSystem = DJIVirtualStickFlightCoordinateSystem.ground
        self.flightController?.delegate = self
        
        // Enable collision avoidance (not all models)
        self.flightController?.flightAssistant?.setCollisionAvoidanceEnabled(false, withCompletion: {(err) in
            if err == nil {
                self.logTV(text: "Disabled collision avoidance.")
            } else {
                self.logTV(text: "Could not set collision avoidance: " + err!.localizedDescription)
            }
        })
        
        // Enable upwards avoidance
        self.flightController?.flightAssistant?.setUpwardsAvoidanceEnabled(true, withCompletion: {(err) in
            if err == nil {
                self.logTV(text: "Set upwards avoidance.")
            } else {
                self.logTV(text: "Could not set upwards avoidance: " + err!.localizedDescription)
            }
        })
        
        // Enable vision positioning
        self.flightController?.setVisionAssistedPositioningEnabled(true, withCompletion: { (err) in
            if err == nil {
                self.logTV(text: "Set vision assisted positioning.")
            } else {
                self.logTV(text: "Could not set vision assisted positioning: " + err!.localizedDescription)
            }
        })
        
        self.flightPlanner = FlightPlanner(flightController: self.flightController!, callback: self)
        
        // Make sure the camera is pointing straight ahead
        DJISDKManager.product()?.gimbal?.rotate(with: DJIGimbalRotation(pitchValue: 0, rollValue: 0, yawValue: 0, time: 1, mode: DJIGimbalRotationMode.relativeAngle), completion: { (error) in
            if error != nil {
                self.logTV(text: "Gimbal: " + (error?.localizedDescription)!)
            }
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        DJISDKManager.missionControl()?.removeListener(self)
        DJISDKManager.keyManager()?.stopAllListening(ofListeners: self)
    }
    
    //sets logTextView text and auto scrolls to bottom
    func logTV(text: String){
        //Insert text
        logTextView.text.append("\n"+text)
        let btm = NSMakeRange(logTextView.text.count-1, 0)
        logTextView.scrollRangeToVisible(btm)
    }
    
    private var firstLoad = false
    
    // DJIFlightControllerDelegate
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        
        self.pitchLabel.text = String(format: "Pitch: %.2f", state.attitude.pitch)
        self.yawLabel.text = String(format: "Yaw: %.2f", state.attitude.yaw)
        self.rollLabel.text = String(format: "Roll: %.2f", state.attitude.roll)
        self.altitudeLabel.text = String(format: "Altitude: %.2f", state.altitude)
        self.lastYaw = Float(state.attitude.yaw)
        
        recorder.addAttitudeAltitudeMeasurement(pitch: state.velocityY, yaw: Float(state.attitude.yaw), roll: state.velocityX, altitude: Float(state.velocityZ))
        
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
                self.logTV(text : "IsUltrasonicBeingUsed: \(state.isUltrasonicBeingUsed)")
            }
            
            self.logTV(text: "Controller State: " + message)
            self.logTV(text: "Controller State Info: \(state.attitude.yaw)")
        }
    }
    
    @IBAction func stop(_ sender: Any?) {
        self.flightController?.setVirtualStickModeEnabled(false, withCompletion: nil)
    }
    
    @IBAction func turn(_ sender: Any?) {
        self.flightController?.setVirtualStickModeEnabled(true, withCompletion: { (error) in
            if error != nil {
                self.logTV(text: "VSME: " + (error?.localizedDescription)!)
            } else {
                self.logTV(text: "Set virtual stick mode. Disabling collision avoidance...")
                self.flightController?.flightAssistant?.setCollisionAvoidanceEnabled(false, withCompletion: { (error) in
                    if error != nil {
                        self.logTV(text: "Collision Avoidance couldn't be disabled.")
                    } else {
                        self.logTV(text: "Collision Avoidance disabled.")
                    }
                })
            }
        })
    }
    
    @IBAction func increasePitch(_ sender: Any?) {
        self.flightPlanner.changePitch()
    }
    
    @IBAction func startFlight(_ sender: Any?) {
        self.recorder.startMeasurements()
        logTV(text: "Recording...")
    }
    
    //MARK: - Helpers
    private func fetchCamera() -> DJICamera? {
        if (DJISDKManager.product() == nil) { return nil }
        if (DJISDKManager.product() is DJIAircraft) { return (DJISDKManager.product() as? DJIAircraft)?.camera }
        return nil
    }
    
    
    //MARK: Buttons
    @IBAction func rightBtnClick(_ sender: Any) {
        
        let caps = self.gimbal!.capabilities
        for (key, value) in caps {
            if value is DJIParamCapabilityMinMax {
                self.logTV(text: "\(key): \((value as! DJIParamCapabilityMinMax).min), \((value as! DJIParamCapabilityMinMax).max)")
            }
        }
    }
    
    @IBAction func leftBtnClick(_ sender: Any) {
        (DJISDKManager.product() as! DJIAircraft).gimbal!.startCalibration { (err) in
            if err != nil {
                self.logTV(text: "Calibrated camera gimbal.")
            } else {
                self.logTV(text: "Could not calibrate gimbal.")
            }
        }
    }
    
    @IBAction func forwardBtnClick(_ sender: Any) {
        self.cameraView.isHidden = false
        self.flightController?.setVirtualStickModeEnabled(true, withCompletion: { (error) in
            if error != nil {
                self.logTV(text: "VSME: " + (error?.localizedDescription)!)
            } else {
                self.flightController?.startTakeoff(completion: { (error) in
                    if error != nil {
                        self.logTV(text: "ST: " + (error?.localizedDescription)!)
                    } else {
                        self.firstLoad = false
                    }
                })
            }
        })
    }
    
    @IBAction func backBtnClick(_ sender: Any) {
        DispatchQueue.main.async {
            self.flightPlanner.saveTimes()
            self.logTV(text: "Saved times to file.")
        }
    }
    
    @IBAction func upClicked(_ sender: Any) {
        self.logTV(text: "Adding commands to replayer")
        let replayer = FlightReplayer(commands: recorder.getMeasurements())
        self.logTV(text: "Executing " + String(recorder.getMeasurements().count) + " commands.")
        self.recorder.resetMeasurements()
        self.recorder.startMeasurements()
        replayer.executeCommandQueue(controller: self.flightController!, cameraGimbal: self.gimbal!, callback: {() in
            DispatchQueue.main.async {
                self.recorder.finalizeMeasurements()
                self.logTV(text: "Flight replay complete. Saving to flightplan-autonomous.csv")
                self.recorder.saveFile(with: "flightplan-autonomous.csv")
            }
        })
    }
    
    @IBAction func downClicked(_ sender: Any) {
        self.logTV(text: "Finalizing measurements...")
        recorder.finalizeMeasurements()
        recorder.saveFile(with: "flightplan-human.csv")
        self.logTV(text: "Saved measurements to file.")
    }
    
    func setupVideoPreviewer() {
        DJIVideoPreviewer.instance()?.setView(self.cameraView)
        DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
        DJIVideoPreviewer.instance()?.start()
    }
    
    func resetVideoPreviewer() {
        DJIVideoPreviewer.instance()?.unSetView()
        DJISDKManager.videoFeeder()?.primaryVideoFeed.remove(self)
    }
    
    //MARK: GIMBAL UPDATES
    func gimbal(_ gimbal: DJIGimbal, didUpdate state: DJIGimbalState) {
        let pitch = state.attitudeInDegrees.pitch
        let roll = state.attitudeInDegrees.roll
        let yaw = state.attitudeInDegrees.yaw - self.lastYaw
        self.recorder.addCameraMeasurement(pitch: pitch, yaw: yaw, roll: roll)
    }
    
    //MARK: STICK UPDATES
    func remoteController(_ rc: DJIRemoteController, didUpdate state: DJIRCHardwareState) {
        let left_h = Float(state.leftStick.horizontalPosition)
        let left_v = Float(state.leftStick.verticalPosition)
        let right_h = Float(state.rightStick.horizontalPosition)
        let right_v = Float(state.rightStick.verticalPosition)
        
        recorder.addJoystickMeasurement(left_h, left_v, right_h, right_v)
    }
    
    func onCommandSuccess() {
        self.fetchCamera()?.startShootPhoto(completion: { (error) in
            if error != nil {
                self.logTV(text: "Shoot Photo: " + (error?.localizedDescription)!)
            }
        })
    }
    
    func onError(error: Error?) {
        if error != nil {
            self.logTV(text: "Flight Control: " + (error?.localizedDescription)!)
        } else {
            self.logTV(text: "Unknown Error has occured")
        }
    }
    
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
        let videoData = videoData as NSData
        let videoBuffer = UnsafeMutablePointer<UInt8>.allocate(capacity: videoData.length)
        videoData.getBytes(videoBuffer, length: videoData.length)
        DJIVideoPreviewer.instance()?.push(videoBuffer, length: Int32(videoData.length))
    }
}
