//
//  ImageDownloader.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/26/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import DJISDK
import Foundation

class ImageDownloader {
    private var callback: DownloadCallback!
    
    init(callback: DownloadCallback) {
        self.callback = callback
    }
    
    func downloadImage(file: DJIMediaFile) {
        let isPhoto = file.mediaType == .JPEG || file.mediaType == .TIFF;
        if (!isPhoto) {
            return
        }
        
        var mutableData: Data? = nil
        var previousOffset = 0
        
        file.fetchData(withOffset: UInt(previousOffset), update: DispatchQueue.main, update: { (data, isComplete, error) in
            if (error != nil) {
                self.callback.onDownloadError(error: error)
                return
            }
            
            if (mutableData == nil) {
                mutableData = data
            } else {
                mutableData?.append(data!)
            }
            
            previousOffset += (data?.count)!;
            if (previousOffset == file.fileSizeInBytes && isComplete) {
                let image = UIImage(data: mutableData!)
                self.callback.onDownloadSuccess(image: image!)
            }
        })
    }
}
