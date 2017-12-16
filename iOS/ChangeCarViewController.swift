//
//  ChangeCarViewController.swift
//  unPredictable - iOS
//
//  Created by Majo on 16/12/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import UIKit

class ChangeCarViewController: UIViewController, UIGestureRecognizerDelegate {
    static let backFromScene = Notification.Name("backFromCCScene")
    static let changePCar = Notification.Name("chPCar")
    
    @IBOutlet weak var backBtt: UIBarButtonItem!
    @IBOutlet weak var restoreBtt: UIButton! {
        willSet {
            newValue.layer.cornerRadius = 9
        }
    }
    @IBOutlet weak var enableAdsBtt: UIButton! {
        willSet {
            newValue.layer.cornerRadius = 9
        }
    }
    @IBOutlet weak var orLabel: UILabel!
    @IBOutlet weak var buyBtt: UIButton! {
        willSet {
            newValue.layer.cornerRadius = 9
        }
    }

    @IBOutlet weak var leftArr: UIButton!
    @IBOutlet weak var rightArr: UIButton!
    @IBOutlet weak var carImg: UIImageView!
    @IBOutlet weak var carName: UILabel!
    @IBOutlet weak var descLabel: UILabel!
        
    #if os(iOS) || os(tvOS)
    var myRecongizers = [UIGestureRecognizer]()
    #endif
    
    private let availableCars = [MVACarNames.playerOrdinary, MVACarNames.playerLives, MVACarNames.playerPCS]
    private var selectedCar = MVAMemory.playerCar
    private let ads = MVAAds(config: .onlyVideo)
    var store: MVAStore!
    private var waitView: MVAWaitView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ads.successHandler = { [unowned self] (rewarded: Bool) in
            if rewarded {
                MVAMemory.adCar = self.selectedCar
                MVAMemory.playerCar = self.selectedCar
                MVAMemory.adsEnabled = true
                self.enableAdsBtt.isHidden = true
                self.orLabel.isHidden = true
                self.buyBtt.setTitle(" USE ", for: .normal)
                self.removeSwipes()
                NotificationCenter.default.post(name: ChangeCarViewController.changePCar, object: nil)
            } else {
                MVAMemory.adsEnabled = false
                self.enableAdsBtt.isHidden = false
                self.orLabel.isHidden = false
                self.buyBtt.setTitle(" BUY ", for: .normal)
            }
        }
        ads.completionHandler = {}
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let pCar = MVAMemory.playerCar
        carImg.image = UIImage(named: pCar)
        carName.text = store.mockUpNames[pCar]
        selectedCar = pCar
        checkArrows()
    }
    
    private func checkArrows() {
        if MVAMemory.ownedCars.contains(selectedCar) {
            self.enableAdsBtt.isHidden = true
            self.orLabel.isHidden = true
            self.buyBtt.setTitle(" USE ", for: .normal)
        } else if MVAMemory.adCar == selectedCar {
            self.enableAdsBtt.isHidden = true
            self.orLabel.isHidden = true
            self.buyBtt.setTitle(" \(store.getPrice(forCar: selectedCar)) ", for: .normal)
        } else {
            self.enableAdsBtt.isHidden = false
            self.orLabel.isHidden = false
            self.buyBtt.setTitle(" \(store.getPrice(forCar: selectedCar)) ", for: .normal)
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
            descLabel.text = "You can crash multiple times\nbefore destroying the car"
        case MVACarNames.playerPCS:
            descLabel.text = "Pre-collision system\nhelps to avoid cars"
        default:
            descLabel.text = "Nothing special 😐"
        }
    }
    
    private func animateChange(inDirection dir: MVAPosition) {
        let newCarView = UIImageView(frame: carImg.frame)
        newCarView.image = UIImage(named: selectedCar)
        newCarView.frame.origin.x = dir == .right ? 0.0 : self.view.frame.size.width//-newCarView.frame.width/2)
        newCarView.alpha = 0.0
        self.view.addSubview(newCarView)
        
        UIView.animate(withDuration: 0.4, animations: {
            self.carImg.frame.origin.x = dir == .right ? self.view.frame.size.width : 0.0
            self.carImg.alpha = 0.0
            
            newCarView.frame.origin.x = (self.view.frame.size.width/2)-(newCarView.frame.width/2)
            newCarView.alpha = 1.0
        }) { (end: Bool) in
            self.carImg.removeFromSuperview()
            self.carImg = newCarView
            self.leftArr.isUserInteractionEnabled = true
            self.rightArr.isUserInteractionEnabled = true
        }
    }
    
    func changeCar(_ ind: Int) {
        let currentCarIndex = availableCars.index(of: selectedCar)!
        let newIndex = currentCarIndex+ind
        if newIndex >= 0 && newIndex <= (availableCars.count-1) {
            let newCarName = availableCars[newIndex]
            selectedCar = newCarName
            carName.text = store.mockUpNames[newCarName]
            self.leftArr.isUserInteractionEnabled = false
            self.rightArr.isUserInteractionEnabled = false
            let direction = ind > 0 ? MVAPosition.left:MVAPosition.right
            animateChange(inDirection: direction)
        }
        checkArrows()
    }
    
    private func purchaseCar() {
        waitView = MVAWaitView.new(withSize: self.view.frame.size) //.new(withSize: self.size, inScene: self)
        self.view.addSubview(waitView)
        
        let completion = { (purchased:Bool, _:String, err:Error?) in
            if purchased && err == nil {
                MVAMemory.adsEnabled = false
                MVAMemory.ownedCars.append(self.selectedCar)
                MVAMemory.adCar = nil
                self.enableAdsBtt.isHidden = true
                self.orLabel.isHidden = true
                self.buyBtt.setTitle(" USE ", for: .normal)
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
    
    func selectCar() {
        if buyBtt.title(for: .normal) == " USE " {
            if MVAMemory.ownedCars.contains(selectedCar) {
                #if os(iOS) || os(tvOS)
                    removeSwipes()
                #endif
                MVAMemory.playerCar = selectedCar
                MVAMemory.adCar = nil
                MVAMemory.adsEnabled = false
                NotificationCenter.default.post(name: ChangeCarViewController.changePCar, object: nil)
            }
        } else {
            purchaseCar()
        }
    }
    
    @IBAction func restorePurchases(_ sender: UIButton) {
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
    
    @IBAction func moveCarLeft(_ sender: UIButton) {
        changeCar(-1)
    }
    
    @IBAction func moveCarRight(_ sender: UIButton) {
        changeCar(1)
    }
    
    @IBAction func useCar(_ sender: UIButton) {
        if sender.title(for: .normal) == " USE " {
            selectCar()
        } else {
            purchaseCar()
        }
    }
    
    @IBAction func enableAds(_ sender: UIButton) {
        ads.showAd()
    }
    
    // MARK: - Swipes
    func setupSwipes() {
        let right = UISwipeGestureRecognizer(target: self, action: #selector(swipeGesture(swipe:)))
        right.direction = .right
        
        let left = UISwipeGestureRecognizer(target: self, action: #selector(swipeGesture(swipe:)))
        left.direction = .left
        
        right.delegate = self
        left.delegate = self
        
        let back = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(goBack(eSwipe:)))
        back.edges = .left
        
        view?.addGestureRecognizer(right)
        view?.addGestureRecognizer(left)
        view?.addGestureRecognizer(back)
        
        myRecongizers = [right,left,back]
    }
    
    func removeSwipes() {
        myRecongizers.forEach({ view?.removeGestureRecognizer($0) })
    }
    
    @objc func swipeGesture(swipe: UIGestureRecognizer) {
        if (swipe as? UISwipeGestureRecognizer)?.direction == .left {
            changeCar(1)
        } else if (swipe as? UISwipeGestureRecognizer)?.direction == .right {
            changeCar(-1)
        }
    }
    
    @objc func goBack(eSwipe: UIGestureRecognizer) {
        if eSwipe is UIScreenEdgePanGestureRecognizer {
            if eSwipe.state == .began {
                removeSwipes()
                NotificationCenter.default.post(name: ChangeCarViewController.backFromScene, object: nil)
                self.performSegue(withIdentifier: "goBack", sender: nil)
            }
        }
    }
}
