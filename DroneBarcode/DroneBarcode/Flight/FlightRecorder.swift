//
//  FlightRecorder.swift
//  DroneBarcode
//
//  Records Joystick inputs for a drone flight and converts them to the cinema-mode speed range.
//
//  Created by nick on 10/23/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import Foundation
import DJISDK

class FlightRecorder {
    
    private var isRecording = false
    private var measurements: [Measurement]
    private var initialTime: UInt64
    
    init() {
        self.measurements = []
        self.initialTime = mach_absolute_time()
    }

    enum JoystickSide {
        case left, right
    }
    
    public enum MeasurementType {
        case joystick
        case attitude
        case camera
    }
    
    public struct Attitude {
        var pitch: Float
        var yaw: Float
        var roll: Float
    }

    public struct Measurement {
        var type: MeasurementType
        var time: UInt64
        var attitude: Attitude? = nil
        var altitude: Float? = nil
        var left_h: Float? = nil
        var left_v: Float? = nil
        var right_h: Float? = nil
        var right_v: Float? = nil
        
        init(type measurementType: MeasurementType, time measurementTime: UInt64) {
            self.type = measurementType
            self.time = measurementTime
            self.attitude = nil
            self.altitude = nil
            self.left_h = nil
            self.left_v = nil
            self.right_h = nil
            self.right_v = nil
        }

        /// Converts the time units from the mach_absolute_time to elapsed nanoseconds relative to given value.
        mutating func convertToRelativeTime(_ relativeTo: UInt64) -> Measurement {
            let elapsed = self.time - relativeTo
            var timebaseInfo = mach_timebase_info_data_t()
            mach_timebase_info(&timebaseInfo)
            let elapsedNano = elapsed * UInt64(timebaseInfo.numer) / UInt64(timebaseInfo.denom)
            self.time = elapsedNano
            return self
        }
    }
    
    func isRecordingActive() -> Bool { return self.isRecording }
    
    func startMeasurements() {
        self.initialTime = mach_absolute_time()
        usleep(200000)
        self.isRecording = true
    }
    
    /// Append a timestamped joystick value to the list.
    func addJoystickMeasurement(_ left_h: Float, _ left_v: Float, _ right_h: Float, _ right_v: Float) {
        if !isRecording { return }
        var m = Measurement(type: .joystick, time: mach_absolute_time())
        m.left_v = left_v
        m.left_h = left_h
        m.right_v = right_v
        m.right_h = right_h
        measurements.append(m)
    }
    
    func getMeasurements() -> [Measurement] { return self.measurements }
    
    /// Append a timestamped attitude measurement to the list
    func addAttitudeMeasurement(pitch: Float, yaw: Float, roll: Float) {
        if !isRecording { return }
        let att = Attitude(pitch: pitch, yaw: yaw, roll: roll)
        var m = Measurement(type: .attitude, time: mach_absolute_time())
        m.attitude = att
        measurements.append(m)
    }
    
    func addCameraMeasurement(pitch: Float, yaw: Float, roll: Float) {
        if !isRecording { return }
        let att = Attitude(pitch: pitch, yaw: yaw, roll: roll)
        var m = Measurement(type: .camera, time: mach_absolute_time())
        m.attitude = att
        measurements.append(m)
    }
    
    func addAttitudeAltitudeMeasurement(pitch: Float, yaw: Float, roll: Float, altitude: Float) {
        if !isRecording { return }
        let att = Attitude(pitch: pitch, yaw: yaw, roll: roll)
        var m = Measurement(type: .attitude, time: mach_absolute_time())
        m.attitude = att
        m.altitude = altitude
        measurements.append(m)
    }
    
    /// Stop measuring and finalize the measurements by calculating time relatively.
    func finalizeMeasurements() {
        self.isRecording = false
        if measurements.count == 0 { return }
        for i in 0...measurements.count - 1{
            measurements[i] = measurements[i].convertToRelativeTime(self.initialTime)
        }
    }
    
    func resetMeasurements() {
        self.isRecording = false
        self.measurements = []
    }
    
    func saveFile(with name: String = "flightplan.csv") {
        var outStr = "time,type,left_h,left_v,right_h,right_v,pitch,roll,yaw\n"
        for m in measurements {
            switch m.type {
            case .joystick:
                outStr += String(m.time) + ",joy," + String(m.left_h!) + "," + String(m.left_v!) + "," + String(m.right_h!) + "," + String(m.right_v!) + ",,,"
                break
            case .attitude:
                outStr += String(m.time) + ",att,,,,," + String(m.attitude!.pitch) + "," + String(m.attitude!.roll) + "," + String(m.attitude!.yaw)
                break
            case .camera:
                outStr += String(m.time) + ",cam,,,,," + String(m.attitude!.pitch) + "," + String(m.attitude!.roll) + "," + String(m.attitude!.yaw)
            }
            outStr += "\n"
        }
        
        if let dir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, .allDomainsMask, true).first {
            let path = dir + "/" + name
            print("Saving to " + path)
            do {
                try outStr.write(toFile: path, atomically: false, encoding: .utf8)
                print("Wrote to file.")
            } catch {
                print("Could not save!")
            }
        } else {
            print("Could not get directory!")
        }
    }
    
    private func mapTo(_ value: Float, _ oldmin: Float, _ oldmax: Float, _ newmin: Float, _ newmax: Float) -> Float {
        let oldRange = oldmax - oldmin
        let newRange = newmax - newmin
        return (((value - oldmin) * newRange) / oldRange) + newmin
    }

}
