//
//  Utils.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/23/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import DJISDK

class Utils {
    static func metersToFeet(_ meters: Double) -> Double {
        return 3.28084 * meters
    }
}
