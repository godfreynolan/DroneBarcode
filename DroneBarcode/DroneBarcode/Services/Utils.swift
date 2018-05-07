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
    
    static func convertSpacingFeetToDegrees(_ spacingFeet:Double) -> Double {
        // SpacingFeet / 3280.4 converts feet to kilometers
        // Kilometers / (10000/90) converts kilometers to lat/long distance
        return (spacingFeet / 3280.4) / (10000/90)
    }
    
    static func getTurnAroundFlightCommand(_ yaw: Double) -> DJIVirtualStickFlightControlData {
        return DJIVirtualStickFlightControlData(pitch: 0, roll: 0, yaw: Float(yaw), verticalThrottle: 0)
    }
    
    static func getPitchFlightCommand(_ pitch: Double, _ yaw: Double) -> DJIVirtualStickFlightControlData {
        var data = getTurnAroundFlightCommand(yaw)
        data.pitch = Float(pitch)
        return data
    }
}
