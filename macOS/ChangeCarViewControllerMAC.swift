//
//  ChangeCarViewControllerMACN.swift
//  unPredictable - macOS
//
//  Created by Majo on 17/12/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import Cocoa

class ChangeCarViewControllerMAC: NSViewController, NSWindowDelegate {
    static let changePCar = Notification.Name("chPCar")
    static let backFromScene = Notification.Name("baFrSc")
    
    @IBOutlet weak var tabView: NSView!
    @IBOutlet weak var backBtt: NSButton!
    @IBOutlet weak var restoreBtt: NSButton! {
        willSet {
            newValue.layer?.cornerRadius = 9
        }
    }
    @IBOutlet weak var buyBtt: NSButton! {
        willSet {
            newValue.focusRingType = .none
            newValue.layer?.cornerRadius = 9
        }
    }
    
    @IBOutlet weak var leftArr: NSButton!
    @IBOutlet weak var rightArr: NSButton!
    @IBOutlet weak var carImg: NSImageView!
    @IBOutlet weak var carName: NSTextField!
    @IBOutlet weak var descLabel: NSTextField!
    
    private let availableCars = [MVACarNames.playerOrdinary, MVACarNames.playerLives, MVACarNames.playerPCS]
    private var selectedCar = MVAMemory.playerCar
    var store: MVAStore!
    private var waitView: MVAWaitView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabView.wantsLayer = true
        self.view.wantsLayer = true
        tabView.layer?.backgroundColor = CGColor.black
        tabView.layer?.zPosition = -1
        self.view.layer?.backgroundColor = CGColor(red:0.29, green:0.29, blue:0.29, alpha:1.00)
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        view.window!.styleMask.remove(NSWindow.StyleMask.resizable)
        
        let pCar = MVAMemory.playerCar
        carImg.image = NSImage(named: NSImage.Name(rawValue: pCar))
        carName.stringValue = store.mockUpNames[pCar] ?? ""
        selectedCar = pCar
        checkArrows()
    }
    
    private func checkArrows() {
        if MVAMemory.ownedCars.contains(selectedCar) {
            self.buyBtt.title = " USE "
        } else {
            self.buyBtt.title = " \(store.getPrice(forCar: selectedCar)) "
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
            descLabel.stringValue = "You can crash multiple times\nbefore destroying the car"
        case MVACarNames.playerPCS:
            descLabel.stringValue = "Pre-collision system\nhelps to avoid cars"
        default:
            descLabel.stringValue = "Nothing special 😐"
        }
    }
    
    private var canAnimateChange = true
    private func animateChange(inDirection dir: MVAPosition) {
        let newCarView = NSImageView(frame: carImg.frame)
        newCarView.image = NSImage(named: NSImage.Name(rawValue: selectedCar))
        newCarView.frame.origin.x = dir == .right ? 0.0 : self.view.frame.size.width//-newCarView.frame.width/2)
        newCarView.alphaValue = 0.0
        self.view.addSubview(newCarView)
        
        let oldCarView = NSImageView(frame: carImg.frame)
        oldCarView.image = carImg.image
        self.view.addSubview(oldCarView)
        carImg.alphaValue = 0.0
        
        NSAnimationContext.runAnimationGroup({ (context: NSAnimationContext) in
            context.duration = 0.4
            
            oldCarView.animator().frame.origin.x = dir == .right ? self.view.frame.size.width : 0.0
            oldCarView.animator().alphaValue = 0.0
            
            newCarView.animator().frame.origin.x = (self.view.frame.size.width/2)-(newCarView.frame.width/2)
            newCarView.animator().alphaValue = 1.0
        }, completionHandler: { () in
            oldCarView.removeFromSuperview()
            self.carImg.image = newCarView.image
            self.carImg.alphaValue = 1.0
            newCarView.removeFromSuperview()
            self.canAnimateChange = true
        })
    }
    
    func changeCar(_ ind: Int) {
        if canAnimateChange {
            let currentCarIndex = availableCars.index(of: selectedCar)!
            let newIndex = currentCarIndex+ind
            if newIndex >= 0 && newIndex <= (availableCars.count-1) {
                canAnimateChange = false
                let newCarName = availableCars[newIndex]
                selectedCar = newCarName
                carName.stringValue = store.mockUpNames[newCarName] ?? ""
                let direction = ind > 0 ? MVAPosition.left:MVAPosition.right
                animateChange(inDirection: direction)
            }
            checkArrows()
        }
    }
    
    private func purchaseCar() {
        waitView = MVAWaitView.new(withSize: self.view.frame.size) //.new(withSize: self.size, inScene: self)
        self.view.addSubview(waitView)
        
        let completion = { (purchased: Bool, _: String, err: Error?) in
            if purchased && err == nil {
                MVAMemory.ownedCars.append(self.selectedCar)
                self.buyBtt.title = " USE "
                self.selectCar(self.buyBtt)
            }
            self.waitView.remove()
            self.waitView = nil
        }
        
        let error = { () in
            self.waitView.remove()
            self.waitView = nil
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
    
    @IBAction func selectCar(_ sender: NSButton) {
        if sender.title == " USE " {
            if MVAMemory.ownedCars.contains(selectedCar) {
                MVAMemory.playerCar = selectedCar
                NotificationCenter.default.post(name: ChangeCarViewControllerMAC.changePCar, object: nil)
                self.dismissViewController(self)
            }
        } else {
            purchaseCar()
        }
    }
    
    @IBAction func restorePurchases(_ sender: NSButton) {
        waitView = MVAWaitView.new(withSize: self.view.frame.size)
        self.view.addSubview(waitView)
        
        store.restorePurchases() { (purchased: Bool, car: String, error: Error?) in
            if purchased && error == nil {
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
            if self.waitView != nil {
                self.waitView.remove()
                self.waitView = nil
            }
        }
    }
    
    @IBAction func moveCarLeft(_ sender: NSButton) {
        changeCar(-1)
    }
    
    @IBAction func moveCarRight(_ sender: NSButton) {
        changeCar(1)
    }
    
    @IBAction func goBack(_ : Any) {
        NotificationCenter.default.post(name: ChangeCarViewControllerMAC.backFromScene, object: nil)
        self.dismissViewController(self)
    }
    
    
    // MARK: - Keyboard
    override func keyDown(with event: NSEvent) {
        if event.keyCode == KeyCodes.keyESC {
            NotificationCenter.default.post(name: ChangeCarViewControllerMAC.backFromScene, object: nil)
            self.dismissViewController(self)
        } else {
            interpretKeyEvents([event])
        }
    }
    
    override func insertNewline(_ sender: Any?) {
        selectCar(buyBtt)
    }
    
    override func moveLeft(_ sender: Any?) {
        changeCar(-1)
    }
    
    override func moveRight(_ sender: Any?) {
        changeCar(1)
    }
}
