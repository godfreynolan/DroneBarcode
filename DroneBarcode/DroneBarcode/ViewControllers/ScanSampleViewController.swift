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
    //private var recorder: FlightRecorder!
    private var recorder: LeggedFlightRecorder!
    private var replayer: FlightReplayer?
    private let fc = (DJISDKManager.product() as! DJIAircraft).flightController
    private let gimbal = (DJISDKManager.product() as! DJIAircraft).gimbal!
    private var legs: [[FlightRecorder.Measurement]] = []

    @IBOutlet weak var labelWinner: UILabel!
    @IBOutlet weak var labelSliderVal: UILabel!
    private var scanningAlert: UIAlertController!
    
    private var scanningTimer: Timer!
    
    private var shouldWait: Bool = false
    private var allowPositioning: Bool = false
    private var lastYaw: Float = 0
    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var videoPreviewerView: UIView!
    @IBOutlet weak var rectDrawView: RectDrawView!
    @IBOutlet weak var switchWallMode: UISwitch!
    @IBOutlet weak var ivWind: UIImageView!
    @IBOutlet weak var recordLeg: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.barcodeScanner = BarcodeScanner(callback: self)
        rectDrawView.addTarget()
        self.recorder = LeggedFlightRecorder()
        (DJISDKManager.product() as! DJIAircraft).gimbal?.delegate = self
        self.setUpVideoPreview()
        
        self.fc?.setVirtualStickModeEnabled(true, withCompletion: nil)
        self.fc?.flightAssistant?.setCollisionAvoidanceEnabled(false, withCompletion: nil)
        self.fc?.setVisionAssistedPositioningEnabled(true, withCompletion: nil)
        self.fc?.yawControlMode = .angle
        self.fc?.rollPitchControlMode = .velocity
        self.fc?.verticalControlMode = .velocity
        self.fc?.rollPitchCoordinateSystem = DJIVirtualStickFlightCoordinateSystem.ground
        self.fc?.isVirtualStickAdvancedModeEnabled = true
        self.fc?.delegate = self

        self.fc?.flightAssistant?.delegate = self

        self.positionMonitor = PositionMonitor(qr: CGRect(x:0, y:0, width:0, height:0), target: rectDrawView.getTargetRect(), flightController: fc!)
        self.positionMonitor!.delegate = self
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if self.scanningTimer.isValid {
            self.scanningTimer.invalidate()
        }
    }
    
    @objc func takePhoto() {
        let renderer = UIGraphicsImageRenderer(size: self.videoPreviewerView.bounds.size)
        let capturedImage = renderer.image { ctx in
            self.videoPreviewerView.drawHierarchy(in: self.videoPreviewerView.bounds, afterScreenUpdates: true)
        }
        
        self.barcodeScanner.scanForBarcode(image: capturedImage)
    }
    
    func onError(error: Error?) {}
    
    func onScanSuccess(barcodeData: String) {
        if barcodeData.isEmpty {
            return
        }
        self.labelWinner!.text = barcodeData
    }
    
    func scanSuccess(rect: CGRect, color: UIColor) {
        positionMonitor?.updateQRPosition(rect)
        rectDrawView.addRectangle(rect: rect, color: color)
    }
    

    func positionMonitorStatusUpdated(_ qrIsTargeted: Bool) {
        // Update the UI
        self.rectDrawView.setShouldBeGreenTarget(qrIsTargeted)
        if qrIsTargeted {
            self.positionMonitor?.stopRecentering() // stop recentering
        }
    }
    
    @IBAction func sliderValueChanged(_ sender: Any) {
        self.labelSliderVal.text = "\(slider.value)"
    }
    
    func directionHelper(_ directions: [Direction]) {
        var correct_directions: [Direction] = []
        for direction in directions {
            correct_directions.append(switchWallMode.isOn ? PositionUtil.translateFloorDirectionToWall(direction) : direction)
        }
        self.rectDrawView.setHelperArrows(correct_directions)
        //if !self.allowPositioning { return }
        self.shouldWait = true
        if directions.count > 0 {
            let command = PositionUtil.translateDirectionToCommand(correct_directions[0], isOnWall: false, verticalSpeed: 0.05, horizontalSpeed: slider.value)
            fc?.send(command, withCompletion: { (err) in
                if err != nil {
                    print("Send error: \(err.debugDescription)")
                } else {
                    print("Send success")
                }
            })
            usleep(100000) // 100ms
        }
        
        self.shouldWait = false
    }
    
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
        self.lastYaw = Float(state.attitude.yaw)
        if recorder.isRecording() {
            recorder.addAttitudeMeasurement(pitch: state.velocityY, yaw: Float(state.attitude.yaw), roll: state.velocityX, vs: Float(state.velocityZ))
        }

        switch state.windWarning {
        case .level0:
            self.ivWind.image = UIImage(named: "wind-light")
            break
        case .level1:
            self.ivWind.image = UIImage(named: "wind-moderate")
            break
        case .level2, .unknown:
            self.ivWind.image = UIImage(named: "wind-heavy")
            break
        }
    }
    
    func gimbal(_ gimbal: DJIGimbal, didUpdate state: DJIGimbalState) {
        let pitch = state.attitudeInDegrees.pitch
        let roll = state.attitudeInDegrees.roll
        let yaw = state.attitudeInDegrees.yaw - self.lastYaw
        self.recorder.addCameraMeasurement(pitch: pitch, yaw: yaw, roll: roll)
    }
    
    @IBAction func recordLegPressed(_ sender: Any) {
        if self.recorder!.isRecording() {
            self.fc?.setVirtualStickModeEnabled(true, withCompletion: { (err) in
                self.recorder.finishRecordingLeg()
                self.fc?.yawControlMode = .angularVelocity
                self.positionMonitor?.startRecentering()
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
    
    // this actually stops positioning.
    @IBAction func startPositioning(_ sender: Any) {
        self.positionMonitor?.stopRecentering()
        self.fc?.setVirtualStickModeEnabled(false, withCompletion: nil)
    }
    
    @IBAction func playbackBtn(_ sender: Any) {
        self.fc?.setVirtualStickModeEnabled(true, withCompletion: {(err) in
            usleep(200000)
            self.legs = self.recorder.getLegs()
            self.positionMonitor?.startRecentering {
                self.executeNextLeg()
            }
        })
    }
    
    private func executeNextLeg() {
        // make sure that we are "not targeted" so that it guarantees we wont
        // be automatically targeted when we get to the other code and its not detected immediately.
        self.positionMonitor?.resetTargeting()
        let leg = self.legs.removeFirst()
        self.replayer = FlightReplayer(commands: leg)
        self.fc?.yawControlMode = .angle
        print("Starting leg...")
        self.replayer?.executeCommandQueue(controller: self.fc!, cameraGimbal: self.gimbal, callback: {
            print("Finished leg...Recentering")
            if self.legs.count > 0 {
                DispatchQueue.main.async {
                    self.fc?.yawControlMode = .angularVelocity
                    self.positionMonitor?.startRecentering(withCompletion: {() in
                        print("Finished recentering...Next leg.")
                        self.executeNextLeg()
                    })
                }
            } else {
               self.fc?.setVirtualStickModeEnabled(false, withCompletion: nil)
            }
        })
        
    }
    
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
        videoData.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) -> Void in
            let rawPtr = UnsafeMutablePointer(mutating: bytes)
            VideoPreviewer.instance().push(rawPtr, length: Int32(videoData.count))
        })
    }
    
    private func setUpVideoPreview() {
        VideoPreviewer.instance().setView(self.videoPreviewerView)
        
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
        var posStr = ""
        switch state.position {
        case .left:
            posStr = "left"
            break
        case .right:
            posStr = "right"
            break
        case .nose:
            posStr = "nose"
            break
        case .tail:
            posStr = "tail"
            break
        case .unknown:
            posStr = "unknown"
            break
        }
        
        if state.position != .nose { return }
        
        guard let sectors = state.detectionSectors, sectors != nil else {
            return
        }
        
        for sector in sectors {
            //print("sector dist \(sector.obstacleDistanceInMeters)")
        }
    }
}
