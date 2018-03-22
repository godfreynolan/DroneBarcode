//
//  ScanViewController.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/22/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import DJISDK
import UIKit
import VideoPreviewer
import Vision

class ScanViewController: UIViewController, DJIVideoFeedListener {
    private var camera: DJICamera!
    private var isCameraSetup = false
    
    @IBOutlet weak var videoPreviewerView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUpVideoPreview()
        
        self.camera = fetchCamera()!
        self.camera.getSharpnessWithCompletion { (sharpness, error) in
            if (error != nil) {
                let alert = UIAlertController(title: "Format Error", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else if sharpness == 3 {
                self.isCameraSetup = true
            }
        }
    }
    
    @IBAction func setUpCamera(_ sender: Any?) {
        if self.isCameraSetup {
            let alert = UIAlertController(title: "Ready to Scan", message: "The drone's camera is ready to scan barcodes.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        self.camera.setPhotoFileFormat(.JPEG) { (error) in
            if (error != nil) {
                let alert = UIAlertController(title: "Format Error", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
        
        self.camera.setSharpness(3) { (error) in
            if (error != nil) {
                let alert = UIAlertController(title: "Sharpness Error", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                self.isCameraSetup = true
            }
        }
    }
    
    @IBAction func startTakingPhoto(_ sender: Any?) {
        if !self.isCameraSetup {
            let alert = UIAlertController(title: "Error", message: "Please setup the drone's camera before taking a picture.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
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
            }
        }
    }
    
    @IBAction func download(_ sender: Any?) {
        self.startDownload()
    }
    
    private func startDownload() {
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
        self.camera.mediaManager?.refreshFileList(completion: { (error) in
            if error != nil {
                let alert = UIAlertController(title: "Refresh File List Error", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            } else {
                let lastImage = self.camera.mediaManager?.fileListSnapshot()?.last
                if lastImage == nil {
                    let alert = UIAlertController(title: "Error", message: "No photos available to download. Please take a picture.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    return
                }
                
                self.downloadImage(file: lastImage!)
            }
        })
    }
    
    private func downloadImage(file: DJIMediaFile) {
        let isPhoto = file.mediaType == .JPEG || file.mediaType == .TIFF;
        if (!isPhoto) {
            return
        }
        
        var mutableData: Data? = nil
        var previousOffset = 0
        
        file.fetchData(withOffset: UInt(previousOffset), update: DispatchQueue.main, update: { (data, isComplete, error) in
            if (error != nil) {
                let alert = UIAlertController(title: "Download error", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            if (mutableData == nil) {
                mutableData = data
            } else {
                mutableData?.append(data!)
            }
            
            previousOffset += (data?.count)!;
            if (previousOffset == file.fileSizeInBytes && isComplete) {
                let image = UIImage(data: mutableData!)
                self.scanForBarcode(image: image!)
            }
        })
    }
    
    func setUpVideoPreview() {
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
    
    func resetVideoPreview() {
        VideoPreviewer.instance().unSetView()
        
        let product = DJISDKManager.product()
        if ((product?.model?.isEqual(DJIAircraftModelNameA3))! || (product?.model?.isEqual(DJIAircraftModelNameN3))! ||
            (product?.model?.isEqual(DJIAircraftModelNameMatrice600))! || (product?.model?.isEqual(DJIAircraftModelNameMatrice600Pro))!) {
            DJISDKManager.videoFeeder()?.secondaryVideoFeed.remove(self)
        } else {
            DJISDKManager.videoFeeder()?.primaryVideoFeed.remove(self)
        }
    }
    
    func videoFeed(_ videoFeed: DJIVideoFeed, didUpdateVideoData videoData: Data) {
        videoData.withUnsafeBytes({ (bytes: UnsafePointer<UInt8>) -> Void in
            let rawPtr = UnsafeMutablePointer(mutating: bytes)
            VideoPreviewer.instance().push(rawPtr, length: Int32(videoData.count))
        })
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
    
    private func scanForBarcode(image: UIImage) {
        // Create a barcode detection-request
        let barcodeRequest = VNDetectBarcodesRequest(completionHandler: { request, error in
            
            if error != nil {
                let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            guard let results = request.results else {
                let alert = UIAlertController(title: "Error", message: "What results?", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
                
            }
            
            if results.isEmpty {
                let alert = UIAlertController(title: "error", message: "No barcodes here", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
                return
            }
            
            // Loopm through the found results
            for result in results {
                
                // Cast the result to a barcode-observation
                if let barcode = result as? VNBarcodeObservation {
                    
                    var message = ""
                    // Print barcode-values
                    message += "Symbology: \(barcode.symbology.rawValue)"
                    message += "\nPayload Value: \(barcode.payloadStringValue!)"
                    
                    if let desc = barcode.barcodeDescriptor as? CIQRCodeDescriptor {
                        let content = String(data: desc.errorCorrectedPayload, encoding: .utf8)
                        
                        // FIXME: This currently returns nil. I did not find any docs on how to encode the data properly so far.
                        message += "\nPayload: \(String(describing: content))"
                        message += "\nError-Correction-Level: \(desc.errorCorrectionLevel)"
                        message += "\nSymbol-Version: \(desc.symbolVersion)"
                    }
                    
                    let alert = UIAlertController(title: "Result", message: message, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                    
                    self.camera.setMode(.shootPhoto, withCompletion: { (error) in
                        if (error != nil) {
                            let alert = UIAlertController(title: "Shoot Photo Error", message: error?.localizedDescription, preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                    })
                }
            }
        })
        
        // Create an image handler and use the CGImage your UIImage instance.
        guard let image = image.cgImage else {
            let alert = UIAlertController(title: "Error", message: "What image?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
            
        }
        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        
        // Perform the barcode-request. This will call the completion-handler of the barcode-request.
        guard let _ = try? handler.perform([barcodeRequest]) else {
            let alert = UIAlertController(title: "Error", message: "Could not perform barcode-request!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return print("Could not perform barcode-request!")
        }
    }
}
