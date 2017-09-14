//
//  ChangeCarScene.swift
//  unPredictable
//
//  Created by Majo on 08/08/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import SpriteKit
#if os(iOS)
    import UIKit
#endif

class ChangeCarScene: SKScene {
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
    private var descLabel: SKSpriteNode!
    #if os(iOS) || os(tvOS)
        var myRecongizers = [UISwipeGestureRecognizer]()
    #endif
    
    private let availableCars = [MVACarNames.playerOrdinary, MVACarNames.playerLives, MVACarNames.playerPCS]
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
        scene.descLabel = scene.childNode(withName: "descLabel") as! SKSpriteNode
        scene.descLabel.position = CGPoint(x: 0.0, y: 30.0-(scene.carImg.size.height/2)-15)
        
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
                MVAMemory.adCar = scene.selectedCar
                MVAMemory.playerCar = scene.selectedCar
                MVAMemory.adsEnabled = true
                scene.newCarBtts.isHidden = true
                scene.useBtt.isHidden = false
                #if os(iOS) || os(tvOS)
                    scene.removeSwipes() //!!!
                #endif
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
    
    func refresh() {
        let pCar = MVAMemory.playerCar
        carImg.texture = SKTexture(imageNamed: pCar)
        carName.text = store.mockUpNames[pCar]
        selectedCar = pCar
        checkArrows()
    }
    
    private func checkArrows() {
        if MVAMemory.ownedCars.contains(selectedCar) {
            useBtt.isHidden = false
            newCarBtts.isHidden = true
            (useBtt.childNode(withName: "txt") as! SKLabelNode).text = "USE"
        } else if MVAMemory.adCar == selectedCar {
            useBtt.isHidden = false
            newCarBtts.isHidden = true
            (useBtt.childNode(withName: "txt") as! SKLabelNode).text = store.getPrice(forCar: selectedCar)
        } else {
            #if os(macOS)
            useBtt.isHidden = false
            newCarBtts.isHidden = true
            (useBtt.childNode(withName: "txt") as! SKLabelNode).text = store.getPrice(forCar: selectedCar)
            #else
            useBtt.isHidden = true
            newCarBtts.isHidden = false
            (buyBtt.childNode(withName: "txt") as! SKLabelNode).text = store.getPrice(forCar: selectedCar)
            #endif
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
        
        switch selectedCar {
        case MVACarNames.playerLives:
            (descLabel.childNode(withName: "txt1") as! SKLabelNode).text = "You can crash multiple times"
            (descLabel.childNode(withName: "txt2") as! SKLabelNode).text = "before destroying the car"
        case MVACarNames.playerPCS:
            (descLabel.childNode(withName: "txt1") as! SKLabelNode).text = "Built-in"
            (descLabel.childNode(withName: "txt2") as! SKLabelNode).text = "pre-collision system"
        default:
            (descLabel.childNode(withName: "txt1") as! SKLabelNode).text = "Nothing special 😐"
            (descLabel.childNode(withName: "txt2") as! SKLabelNode).text = ""
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
            carName.text = store.mockUpNames[newCarName]
        }
        checkArrows()
    }
    
    private func purchase() {
        waitNode = MVAWaitNode.new(withSize: self.size, inScene: self)
        waitNode.zPosition = 10.0
        self.addChild(waitNode)
        self.isUserInteractionEnabled = false
        /*
        MVAMemory.adsEnabled = false
        MVAMemory.ownedCars.append(self.selectedCar)
        self.newCarBtts.isHidden = true
        self.useBtt.isHidden = false
        (useBtt.childNode(withName: "txt") as! SKLabelNode).text = "USE"
        
        self.waitNode.remove()
        self.waitNode = nil
        */
        
        let completion = { (purchased:Bool, _:String, err:Error?) in
            if purchased && err == nil {
                MVAMemory.adsEnabled = false
                MVAMemory.ownedCars.append(self.selectedCar)
                MVAMemory.adCar = nil
                self.newCarBtts.isHidden = true
                (self.useBtt.childNode(withName: "txt") as! SKLabelNode).text = "USE"
                self.useBtt.isHidden = false
            }
            self.isUserInteractionEnabled = true
            self.waitNode.remove()
            self.waitNode = nil
        }
        
        let error = { () in
            self.isUserInteractionEnabled = true
            self.waitNode.remove()
            self.waitNode = nil
            let alert = MVAAlert.new(withTitle: "Sorry", andMessage: "Server is unreachable")
            MVAAlert.present(alert)
        }
        
        switch selectedCar {
        case MVACarNames.playerLives:
            store.buyLivesCar(withCompletion: completion, andError: error)
        case MVACarNames.playerPCS:
            store.buyPCSCar(withCompletion: completion, andError: error)
        default: break
        }
    }
    
    #if os(iOS) || os(tvOS)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch = touches.first!.location(in: self)
        touchedPosition(touch)
    }
    #endif
    
    func touchedPosition(_ pos: CGPoint) {
        if backBtt.contains(pos) {
            #if os(iOS) || os(tvOS)
            removeSwipes()
            #endif
            NotificationCenter.default.post(name: ChangeCarScene.backFromScene, object: nil)
        } else if restoreBtt.contains(pos) {
            waitNode = MVAWaitNode.new(withSize: self.size, inScene: self)
            waitNode.zPosition = 10.0
            self.addChild(waitNode)
            store.restorePurchases() { (purchased: Bool, car: String, error: Error?) in
                if purchased && error == nil {
                    MVAMemory.adsEnabled = false
                    switch car {
                    case self.store.productIDs["lives_car"]!: MVAMemory.ownedCars.append(MVACarNames.playerLives)
                    case self.store.productIDs["pcs_car"]!: MVAMemory.ownedCars.append(MVACarNames.playerPCS)
                    default: break
                    }
                    self.checkArrows()
                } else if error != nil {
                    let alertMsg = error == nil ? "Server is unreachable":error!.localizedDescription
                    let alert = MVAAlert.new(withTitle: "Sorry", andMessage: alertMsg)
                    MVAAlert.present(alert)
                }
                if self.waitNode != nil {
                    self.waitNode.remove()
                    self.waitNode = nil
                }
            }
        } else if !useBtt.isHidden && useBtt.contains(pos) {
            if (useBtt.childNode(withName: "txt") as! SKLabelNode).text == "USE" {
                if MVAMemory.ownedCars.contains(selectedCar) {
                    #if os(iOS) || os(tvOS)
                    removeSwipes()
                    #endif
                    MVAMemory.playerCar = selectedCar
                    MVAMemory.adCar = nil
                    MVAMemory.adsEnabled = false
                    NotificationCenter.default.post(name: ChangeCarScene.changePCar, object: nil)
                }
            } else {
                purchase()
            }
        } else if !newCarBtts.isHidden && newCarBtts.contains(pos) {
            let specificTouch = newCarBtts.convert(pos, from: self)
            if enableAdsBtt.contains(specificTouch) {
                ads.showAd()
            } else if buyBtt.contains(specificTouch) {
                purchase()
            }
        } else if rightArr.contains(pos) {
            changeCar(1)
        } else if leftArr.contains(pos) {
            changeCar(-1)
        }
    }
}
