//
//  MVAGameOverNode.swift
//  unPredictable
//
//  Created by Marian Vinicay on 26/07/2017.
//  Copyright © 2017 Marvin. All rights reserved.
//

import SpriteKit
#if os(iOS)
import UIKit
#endif
    
class MVAGameOverNode: SKNode {
    private(set) var yesBtt: SKShapeNode?
    private var noBtt: SKShapeNode?
    private var countD: SKLabelNode?
    private var countDown = 6
    private var showPurchase = false
    
    var store: MVAStore!
    var completion: ((Bool)->())?
    
    class func new(size: CGSize, offerPurchase: Bool, clumsy: Bool) -> MVAGameOverNode {
        let newNode = MVAGameOverNode()
        
        let blank =  SKSpriteNode(color: .clear, size: size)
        blank.position = .zero
        newNode.addChild(blank)
        
        let goLabel = SKLabelNode(text: "Game Over!")
        goLabel.fontName = "Futura Bold"
        goLabel.fontSize = 50
        goLabel.verticalAlignmentMode = .center
        goLabel.position = .zero
        newNode.addChild(goLabel)
        if goLabel.frame.size.width > size.width {
            goLabel.fontSize = 40
        }
        
        newNode.countD = SKLabelNode(text: String(newNode.countDown))
        newNode.countD!.fontName = "Futura Medium"
        newNode.countD!.fontSize = 80
        newNode.countD!.verticalAlignmentMode = .center
        newNode.countD!.position = CGPoint(x: 0.0, y: -(size.height/2)+newNode.countD!.frame.height*2)
        newNode.addChild(newNode.countD!)

        if offerPurchase {
            newNode.showPurchase = offerPurchase
            goLabel.position.y = goLabel.frame.height*2
            
            let firstLabel = clumsy == true ? SKLabelNode(text: "You are a bit clumsy 😜") : SKLabelNode(text: "You are good 😎")
            firstLabel.fontName = "Futura Medium"
            firstLabel.fontSize = 22
            firstLabel.verticalAlignmentMode = .baseline
            firstLabel.position = .zero
            newNode.addChild(firstLabel)
            
            let secondLabel = SKLabelNode(text: "Do you want to continue")
            secondLabel.fontName = "Futura Medium"
            secondLabel.fontSize = 22
            secondLabel.verticalAlignmentMode = .center
            secondLabel.position = CGPoint(x: 0.0, y: firstLabel.frame.minY-20)
            newNode.addChild(secondLabel)
            
            let thirdLabel = SKLabelNode(text: "from where you crashed?")
            thirdLabel.fontName = "Futura Medium"
            thirdLabel.fontSize = 22
            thirdLabel.verticalAlignmentMode = .center
            thirdLabel.position = CGPoint(x: 0.0, y: secondLabel.frame.minY-20)
            newNode.addChild(thirdLabel)
            
            let yLabel = SKLabelNode(text: "YES")
            yLabel.fontName = "Futura Medium"
            yLabel.fontColor = .black
            yLabel.fontSize = 30
            yLabel.verticalAlignmentMode = .center
            yLabel.position = .zero
            newNode.yesBtt = SKShapeNode(circleOfRadius: yLabel.frame.width/1.5)
            newNode.yesBtt!.fillColor = .green
            newNode.yesBtt!.strokeColor = .clear
            newNode.yesBtt!.position = CGPoint(x: -(size.width/2)+60, y: newNode.countD!.position.y)
            newNode.yesBtt!.addChild(yLabel)
            newNode.addChild(newNode.yesBtt!)
            
            let nLabel = SKLabelNode(text: "NO")
            nLabel.fontName = "Futura Medium"
            nLabel.fontColor = .black
            nLabel.fontSize = 30
            nLabel.verticalAlignmentMode = .center
            nLabel.position = .zero
            newNode.noBtt = SKShapeNode(circleOfRadius: yLabel.frame.width/1.5)
            newNode.noBtt!.fillColor = .red
            newNode.noBtt!.strokeColor = .clear
            newNode.noBtt!.position = CGPoint(x: (size.width/2)-60, y: newNode.countD!.position.y)
            newNode.noBtt!.addChild(nLabel)
            newNode.addChild(newNode.noBtt!)
        }
        newNode.isUserInteractionEnabled = true
        return newNode
    }
    
    @objc func performCountDown() {
        if countD != nil {
            if countDown > 1 {
                countDown -= 1
                countD?.text = String(countDown)
                perform(#selector(performCountDown), with: nil, afterDelay: 1.0)
            } else {
                self.startNewGame()
            }
        }
    }
    
    fileprivate func startNewGame() {
        completion?(false)
        removeAllChildren()
        removeFromParent()
    }
    
    fileprivate func continueInGame() {
        completion?(true)
        removeAllChildren()
        removeFromParent()
    }
    
    func touchedPosition(_ touchLocation: CGPoint) {
        countD?.removeFromParent()
        countD = nil

        if yesBtt != nil && noBtt != nil && yesBtt!.contains(touchLocation) {
            createIndicator()
            scene!.view!.addSubview(activityInd!)
            yesBtt?.removeFromParent()
            noBtt?.removeFromParent()
            yesBtt = nil
            noBtt = nil
            
            store.buyLife() { (purchased: Bool, _, _) in
                #if os(iOS)
                self.activityInd?.stopAnimating()
                #else
                self.activityInd?.stopAnimation(nil)
                #endif
                self.activityInd?.removeFromSuperview()
                
                if purchased {
                    self.continueInGame()
                } else {
                    self.startNewGame()
                }
            }
        } else {
            self.startNewGame()
        }
    }
    
    #if os(iOS)
    fileprivate var activityInd: UIActivityIndicatorView?

    fileprivate func createIndicator() {
        activityInd = UIActivityIndicatorView(style: .whiteLarge)
        activityInd!.center = CGPoint(x: scene!.view!.frame.midX, y: -2.5*yesBtt!.position.y)
        activityInd!.startAnimating()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchLocation = touches.first!.location(in: self)
        touchedPosition(touchLocation)
    }
    
    #elseif os(macOS)
    fileprivate var activityInd: NSProgressIndicator?
    
    fileprivate func createIndicator() {
        activityInd = NSProgressIndicator()
        activityInd!.style = .spinning
        let winSize = NSApp.mainWindow!.minSize
        activityInd!.frame = NSRect(x: (winSize.width/2)+75-21, y: (winSize.height/4)-75, width: 150, height: 150)
        let lighten = CIFilter(name: "CIColorControls")!
        lighten.setDefaults()
        lighten.setValue(1, forKey: "inputBrightness")
        activityInd!.contentFilters = [lighten]
        activityInd!.display()
        activityInd!.startAnimation(nil)
    }
    
    override func mouseUp(with event: NSEvent) {
        touchedPosition(event.location(in: self))
    }
    #endif
}
