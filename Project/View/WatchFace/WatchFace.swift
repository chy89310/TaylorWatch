//
//  WatchFace.swift
//  Taylor
//
//  Created by Kevin Sum on 19/1/2018.
//  Copyright © 2018 KevinSum. All rights reserved.
//

import UIKit
import SwiftyTimer

class WatchFace: DesignableView {

    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var minuteView: UIView!
    @IBOutlet weak var minuteHand: WatchHand!
    @IBOutlet weak var hourView: UIView!
    @IBOutlet weak var hourHand: WatchHand!
    @IBOutlet var minuteRecognizer: UIPanGestureRecognizer!
    @IBOutlet var hourRecognizer: UIPanGestureRecognizer!
    
    @IBInspectable var background: UIImage?
    @IBInspectable var interactable: Bool {
        didSet {
            minuteRecognizer.isEnabled = interactable
            hourRecognizer.isEnabled = interactable
        }
    }
    var beginPoints: [WatchHand: CGPoint] = [:]
    var hour: Int = 0
    var minute: Int = 0
    var didUpdateTime: ((_ hour: Int, _ minute: Int) -> ())?
    var animateTimer: Timer?
    
    required init?(coder aDecoder: NSCoder) {
        interactable = false
        super.init(coder: aDecoder)
    }
    
    override init(frame: CGRect) {
        interactable = false
        super.init(frame: frame)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if let image = background {
            bgImageView.image = image
        }
        hour = Calendar.current.component(.hour, from: Date())
        minute = Calendar.current.component(.minute, from: Date())
        let (hourPoint, minutePoint) = updateTransform()
        beginPoints = [minuteHand: minutePoint,
                       hourHand: hourPoint]
    }
    
    func updateTransform() -> (CGPoint, CGPoint) {
        let dayMinute = CGFloat(60*hour+minute)
        let hourAngle = dayMinute*CGFloat.pi/360.0
        let minuteAngle = CGFloat(minute)*CGFloat.pi/30
        let hourPoint = CGPoint(x: sin(hourAngle)*hourHand.long, y: cos(hourAngle)*hourHand.long)
        let minutePoint = CGPoint(x: sin(minuteAngle)*minuteHand.long, y: cos(minuteAngle)*minuteHand.long)
        self.hourView.transform = CGAffineTransform(rotationAngle: hourAngle)
        self.minuteView.transform = CGAffineTransform(rotationAngle: minuteAngle)
        
        return (hourPoint, minutePoint)
    }
    
    @IBAction func didPanView(_ sender: UIPanGestureRecognizer) {
        var translation = sender.translation(in: view);
        translation = CGPoint(x: translation.x, y: -translation.y)
        if let handView = sender.view as? WatchHand, let beginPoint = beginPoints[handView] {
            let touchPoint = CGPoint(x: beginPoint.x*handView.touchScale, y: beginPoint.y*handView.touchScale)
            let point = CGPoint(x: touchPoint.x+translation.x, y: touchPoint.y+translation.y)
            var angle = atan(point.x/point.y)
            if (point.y < 0) {
                angle = CGFloat.pi-atan(point.x/abs(point.y))
            } else if (point.x < 0) {
                angle = 2*CGFloat.pi-atan(abs(point.x)/point.y)
            }
            
            // Update time
            if (handView == hourHand) {
                let hourOld = hour
                let dayminute = Int(Double(angle)*360/Double.pi)
                hour = dayminute/60
                if 11 <= abs(hourOld-hour) && abs(hourOld-hour) <= 13 {
                    hour += 12
                }
                minute = dayminute%60
            } else {
                let minuteOld = minute
                minute = Int(angle*30/CGFloat.pi)
                if abs(minute-minuteOld) > 50 {
                    if minute > minuteOld {
                        hour -= 1
                    } else {
                        hour += 1
                    }
                }
                if hour >= 24 {
                    hour -= 24
                } else if hour < 0 {
                    hour += 24
                }
            }
            // Update transform
            let (hourPoint, minutePoint) = updateTransform()
            
            if (sender.state == .ended) {
                beginPoints[hourHand] = hourPoint
                beginPoints[minuteHand] = minutePoint
                didUpdateTime?(hour, minute)
            }
        }
    }
    
    func setTime(_ time: Date) {
        hour = Calendar.current.component(.hour, from: time)
        minute = Calendar.current.component(.minute, from: time)
        UIView.animate(withDuration: 0.5) {
            let (hourPoint, minutePoint) = self.updateTransform()
            self.beginPoints = [self.minuteHand: minutePoint,
                                self.hourHand: hourPoint]
        }
    }
    
    func animate(_ animated: Bool) {
        if animated {
            animateTimer = Timer.every(1.0, {
                let hour = Int(arc4random_uniform(12))
                let minute = Int(arc4random_uniform(12))*5
                self.setTime(Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date())!)
            })
        } else {
            animateTimer?.invalidate()
        }
    }

}

class WatchHand : UIView {
    
    var touchY: CGFloat = 0
    var touchScale: CGFloat = 0
    var long: CGFloat {
        get {
            return frame.height
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!
        let location = touch.location(in: self)
        touchY = long - location.y
        touchScale = touchY/long
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchY = 0
        touchScale = 0
    }
    
}
