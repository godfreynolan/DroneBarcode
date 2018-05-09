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
        let data = ["code": "", "data": barcode]
        let dataArray = [data]
        
        let jsonObject = ["codes": dataArray]
        
        var request = URLRequest(url: URL(string: "http://10.5.2.16:8000/riis")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: jsonObject, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
        })
        
        task.resume()
    }
}
