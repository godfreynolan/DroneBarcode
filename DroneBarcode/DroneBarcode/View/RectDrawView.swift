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
    
    private let LEFT_ARROW = UIImageView(image: UIImage(named: "arrow-left"))
    private let RIGHT_ARROW = UIImageView(image: UIImage(named: "arrow-right"))
    private let UP_ARROW = UIImageView(image: UIImage(named: "arrow-forward"))
    private let DOWN_ARROW = UIImageView(image: UIImage(named: "arrow-back"))
    private let FORWARD_ARROW = UIImageView(image: UIImage(named: "arrow-up"))
    private let BACK_ARROW = UIImageView(image: UIImage(named: "arrow-down"))
    
    private static let OVERLAP_AREA_THRESHOLD: Float = 0.5
    
    var rectangle: ColoredRect? = nil
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
            targetImage!.alpha = 0.65
            targetImage!.frame = CGRect(x: (self.frame.width / 2) - 75, y: (self.frame.height / 2) - 75, width: 150, height: 150)
            self.addSubview(self.targetImage!)
            self.hasAddedTarget = true
            self.initializeArrows()
        }
    }
    
    public func getTargetRect() -> CGRect {
        return targetImage!.frame
    }
    
    public func addRectangle(rect: CGRect, color: UIColor) {
        self.rectangle = ColoredRect(rect: rect, color: color)
        self.setNeedsDisplay()
    }
    
    public func setShouldBeGreenTarget(_ should: Bool) {
        if should {
            self.targetImage!.image = GREEN_TARGET
        } else {
            self.targetImage!.image = RED_TARGET
        }
        self.setNeedsDisplay()
    }

    // Returns the percentage of first that is overlapped by second.
    private func calculateOverlap(first: CGRect, second: CGRect) -> Float {
        let secondArea = abs(second.maxX - second.minX) * abs(second.maxY - second.minY)
        let intersectionArea = (min(first.maxX, second.maxX) - max(first.minX, second.minX)) * (min(first.maxY, second.maxY) - max(first.minY, second.minY))
        return Float(intersectionArea / secondArea)
    }
    
    func setHelperArrows(_ directions: [Direction]) {
        self.removeHelperArrows()
        for d in directions {
            switch d {
            case .left:
                LEFT_ARROW.isHidden = false
                break
            case .right:
                RIGHT_ARROW.isHidden = false
                break
            case .up:
                UP_ARROW.isHidden = false
                break
            case .down:
                DOWN_ARROW.isHidden = false
                break
            case .forward:
                FORWARD_ARROW.isHidden = false
                break
            case .back:
                BACK_ARROW.isHidden = false
                break
            }
        }
    }
    
    private func removeHelperArrows() {
        LEFT_ARROW.isHidden = true
        RIGHT_ARROW.isHidden = true
        UP_ARROW.isHidden = true
        DOWN_ARROW.isHidden = true
        FORWARD_ARROW.isHidden = true
        BACK_ARROW.isHidden = true
    }

    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
        super.draw(rect)
        // draw the rectangle
        if rectangle != nil {
            let path = UIBezierPath(rect: rectangle!.rect)
            rectangle!.color.set()
            path.stroke()
        }
    }
    
    private func initializeArrows() {
        let centerx = self.frame.width / 2
        let centery = self.frame.height / 2
        // Aspect scaling
        LEFT_ARROW.contentMode = .scaleAspectFit
        RIGHT_ARROW.contentMode = .scaleAspectFit
        UP_ARROW.contentMode = .scaleAspectFit
        DOWN_ARROW.contentMode = .scaleAspectFit
        FORWARD_ARROW.contentMode = .scaleAspectFit
        BACK_ARROW.contentMode = .scaleAspectFit
        
        // On screen positioning
        LEFT_ARROW.frame = CGRect(x: centerx - 240, y: centery - 20, width: 40, height: 40)
        RIGHT_ARROW.frame = CGRect(x: centerx + 200, y: centery - 20, width: 40, height: 40)
        UP_ARROW.frame = CGRect(x: centerx - 20, y: centery - 200, width: 40, height: 40)
        DOWN_ARROW.frame = CGRect(x: centerx - 20, y: centery + 200, width: 40, height: 40)
        FORWARD_ARROW.frame = CGRect(x: centerx - 20, y: centery - 100, width: 40, height: 40)
        BACK_ARROW.frame = CGRect(x: centerx - 20, y: centery + 60, width: 40, height: 40)
        
        // Hide at beginning
        self.removeHelperArrows()
        
        // Add to view.
        self.addSubview(LEFT_ARROW)
        self.addSubview(RIGHT_ARROW)
        self.addSubview(UP_ARROW)
        self.addSubview(DOWN_ARROW)
        self.addSubview(FORWARD_ARROW)
        self.addSubview(BACK_ARROW)
    }
}
