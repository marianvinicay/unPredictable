//
//  ChangeCarScene.swift
//  unPredictable
//
//  Created by Majo on 08/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import UIKit
import SpriteKit

class ChangeCarScene: SKScene, UIGestureRecognizerDelegate {
    static let backFromScene = Notification.Name("backFromCCScene")
    static let changePCar = Notification.Name("chPCar")
    
    private var backBtt: SKSpriteNode!
    private var useBtt: SKSpriteNode!
    private var leftArr: SKSpriteNode!
    private var rightArr: SKSpriteNode!
    private var carImg: SKSpriteNode!
    private var carName: SKLabelNode!
    
    private let availableCars = ["audi", "playerJeep"]
    private let mockUpNames = ["audi":"Veep", "playerJeep":"Mudi"]
    private var selectedCar = MVAMemory.playerCar
    
    class func new(withSize deviceSize: CGSize) -> ChangeCarScene {
        guard let scene = ChangeCarScene(fileNamed: "ChangeCarScene") else {
            abort()
        }
        scene.scaleMode = .aspectFill
        scene.size = deviceSize
        let background = scene.childNode(withName: "background") as! SKSpriteNode
        background.position = .zero
        background.size = deviceSize
        
        scene.backBtt = scene.childNode(withName: "back") as! SKSpriteNode
        scene.useBtt = scene.childNode(withName: "use") as! SKSpriteNode
        scene.leftArr = scene.childNode(withName: "left") as! SKSpriteNode
        scene.rightArr = scene.childNode(withName: "right") as! SKSpriteNode
        scene.carImg = scene.childNode(withName: "carImg") as! SKSpriteNode
        scene.carName = scene.childNode(withName: "carName") as! SKLabelNode
        
        scene.backBtt = scene.childNode(withName: "back") as! SKSpriteNode
        scene.backBtt.position = CGPoint(x: (-deviceSize.width/2)+(scene.backBtt.size.width/2),
                                         y: (deviceSize.height/2)-(scene.backBtt.size.height/2))
        (scene.childNode(withName: "title") as! SKLabelNode).position = CGPoint(x: 0.0, y: scene.backBtt.position.y)
        scene.carImg = scene.childNode(withName: "carImg") as! SKSpriteNode
        scene.carImg.position = .zero
        scene.carName = scene.childNode(withName: "carName") as! SKLabelNode
        scene.carName.position = CGPoint(x: 0.0, y: (scene.carImg.size.height/2)+30)
        scene.leftArr = scene.childNode(withName: "left") as! SKSpriteNode
        scene.leftArr.position = CGPoint(x: (-deviceSize.width/2)+50, y: 0.0)
        scene.rightArr = scene.childNode(withName: "right") as! SKSpriteNode
        scene.rightArr.position = CGPoint(x: (deviceSize.width/2)-50, y: 0.0)
        scene.useBtt = scene.childNode(withName: "use") as! SKSpriteNode
        scene.useBtt.position = CGPoint(x: 0.0, y: (-deviceSize.height/2)+50)
        
        return scene
    }
    
    override func didMove(to view: SKView) {
        setupSwipes()
    }
    
    func refresh() {
        let pCar = MVAMemory.playerCar
        carImg.texture = SKTexture(imageNamed: pCar)
        carName.text = mockUpNames[pCar]
        selectedCar = pCar
        checkArrows()
    }
    
    private func checkArrows() {
        switch availableCars.index(of: selectedCar)! {
        case 0:
            leftArr.isHidden = true
            rightArr.isHidden = false
        case (availableCars.count-1):
            leftArr.isHidden = false
            rightArr.isHidden = true
        default:
            leftArr.isHidden = false
            rightArr.isHidden = false
        }
    }
    
    private func animateChange(inDirection dir: MVAPosition) {
        let baseX = dir == .left ? self.size.width/2:-self.size.width/2
        let newCarNode = SKSpriteNode(texture: SKTexture(imageNamed: selectedCar))
        newCarNode.size = carImg.size
        newCarNode.position = CGPoint(x: baseX, y: 0.0)
        newCarNode.alpha = 0.0
        self.addChild(newCarNode)
        
        let moveOldCar = SKAction.group([SKAction.moveTo(x: (-1*baseX), duration: 0.4),SKAction.fadeOut(withDuration: 0.3)])
        let moveNewCar = SKAction.group([SKAction.moveTo(x: 0.0, duration: 0.4),SKAction.fadeIn(withDuration: 0.3)])
        
        let swap = SKAction.run {
            self.carImg.run(moveOldCar)
            newCarNode.run(moveNewCar)
            self.carImg = newCarNode
        }
        
        self.run(swap)
    }
    
    func changeCar(_ ind: Int) {
        let currentCarIndex = availableCars.index(of: selectedCar)!
        let newIndex = currentCarIndex+ind
        if newIndex >= 0 && newIndex <= (availableCars.count-1) {
            let newCarName = availableCars[newIndex]
            selectedCar = newCarName
            let direction = ind > 0 ? MVAPosition.left:MVAPosition.right
            animateChange(inDirection: direction)
            carName.text = mockUpNames[newCarName]
        }
        checkArrows()
    }
    
    private var myRecongizers = [UISwipeGestureRecognizer]()
    
    private func setupSwipes() {
        let right = UISwipeGestureRecognizer(target: self, action: #selector(swipeGesture(swipe:)))
        right.direction = .right
        
        let left = UISwipeGestureRecognizer(target: self, action: #selector(swipeGesture(swipe:)))
        left.direction = .left
        
        right.delegate = self
        left.delegate = self
        
        view?.addGestureRecognizer(right)
        view?.addGestureRecognizer(left)
        
        myRecongizers = [right,left]
    }
    
    private func removeSwipes() {
        myRecongizers.forEach({ view?.removeGestureRecognizer($0) })
    }
    
    func swipeGesture(swipe: UIGestureRecognizer) {
        if (swipe as? UISwipeGestureRecognizer)?.direction == .left {
            changeCar(1)
        } else if (swipe as? UISwipeGestureRecognizer)?.direction == .right {
            changeCar(-1)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!.location(in: self)
        if backBtt.contains(touch) {
            removeSwipes()
            NotificationCenter.default.post(name: ChangeCarScene.backFromScene, object: nil)
        } else if useBtt.contains(touch) {
            removeSwipes()
            MVAMemory.playerCar = selectedCar
            NotificationCenter.default.post(name: ChangeCarScene.changePCar, object: nil)
        } else if rightArr.contains(touch) {
            changeCar(1)
        } else if leftArr.contains(touch) {
            changeCar(-1)
        }
    }
}
