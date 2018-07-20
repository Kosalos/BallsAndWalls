import UIKit

let GRAVITY_MIN:CGFloat = 200.0
let GRAVITY_MAX:CGFloat = 3000.0 // larger = more bounce
let FRICTION_MIN:CGFloat = 0.99
let FRICTION_MAX:CGFloat = 0.999 // larger = slower
let TARGET_MIN:Float = 0.005
let TARGET_MAX:Float = 0.03  // larger = faster

class ViewController: UIViewController {
    @IBOutlet var qv: QuartzView!
    @IBOutlet var ss1: UISlider!
    @IBOutlet var ss2: UISlider!
    @IBOutlet var ss3: UISlider!

    @IBAction func sliderChange(_ sender: UISlider) {
        let v = sender.value
        switch(sender) {
        case ss1 : gravity = GRAVITY_MIN + (GRAVITY_MAX - GRAVITY_MIN) * CGFloat(1.0 - v)
        case ss2 : deacceleration = FRICTION_MIN + (FRICTION_MAX - FRICTION_MIN) * CGFloat(1.0 - v)
        case ss3 : targetAngleHop = TARGET_MIN + (TARGET_MAX - TARGET_MIN) * v
        default  : break
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        Timer.scheduledTimer(withTimeInterval:0.05, repeats:true) { timer in self.timerHandler() }
    }
    
    @objc func timerHandler() {
        qv.update()
        qv.setNeedsDisplay()
    }

    override var prefersStatusBarHidden: Bool { return true }
}
