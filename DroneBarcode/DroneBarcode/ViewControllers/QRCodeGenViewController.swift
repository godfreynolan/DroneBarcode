//
//  QRCodeGenViewController.swift
//  DroneBarcode
//
//  Created by Administrator on 11/5/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import UIKit
import PDFKit

class QRCodeGenViewController: UIViewController {

    
    @IBOutlet weak var editTextQRNum: UITextField!
    var dataArray: [String] = [] // data for each QR code
    var cgImageArray: [CGImage] = [] // store each QR code as a CGImage
    var pathGlobal: String = "" // path of the pdf file when it is made
    
    // takes user input int and makes n number of QR images
    @IBAction func generateQR(_ sender: Any) {
        let numberOfQRCodes: Int = Int(editTextQRNum.text ?? "0") ?? 0
        
        for tempCounter in 0..<numberOfQRCodes{
            dataArray.append("\(tempCounter)")
        }
        
        for tempCGIImageArray in dataArray{
            cgImageArray.append(generateQRCode(from: tempCGIImageArray)!)
        }
        
    }
    
    // initializes pathGlobal to use as a URL later to print from.
    // calls createPDF to make a NSData from a array of CGImages
    // creates a pdf file to be accessed from itunes
  
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
    
 
    
    @IBAction func printQR(_ sender: Any) {

        // make a url from global pdf path
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
    
    @IBAction func addPageNumbers(_ sender: Any) {
        let cgImageArraySize = cgImageArray.count
        
        //requires PDFKit import
        //makes Text widget
        var pageNumber = PDFAnnotation(bounds: CGRect(x: 230, y: 600, width: 235, height: 180), forType: .widget, withProperties: nil)
        pageNumber.widgetFieldType = .text
        pageNumber.backgroundColor = UIColor.white
        pageNumber.fontColor = UIColor.black
        pageNumber.font = UIFont.systemFont(ofSize: 180, weight: UIFont.Weight.bold)
        pageNumber.widgetStringValue = "\(cgImageArraySize)"
        
        
        //get PDFDocument from URL and add the Text widget
        let inUrl: URL = URL(fileURLWithPath: pathGlobal)
        let doc: PDFDocument = PDFDocument(url: inUrl)!
        let page: PDFPage = doc.page(at: 0)!
        page.addAnnotation(pageNumber)
        
        do {
            try doc.write(toFile: pathGlobal)
            print("Wrote to file.")
        } catch {
            print("Could not save!")
        }
    }
        

    
    func generateQRCode(from string: String) -> CGImage? {
        let data = string.data(using: String.Encoding.ascii)
        
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            
            //makes the CIImage larger/smaller
            let transform = CGAffineTransform(scaleX: 11, y: 11)
            
            if let output: CIImage = filter.outputImage?.transformed(by: transform) {

                return convertCIImageToCGImage(inputImage: output)

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
            pdfContext.draw(tempCGImage, in: imageDrawing)
            //end the current page
            pdfContext.endPage()
        }

        return pdfData
    }

}


