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
    
    private var callback: FlightControlCallback!
    private var flightController: DJIFlightController!
    
    init(flightController: DJIFlightController, callback: FlightControlCallback) {
        self.flightController = flightController
        self.callback = callback
        flightController.setVirtualStickModeEnabled(true) { (err) in
            if err == nil {
                print("Virtual stick mode enabled.")
            } else {
                print("Error enabling virutal stick mode: ", err.debugDescription)
            }
        }
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
    
    func turn() {
        if self.isInitialHeading {
            self.currentYaw = self.turnAroundYaw
        } else {
            self.currentYaw = self.initialYaw
        }
        
        self.isInitialHeading = !self.isInitialHeading
        
        self.turnTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: (#selector(turnDroneCommand)), userInfo: nil, repeats: true)
    }
    
    @objc func turnDroneCommand() {
        self.turnTime += 1
        
        let data = Utils.getTurnAroundFlightCommand(self.currentYaw)
        
        self.flightController.send(data, withCompletion: { (error) in
            if error != nil {
                self.callback.onError(error: error)
            }
        })
        
        if self.turnTime >= 7 {
            self.turnTimer?.invalidate()
            self.turnTime = 0
            self.callback.onCommandSuccess()
        }
    }
    
    func changePitch() {
        let data = Utils.getPitchFlightCommand(0.5, self.currentYaw)
        
        self.flightController.send(data, withCompletion: { (error) in
            if error != nil {
                self.callback.onError(error: error)
            }
        })
        // There are other scheduledTimer methods, but they do not appear to work as consistently as this one
//        self.pitchTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: (#selector(pitchDroneCommand)), userInfo: nil, repeats: true)
    }
    
    @objc func pitchDroneCommand() {
        self.pitchTime += 0.2
        
        // Pitch controls left/right. Positive pitch values go right. Range is -15 to 15
        // Roll controlls forward/backward. Positive values go forward. Range is -15 to 15
        let data = Utils.getPitchFlightCommand(0.5, self.currentYaw)
        
        self.flightController.send(data, withCompletion: { (error) in
            if error != nil {
                self.callback.onError(error: error)
            }
        })
        
        if self.pitchTime >= 1 {
            self.pitchTimer?.invalidate()
            self.pitchTime = 0.0
            self.callback.onCommandSuccess()
        }
    }
    
    func changeAltitude() {
        let data = DJIVirtualStickFlightControlData(pitch: 0, roll: 0, yaw: Float(self.currentYaw), verticalThrottle: Float(0.5))
        
        self.flightController?.send(data, withCompletion: { (error) in
            if error != nil {
                self.callback.onError(error: error)
            }
        })
    }
}
