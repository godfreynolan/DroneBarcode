//
//  FlightControlCallback.swift
//  DroneBarcode
//
//  Created by Tom Kocik on 5/3/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

protocol FlightControlCallback {
    func onCommandSuccess()
    func onError(error: Error?)
}
