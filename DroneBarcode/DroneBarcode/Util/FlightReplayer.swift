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
    
    /// Please use relative time measured in nanoseconds for the flight recorder.
    init(commands attitudes: [FlightRecorder.Measurement]) {
        self.commands = attitudes
    }
    
    /// Creates an angle-based pitch/roll/yaw command to send to the drone.
    private func createCommand(from measurement: FlightRecorder.Measurement) -> DJIVirtualStickFlightControlData {
        return DJIVirtualStickFlightControlData(pitch: measurement.attitude!.pitch, roll: measurement.attitude!.roll, yaw: measurement.attitude!.yaw, verticalThrottle: 0)
    }
    
    func executeCommandQueue(controller flightController: DJIFlightController,  callback done: @escaping () -> Void) {
        DispatchQueue.global(qos: .default).async {
            for i in 0...self.commands.count - 1 {
                let command = self.createCommand(from: self.commands[i])
                flightController.send(command, withCompletion: {(err) in
                    if err != nil {
                        print(err.debugDescription)
                    }
                })
                
                if i != self.commands.count - 1 {
                    usleep(useconds_t((self.commands[i+1].time - self.commands[i].time) / 1000)) // microseconds, not nano
                }
            }
            done()
        }
    }
    
}
