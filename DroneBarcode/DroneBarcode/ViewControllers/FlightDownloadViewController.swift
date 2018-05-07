//
//  FlightDownloadViewController.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/26/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import DJISDK
import UIKit

class FlightDownloadViewController: UIViewController, UITableViewDataSource, BarcodeScanCallback, CameraCallback, DownloadCallback {
    private var appDelegate: AppDelegate! = UIApplication.shared.delegate as? AppDelegate
    private var barcodeList = [String]()
    private var barcodeScanner: BarcodeScanner!
    private var camera: DJICamera!
    private var currentDownloadIndex = 0
    private var imageDownloader: ImageDownloader!
    private var mediaDownloadList: [DJIMediaFile] = []
    private var mediaHandler: MediaHandler!
    private var statusIndex = 0
    
    @IBOutlet weak var downloadProgressLabel: UILabel!
    @IBOutlet weak var totalDownloadImageLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.imageDownloader = ImageDownloader(callback: self)
        self.mediaHandler = MediaHandler(callback: self, camera: self.fetchCamera()!)
        
        self.tableView.dataSource = self
        
        let snapshotHandler = MediaSnapshotHandler(camera: self.fetchCamera()!, viewController: self)
        snapshotHandler.fetchInitialData()
    }
    
    @IBAction func downloadPictures(_ sender: UIButton) {
        if self.appDelegate.flightImageCount == 0 {
            let alert = UIAlertController(title: "Error", message: "There are no pictures to download", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        self.mediaHandler.setCameraToDownload()
    }
    
    //UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.barcodeList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableCell")!
        cell.textLabel?.text = self.barcodeList[indexPath.row]
        
        return cell
    }
    
    //CameraCallback
    func onDownloadReady() {
        self.mediaDownloadList = self.mediaHandler.fetchMediaManager().sdCardFileListSnapshot()!
        
        self.downloadProgressLabel.text = "Downloading Image 1 of \(self.appDelegate.flightImageCount)"
        self.startDownload()
    }
    
    func onPhotoReady() {
        self.downloadProgressLabel.text = "All Images Downloaded"
    }
    
    func onFileListRefresh() {
        // Not needed
    }
    
    //DownloadCallback
    func onDownloadError(error: Error?) {
        let alert = UIAlertController(title: "Download error", message: error?.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    func onDownloadSuccess(image: UIImage) {
        self.barcodeScanner.scanForBarcode(image: image)
    }
    
    //BarcodeScanCallback
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
        if barcodeData.isEmpty {
            self.barcodeList.append("No barcode data found")
        } else {
            self.barcodeList.append(barcodeData)
        }
        
        self.tableView.reloadData()
        
        self.currentDownloadIndex += 1
        self.statusIndex += 1
        
        if (self.currentDownloadIndex < self.mediaDownloadList.count) {
            self.downloadProgressLabel.text = "Downloading Image \(self.statusIndex) of \(self.appDelegate.flightImageCount)"
            self.imageDownloader.downloadImage(file: self.mediaDownloadList[self.currentDownloadIndex])
        } else {
            self.mediaHandler.setCameraToPhotoShoot()
        }
    }
    
    //Helpers
    func setTotalImageCount(totalFileCount: Int) {
        self.appDelegate.flightImageCount = totalFileCount - self.appDelegate.preFlightImageCount
        
        if self.appDelegate.flightImageCount == 0 {
            self.totalDownloadImageLabel.text = "0 Images to download"
            self.downloadProgressLabel.text = "No images to download"
        } else if self.appDelegate.flightImageCount == 1 {
            self.totalDownloadImageLabel.text = "1 Image to download"
            self.downloadProgressLabel.text = "Ready to download"
        } else {
            self.totalDownloadImageLabel.text = "\(self.appDelegate.flightImageCount) Images to download"
            self.downloadProgressLabel.text = "Ready to download"
        }
    }
    
    private func startDownload() {
        self.statusIndex = 1
        self.currentDownloadIndex = self.appDelegate.preFlightImageCount
        
        self.imageDownloader.downloadImage(file: self.mediaDownloadList[self.currentDownloadIndex])
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
    
    private func resetCamera() {
        self.camera.setMode(.shootPhoto, withCompletion: { (error) in
            if (error != nil) {
                let alert = UIAlertController(title: "Shoot Photo Error", message: error?.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        })
    }
}
