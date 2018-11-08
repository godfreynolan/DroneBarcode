//
//  FlightTrack.swift
//  DroneBarcode
//  Manages a track of
//
//  Created by nick on 10/19/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import Foundation
import DJISDK

public class FlightTrack {
    private var queue: [DJIVirtualStickFlightControlData]
    private let controller: DJIFlightController
    private var isExecuting: Bool
    
    init(commands cmdList: [DJIVirtualStickFlightControlData], controller c: DJIFlightController) {
        self.queue = cmdList
        self.controller = c
        self.isExecuting = false
    }
    
    /// Push a command to the end of the track's queue
    public func enqueueCommand(_ command: DJIVirtualStickFlightControlData) {
        self.queue.append(command)
    }
    
    /// Insert a command at a given index in the queue. Does not perform safety checks.
    public func insertCommand(_ command: DJIVirtualStickFlightControlData, index at: Int) {
        self.queue.insert(command, at: at)
    }
    
    public func canExecuteNext() -> Bool {
        return (!self.isExecuting) && self.queue.count > 0
    }
    
    /// Execute the next command in the queue, with an optional callback. Does not perform safety checks.
    public func executeNext(completionCallback extraCallback: ((String?) -> Void)?)  {
        let action = self.queue.remove(at: 0)
        self.isExecuting = true
        self.controller.send(action) { (err) in
            self.isExecuting = false
            if(err == nil) {
                extraCallback?(nil)
            } else {
                extraCallback?(err!.localizedDescription)
            }
        }
    }
}
