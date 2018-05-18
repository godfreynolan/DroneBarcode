//
//  SendBarcodeTask.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 5/8/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import UIKit

class SendBarcodeTask {
    private var nonce = 0
    
    func getBlockDetails(_ barcode: String) {
        var request = URLRequest(url: URL(string: "http://10.5.2.16:8000/block")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            if data != nil {
                let responseObject = try? JSONSerialization.jsonObject(with: data!, options: [])
                let jsonObject = responseObject as? [String: Any]

                let difficulty = jsonObject!["difficulty"] as! Int
                let lastHash = jsonObject!["last_hash"] as! String

                self.sendBarcode(difficulty: difficulty, barcode: barcode, lastHash: lastHash)
            }
        })

        task.resume()
    }
    
    func sendBarcode(difficulty: Int, barcode: String, lastHash: String) {
        let timeStamp = Int((Date().timeIntervalSince1970 * 1000.0).rounded())
        
        let hash = self.generateHash(difficulty: difficulty, timeStamp: timeStamp, previousHash: lastHash, data: barcode)
        
        let block = ["hash": hash, "nonce": self.nonce, "created": timeStamp, "data": barcode, "prevhash": lastHash] as [String : Any]
        let data = ["block": block]
        
        var request = URLRequest(url: URL(string: "http://10.5.2.16:8000/append")!)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject: data, options: [])
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
        })
        
        task.resume()
    }
    
    private func generateHash(difficulty: Int, timeStamp: Int, previousHash: String, data: String) -> String {
        var startingChars = ""
        while startingChars.count < difficulty {
            startingChars += "0"
        }
        
        var result = ""
        while result.prefix(difficulty) != startingChars {
            let dataToBeHashed = previousHash + "\(timeStamp)\(self.nonce)" + data
            
            let data = dataToBeHashed.data(using: .utf8)!
            var digest = [UInt8](repeating: 0, count: Int(CC_SHA512_DIGEST_LENGTH))
            data.withUnsafeBytes({
                _ = CC_SHA512($0, CC_LONG(data.count), &digest)
            })
            
            result = digest.map({ String(format: "%02hhx", $0) }).joined(separator: "")
            
            self.nonce += 1
        }
        
        return result
    }
}
