//
//  MVATutorialNode.swift
//  unPredictable
//
//  Created by Majo on 26/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit
#if os(iOS)
    import FirebaseAnalytics
#endif

enum MVATutorialText {
    #if os(iOS)
    static let swipeLabel = "Swiping changes"
    static let swipe2ndLabel = "your car's lane"
    static let swipe3rdLabel = "Try it! 😎"
    static let tiltLabel = "You can also change"
    static let tilt2ndLabel = "lanes by tilting the phone"
    static let tilt3rdLabel = "Tilt me! 🙃"
    static let brakeLabel = "Touch and hold"
    static let brake2ndLabel = "to brake" //"and drag"
    static let brake3rdLabel = ""//"to change direction"
    #elseif os(macOS)
    static let swipeLabel = "Change your car's"
    static let swipe2ndLabel = "lane with ◀️/▶️"
    static let swipe3rdLabel = "Try it! 😎"
    static let tiltLabel = "You can also change"
    static let tilt2ndLabel = "lanes by moving the cursor"
    static let tilt3rdLabel = "Move me! ↖️"
    static let brakeLabel = "Hold the spacebar"// to brake"
    static let brake2ndLabel = "to brake"//"and click ◀️|▶️"
    static let brake3rdLabel = ""//"to change direction"
    #endif
}

protocol MVATutorialDelegate {
    func tutorialActivateSwipe()
    func tutorialActivateTilt()
    #if os(iOS)
    func tutorialActivateSphero()
    #endif
}

class MVATutorialNode: SKNode {
    var dispSize: CGSize!
    
    /// stage = 0 -> swipe & stage = 1 -> tilt & stage = 2 -> brake
    var stage = 0
    var delegate: MVATutorialDelegate?
    
    class func label(withText txt: String, andName name: String?) -> SKLabelNode {
        let lbl = SKLabelNode(text: txt)
        lbl.fontName = "Futura Medium"
        lbl.fontSize = 25
        lbl.verticalAlignmentMode = .center
        lbl.name = name
        return lbl
    }
    
    let iphoneXTopNotch: CGFloat = MVAMemory.isIphoneX ? 30.0:0.0
    
    class func new(size: CGSize) -> MVATutorialNode {
        let newNode = MVATutorialNode()
        newNode.dispSize = size
        
        let swipeLabel = MVATutorialNode.label(withText: MVATutorialText.swipeLabel, andName: "swipe")
        swipeLabel.position = CGPoint(x: 0.0, y: (size.height/2.3)-newNode.iphoneXTopNotch)
        newNode.addChild(swipeLabel)
        
        let swipe2ndLabel = MVATutorialNode.label(withText: MVATutorialText.swipe2ndLabel, andName: "swipe")
        swipe2ndLabel.position = CGPoint(x: 0.0, y: swipeLabel.frame.minY-23)
        newNode.addChild(swipe2ndLabel)
        
        let swipe3rdLabel = MVATutorialNode.label(withText: MVATutorialText.swipe3rdLabel, andName: "swipe")
        swipe3rdLabel.position = CGPoint(x: 0.0, y: swipe2ndLabel.frame.minY-30)
        newNode.addChild(swipe3rdLabel)

        let gradient = SKSpriteNode(imageNamed: "grad")
        gradient.size = CGSize(width: size.width, height: size.height/2)
        gradient.anchorPoint.y = 0.0
        gradient.position = CGPoint(x: 0.0, y: 0-newNode.iphoneXTopNotch)
        gradient.zPosition = -1
        newNode.addChild(gradient)
        if newNode.iphoneXTopNotch > 0 {
            let node = SKSpriteNode(color: .black, size: CGSize(width: size.width, height: newNode.iphoneXTopNotch))
            node.anchorPoint.y = 1.0
            node.position.x = 0.0
            node.position.y = size.height/2
            node.zPosition = 1
            newNode.addChild(node)
        }
        
        #if os(iOS)
            Analytics.logEvent(AnalyticsEventTutorialBegin, parameters: nil)
        #endif
            
        return newNode
    }
    
    func continueToTilting(playerCar: MVACarPlayer) {
        let labels = children.filter({ $0.name == "swipe" })
        labels.forEach({ $0.run(SKAction.fadeOut(withDuration: 0.1), completion: { self.removeChildren(in: labels) }) })
        
        if children.filter({ $0.name == "done" }).isEmpty {
            self.stage = 1
            
            let wellDLabel = MVATutorialNode.label(withText: "👍", andName: nil)
            wellDLabel.verticalAlignmentMode = .top
            wellDLabel.fontSize = 66
            wellDLabel.position = CGPoint(x: 0.0, y: (dispSize.height/2.3)-iphoneXTopNotch)
            wellDLabel.alpha = 0.0
            wellDLabel.name = "done"
            addChild(wellDLabel)
            
            let presentTiltInstructs = SKAction.run {
                self.delegate?.tutorialActivateTilt()
                
                playerCar.run(SKAction.moveTo(x: 0.0, duration: 0.2))
                
                let tNode = SKNode()
                tNode.name = "tilt"
                
                let tiltLabel = MVATutorialNode.label(withText: MVATutorialText.tiltLabel, andName: "tilt")
                tiltLabel.position = CGPoint(x: 0.0, y: (self.dispSize.height/2.3)-self.iphoneXTopNotch)
                tNode.addChild(tiltLabel)
                
                let tilt2ndLabel = MVATutorialNode.label(withText: MVATutorialText.tilt2ndLabel, andName: "tilt")
                tilt2ndLabel.position = CGPoint(x: 0.0, y: tiltLabel.frame.minY-23)
                tNode.addChild(tilt2ndLabel)
                
                let tilt3ndLabel = MVATutorialNode.label(withText: MVATutorialText.tilt3rdLabel, andName: "tilt")
                tilt3ndLabel.position = CGPoint(x: 0.0, y: tilt2ndLabel.frame.minY-30)
                tNode.addChild(tilt3ndLabel)
                
                tNode.alpha = 0.0
                self.addChild(tNode)
                
                tNode.run(SKAction.sequence([SKAction.fadeIn(withDuration: 0.1),
                                             SKAction.wait(forDuration: 1.5),
                                             SKAction.run({ self.stage = 2 })]))
            }
            
            wellDLabel.run(SKAction.sequence([SKAction.fadeIn(withDuration: 0.1),
                                              SKAction.wait(forDuration: 1.8),
                                              SKAction.fadeOut(withDuration: 0.1),
                                              presentTiltInstructs]), completion: { self.removeChildren(in: self.children.filter({ $0.name == "done" })) })
        }
    }
    
    func continueToBraking() {
        let labels = children.filter({ $0.name == "tilt" })
        labels.forEach({ $0.run(SKAction.fadeOut(withDuration: 0.1), completion: { self.removeChildren(in: labels) }) })
        
        if children.filter({ $0.name == "done" }).isEmpty {
        let wellDLabel = MVATutorialNode.label(withText: "👍", andName: nil)
            wellDLabel.verticalAlignmentMode = .top
            wellDLabel.fontSize = 66
            wellDLabel.position = CGPoint(x: 0.0, y: (dispSize.height/2.3)-iphoneXTopNotch)
            wellDLabel.alpha = 0.0
            wellDLabel.name = "done"
            addChild(wellDLabel)
            
            let presentBrakeInstructs = SKAction.run {
                let bNode = SKNode()
                bNode.name = "brake"
                
                let brakeLabel = MVATutorialNode.label(withText: MVATutorialText.brakeLabel, andName: nil)
                brakeLabel.position = CGPoint(x: 0.0, y: (self.dispSize.height/2.3)-self.iphoneXTopNotch)
                bNode.addChild(brakeLabel)
                
                let brake2ndLabel = MVATutorialNode.label(withText: MVATutorialText.brake2ndLabel, andName: nil)
                brake2ndLabel.position = CGPoint(x: 0.0, y: brakeLabel.frame.minY-23)
                bNode.addChild(brake2ndLabel)
                
                let brake3ndLabel = MVATutorialNode.label(withText: MVATutorialText.brake3rdLabel, andName: nil)
                brake3ndLabel.position = CGPoint(x: 0.0, y: brake2ndLabel.frame.minY-23)
                bNode.addChild(brake3ndLabel)
                
                bNode.alpha = 0.0
                self.addChild(bNode)
                bNode.run(SKAction.fadeIn(withDuration: 0.1), completion: { self.stage = 3 })
            }
            
            wellDLabel.run(SKAction.sequence([SKAction.fadeIn(withDuration: 0.1),
                                              SKAction.wait(forDuration: 1.5),
                                              SKAction.fadeOut(withDuration: 0.1),
                                              presentBrakeInstructs]))
        }
    }
    
    func prepareEnd() {
        let labels = children.filter({ $0.name == "brake" })
        labels.forEach({ $0.run(SKAction.fadeOut(withDuration: 0.1), completion: { self.removeChildren(in: labels) }) })
        stage = 4
        
        let wellDLabel = MVATutorialNode.label(withText: "👍", andName: nil)
        wellDLabel.verticalAlignmentMode = .top
        wellDLabel.fontSize = 66
        wellDLabel.position = CGPoint(x: 0.0, y: dispSize.height/2.3)
        wellDLabel.alpha = 0.0
        addChild(wellDLabel)
        
        wellDLabel.run(SKAction.fadeIn(withDuration: 0.1))
    }
    
    func end(_ completion: @escaping ()->Void) {
        #if os(iOS)
            Analytics.logEvent(AnalyticsEventTutorialComplete, parameters: nil)
        #endif
        
        self.run(SKAction.fadeOut(withDuration: 0.2), completion: completion)
    }
}
