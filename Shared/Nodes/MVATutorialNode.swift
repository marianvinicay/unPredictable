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
    #if os(iOS) || os(tvOS)
    static let swipeLabel = "Swiping changes"
    static let swipe2ndLabel = "your car's lane"
    static let swipe3rdLabel = "Try it! 😎"
    static let brakeLabel = "Touch and hold to brake"
    static let brake2ndLabel = "and drag"
    static let brake3rdLabel = "to change direction"
    #elseif os(macOS)
    static let swipeLabel = "Change your car's"
    static let swipe2ndLabel = "lane with ◀️|▶️"
    static let swipe3rdLabel = "Try it! 😎"
    static let brakeLabel = "Hold 🔽 to brake"
    static let brake2ndLabel = "and click ◀️|▶️"
    static let brake3rdLabel = "to change direction"
    #endif
}

class MVATutorialNode: SKNode {
    private var dispSize: CGSize!
    
    /// stage = 0 -> speed & stage = 1 -> brake
    var stage = 0
    
    class func label(withText txt: String, andName name: String?) -> SKLabelNode {
        let lbl = SKLabelNode(text: txt)
        lbl.fontName = "Futura Medium"
        lbl.fontSize = 25
        lbl.verticalAlignmentMode = .center
        lbl.name = name
        return lbl
    }
    
    class func new(size: CGSize) -> MVATutorialNode {
        let newNode = MVATutorialNode()
        newNode.dispSize = size
        
        let swipeLabel = MVATutorialNode.label(withText: MVATutorialText.swipeLabel, andName: "swipe")
        swipeLabel.position = CGPoint(x: 0.0, y: size.height/2.3)
        newNode.addChild(swipeLabel)
        
        let swipe2ndLabel = MVATutorialNode.label(withText: MVATutorialText.swipe2ndLabel, andName: "swipe")
        swipe2ndLabel.position = CGPoint(x: 0.0, y: swipeLabel.frame.minY-20)
        newNode.addChild(swipe2ndLabel)
        
        let swipe3rdLabel = MVATutorialNode.label(withText: MVATutorialText.swipe3rdLabel, andName: "swipe")
        swipe3rdLabel.position = CGPoint(x: 0.0, y: swipe2ndLabel.frame.minY-30)
        newNode.addChild(swipe3rdLabel)

        let gradient = SKSpriteNode(imageNamed: "grad")
        gradient.size = CGSize(width: size.width, height: size.height/2)
        gradient.anchorPoint.y = 0.0
        gradient.position = .zero
        gradient.zPosition = -1
        newNode.addChild(gradient)
        
        #if os(iOS)
            Analytics.logEvent(AnalyticsEventTutorialBegin, parameters: nil)
        #endif
            
        return newNode
    }
    
    func continueToBraking() {
        let labels = children.filter({ $0.name == "swipe" })
        labels.forEach({ $0.run(SKAction.fadeOut(withDuration: 0.1), completion: { self.removeChildren(in: labels) }) })
        
        if children.filter({ $0.name == "done" }).isEmpty {
        let wellDLabel = MVATutorialNode.label(withText: "👍", andName: nil)
            wellDLabel.verticalAlignmentMode = .top
            wellDLabel.fontSize = 66
            wellDLabel.position = CGPoint(x: 0.0, y: dispSize.height/2.3)
            wellDLabel.alpha = 0.0
            wellDLabel.name = "done"
            addChild(wellDLabel)
            
            let presentBrakeInstructs = SKAction.run {
                let bNode = SKNode()
                bNode.name = "brake"
                
                let brakeLabel = MVATutorialNode.label(withText: MVATutorialText.brakeLabel, andName: nil)
                brakeLabel.position = CGPoint(x: 0.0, y: self.dispSize.height/2.3)
                bNode.addChild(brakeLabel)
                
                let brake2ndLabel = MVATutorialNode.label(withText: MVATutorialText.brake2ndLabel, andName: nil)
                brake2ndLabel.position = CGPoint(x: 0.0, y: brakeLabel.frame.minY-27)
                bNode.addChild(brake2ndLabel)
                
                let brake3ndLabel = MVATutorialNode.label(withText: MVATutorialText.brake3rdLabel, andName: nil)
                brake3ndLabel.position = CGPoint(x: 0.0, y: brake2ndLabel.frame.minY-20)
                bNode.addChild(brake3ndLabel)
                
                bNode.alpha = 0.0
                self.addChild(bNode)
                bNode.run(SKAction.fadeIn(withDuration: 0.1), completion: { self.stage = 1 })
            }
            
            wellDLabel.run(SKAction.sequence([SKAction.fadeIn(withDuration: 0.1),
                                              SKAction.wait(forDuration: 1.5),
                                              SKAction.fadeOut(withDuration: 0.1),
                                              presentBrakeInstructs]))
        }
    }
    
    func end(_ completion: @escaping (()->())) {
        let labels = children.filter({ $0.name == "brake" })
        labels.forEach({ $0.run(SKAction.fadeOut(withDuration: 0.1), completion: { self.removeChildren(in: labels) }) })
        stage = 2
        
        let wellDLabel = MVATutorialNode.label(withText: "👍", andName: nil)
        wellDLabel.verticalAlignmentMode = .top
        wellDLabel.fontSize = 66
        wellDLabel.position = CGPoint(x: 0.0, y: dispSize.height/2.3)
        wellDLabel.alpha = 0.0
        addChild(wellDLabel)
        
        let act = SKAction.run {
            self.run(SKAction.fadeOut(withDuration: 0.2), completion: { completion() })
        }
        
        #if os(iOS)
            Analytics.logEvent(AnalyticsEventTutorialComplete, parameters: nil)
        #endif
        
        wellDLabel.run(SKAction.sequence([SKAction.fadeIn(withDuration: 0.1),
                                          SKAction.wait(forDuration: 1),
                                          act]))
    }
}
