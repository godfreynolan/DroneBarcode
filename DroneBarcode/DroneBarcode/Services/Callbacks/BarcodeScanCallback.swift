//
//  BarcodeScanCallback.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/26/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import UIKit
import CoreGraphics

protocol BarcodeScanCallback {
    func onError(error: Error?)
    func onScanSuccess(rect: CGRect, color: UIColor)
}
