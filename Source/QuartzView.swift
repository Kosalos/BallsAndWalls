import UIKit

struct WallData {
    var isHorizontal = Bool()
    var pt1 = CGPoint()
    var pt2 = CGPoint()
}

struct BallData {
    var pt = CGPoint()
    var dir = CGPoint()
    var radius = CGFloat()
    var index = Int()
}

let MAX_WALL:Int = 6
let MAX_BALL:Int = 40
let MAX_IMG:Int = 6
let NONE:Int = -1
let MIN_RADIUS:CGFloat =  6
let MAX_RADIUS:CGFloat =  24

var gravity:CGFloat = 500
var deacceleration:CGFloat = 0.9995
var targetAngleHop:Float = 0.002

class QuartzView: UIView
{
    var xs = CGFloat()
    var ys = CGFloat()
    var target = CGPoint()
    var targetAngle:Float = 0
    let Cycle:Int = 20 // #cycles between draws
    
    var wallIndex:Int = 0
    var wall = Array(repeating: WallData(), count: MAX_WALL)
    var ball = Array(repeating: BallData(), count: MAX_BALL)
    var img = Array(repeating: UIImage(), count:6)
    
    var pt = CGPoint()
    var previousPt = CGPoint()
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        for i in 0 ..< MAX_IMG { img[i] = UIImage(named:String(format:"b%d.png",i+1))! }
        rotated()
        reset()
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.rotated), name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    func reset() {
        for i in 0 ..< MAX_BALL {
            ball[i].pt.x = fRandom(0,xs)
            ball[i].pt.y = fRandom(0,ys)
            ball[i].radius = fRandom(CGFloat(MIN_RADIUS),CGFloat(MAX_RADIUS))
            ball[i].index = i % MAX_IMG
        }
        
        for i in 0 ..< MAX_WALL/2 {
            wall[i].isHorizontal = true
            wall[i].pt1.x = CGFloat(100 + i * 200)
            wall[i].pt2.x = wall[i].pt1.x + 180
            wall[i].pt1.y = 700
            wall[i].pt2.y = 700
            
            let j = i + MAX_WALL/2
            wall[j].isHorizontal = false
            wall[j].pt1.y = CGFloat(100 + i * 250)
            wall[j].pt2.y = wall[j].pt1.y + 230
            wall[j].pt1.x = 400
            wall[j].pt2.x = 400
        }
        
        wallIndex = NONE
    }
    
    func updateTargetPosition() {
        target.x = xs/2 + CGFloat(cosf(targetAngle) * Float(xs/2 - 100))
        target.y = ys/2 + CGFloat(sinf(targetAngle) * Float(ys/2 - 100))
        targetAngle += targetAngleHop
        
        for i in 0 ..< MAX_BALL {
            ball[i].dir.x -= (ball[i].pt.x - target.x) / gravity
            ball[i].dir.y -= (ball[i].pt.y - target.y) / gravity
        }
    }
    
    func moveAndCollideBalls() {
        // normal movement
        for i in 0 ..< MAX_BALL {
            ball[i].pt.x += ball[i].dir.x / CGFloat(Cycle)
            ball[i].pt.y += ball[i].dir.y / CGFloat(Cycle)
        }
        
        // collision detection vs other balls
        for i in 0 ..< MAX_BALL-1 {
            for j in i+1 ..< MAX_BALL {
                // do the two balls overlap?
                var dx = ball[j].pt.x - ball[i].pt.x
                var dy = ball[j].pt.y - ball[i].pt.y
                
                if fabs(dx) > MAX_RADIUS*2 || fabs(dy) > MAX_RADIUS*2 { continue }
                let distance = CGFloat(hypotf(Float(dx),Float(dy)))
                let collisionDistance = ball[i].radius + ball[j].radius
                let gap = distance - collisionDistance
                
                // balls overlap = collision
                if gap <= 0 {
                    dx /= distance
                    dy /= distance
                    
                    // weight the balls according to volume (radius cubed)
                    let wi = Float.pi * powf(Float(ball[i].radius),3)
                    let wj = Float.pi * powf(Float(ball[j].radius),3)
                    var weightRatio = CGFloat(wi / (wi + wj))
                    
                    ball[j].dir.x -= gap * dx * weightRatio
                    ball[j].dir.y -= gap * dy * weightRatio
                    
                    weightRatio = 1 - weightRatio
                    
                    ball[i].dir.x += gap * dx * weightRatio
                    ball[i].dir.y += gap * dy * weightRatio
                }
            }
        }
        
        // collision detection vs walls
        for i in 0 ..< MAX_BALL {
            for j in 0 ..< MAX_WALL {
                if wall[j].isHorizontal {
                    // off to the side of the line segment?
                    if ball[i].pt.x < wall[j].pt1.x - ball[i].radius ||
                        ball[i].pt.x > wall[j].pt2.x + ball[i].radius { continue }
                    
                    // Y coordinate overlaps the line?
                    if fabs(ball[i].pt.y - wall[j].pt1.y) <= ball[i].radius {
                        ball[i].dir.y = -ball[i].dir.y
                        
                        if ball[i].pt.y < wall[j].pt1.y {
                            ball[i].pt.y = wall[j].pt1.y - ball[i].radius
                        }
                        else {
                            ball[i].pt.y = wall[j].pt1.y + ball[i].radius
                        }
                    }
                }
                else {  // vertical
                    if ball[i].pt.y < wall[j].pt1.y - ball[i].radius ||
                        ball[i].pt.y > wall[j].pt2.y + ball[i].radius { continue }
                    
                    if fabs(ball[i].pt.x - wall[j].pt1.x) <= ball[i].radius {
                        ball[i].dir.x = -ball[i].dir.x
                        
                        if ball[i].pt.x < wall[j].pt1.x {
                            ball[i].pt.x = wall[j].pt1.x - ball[i].radius
                        }
                        else {
                            ball[i].pt.x = wall[j].pt1.x + ball[i].radius
                        }
                    }
                }
            }
        }
    }
    
    func update() {
        for _ in 0 ..< Cycle {
            moveAndCollideBalls()
            
            for i in 0 ..< MAX_BALL {
                ball[i].dir.x *= deacceleration
                ball[i].dir.y *= deacceleration
            }
        }
        
        updateTargetPosition()
    }

    // MARK: -

    var context : CGContext?
    
    func drawLine(_ p1:CGPoint, _ p2:CGPoint) {
        context?.beginPath()
        context?.move(to:p1)
        context?.addLine(to:p2)
        context?.strokePath()
    }

    func drawBall(_ index:Int, _ pt:CGPoint, _ radius:CGFloat) {
        let dia:CGFloat = radius * 2
        img[index].draw(in:CGRect(x:pt.x-radius, y:pt.y-radius, width:dia, height:dia))
    }

    override func draw(_ rect: CGRect) {
        context = UIGraphicsGetCurrentContext()
        UIColor.black.setFill()
        UIBezierPath(rect:rect).fill()
        
        UIColor.darkGray.set()
        context?.setLineWidth(1)
        drawLine(CGPoint(x:0, y:target.y), CGPoint(x:xs, y:target.y))
        drawLine(CGPoint(x:target.x, y:0), CGPoint(x:target.x, y:ys))
        drawBall(0,target,6)
        
        UIColor.white.set()
        context?.setLineWidth(3)
        for i in 0 ..< MAX_WALL {
            drawLine(wall[i].pt1,wall[i].pt2)
        }
        
        for i in 0 ..< MAX_BALL {
            drawBall(ball[i].index,ball[i].pt,ball[i].radius)
        }
    }

    // MARK: -
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if wallIndex != NONE { return }
        
        for touch in touches {
            let pt = touch.location(in: self)
            
            for i in 0 ..< MAX_WALL {
                if wall[i].isHorizontal == true {
                    if pt.x >= wall[i].pt1.x && pt.x < wall[i].pt2.x && fabs(pt.y - wall[i].pt1.y) < 25 {
                        wallIndex = i
                        previousPt = pt
                        return
                    }
                }
                else {  // vertical
                    if pt.y >= wall[i].pt1.y && pt.y < wall[i].pt2.y && fabs(pt.x - wall[i].pt1.x) < 25 {
                        wallIndex = i
                        previousPt = pt
                        return
                    }
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if wallIndex == NONE { return }
        
        for touch in touches {
            let pt = touch.location(in: self)
            
            wall[wallIndex].pt1.x += pt.x - previousPt.x
            wall[wallIndex].pt2.x += pt.x - previousPt.x
            wall[wallIndex].pt1.y += pt.y - previousPt.y
            wall[wallIndex].pt2.y += pt.y - previousPt.y
            
            previousPt = pt
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { touchesEnded(touches, with: event) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { wallIndex = NONE }
    
    @objc func rotated() { xs = bounds.width; ys = bounds.height }
    
    func fRandom(_ vmin:CGFloat, _ vmax:CGFloat) -> CGFloat {
        let ratio = CGFloat(arc4random() & 1023) / CGFloat(1024)
        return vmin + (vmax - vmin) * ratio
    }
}
