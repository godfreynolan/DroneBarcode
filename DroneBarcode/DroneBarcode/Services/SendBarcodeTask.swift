//
//  SendBarcodeTask.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 5/8/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import UIKit

class SendBarcodeTask {
    func sendBarcode(_ barcode: String) {
        let params = ["barcode":barcode] as Dictionary<String, String>
        
        var request = URLRequest(url: URL(string: "test")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: params, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
//            do {
//                let json = try JSONSerialization.jsonObject(with: data!) as! Dictionary<String, AnyObject>
//            } catch {
//            }
        })
        
        task.resume()
    }
}
