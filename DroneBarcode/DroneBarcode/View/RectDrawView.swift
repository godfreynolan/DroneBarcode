//
//  RectDrawView.swift
//  DroneBarcode
//
//  Created by nick on 11/1/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import UIKit

class RectDrawView: UIView {
    
    private let GREEN_TARGET = UIImage(named: "target-green")
    private let RED_TARGET = UIImage(named: "target-red")
    
    var rectangles: [ColoredRect] = []
    private var hasAddedTarget = false
    var targetImage: UIImageView? = nil

    public struct ColoredRect {
        var rect: CGRect
        var color: UIColor
    }
    
    public func addTarget() {
        if !hasAddedTarget {
            self.targetImage = UIImageView(image: self.RED_TARGET)
            targetImage!.contentMode = .scaleAspectFit
            targetImage!.alpha = 0.85
            targetImage!.frame = CGRect(x: (self.frame.width / 2) - 100, y: (self.frame.height / 2) - 100, width: 200, height: 200)
            self.addSubview(self.targetImage!)
            self.hasAddedTarget = true
        }
    }
    
    public func addRectangle(rect: CGRect, color: UIColor) {
        self.clearRectangles()
        self.rectangles.append(ColoredRect(rect: rect, color: color))
        print("rect/target overlap: \(calculateOverlap(first: rect, second: targetImage!.frame)), target/rect overlap: \(calculateOverlap(first: targetImage!.frame, second: rect))")
//        if calculateOverlap() > 0.8 {
//            targetImage!.image = GREEN_TARGET
//        } else {
//            targetImage!.image = RED_TARGET
//        }
        self.setNeedsDisplay()
    }
    
    public func clearRectangles() {
        self.rectangles = []
        self.setNeedsDisplay()
    }

    // Returns the percentage of first that is overlapped by second.
    private func calculateOverlap(first: CGRect, second: CGRect) -> Float {
        let secondArea = abs(second.maxX - second.minX) * abs(second.maxY - second.minY)
        let intersectionArea = (min(first.maxX, second.maxX) - max(first.minX, second.minX)) * (min(first.maxY, second.maxY) - max(first.minY, second.minY))
        return Float(intersectionArea / secondArea)
    }

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
        // draw the rectangles
        for r in self.rectangles {
            let path = UIBezierPath(rect: r.rect)
            r.color.set()
            path.stroke()
        }
    }
    
    private func rectanglesOverlap(_ first: CGRect, _ second: CGRect) -> Bool{
        return (first.minX < second.maxX && first.maxX > second.minX && first.minY < second.maxY && first.maxY > second.minY)
    }

}
