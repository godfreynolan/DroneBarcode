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
    var cgImageArray: [CGImage] = []
    var pdfStuff: NSData?
    var nsDataArray: [NSData] = []
    var pathGlobal: String = ""
    @IBOutlet weak var qrImageView: UIImageView!
    
    @IBAction func generateQR(_ sender: Any) {
        let numberOfQRCodes: Int = Int(editTextQRNum.text ?? "0") ?? 0
        
        for tempCounter in 0..<numberOfQRCodes{
            dataArray.append("\(tempCounter)")
        }
        
        for tempCGIImageArray in dataArray{
            cgImageArray.append(generateQRCode(from: tempCGIImageArray)!)
        }
        
    }//end generate
    
    @IBAction func makePDF(_ sender: Any) {
        
        if let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, .allDomainsMask, true).first {
            let path = dir + "/" + "something.pdf"
            print("Saving to " + path)
            pathGlobal = dir + "/" + "something.pdf"
            //creating pdf from array of CGImages
            let somePDF: NSData? = createPDF(cgImage: cgImageArray)

            do {
                try somePDF?.write(toFile: path, atomically: false)
                print("Wrote to file.")
            } catch {
                print("Could not save!")
            }
        } else {
            print("Could not get directory!")
        }

    }
    
    @IBAction func printPDF(_ sender: Any) {
        
    }
    
    @IBAction func printQR(_ sender: Any) {

        // make a url from pdf file path
        let pdfURL = NSURL.fileURL(withPath: pathGlobal)

        let uiViewController = UIActivityViewController(activityItems: [pdfURL], applicationActivities: [])
        uiViewController.popoverPresentationController?.sourceView = self.view

        // all the UI to exclude from printing GUI
        uiViewController.excludedActivityTypes = [UIActivityType.addToReadingList, UIActivityType.airDrop, UIActivityType.assignToContact, UIActivityType.copyToPasteboard, UIActivityType.mail, UIActivityType.markupAsPDF, UIActivityType.message, UIActivityType.openInIBooks, UIActivityType.postToFacebook, UIActivityType.postToFlickr, UIActivityType.postToTencentWeibo, UIActivityType.postToTwitter, UIActivityType.postToVimeo, UIActivityType.postToWeibo, UIActivityType.saveToCameraRoll]
        
        // getting the printing GUI to pop open
        self.present(uiViewController, animated: true)
        if let popOver = uiViewController.popoverPresentationController {
            popOver.sourceView = self.view
        }
        
    }
    
    func generateQRCode(from string: String) -> CGImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            
            //makes the CIImage larger/smaller
            let transform = CGAffineTransform(scaleX: 11, y: 11)
            
            //ciImage
            if let output = filter.outputImage?.transformed(by: transform) {

                return convertCIImageToCGImage(inputImage: output)
//                return UIImage(ciImage: output)
            }
        }
        
        return nil
    }//end generateQRCode
    
    func convertCIImageToCGImage(inputImage: CIImage) -> CGImage! {
        let context = CIContext(options: nil)
        if context != nil {
            return context.createCGImage(inputImage, from: inputImage.extent)
        }
        return nil
    }
    
    func createPDF(cgImage: [CGImage]) -> NSData? {
        
        let pdfData = NSMutableData()
        
        // count bytes into pdfData
        let pdfConsumer = CGDataConsumer(data: pdfData as CFMutableData)!
        
        // makes a CGRect from UIImage size
        var imageDrawing = CGRect.init(x: 200, y: 300, width: cgImage[0].width, height: cgImage[0].height)
        
        // need firstPage mediaBox
        let pdfContext = CGContext(consumer: pdfConsumer, mediaBox: &imageDrawing, nil)!

    //   used to approximate blankPieceOfPaper dimensions when loaded in google chrome
    //   let defaultPaper = UIPrintPaper.init()
    //   defaultPaper.paperSize.width, height: defaultPaper.paperSize.height
        
        //container dimensions the CGImage is drawn onto
        var blankPieceOfPaper = CGRect.init(x:0, y:0, width: 614, height: 794)
       
        //drawing multiple pdf pages
        for tempCGImage in cgImageArray{
            //begins a new page
            pdfContext.beginPage(mediaBox: &blankPieceOfPaper)
            //drawing UIImage in CGRect
            pdfContext.draw(tempCGImage, in: imageDrawing)
            //end the current page
            pdfContext.endPage()
        }

        return pdfData
    }
    
}
