//
//  CameraCallback.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/19/18.
//  Copyright © 2018 DJI. All rights reserved.
//

protocol CameraCallback {
    func onDownloadReady()
    func onPhotoReady()
    func onFileListRefresh()
    func onError(error: Error?)
}

