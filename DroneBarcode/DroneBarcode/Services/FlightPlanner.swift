//
//  FlightPlanner.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 3/23/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import DJISDK

class FlightPlanner {
    func createMission(missionCoordinates: [CLLocationCoordinate2D]) -> DJIWaypointMission {
        let mission = DJIMutableWaypointMission()
        mission.maxFlightSpeed = 8
        mission.autoFlightSpeed = 4
        mission.finishedAction = .goHome
        mission.headingMode = .usingWaypointHeading
        mission.flightPathMode = .normal
        mission.rotateGimbalPitch = true
        mission.exitMissionOnRCSignalLost = true
        mission.gotoFirstWaypointMode = .safely
        
        // TODO Explore other flight plans. Don't want to do a zig-zag
        for coordinate in missionCoordinates {
            mission.add(createWaypoint(coordinate: coordinate, altitude: 1))
            mission.add(createWaypoint(coordinate: coordinate, altitude: 2))
            mission.add(createWaypoint(coordinate: coordinate, altitude: 3))
        }
        
        return DJIWaypointMission(mission: mission)
    }
    
    private func createWaypoint(coordinate: CLLocationCoordinate2D, altitude: Float) -> DJIWaypoint {
        let lowWaypoint = DJIWaypoint(coordinate: coordinate)
        lowWaypoint.altitude = altitude
        lowWaypoint.heading = 0
        lowWaypoint.actionRepeatTimes = 1
        lowWaypoint.actionTimeoutInSeconds = 30
        lowWaypoint.turnMode = .clockwise
        lowWaypoint.add(DJIWaypointAction(actionType: .rotateGimbalPitch, param: 0))
//        lowWaypoint.add(DJIWaypointAction(actionType: .shootPhoto, param: 0))
        lowWaypoint.gimbalPitch = 0
        
        return lowWaypoint
    }
}
