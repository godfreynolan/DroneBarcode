//
//  LeggedFlightRecorder.swift
//  DroneBarcode
//
//  Created by nick on 11/6/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import Foundation

class LeggedFlightRecorder {
    private var recorder: FlightRecorder!
    private var legs: [[FlightRecorder.Measurement]]
    
    init() {
        self.recorder = FlightRecorder()
        self.legs = []
    }
   
    func startRecordingLeg() {
        //self.recorder.finalizeMeasurements()
        self.recorder.resetMeasurements()
        self.recorder.startMeasurements()
    }
    
    func finishRecordingLeg() {
        self.recorder.finalizeMeasurements()
        let leg = recorder.getMeasurements()
        legs.append(leg)
    }
    
    func getLegs() -> [[FlightRecorder.Measurement]] {
        return self.legs
    }
    
    func isRecording() -> Bool {
        return self.recorder.isRecordingActive()
    }
    
    func addAttitudeMeasurement(pitch: Float, yaw: Float, roll: Float, vs: Float) {
        self.recorder.addAttitudeAltitudeMeasurement(pitch: pitch, yaw: yaw, roll: roll, altitude: vs)
    }
    
    func addCameraMeasurement(pitch: Float, yaw: Float, roll: Float) {
        self.recorder.addCameraMeasurement(pitch: pitch, yaw: yaw, roll: roll)
    }
}
