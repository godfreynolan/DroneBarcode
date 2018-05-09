//
//  DownloadCallback.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/26/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import UIKit

protocol DownloadCallback {
    func onDownloadError(error: Error?)
    func onDownloadSuccess(image: UIImage)
}
