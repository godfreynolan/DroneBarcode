//
//  ScanSampleViewController.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/22/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import DJISDK
import UIKit
import VideoPreviewer

class ScanSampleViewController: UIViewController, DJIFlightControllerDelegate,  DJIVideoFeedListener, BarcodeScanCallback, PositionMonitorDelegate, DJIGimbalDelegate, DJIFlightAssistantDelegate {

    private var barcodeScanner: BarcodeScanner!
    private var positionMonitor: PositionMonitor? = nil
    private var recorder: LeggedFlightRecorder!
    private var replayer: FlightReplayer?
    private let fc = (DJISDKManager.product() as! DJIAircraft).flightController
    private let gimbal = (DJISDKManager.product() as! DJIAircraft).gimbal!
    private var legs: [[FlightRecorder.Measurement]] = []

    @IBOutlet weak var labelWinner: UILabel!
    @IBOutlet weak var labelSliderVal: UILabel!
    private var scanningAlert: UIAlertController!
    
    // Timer that handles periodically pulling frames from the screen and detecting barcodes in those frames.
    private var scanningTimer: Timer!
    private var allowPositioning: Bool = false
    // Holds the most recently retrieved value of the aircraft's yaw (from FlightControllerDelegate)
    // Used for positioning the gimbal relatively with a reasonable degree of accuracy during flight replay.
    private var lastYaw: Float = 0
    
    // Controls the severity of the drones automatic alignment adjustments
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var videoPreviewerView: UIView!
    // This is the view that draws both the QR rectangle and the target
    @IBOutlet weak var rectDrawView: RectDrawView!
    // Positioning on the ground vs. the wall.
    @IBOutlet weak var switchWallMode: UISwitch!
    // Image view that contains a wind severity indicator
    @IBOutlet weak var ivWind: UIImageView!
    @IBOutlet weak var recordLeg: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.barcodeScanner = BarcodeScanner(callback: self)
        rectDrawView.addTarget()
        self.recorder = LeggedFlightRecorder()
        (DJISDKManager.product() as! DJIAircraft).gimbal?.delegate = self
        self.setUpVideoPreview()
        
        ///MARK: Flight Controller Configuration
        self.fc?.setVirtualStickModeEnabled(true, withCompletion: nil)
        // Turn this off so the drone doesn't try to prevent itself hitting walls and things.
        self.fc?.flightAssistant?.setCollisionAvoidanceEnabled(false, withCompletion: nil)
        // Replace GPS with vision assisted positioning
        self.fc?.setVisionAssistedPositioningEnabled(true, withCompletion: nil)
        // Control modes:
        self.fc?.yawControlMode = .angle // this changes several times later.
        self.fc?.rollPitchControlMode = .velocity
        self.fc?.verticalControlMode = .velocity
        // use coordinate system relative to the ground rather than the aircraft itself.
        // This keeps things the same every time instead of varying based on aircraft position
        self.fc?.rollPitchCoordinateSystem = DJIVirtualStickFlightCoordinateSystem.ground
        self.fc?.isVirtualStickAdvancedModeEnabled = true
        
        self.positionMonitor = PositionMonitor(qr: CGRect(x:0, y:0, width:0, height:0), target: rectDrawView.getTargetRect(), flightController: fc!)
        
        // Get updates from the position monitor, flight controller, and assistant
        self.fc?.delegate = self
        self.fc?.flightAssistant?.delegate = self
        self.positionMonitor!.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if self.scanningTimer.isValid {
            self.scanningTimer.invalidate()
        }
    }
    
    // Obtains an image from the video preview that can be sent to the barcode scanner
    @objc func takePhoto() {
        let renderer = UIGraphicsImageRenderer(size: self.videoPreviewerView.bounds.size)
        let capturedImage = renderer.image { ctx in
            self.videoPreviewerView.drawHierarchy(in: self.videoPreviewerView.bounds, afterScreenUpdates: true)
        }
        
        self.barcodeScanner.scanForBarcode(image: capturedImage)
    }
    
    // From BarcodeScanCallback
    func onError(error: Error?) {}
    
    // From BarcodeScanCallback
    func onScanSuccess(rect: CGRect, color: UIColor) {
        positionMonitor?.updateQRPosition(rect)
        rectDrawView.addRectangle(rect: rect, color: color)
    }

    func positionMonitorStatusUpdated(_ qrIsTargeted: Bool) {
        // Update the UI
        self.rectDrawView.setShouldBeGreenTarget(qrIsTargeted)
    }
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        self.labelSliderVal.text = "\(slider.value)"
    }
    
    // From PositionMonitor
    func directionHelper(_ directions: [Direction]) {
        // Correct the directions depending on if its in wall or floor mode
        var correct_directions: [Direction] = []
        for direction in directions {
            correct_directions.append(switchWallMode.isOn ? PositionUtil.translateFloorDirectionToWall(direction) : direction)
        }
        
        // Draw the arrows on screen
        self.rectDrawView.setHelperArrows(correct_directions)
        
        // Make commands from the arrows and execute them in series
        if directions.count > 0 {
            let command = PositionUtil.translateDirectionToCommand(correct_directions[0], isOnWall: false, verticalSpeed: 0.05, horizontalSpeed: slider.value)
            fc?.send(command, withCompletion: nil)
            usleep(100000) // 100ms
        }
    }
    
    // Records position data on the aircraft 10 times a second (and wind severity)
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        // Record the aircraft position and save the yaw (for gimbal updates)
        self.lastYaw = Float(state.attitude.yaw)
        if recorder.isRecording() {
            recorder.addAttitudeMeasurement(pitch: state.velocityY, yaw: Float(state.attitude.yaw), roll: state.velocityX, vs: Float(state.velocityZ))
        }

        // Select the correct wind warning image.
        switch state.windWarning {
        case .level0:
            self.ivWind.image = UIImage(named: "wind-light")
            break
        case .level1:
            self.ivWind.image = UIImage(named: "wind-moderate")
            break
        case .level2:
            self.ivWind.image = UIImage(named: "wind-heavy")
            break
        case .unknown:
            self.ivWind.image = nil
            break
        }
    }
    
    // Records gimbal position several times per second.
    func gimbal(_ gimbal: DJIGimbal, didUpdate state: DJIGimbalState) {
        let pitch = state.attitudeInDegrees.pitch
        let roll = state.attitudeInDegrees.roll
        // Calculate relative to last known aircraft yaw- prevents camera from
        // wildly moving to one side instead of staying in line with the drone.
        let yaw = state.attitudeInDegrees.yaw - self.lastYaw
        self.recorder.addCameraMeasurement(pitch: pitch, yaw: yaw, roll: roll)
    }
    
    @IBAction func recordLegPressed(_ sender: Any) {
        if self.recorder!.isRecording() {
            self.fc?.setVirtualStickModeEnabled(true, withCompletion: { (err) in
                self.recorder.finishRecordingLeg()
                self.fc?.yawControlMode = .angularVelocity
                self.positionMonitor?.startRecentering(withCompletion: {() in
                    self.positionMonitor?.stopRecentering()
                })
                self.recordLeg!.setTitle("Record Leg", for: .normal)
            })
        } else {
            self.fc?.setVirtualStickModeEnabled(false, withCompletion: { (err) in
                self.positionMonitor?.stopRecentering()
                self.recorder.startRecordingLeg()
                self.recordLeg!.setTitle("Finish Leg", for: .normal)
            })
        }
    }

    @IBAction func takeOff(_ sender: Any) {
        self.fc?.startTakeoff(completion: nil)
    }
    
    // this actually stops positioning
    @IBAction func stopPositioning(_ sender: Any) {
        self.positionMonitor?.stopRecentering()
        self.fc?.setVirtualStickModeEnabled(false, withCompletion: nil)
    }
    
    @IBAction func playbackBtn(_ sender: Any) {
        self.fc?.setVirtualStickModeEnabled(true, withCompletion: {(err) in
            usleep(200000)
            self.legs = self.recorder.getLegs()
            self.positionMonitor?.startRecentering(withCompletion:{ () in
                self.positionMonitor?.stopRecentering()
                self.executeNextLeg()
            })
        })
    }
    
    private func executeNextLeg() {
        // make sure that we are "not targeted" so that it guarantees we wont
        // be automatically targeted when we get to the other code and its not detected immediately.
        self.positionMonitor?.resetTargeting()
        
        // Remove the leg that should come next and add it to a replayer
        let leg = self.legs.removeFirst()
        self.replayer = FlightReplayer(commands: leg)
        // Set the mode for replaying human inputs and execute it.
        self.fc?.yawControlMode = .angle
        self.replayer?.executeCommandQueue(controller: self.fc!, cameraGimbal: self.gimbal, callback: {
            // Check if theres more legs. If not, center again and land
            if self.legs.count > 0 {
                DispatchQueue.main.async {
                    // Set the mode for automatic positioning, and recenter before the next leg.
                    self.fc?.yawControlMode = .angularVelocity
                    self.positionMonitor?.startRecentering(withCompletion: {() in
                        self.positionMonitor?.stopRecentering()
                        self.executeNextLeg()
                    })
                }
            } else {
                self.positionMonitor?.startRecentering {
                    self.positionMonitor?.stopRecentering()
                    self.fc?.startLanding(completion: { (err) in
                        self.fc?.confirmLanding(completion: nil)
                    })
                }
                self.fc?.setVirtualStickModeEnabled(false, withCompletion: nil)
            }
        })
        
    }
    
    // Gets video from the drone camera
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
        videoData.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) -> Void in
            let rawPtr = UnsafeMutablePointer(mutating: bytes)
            VideoPreviewer.instance().push(rawPtr, length: Int32(videoData.count))
        })
    }
    
    // Initializes the video preview
    private func setUpVideoPreview() {
        VideoPreviewer.instance().setView(self.videoPreviewerView)
            VideoPreviewer.instance().enableHardwareDecode = true
        
        let product = DJISDKManager.product()
        if ((product?.model?.isEqual(DJIAircraftModelNameA3))! || (product?.model?.isEqual(DJIAircraftModelNameN3))! ||
            (product?.model?.isEqual(DJIAircraftModelNameMatrice600))! || (product?.model?.isEqual(DJIAircraftModelNameMatrice600Pro))!) {
            DJISDKManager.videoFeeder()?.secondaryVideoFeed.add(self, with: nil)
        } else {
            DJISDKManager.videoFeeder()?.primaryVideoFeed.add(self, with: nil)
        }
        
        VideoPreviewer.instance().start()
        self.scanningTimer = Timer.scheduledTimer(timeInterval: 0.3, target: self, selector: (#selector(takePhoto)), userInfo: nil, repeats: true)
    }
    
    // Resets the video preview.
    private func resetVideoPreview() {
        VideoPreviewer.instance().unSetView()
        
        let product = DJISDKManager.product()
        if ((product?.model?.isEqual(DJIAircraftModelNameA3))! || (product?.model?.isEqual(DJIAircraftModelNameN3))! ||
            (product?.model?.isEqual(DJIAircraftModelNameMatrice600))! || (product?.model?.isEqual(DJIAircraftModelNameMatrice600Pro))!) {
            DJISDKManager.videoFeeder()?.secondaryVideoFeed.remove(self)
        } else {
            DJISDKManager.videoFeeder()?.primaryVideoFeed.remove(self)
        }
        
        if self.scanningTimer.isValid {
            self.scanningTimer.invalidate()
        }
    }
    
    func flightAssistant(_ assistant: DJIFlightAssistant, didUpdate state: DJIVisionDetectionState) {
        // TODO: Handle vision state and obstacle detection
    }
}
