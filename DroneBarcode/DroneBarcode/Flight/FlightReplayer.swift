//
//  FlightReplayer.swift
//  DroneBarcode
//
//  Replays a list of attitude commands given by a FlightRecorder
//  Created by nick on 10/24/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import Foundation
import DJISDK

class FlightReplayer {
    
    private var commands: [FlightRecorder.Measurement]
    
    /// Please use time measured in nanoseconds for the flight recorder measurements.
    /// Measurements use monotonic time and be in order.
    init(commands attitudes: [FlightRecorder.Measurement]) {
        self.commands = attitudes
    }
    
    /// Creates an angle-based pitch/roll/yaw command to send to the drone.
    private func createCommand(from measurement: FlightRecorder.Measurement) -> DJIVirtualStickFlightControlData {
        print("PITCH \(measurement.attitude!.pitch) ROLL \(measurement.attitude!.roll) YAW \(measurement.attitude!.yaw)")
        return DJIVirtualStickFlightControlData(pitch: measurement.attitude!.pitch, roll: measurement.attitude!.roll, yaw: measurement.attitude!.yaw, verticalThrottle: -1 * measurement.altitude!)
    }
    
    func executeCommandQueue(controller flightController: DJIFlightController, cameraGimbal gimbal: DJIGimbal,  callback done: @escaping () -> Void) {
        DispatchQueue.global(qos: .default).async {
            for i in 0...self.commands.count - 1 {
                switch self.commands[i].type {
                case .camera:
                    self.executeCameraAction(from: self.commands[i], cameraGimbal: gimbal)
                    break
                case .attitude:
                    self.executeAttitudeAltitudeAction(from: self.commands[i], controller: flightController)
                    break
                case .joystick:
                    break
                }
                
                if i != self.commands.count - 1 {
                    usleep(useconds_t((self.commands[i+1].time - self.commands[i].time) / 1000))
                }
            }
            done()
        }
    }
    
    @inline(__always) private func executeCameraAction(from measurement: FlightRecorder.Measurement, cameraGimbal gimbal: DJIGimbal){
        let pitch = NSNumber(value: measurement.attitude!.pitch)
        let roll = NSNumber(value: measurement.attitude!.roll)
        let yaw = NSNumber(value: measurement.attitude!.yaw)
        let rotation = DJIGimbalRotation(pitchValue: pitch, rollValue: roll, yawValue: yaw, time: TimeInterval(1.0), mode: .absoluteAngle)
        gimbal.rotate(with: rotation, completion: { (err) in
            if err != nil {
                print("Error rotating gimbal: " + err.debugDescription)
            }
        })
    }
    
    @inline(__always) private func executeAttitudeAltitudeAction(from measurement: FlightRecorder.Measurement, controller fc: DJIFlightController) {
        fc.send(self.createCommand(from: measurement), withCompletion: {(err) in
            if err != nil {
                print("Error executing: " + err.debugDescription)
            }
        })
    }
    
    
}
