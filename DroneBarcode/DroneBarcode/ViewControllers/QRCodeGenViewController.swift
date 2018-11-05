//
//  QRCodeGenViewController.swift
//  DroneBarcode
//
//  Created by Administrator on 11/5/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import UIKit

class QRCodeGenViewController: UIViewController {

    
    @IBOutlet weak var editTextQRNum: UITextField!
    var dataArray: [String] = []
    var imageArray: [UIImage] = []
    @IBOutlet weak var qrImageView: UIImageView!
    
    @IBAction func generateQR(_ sender: Any) {
        let numberOfQRCodes: Int = Int(editTextQRNum.text ?? "0") ?? 0
        
        for tempCounter in 0..<numberOfQRCodes{
            dataArray.append("\(tempCounter)")
        }
        
        for tempDataArray in dataArray{
            imageArray.append(generateQRCode(from: tempDataArray)!)
        }
        
//        for tempDataArray in dataArray{
//            let newSizedUIImage: UIImage = resizeImage(image: generateQRCode(from: tempDataArray)!, withSize: CGSize(width: 300, height: 300))
//            imageArray.append(newSizedUIImage)
//        }
        
    }//end generate
    
    
    @IBAction func printQR(_ sender: Any) {
        
        
        let vc = UIActivityViewController(activityItems: imageArray, applicationActivities: [])
        self.present(vc, animated: true)
        if let popOver = vc.popoverPresentationController {
            popOver.sourceView = self.view
        }
//        for tempImageArray in imageArray{
//            let vc = UIActivityViewController(activityItems: [tempImageArray], applicationActivities: [])
//
//        }
        
    }
    
    func generateQRCode(from string: String) -> UIImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            
            guard let qrCodeImage = filter.outputImage else{
                return nil
            }
            let scaleX = qrImageView.frame.size.width / qrCodeImage.extent.size.width
            let scaleY = qrImageView.frame.size.height / qrCodeImage.extent.size.height
            let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
            
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }//end generateQRCode
    
//    func resizeImage(image: UIImage, withSize: CGSize) -> UIImage {
//
//        var actualHeight: CGFloat = image.size.height
//        var actualWidth: CGFloat = image.size.width
//        let maxHeight: CGFloat = withSize.width
//        let maxWidth: CGFloat = withSize.height
//        var imgRatio: CGFloat = actualWidth/actualHeight
//        let maxRatio: CGFloat = maxWidth/maxHeight
//        let compressionQuality = 0.5//50 percent compression
//
//        if (actualHeight > maxHeight || actualWidth > maxWidth) {
//            if(imgRatio < maxRatio) {
//                //adjust width according to maxHeight
//                imgRatio = maxHeight / actualHeight
//                actualWidth = imgRatio * actualWidth
//                actualHeight = maxHeight
//            } else if(imgRatio > maxRatio) {
//                //adjust height according to maxWidth
//                imgRatio = maxWidth / actualWidth
//                actualHeight = imgRatio * actualHeight
//                actualWidth = maxWidth
//            } else {
//                actualHeight = maxHeight
//                actualWidth = maxWidth
//            }
//        }
//
//        let rect: CGRect = CGRect(x: 0.0, y: 0.0, width: actualWidth, height: actualHeight)
//        UIGraphicsBeginImageContext(rect.size)
//        image.draw(in: rect)
//        let image: UIImage  = UIGraphicsGetImageFromCurrentImageContext()!
//        let imageData = UIImageJPEGRepresentation(image, CGFloat(compressionQuality))
//        UIGraphicsEndImageContext()
//
//        let resizedImage = UIImage(data: imageData!)
//        return resizedImage!
//
//    }
    
}
