//
//  TrackManager.swift
//  DroneBarcode
//
//  Created by nick on 10/19/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import Foundation


class TrackManager {
    private var track: FlightTrack? = nil
    private var shouldCancel: Bool = false
    private var messageCallback: ((String?) -> Void)? = nil
    
    init(track flightTrack: FlightTrack?, callback msgCallback: ((String?) -> Void)?) {
        self.track = flightTrack
        self.messageCallback = msgCallback
    }
    
    /// Start executing each step in the track one by one.
    func startTrackExecution() {
        if !self.shouldCancel {
            executePerpetual()
        }
    }
    
    private func executePerpetual() {
        if self.shouldCancel { return }
        self.track?.executeNext(completionCallback: { (msg) in
            self.messageCallback?(msg)
            self.executePerpetual()
        })
    }
    
    /// Attempts to cancel the current track. This should not be used as an emergency stop.
    /// Use the controller for that.
    func requestCancelTrackExecution() {
        self.shouldCancel = true
    }
    
    /// Calculates the stick inputs required to fly the track.
    private func calculateTrackMovements() {
        
    }
}
