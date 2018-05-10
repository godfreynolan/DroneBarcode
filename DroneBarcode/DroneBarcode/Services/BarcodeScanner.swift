//
//  BarcodeScanner.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/26/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import UIKit
import Vision

class BarcodeScanner {
    private var callback: BarcodeScanCallback!
    
    init(callback: BarcodeScanCallback) {
        self.callback = callback
    }
    
    func scanForBarcode(image: UIImage) {
        let barcodeRequest = VNDetectBarcodesRequest(completionHandler: { request, error in
            if error != nil {
                DispatchQueue.main.async {
                    self.callback.onError(error: error)
                }
                return
            }
            
            guard let results = request.results else {
                DispatchQueue.main.async {
                    self.callback.onScanSuccess(barcodeData: "")
                }
                return
            }
            
            if results.isEmpty {
                DispatchQueue.main.async {
                    self.callback.onScanSuccess(barcodeData: "")
                }
                return
            }
            
            var message = ""
            // Loop through the found results
            for result in results {
                // Cast the result to a barcode-observation
                if let barcode = result as? VNBarcodeObservation {
                    message = "Symbology: \(barcode.symbology.rawValue)"
                    message += "\nPayload Value: \(barcode.payloadStringValue!)"
                }
            }
            
            self.callback.onScanSuccess(barcodeData: message)
        })
        
        // Create an image handler and use the CGImage your UIImage instance.
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async {
                self.callback.onError(error: nil)
            }
            return
            
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        // Perform the barcode-request. This will call the completion-handler of the barcode-request.
        guard let _ = try? handler.perform([barcodeRequest]) else {
            DispatchQueue.main.async {
                self.callback.onError(error: nil)
            }
            return
        }
    }
}
