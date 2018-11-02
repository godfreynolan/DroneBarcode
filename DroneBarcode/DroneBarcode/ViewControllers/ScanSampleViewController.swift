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

class ScanSampleViewController: UIViewController, DJIVideoFeedListener, BarcodeScanCallback, PositionMonitorDelegate {

    private var barcodeScanner: BarcodeScanner!
    private var positionMonitor: PositionMonitor? = nil
    private let fc = (DJISDKManager.product() as! DJIAircraft).flightController
    
    @IBOutlet weak var labelWinner: UILabel!
    private var scanningAlert: UIAlertController!
    
    private var scanningTimer: Timer!
    
    private var shouldWait: Bool = false
    private var allowPositioning: Bool = false
    
    @IBOutlet weak var videoPreviewerView: UIView!
    @IBOutlet weak var rectDrawView: RectDrawView!
    
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
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if self.scanningTimer.isValid {
            self.scanningTimer.invalidate()
        }
    }
    
    @objc func takePhoto() {
        let renderer = UIGraphicsImageRenderer(size: self.videoPreviewerView.bounds.size)
//        self.videoPreviewerView.snapshotView(afterScreenUpdates: true)
//        UIGraphicsBeginImageContextWithOptions(self.videoPreviewerView!.frame.size, false, 0.0)
//        self.videoPreviewerView.layer.render(in: UIGraphicsGetCurrentContext()!)
//        let renderedImage = UIGraphicsGetImageFromCurrentImageContext()
//        UIGraphicsEndImageContext()
        
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
    
    func directionHelper(_ directions: [Direction]) {
        self.rectDrawView.setHelperArrows(directions)
        if self.shouldWait || !self.allowPositioning { return }
        self.shouldWait = true
        for d in directions {
            switch d {
            case .up:
                altitudeSlight(up: true)
                break
            case .down:
                altitudeSlight(up: false)
                break
            case .right:
                pitchSlight(right: false)
                break
            case .left:
                pitchSlight(right: false)
                break
            case .forward:
                rollSlight(forward: true)
                break
            case .back:
                rollSlight(forward: false)
                break
            }
            usleep(100000) // 10ms
        }
        self.shouldWait = false
    }
    
    func pitchSlight(right: Bool) {
        let val = Float(right ? 0.05 : -0.05)
        fc?.send(DJIVirtualStickFlightControlData(pitch: val, roll: 0, yaw: 0, verticalThrottle: 0), withCompletion: { (err) in

        })
    }
    
    func rollSlight(forward: Bool) {
        let val = Float(forward ? 0.05 : -0.05)
        fc?.send(DJIVirtualStickFlightControlData(pitch: 0, roll: val, yaw: 0, verticalThrottle: 0), withCompletion: { (err) in
            
        })
    }
    
    func altitudeSlight(up: Bool) {
        let val = Float(up ? 0.05 : -0.05)
        fc?.send(DJIVirtualStickFlightControlData(pitch: 0, roll: 0, yaw: 0, verticalThrottle: val), withCompletion: { (err) in

        })
    }
    
    @IBAction func virtualSticksOff(_ sender: Any) {
        self.fc?.setVirtualStickModeEnabled(false, withCompletion: nil)
    }
    
    @IBAction func takeOff(_ sender: Any) {
        self.fc?.startTakeoff(completion: nil)
    }
    
    @IBAction func startPositioning(_ sender: Any) {
        self.allowPositioning = true
    }
}
