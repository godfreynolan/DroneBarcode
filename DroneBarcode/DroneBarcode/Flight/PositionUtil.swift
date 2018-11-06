//
//  PositionUtil.swift
//  DroneBarcode
//
//  Created by nick on 11/5/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import Foundation
import DJISDK

class PositionUtil {
    /// MAKE SURE to set isOnWall correctly! Also MAKE SURE the control modes for VirtualStick is right too.
    static func translateDirectionToCommand(_ direction: Direction, isOnWall: Bool, verticalSpeed: Float, horizontalSpeed: Float) -> DJIVirtualStickFlightControlData {

        return getFloorTranslation(direction, verticalSpeed: verticalSpeed, horizontalSpeed: horizontalSpeed)
//        if isOnWall {
//            return getWallTranslation(direction, verticalSpeed: verticalSpeed, horizontalSpeed: horizontalSpeed)
//        } else {
//        }
    }
    
    static func translateFloorDirectionToWall(_ direction: Direction) -> Direction {
        switch direction {
        case .left, .right:
            return direction
        case .up:
            return .forward
        case .down:
            return .back
        case .forward:
            return .up
        case .back:
            return .down
        }
    }

    private static func getWallTranslation(_ direction: Direction, verticalSpeed: Float, horizontalSpeed: Float) -> DJIVirtualStickFlightControlData {
        var data = DJIVirtualStickFlightControlData(pitch: 0, roll: 0, yaw: 0, verticalThrottle: 0)
        switch direction {
        case .left:
            data.roll = -1 * horizontalSpeed
            break
        case .right:
            data.roll = horizontalSpeed
            break
        case .forward: // up
            data.verticalThrottle = verticalSpeed
            break
        case .back: // down
            data.verticalThrottle = -1 * verticalSpeed
            break
        case .up: // needs to make barcode smaller
            data.pitch = horizontalSpeed
            break
        case .down: // needs to make barcode bigger
            data.pitch = -1 * horizontalSpeed
            break
        }
    
        print("FLIGHT DATA \(data.pitch) \(data.roll) \(data.verticalThrottle) WALL")
        return data
    }

    private static func getFloorTranslation(_ direction: Direction, verticalSpeed: Float, horizontalSpeed: Float) -> DJIVirtualStickFlightControlData {
        var data = DJIVirtualStickFlightControlData(pitch: 0, roll: 0, yaw: 0, verticalThrottle: 0)
    
        switch direction {
        case .left:
            data.roll = -1 * horizontalSpeed
            break
        case .right:
            data.roll = horizontalSpeed
            break
        case .forward: // negative pitch is forward.
            data.pitch = -1 * horizontalSpeed
            break
        case .back:
            data.pitch = horizontalSpeed
            break
        case .up:
            data.verticalThrottle = verticalSpeed
            break
        case .down:
            data.verticalThrottle = -1 * verticalSpeed
            break
        }
        
        print("FLIGHT DATA \(data.pitch) \(data.roll) \(data.verticalThrottle) FLOOR ")

        return data
    }
}
