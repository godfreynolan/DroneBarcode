//
//  MediaSnapshotHandler.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/26/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import DJISDK

class MediaSnapshotHandler: CameraCallback {
    private var mediaHandler: MediaHandler!
    private var viewController: UIViewController!
    
    init(camera: DJICamera, viewController: UIViewController) {
        self.mediaHandler = MediaHandler(callback: self, camera: camera)
        self.viewController = viewController
    }
    
    func fetchInitialData() {
        self.mediaHandler.setCameraToDownload()
    }
    
    func onDownloadReady() {
        self.mediaHandler.retrieveMediaFiles()
    }
    
    func onPhotoReady() {
        if viewController is StartupViewController {
            let startupViewController = self.viewController as! StartupViewController
            startupViewController.showDroneConnected()
        }
    }
    
    func onFileListRefresh() {
        let mediaManager = self.mediaHandler.fetchMediaManager()
        
        if viewController is StartupViewController {
            let startupViewController = self.viewController as! StartupViewController
            startupViewController.setPreFlightImageCount(imageCount: (mediaManager.sdCardFileListSnapshot()?.count)!)
        } else if self.viewController is FlightPlanViewController {
            let flightPlanViewController = self.viewController as! FlightPlanViewController
            flightPlanViewController.setPreFlightImageCount(imageCount: (mediaManager.sdCardFileListSnapshot()?.count)!)
        } else if self.viewController is FlightDownloadViewController {
            let flightDownloadViewController = self.viewController as! FlightDownloadViewController
            flightDownloadViewController.setTotalImageCount(totalFileCount: (mediaManager.sdCardFileListSnapshot()?.count)!)
        }
        
        self.mediaHandler.setCameraToPhotoShoot()
    }
    
    func onError(error: Error?) {
        let alert = UIAlertController(title: "Error", message: error?.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.viewController.present(alert, animated: true, completion: nil)
    }
}
