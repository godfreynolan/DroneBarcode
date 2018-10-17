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

class ScanSampleViewController: UIViewController, DJIVideoFeedListener, BarcodeScanCallback {
    private var barcodeScanner: BarcodeScanner!
    
    private var scanningAlert: UIAlertController!
    
    private var scanningTimer: Timer!

    @IBOutlet weak var videoPreviewerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.barcodeScanner = BarcodeScanner(callback: self)
        self.setUpVideoPreview()
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
        print("Successful scan: " + barcodeData)
//        SendBarcodeTask().getBlockDetails(barcodeData)
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
}
