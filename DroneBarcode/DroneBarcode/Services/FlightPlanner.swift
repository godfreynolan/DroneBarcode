//
//  FlightPlanner.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/23/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import DJISDK

class FlightPlanner {
    private var isInitialHeading = true
    
    private var initialYaw = 0.0
    private var turnAroundYaw = 180.0
    private var currentYaw = 0.0
    
    private var turnTime = 0
    private var turnTimer: Timer? = nil
    
    private var pitchTime = 0.0
    private var pitchTimer: Timer? = nil
    
    private var callbackTimes: [UInt64] = []
    
    private var callback: FlightControlCallback!
    private var flightController: DJIFlightController!
    
    init(flightController: DJIFlightController, callback: FlightControlCallback) {
        self.flightController = flightController
        self.callback = callback
    }
    
    func setUpParameters(initialYaw: Double) {
        self.initialYaw = initialYaw
        self.currentYaw = initialYaw
        
        if self.initialYaw > 0 {
            self.turnAroundYaw = self.initialYaw - 180
        } else {
            self.turnAroundYaw = self.initialYaw + 180
        }
    }

    func logTime(_ time: UInt64) {
        self.callbackTimes.append(time)
    }
    
    func saveTimes() {
        Benchmark.saveTimesToDataFile(self.callbackTimes, file: "nanosecond-times.txt")
    }
}
