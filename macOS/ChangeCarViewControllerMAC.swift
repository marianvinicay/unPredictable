//
//  ChangeCarViewController.swift
//  unPredictable - iOS
//
//  Created by Majo on 16/12/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import AppKit

class ChangeCarViewController: NSViewController {
    static let changePCar = Notification.Name("chPCar")
    
    @IBOutlet weak var backBtt: NSButton!
    @IBOutlet weak var restoreBtt: NSButton! {
        willSet {
            newValue.layer?.cornerRadius = 9
        }
    }
    @IBOutlet weak var enableAdsBtt: NSButton! {
        willSet {
            newValue.layer?.cornerRadius = 9
        }
    }
    @IBOutlet weak var orLabel: NSTextField!
    @IBOutlet weak var buyBtt: NSButton! {
        willSet {
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
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        let pCar = MVAMemory.playerCar
        carImg.image = NSImage(named: NSImage.Name(rawValue: pCar))
        carName.stringValue = store.mockUpNames[pCar] ?? ""
        selectedCar = pCar
        checkArrows()
    }
    
    private func checkArrows() {
        if MVAMemory.ownedCars.contains(selectedCar) {
            self.enableAdsBtt.isHidden = true
            self.orLabel.isHidden = true
            self.buyBtt.title = " USE "
        } else if MVAMemory.adCar == selectedCar {
            self.enableAdsBtt.isHidden = true
            self.orLabel.isHidden = true
            self.buyBtt.title = " \(store.getPrice(forCar: selectedCar)) "
        } else {
            self.enableAdsBtt.isHidden = false
            self.orLabel.isHidden = false
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
    
    private func animateChange(inDirection dir: MVAPosition) {
        /*let newCarView = NSImageView(frame: carImg.frame)
        newCarView.image = NSImage(named: NSImage.Name(rawValue: selectedCar))
        newCarView.frame.origin.x = dir == .right ? 0.0 : self.view.frame.size.width//-newCarView.frame.width/2)
        newCarView.alpha = 0.0
        self.view.addSubview(newCarView)
        
        let oldCarView = NSImageView(frame: carImg.frame)
        oldCarView.image = carImg.image
        self.view.addSubview(oldCarView)
        carImg.alpha = 0.0
        
        UIView.animate(withDuration: 0.4, animations: {
            oldCarView.frame.origin.x = dir == .right ? self.view.frame.size.width : 0.0
            oldCarView.alpha = 0.0
            
            newCarView.frame.origin.x = (self.view.frame.size.width/2)-(newCarView.frame.width/2)
            newCarView.alpha = 1.0
        }) { (end: Bool) in
            oldCarView.removeFromSuperview()
            self.carImg.image = newCarView.image
            self.carImg.alpha = 1.0
            newCarView.removeFromSuperview()
            self.leftArr.isUserInteractionEnabled = true
            self.rightArr.isUserInteractionEnabled = true
        }*/
    }
    
    func changeCar(_ ind: Int) {
        let currentCarIndex = availableCars.index(of: selectedCar)!
        let newIndex = currentCarIndex+ind
        if newIndex >= 0 && newIndex <= (availableCars.count-1) {
            let newCarName = availableCars[newIndex]
            selectedCar = newCarName
            carName.stringValue = store.mockUpNames[newCarName] ?? ""
            //self.leftArr.isUserInteractionEnabled = false
            //self.rightArr.isUserInteractionEnabled = false
            let direction = ind > 0 ? MVAPosition.left:MVAPosition.right
            animateChange(inDirection: direction)
        }
        checkArrows()
    }
    
    private func purchaseCar() {
        waitView = MVAWaitView.new(withSize: self.view.frame.size) //.new(withSize: self.size, inScene: self)
        self.view.addSubview(waitView)
        
        let completion = { (purchased: Bool, _: String, err: Error?) in
            if purchased && err == nil {
                MVAMemory.adsEnabled = false
                MVAMemory.ownedCars.append(self.selectedCar)
                MVAMemory.adCar = nil
                self.enableAdsBtt.isHidden = true
                self.orLabel.isHidden = true
                self.buyBtt.title = " USE "
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
                MVAMemory.adCar = nil
                MVAMemory.adsEnabled = false
                NotificationCenter.default.post(name: ChangeCarViewController.changePCar, object: nil)
                //self.performSegue(withIdentifier: "goBack", sender: nil)
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
}
