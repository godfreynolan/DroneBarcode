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

class ScanSampleViewController: UIViewController, DJIVideoFeedListener, BarcodeScanCallback, DownloadCallback {
    private var barcodeScanner: BarcodeScanner!
    private var camera: DJICamera!
    private var imageDownloader: ImageDownloader!
    
    @IBOutlet weak var videoPreviewerView: UIView!
    @IBOutlet weak var statusLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.barcodeScanner = BarcodeScanner(callback: self)
        self.imageDownloader = ImageDownloader(callback: self)
        
        self.setUpVideoPreview()
        
        self.camera = fetchCamera()!
    }
    
    @IBAction func startTakingPhoto(_ sender: Any?) {
        camera.setMode(.shootPhoto, withCompletion: { (error) in
            DispatchQueue.main.asyncAfter(deadline: (DispatchTime.now() + 1), execute: {() -> Void in
                if (error != nil) {
                    let alert = UIAlertController(title: "Shoot Photo Error", message: error?.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                } else {
                    self.takePhoto()
                }
            })
        })
    }
    
    private func takePhoto() {
        self.camera.startShootPhoto { (error) in
            if error != nil {
                let alert = UIAlertController(title: "Start Shoot Error", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                let alert = UIAlertController(title: "Success", message: "Photo captured. Ready to download.", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                
//                self.startDownload()
            }
        }
    }
    
    @IBAction func download(_ sender: Any?) {
        self.startDownload()
    }
    
    func onDownloadError(error: Error?) {
        let alert = UIAlertController(title: "Download error", message: error?.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func onDownloadSuccess(image: UIImage) {
        self.barcodeScanner.scanForBarcode(image: image)
    }
    
    func onError(error: Error?) {
        if error == nil {
            let alert = UIAlertController(title: "Error", message: "Could not perform barcode-request!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func onScanSuccess(barcodeData: String) {
        var displayData = barcodeData
        
        if displayData.isEmpty {
            displayData = "No barcode found"
        }
        
        self.camera.setMode(.shootPhoto, withCompletion: { (error) in
            if (error != nil) {
                let alert = UIAlertController(title: "Shoot Photo Error", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        })
        
        self.statusLabel.text = "Finished Barcode Scan"
        
        let alert = UIAlertController(title: "Barcodes", message: displayData, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    private func startDownload() {
        self.statusLabel.text = "Scanning Barcode"
        
        self.camera.setMode(.mediaDownload, withCompletion: { (error) in
            if error != nil {
                let alert = UIAlertController(title: "Start Download Error", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.fetchImage()
            }
        })
    }
    
    private func fetchImage() {
        self.camera.mediaManager?.refreshFileList(of: .sdCard, withCompletion: { (error) in
            if error != nil {
                let alert = UIAlertController(title: "Refresh File List Error", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.imageDownloader.downloadImage(file: (self.camera.mediaManager?.sdCardFileListSnapshot()?.last)!)
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
