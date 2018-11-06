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
    
    private static let QR_TARGET_THRESHOLD: Float = 0.55
    
    weak var delegate: PositionMonitorDelegate?
    
    private var flightController: DJIFlightController!
    
    private var qrIsTargeted: Bool = false
    private var isRecentering: Bool = false
    private var qrRect: CGRect
    private let targetRect: CGRect
    private var targetingCompleteCallback: (() -> Void)? = nil

    init(qr qr_rect: CGRect, target target_rect: CGRect, flightController fc: DJIFlightController) {
        self.qrRect = qr_rect
        self.targetRect = target_rect
        self.flightController = fc
    }
    
    func startRecentering() {
        self.isRecentering = true
    }
    
    func startRecentering(withCompletion: @escaping () -> Void) {
        self.isRecentering = true
        self.targetingCompleteCallback = withCompletion
    }
    
    func stopRecentering() {
        self.isRecentering = false
    }
    
    func isPositioned() -> Bool {
        return self.qrIsTargeted
    }
    
    func updateQRPosition(_ qrRect: CGRect) {
        self.qrRect = qrRect
        
        if !self.isRecentering { return }
        
        let intersect = calculateOverlap(first: self.targetRect, second: self.qrRect)
        let coverage = calculateOverlap(first: self.qrRect, second: self.targetRect)
        
        // Check if inside/outside boundaries are met, then send update.
        self.qrIsTargeted = intersect >= 1.0 && coverage >= PositionMonitor.QR_TARGET_THRESHOLD
        print("Running if statement")
        if !self.qrIsTargeted {
            self.delegate?.directionHelper(getDirectionHelper(intersect: intersect, coverage: coverage))
        } else {
            self.targetingCompleteCallback?()
            self.targetingCompleteCallback = nil
            self.delegate?.directionHelper([])
        }
        self.delegate?.positionMonitorStatusUpdated(self.qrIsTargeted)
    }
    
    private func getDirectionHelper(intersect: Float, coverage: Float) -> [Direction] {
        let targetArea = getArea(self.targetRect)
        let qrArea = getArea(self.qrRect)
        
        // Up and down , return early so we have the right area first.
        if (qrArea / targetArea >= 0.88) {
            return [.up] //get further away
        } else if (qrArea / targetArea <= PositionMonitor.QR_TARGET_THRESHOLD) {
            return [.down] // Get closer
        }

        // Forward and backwards
        if (self.qrRect.minY > self.targetRect.minY) && (self.qrRect.maxY > self.targetRect.maxY) {
            return [.back]
        } else if (self.qrRect.minY < self.targetRect.minY) && (self.qrRect.maxY < self.targetRect.maxY) {
            return [.forward]
        }
        
        // Left and right
        if (self.qrRect.minX > self.targetRect.minX) && (self.qrRect.maxX > self.targetRect.maxX){
            return [.right]
        } else if (self.qrRect.minX < self.targetRect.maxX) && (self.qrRect.maxX < self.targetRect.maxX) {
            return [.left]
        }
        
        return []
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
