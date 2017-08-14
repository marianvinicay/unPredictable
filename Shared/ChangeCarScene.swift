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
    private var restoreBtt: SKSpriteNode!
    private var useBtt: SKSpriteNode!
    private var newCarBtts: SKSpriteNode!
    private var enableAdsBtt: SKSpriteNode!
    private var buyBtt: SKSpriteNode!
    private var leftArr: SKSpriteNode!
    private var rightArr: SKSpriteNode!
    private var carImg: SKSpriteNode!
    private var carName: SKLabelNode!
    private var mudiDesc: SKSpriteNode!
    
    private let availableCars = ["audi", "playerJeep"]
    private let mockUpNames = ["audi":"Veep", "playerJeep":"Mudi"]
    private var selectedCar = MVAMemory.playerCar
    private let ads = MVAAds(config: .onlyVideo)
    private var store: MVAStore!
    private var waitNode: MVAWaitNode!

    class func new(withSize deviceSize: CGSize, andStore nStore: MVAStore) -> ChangeCarScene {
        guard let scene = ChangeCarScene(fileNamed: "ChangeCarScene") else {
            abort()
        }
        scene.scaleMode = .aspectFill
        scene.size = deviceSize
        let background = scene.childNode(withName: "background") as! SKSpriteNode
        background.position = .zero
        background.size = deviceSize
        
        scene.store = nStore
        
        scene.backBtt = scene.childNode(withName: "back") as! SKSpriteNode
        scene.backBtt.position = CGPoint(x: (-deviceSize.width/2)+(scene.backBtt.size.width/2),
                                         y: (deviceSize.height/2)-(scene.backBtt.size.height/2))
        scene.restoreBtt = scene.childNode(withName: "restore") as! SKSpriteNode
        scene.restoreBtt.position = CGPoint(x: (deviceSize.width/2)-(scene.restoreBtt.size.width/2)-8,
                                         y: scene.backBtt.position.y)
        (scene.childNode(withName: "title") as! SKLabelNode).position = CGPoint(x: 0.0, y: scene.backBtt.position.y)
        
        scene.carImg = scene.childNode(withName: "carImg") as! SKSpriteNode
        scene.carImg.position = CGPoint(x: 0.0, y: 30.0)
        scene.carName = scene.childNode(withName: "carName") as! SKLabelNode
        scene.carName.position = CGPoint(x: 0.0, y: 30.0+(scene.carImg.size.height/2)+20)
        scene.mudiDesc = scene.childNode(withName: "mudiDesc") as! SKSpriteNode
        scene.mudiDesc.position = CGPoint(x: 0.0, y: 30.0-(scene.carImg.size.height/2)-10)
        
        scene.leftArr = scene.childNode(withName: "left") as! SKSpriteNode
        scene.leftArr.position = CGPoint(x: (-deviceSize.width/2)+50, y: 30.0)
        scene.rightArr = scene.childNode(withName: "right") as! SKSpriteNode
        scene.rightArr.position = CGPoint(x: (deviceSize.width/2)-50, y: 30.0)
        scene.useBtt = scene.childNode(withName: "use") as! SKSpriteNode
        scene.useBtt.position = CGPoint(x: 0.0, y: (-deviceSize.height/2)+50)
        
        scene.newCarBtts = scene.childNode(withName: "newCar") as! SKSpriteNode
        scene.newCarBtts.position = CGPoint(x: 0.0, y: (-deviceSize.height/2)+50)
        scene.enableAdsBtt = scene.newCarBtts.childNode(withName: "ads") as! SKSpriteNode
        scene.buyBtt = scene.newCarBtts.childNode(withName: "buy") as! SKSpriteNode
        
        scene.ads.successHandler = { [unowned scene] (rewarded: Bool) in
            if rewarded {
                MVAMemory.adCars.append(scene.selectedCar)
                MVAMemory.playerCar = scene.selectedCar
                MVAMemory.adsEnabled = true
                scene.newCarBtts.isHidden = true
                scene.useBtt.isHidden = false
                scene.removeSwipes()
                NotificationCenter.default.post(name: ChangeCarScene.changePCar, object: nil)
            } else {
                MVAMemory.adsEnabled = false
                scene.newCarBtts.isHidden = false
                scene.useBtt.isHidden = true
            }
        }
        scene.ads.completionHandler = {}
        
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
        if MVAMemory.ownedCars.contains(selectedCar) {
            useBtt.isHidden = false
            newCarBtts.isHidden = true
            (useBtt.childNode(withName: "txt") as! SKLabelNode).text = "USE"
        } else if MVAMemory.adCars.contains(selectedCar) {
            useBtt.isHidden = false
            newCarBtts.isHidden = true
            (useBtt.childNode(withName: "txt") as! SKLabelNode).text = store.getCarPrice()
        } else {
            useBtt.isHidden = true
            newCarBtts.isHidden = false
            (buyBtt.childNode(withName: "txt") as! SKLabelNode).text = store.getCarPrice()
        }
        
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
        
        if selectedCar == "playerJeep" {
            mudiDesc.isHidden = false
        } else {
            mudiDesc.isHidden = true
        }
    }
    
    private func animateChange(inDirection dir: MVAPosition) {
        let baseX = dir == .left ? self.size.width/2:-self.size.width/2
        let newCarNode = SKSpriteNode(texture: SKTexture(imageNamed: selectedCar))
        newCarNode.size = carImg.size
        newCarNode.position = CGPoint(x: baseX, y: 30.0)
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
    
    private func purchase() {
        waitNode = MVAWaitNode.new(withSize: self.size, inScene: self)
        waitNode.zPosition = 10.0
        self.addChild(waitNode)
        /*
        MVAMemory.adsEnabled = false
        MVAMemory.ownedCars.append(self.selectedCar)
        self.newCarBtts.isHidden = true
        self.useBtt.isHidden = false
        (useBtt.childNode(withName: "txt") as! SKLabelNode).text = "USE"
        
        self.waitNode.remove()
        self.waitNode = nil
        */
        store.buyMudiCar { (purchased: Bool, _) in
            if purchased {
                MVAMemory.adsEnabled = false
                MVAMemory.ownedCars.append(self.selectedCar)
                self.newCarBtts.isHidden = true
                self.useBtt.isHidden = false
            }
            self.waitNode.remove()
            self.waitNode = nil
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!.location(in: self)
        if backBtt.contains(touch) {
            removeSwipes()
            NotificationCenter.default.post(name: ChangeCarScene.backFromScene, object: nil)
        } else if restoreBtt.contains(touch) {
            waitNode = MVAWaitNode.new(withSize: self.size, inScene: self)
            waitNode.zPosition = 10.0
            self.addChild(waitNode)
            store.restorePurchases() { (purchased: Bool, car: String?) in
                if purchased && car == "unpredictable.lives_car" {
                    MVAMemory.adsEnabled = false
                    MVAMemory.ownedCars.append("playerJeep")
                    self.checkArrows()
                }
                self.waitNode.remove()
                self.waitNode = nil
            }
        } else if !useBtt.isHidden && useBtt.contains(touch) {
            removeSwipes()
            if (useBtt.childNode(withName: "txt") as! SKLabelNode).text == "USE" {
                if MVAMemory.ownedCars.contains(selectedCar) {
                    MVAMemory.playerCar = selectedCar
                    MVAMemory.adCars = []
                    MVAMemory.adsEnabled = false
                }
            } else {
                purchase()
                (useBtt.childNode(withName: "txt") as! SKLabelNode).text = "USE"
            }
            NotificationCenter.default.post(name: ChangeCarScene.changePCar, object: nil)
        } else if !newCarBtts.isHidden && newCarBtts.contains(touch) {
            let specificTouch = touches.first!.location(in: self.newCarBtts)
            if enableAdsBtt.contains(specificTouch) {
                ads.showAd()
            } else if buyBtt.contains(specificTouch) {
                purchase()
            }
        } else if rightArr.contains(touch) {
            changeCar(1)
        } else if leftArr.contains(touch) {
            changeCar(-1)
        }
    }
}
