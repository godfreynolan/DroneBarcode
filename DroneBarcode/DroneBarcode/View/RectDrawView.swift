//
//  RectDrawView.swift
//  DroneBarcode
//
//  Created by nick on 11/1/18.
//  Copyright © 2018 Tom Kocik. All rights reserved.
//

import UIKit

class RectDrawView: UIView {
    
    var rectangles: [ColoredRect] = []

    public struct ColoredRect {
        var rect: CGRect
        var color: UIColor
    }
    
    public func addRectangle(rect: CGRect, color: UIColor) {
        for (i, _) in rectangles.enumerated() {
            if rectangles[i].color == color {
                rectangles[i] = ColoredRect(rect: rect, color: color)
                self.setNeedsDisplay()
                return
            }
        }

        self.rectangles.append(ColoredRect(rect: rect, color: color))
        self.setNeedsDisplay()
    }
    
    public func clearRectangles() {
        self.rectangles = []
        self.setNeedsDisplay()
    }
    
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
        // draw the rectangles
        for r in self.rectangles {
            if r.color == .blue {
                print("APPLE x1 = \(r.rect.minX) y1 - \(r.rect.minY)")
            } else {
                print("GOOGLE x1 = \(r.rect.minX) y1 - \(r.rect.minY)")
            }
            let path = UIBezierPath(rect: r.rect)
            r.color.set()
            path.stroke()
        }
    }

}
