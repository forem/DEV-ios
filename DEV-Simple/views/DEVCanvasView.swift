//
//  DEVCanvasView.swift
//  DEV-Simple
//
//  Created by Jacob Boyd on 7/3/19.
//  Copyright © 2019 DEV. All rights reserved.
//

import UIKit

class DEVCanvasView: UIView {
    var startingPoint: CGPoint!
    var touchPoint: CGPoint!
    var path: UIBezierPath!
    var strokeColor: CGColor! = UIColor(red: 244/255, green: 144/255, blue: 142/255, alpha: 1).cgColor
    
    func setStrokeColor(_ color: UIColor) {
        self.strokeColor = color.cgColor
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        startingPoint = touch?.location(in: self)
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first
        touchPoint = touch?.location(in: self)
        
        path = UIBezierPath()
        path?.move(to: startingPoint)
        path?.addLine(to: touchPoint)
        startingPoint = touchPoint
        drawShapeLayer()
    }

    private func drawShapeLayer() {
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath
        shapeLayer.strokeColor = strokeColor
        shapeLayer.lineWidth = 3
        shapeLayer.fillColor = UIColor.clear.cgColor
        self.layer.addSublayer(shapeLayer)
        self.setNeedsDisplay()
    }
    
}
