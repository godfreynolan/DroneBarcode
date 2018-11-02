//
//  PositionMonitor.swift
//  DroneBarcode
//
//  Monitors and corrects the drone's position relative to
//  the locations of the qr code and target.
//  Created by nick on 11/2/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import Foundation
import CoreGraphics
import DJISDK

public enum Direction {
    case left, right, up, down
    case forward, back
}

public protocol PositionMonitorDelegate: class {
    /// qrIsTargeted is true if it is correctly targeted
    func positionMonitorStatusUpdated(_ qrIsTargeted: Bool) -> Void
    
    /// Provides a list of directions that the qr code needs to move to be correctly targeted
    func directionHelper(_ directions: [Direction])
}

public class PositionMonitor {
    
    private static let QR_TARGET_THRESHOLD: Float = 0.60
    
    weak var delegate: PositionMonitorDelegate?
    
    private var flightController: DJIFlightController!
    
    private var qrIsTargeted: Bool = false
    private var qrRect: CGRect
    private let targetRect: CGRect

    init(qr qr_rect: CGRect, target target_rect: CGRect, flightController fc: DJIFlightController) {
        self.qrRect = qr_rect
        self.targetRect = target_rect
        self.flightController = fc
    }
    
    func updateQRPosition(_ qrRect: CGRect) {
        self.qrRect = qrRect
        let intersect = calculateOverlap(first: self.targetRect, second: self.qrRect)
        let coverage = calculateOverlap(first: self.qrRect, second: self.targetRect)
        
        // Check if inside/outside boundaries are met, then send update.
        self.qrIsTargeted = intersect >= 1.0 && coverage >= PositionMonitor.QR_TARGET_THRESHOLD
        if !self.qrIsTargeted {
            self.delegate?.directionHelper(getDirectionHelper(intersect: intersect, coverage: coverage))
        } else {
            self.delegate?.directionHelper([])
        }
        self.delegate?.positionMonitorStatusUpdated(self.qrIsTargeted)
    }
    
    private func getDirectionHelper(intersect: Float, coverage: Float) -> [Direction] {
        var directions: [Direction] = []
        
        let minXDiff = self.qrRect.minX - self.targetRect.minX
        let minYDiff = self.qrRect.minY - self.targetRect.minY
        let maxXDiff = self.qrRect.maxX - self.targetRect.maxX
        let maxYDiff = self.qrRect.maxY - self.targetRect.maxY
        
        // Forward and backwards
        if (minXDiff >= 25 && maxXDiff <= -25) || (minYDiff >= 25 && maxYDiff <= -25) {
            directions.append(.up)
        } else if (getArea(self.targetRect) <= getArea(self.qrRect)) {
            directions.append(.down)
        }
        
        // Up and down
        if (self.qrRect.minY < self.targetRect.maxY) && (self.qrRect.maxY > self.targetRect.maxY) {
            directions.append(.back)
        } else if (self.qrRect.minY < self.targetRect.minY) && (self.qrRect.maxY > self.targetRect.minY) {
            directions.append(.forward)
        }

        // Left and right
        if (self.qrRect.minX < self.targetRect.minX) && (self.qrRect.maxX > self.targetRect.minX) {
            directions.append(.left)
        } else if (self.qrRect.minX < self.targetRect.maxX) && (self.qrRect.maxX > self.targetRect.maxX) {
            directions.append(.right)
        }
        
        return directions
    }
    
    private func getArea(_ rect: CGRect) -> Float {
        return Float((rect.maxX - rect.minX) * (rect.maxY - rect.minY))
    }

    // Returns the percentage of first that is overlapped by second.
    private func calculateOverlap(first: CGRect, second: CGRect) -> Float {
        let secondArea = abs(second.maxX - second.minX) * abs(second.maxY - second.minY)
        let intersectionArea = (min(first.maxX, second.maxX) - max(first.minX, second.minX)) * (min(first.maxY, second.maxY) - max(first.minY, second.minY))
        return Float(intersectionArea / secondArea)
    }
    
    /// TODO: Remove if unused.
    private func doRectanglesOverlap(_ first: CGRect, _ second: CGRect) -> Bool{
        return (first.minX < second.maxX && first.maxX > second.minX && first.minY < second.maxY && first.maxY > second.minY)
    }
    
}
