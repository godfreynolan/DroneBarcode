//
//  MediaHandler.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/19/18.
//  Copyright © 2018 DJI. All rights reserved.
//

import DJISDK
import UIKit

class MediaHandler {
    private var isFirstAttempt = true
    private var camera: DJICamera!
    private var callback: CameraCallback!
    
    init(callback: CameraCallback, camera: DJICamera) {
        self.callback = callback
        self.camera = camera
    }
    
    // ### Camera Modes ###
    func setCameraToDownload() {
        self.camera.setMode(.mediaDownload, withCompletion: { (error) in
            if (error != nil) {
                if self.isFirstAttempt {
                    self.isFirstAttempt = false
                    self.setCameraToDownload()
                } else {
                    self.isFirstAttempt = true
                    self.callback.onError(error: error)
                }
            } else {
                self.isFirstAttempt = true
                self.callback.onDownloadReady()
            }
        })
    }
    
    func setCameraToPhotoShoot() {
        self.camera.setMode(.shootPhoto, withCompletion: { (error) in
            if (error != nil) {
                self.callback.onError(error: error)
            } else {
                self.callback.onPhotoReady()
            }
        })
    }
    
    // ### MediaManager state ###
    func retrieveMediaFiles() {
        if (self.fetchMediaManager().sdCardFileListState == .syncing || self.fetchMediaManager().sdCardFileListState == .deleting) {
            self.callback.onError(error: nil)
        } else {
            self.camera.mediaManager?.refreshFileList(of: .sdCard, withCompletion: { (error) in
                if (error != nil) {
                    self.callback.onError(error: error)
                } else {
                    self.callback.onFileListRefresh()
                }
            })
        }
    }
    
    // ### Helpers ###
    func fetchMediaManager() -> DJIMediaManager {
        return (self.camera.mediaManager)!
    }
}

