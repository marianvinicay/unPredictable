//
//  MVAGameOverNode.swift
//  unPredictable
//
//  Created by Majo on 26/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit

class MVAGameOverNode: SKNode {
    
    private var yesBtt: SKShapeNode?
    private var noBtt: SKShapeNode?
    private var countD: SKLabelNode?
    private var countDown = 6
    
    weak var store: MVAStore!
    var completion: ((Bool)->())?
    
    class func new(size: CGSize, offerPurchase: Bool) -> MVAGameOverNode {
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
        
        newNode.countD = SKLabelNode(text: String(newNode.countDown))
        newNode.countD!.fontName = "Futura Medium"
        newNode.countD!.fontSize = 80
        newNode.countD!.verticalAlignmentMode = .center
        newNode.countD!.position = CGPoint(x: 0.0, y: -(size.height/2)+newNode.countD!.frame.height*2)
        newNode.addChild(newNode.countD!)
        
        if offerPurchase {
            goLabel.position.y = goLabel.frame.height*2
            
            let firstLabel = SKLabelNode(text: "You are a bit clumsy 😛")
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
    
    func performCountDown() {
        if countD != nil {
            if countDown > 1 {
                countDown -= 1
                countD?.text = String(countDown)
                perform(#selector(performCountDown), with: nil, afterDelay: 1.0)
            } else {
                startNewGame()
            }
        }
    }
    
    private func startNewGame() {
        completion?(false)
        removeAllChildren()
        removeFromParent()
    }
    
    private func continueInGame() {
        completion?(true)
        removeAllChildren()
        removeFromParent()
    }
    
    private var activityInd: UIActivityIndicatorView!

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touchLocation = touches.first!.location(in: self)
        countD?.removeFromParent()
        countD = nil
        
        if yesBtt != nil && noBtt != nil {
            if nodes(at: touchLocation).contains(yesBtt!) {
                
                activityInd = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
                activityInd.center = CGPoint(x: scene!.view!.frame.midX, y: -2.5*yesBtt!.position.y)
                activityInd.startAnimating()
                scene!.view!.addSubview(activityInd)
                
                self.activityInd.stopAnimating()
                self.activityInd.removeFromSuperview()
                self.continueInGame()
                /*store.buy() { (purchased: Bool) in
                    self.activityInd.stopAnimating()
                    self.activityInd.removeFromSuperview()
                    if purchased {
                        self.continueInGame()
                    } else {
                        self.startNewGame()
                    }
                }*/
            } else if nodes(at: touchLocation).contains(noBtt!) {
                self.startNewGame()
            }
        } else {
            startNewGame()
        }
    }
    
}
