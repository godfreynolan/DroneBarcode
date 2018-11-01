//
//  BarcodeScanner.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/26/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import UIKit
import Vision
import Firebase
import ScanditBarcodeScanner

class BarcodeScanner: SBSScanDelegate {
    private var callback: BarcodeScanCallback!
    private var scanAttempts = 0
    private var googleCount = 0
    private var appleCount = 0
    private lazy var vision = Vision.vision()

    private var format = VisionBarcodeFormat.all
    private var googleDetector: VisionBarcodeDetector? = nil

    init(callback: BarcodeScanCallback) {
        self.callback = callback
        let options = VisionBarcodeDetectorOptions(formats: format)
        self.googleDetector = self.vision.barcodeDetector(options: options)
    }

    func scanForBarcode(image: UIImage) {
        scanAttempts += 1
        scanGoogle(image)
        scanApple(image)
        
        self.callback.onScanSuccess(barcodeData: "Google: \(self.googleCount)     Apple: \(self.appleCount)")
    }
    
    func getGoogleCount() -> Int { return self.googleCount }
    func getAppleCount() -> Int { return self.appleCount }
    
    func scanApple(_ image: UIImage) {
        let barcodeRequest = VNDetectBarcodesRequest(completionHandler: { request, error in
            guard let results = request.results else {
                return
            }
            
            if results.isEmpty {
                return
            }
            
            for result in results {
                let result = result as! VNBarcodeObservation
                let x1 = result.topLeft.x * image.size.width
                let x2 = result.topRight.x * image.size.width
                let y1 = result.topLeft.y * image.size.height
                let y2 = result.bottomLeft.y * image.size.height
                let rect = CGRect(x: x1, y: image.size.height - y2, width: x2 - x1, height: y2 - y1)
                self.callback.scanSuccess(rect: rect, color: .blue)
            }
            
            self.appleCount += results.count
        })
        
        // Create an image handler and use the CGImage your UIImage instance.
        guard let cgImage = image.cgImage else {
            return
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Perform the barcode-request. This will call the completion-handler of the barcode-request.
        guard let _ = try? handler.perform([barcodeRequest]) else {
            return
        }
    }
    
    func scanGoogle(_ image: UIImage) {
        let image = VisionImage(image: image)
        self.googleDetector!.detect(in: image) { features, error in
            guard error == nil, let features = features, !features.isEmpty else {
                return
            }
            
            for feature in features {
                self.callback.scanSuccess(rect: feature.frame, color: .red)
            }
            
            self.googleCount += features.count
        }
    }
    
    func scanScandit(_ image: UIImage) {
        let scanSettings = SBSScanSettings.default()
        scanSettings.cameraFacingPreference = .front
        scanSettings.setSymbology(.aztec, enabled: true)
        scanSettings.setSymbology(.qr, enabled: true)
        scanSettings.setSymbology(.microQR, enabled: true)
        scanSettings.setSymbology(.ean8, enabled: true)
        scanSettings.setSymbology(.ean13, enabled: true)
        scanSettings.setSymbology(.code11, enabled: true)
        scanSettings.setSymbology(.code128, enabled: true)
        scanSettings.setSymbology(.fiveDigitAddOn, enabled: true)
        let picker = SBSBarcodePicker(settings: scanSettings)
        picker.scanDelegate = self
        picker.startScanning()
    }
    
    func barcodePicker(_ picker: SBSBarcodePicker, didScan session: SBSScanSession) {
        guard let code = session.newlyRecognizedCodes.first else { return }
        self.callback.onScanSuccess(barcodeData: code.data!)
    }
}
