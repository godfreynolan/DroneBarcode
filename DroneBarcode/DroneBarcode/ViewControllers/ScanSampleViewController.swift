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

class ScanSampleViewController: UIViewController, DJIFlightControllerDelegate,  DJIVideoFeedListener, BarcodeScanCallback, PositionMonitorDelegate {

    private var barcodeScanner: BarcodeScanner!
    private var positionMonitor: PositionMonitor? = nil
    private let fc = (DJISDKManager.product() as! DJIAircraft).flightController
    
    @IBOutlet weak var labelWinner: UILabel!
    @IBOutlet weak var labelSliderVal: UILabel!
    private var scanningAlert: UIAlertController!
    
    private var scanningTimer: Timer!
    
    private var shouldWait: Bool = false
    private var allowPositioning: Bool = false
    
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var videoPreviewerView: UIView!
    @IBOutlet weak var rectDrawView: RectDrawView!
    @IBOutlet weak var switchWallMode: UISwitch!
    @IBOutlet weak var ivWind: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.barcodeScanner = BarcodeScanner(callback: self)
        rectDrawView.addTarget()
        self.setUpVideoPreview()
        
        self.fc?.setVirtualStickModeEnabled(true, withCompletion: nil)
        self.fc?.flightAssistant?.setCollisionAvoidanceEnabled(false, withCompletion: nil)
        self.fc?.setVisionAssistedPositioningEnabled(true, withCompletion: nil)
        self.fc?.yawControlMode = .angularVelocity
        self.fc?.rollPitchControlMode = .velocity
        self.fc?.verticalControlMode = .velocity
        self.fc?.delegate = self
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
    
    func onError(error: Error?) {
    }
    
    func onScanSuccess(barcodeData: String) {
        if barcodeData.isEmpty {
            return
        }
        self.labelWinner!.text = barcodeData
    }
    
    func scanSuccess(rect: CGRect, color: UIColor) {
        if positionMonitor == nil {
            self.positionMonitor = PositionMonitor(qr: rect, target: rectDrawView.getTargetRect(), flightController: fc!)
            self.positionMonitor!.delegate = self
        }
        positionMonitor?.updateQRPosition(rect)
        rectDrawView.addRectangle(rect: rect, color: color)
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
        self.scanningTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: (#selector(takePhoto)), userInfo: nil, repeats: true)
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
    
    func positionMonitorStatusUpdated(_ qrIsTargeted: Bool) {
        // Update the UI
        self.rectDrawView.setShouldBeGreenTarget(qrIsTargeted)
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
        if  !self.allowPositioning { return }
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
    
    func pitchSlight(forward: Bool) {
        let val = Float(!forward ? slider.value : -1 * slider.value)
        fc?.send(DJIVirtualStickFlightControlData(pitch: val, roll: 0, yaw: 0, verticalThrottle: 0), withCompletion: { (err) in
            if err == nil {
                print("pitch \(val) err nil")
            } else {
                print("pitch \(val) err \(err.debugDescription)")
            }
        })
    }
    
    func rollSlight(right: Bool) {
        let val = Float(right ? slider.value : -1 * slider.value)
        fc?.send(DJIVirtualStickFlightControlData(pitch: 0, roll: val, yaw: 0, verticalThrottle: 0), withCompletion: { (err) in
            if err == nil {
                print("roll \(val) err nil")
            } else {
                print("roll \(val) err \(err.debugDescription)")
            }
        })
    }
    
    func altitudeSlight(up: Bool) {
        let val = Float(up ? 0.05 : -0.05)
        fc?.send(DJIVirtualStickFlightControlData(pitch: 0, roll: 0, yaw: 0, verticalThrottle: val), withCompletion: { (err) in
            if err == nil {
                print("altitude \(val) err nil")
            } else {
                print("altitude \(val) err \(err.debugDescription)")
            }
        })
    }
    
    func flightController(_ fc: DJIFlightController, didUpdate state: DJIFlightControllerState) {
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
    
    @IBAction func virtualSticksOff(_ sender: Any) {
        self.fc?.setVirtualStickModeEnabled(false, withCompletion: nil)
    }
    
    @IBAction func takeOff(_ sender: Any) {
        self.fc?.startTakeoff(completion: nil)
    }
    
    @IBAction func startPositioning(_ sender: Any) {
        self.allowPositioning = !self.allowPositioning
        self.labelWinner.text = "Positioning enabled: \(self.allowPositioning)"
        if !self.allowPositioning {
            self.fc?.setVirtualStickModeEnabled(false, withCompletion: nil)
        } else {
            self.fc?.setVirtualStickModeEnabled(true, withCompletion: nil)
        }
    }
}
