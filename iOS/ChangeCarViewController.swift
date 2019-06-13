//
//  ChangeCarViewController.swift
//  unPredictable
//
//  Created by Marian Vinicay on 16/12/2017.
//  Copyright © 2017 Marvin. All rights reserved.
//

import UIKit

class ChangeCarViewController: UIViewController {
    
    static let changePCar = Notification.Name("chPCar")
    
    @IBOutlet weak var backBtt: UIBarButtonItem!
    @IBOutlet weak var buyBtt: UIButton! {
        willSet {
            newValue.layer.cornerRadius = 9
        }
    }

    @IBOutlet weak var leftArr: UIButton!
    @IBOutlet weak var rightArr: UIButton!
    @IBOutlet var swipeGestures: [UISwipeGestureRecognizer]!
    @IBOutlet weak var carImg: UIImageView!
    @IBOutlet weak var carName: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    
    private let availableCars = [MVACarNames.playerOrdinary, MVACarNames.playerLives, MVACarNames.playerPCS]
    private var selectedCar = MVAMemory.playerCar
    var store: MVAStore!
    private var waitView: MVAWaitView!
    
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
            self.buyBtt.setTitle(" USE ", for: .normal)
        } else {
            self.buyBtt.setTitle(" \(store.getPrice(forCar: selectedCar)) ", for: .normal)
        }
        
        switch availableCars.firstIndex(of: selectedCar)! {
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
        newCarView.frame.origin.x = dir == .right ? 0.0 : self.view.frame.size.width
        newCarView.alpha = 0.0
        self.view.addSubview(newCarView)
        
        let oldCarView = UIImageView(frame: carImg.frame)
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
            for gest in self.swipeGestures {
                gest.isEnabled = true
            }
        }
    }
    
    private func changeCar(_ ind: Int) {
        let currentCarIndex = availableCars.firstIndex(of: selectedCar)!
        let newIndex = currentCarIndex+ind
        if newIndex >= 0 && newIndex <= (availableCars.count-1) {
            let newCarName = availableCars[newIndex]
            selectedCar = newCarName
            carName.text = store.mockUpNames[newCarName]
            self.leftArr.isUserInteractionEnabled = false
            self.rightArr.isUserInteractionEnabled = false
            for gest in self.swipeGestures {
                gest.isEnabled = false
            }
            let direction = ind > 0 ? MVAPosition.left:MVAPosition.right
            animateChange(inDirection: direction)
        }
        checkArrows()
    }
    
    private func purchaseCar() {
        waitView = MVAWaitView.new(withSize: self.view.frame.size)
        self.view.addSubview(waitView)
        backBtt.isEnabled = false
        
        let completion = { (purchased: Bool, _: String, err: Error?) in
            self.backBtt.isEnabled = true
            
            if purchased && err == nil {
                MVAMemory.ownedCars.append(self.selectedCar)
                self.buyBtt.setTitle(" USE ", for: .normal)
            }
            self.waitView.remove()
            self.waitView = nil
        }
        
        let error = { () in
            self.backBtt.isEnabled = true
            self.waitView.remove()
            self.waitView = nil
            MVAPopup.createOKPopup(withMessage: "Sorry\n\nServer is unreachable").present()
        }
        
        switch selectedCar {
        case MVACarNames.playerLives:
            store.buyLivesCar(withCompletion: completion, andError: error)
        case MVACarNames.playerPCS:
            store.buyPCSCar(withCompletion: completion, andError: error)
        default: break
        }
    }
    
    @IBAction func selectCar(_ sender: UIButton) {
        if sender.title(for: .normal) == " USE " {
            if MVAMemory.ownedCars.contains(selectedCar) {
                MVAMemory.playerCar = selectedCar
                NotificationCenter.default.post(name: ChangeCarViewController.changePCar, object: nil)
                self.performSegue(withIdentifier: "goBack", sender: nil)
            }
        } else {
            purchaseCar()
        }
    }
    
    @IBAction func restorePurchases(_ sender: UIBarButtonItem) {
        waitView = MVAWaitView.new(withSize: self.view.frame.size)
        self.view.addSubview(waitView)
        backBtt.isEnabled = false
        sender.isEnabled = false
        
        store.restorePurchases() { (purchased: Bool, car: String, error: Error?) in
            self.backBtt.isEnabled = true
            sender.isEnabled = true
            
            if purchased && error == nil {
                switch car {
                case self.store.productIDs["lives_car"]!: MVAMemory.ownedCars.append(MVACarNames.playerLives)
                case self.store.productIDs["pcs_car"]!: MVAMemory.ownedCars.append(MVACarNames.playerPCS)
                default: break
                }
                self.checkArrows()
            } else if error != nil {
                let alertMsg = error == nil ? "Server is unreachable" : error!.localizedDescription
                MVAPopup.createOKPopup(withMessage: "Sorry\n\n\(alertMsg)")
                    
                    .present()
            }
            self.waitView.remove()
            self.waitView = nil
        }
    }
    
    @IBAction func moveCarLeft(_ sender: UIButton) {
        changeCar(-1)
    }
    
    @IBAction func moveCarRight(_ sender: UIButton) {
        changeCar(1)
    }
    
    @IBAction func swipeGesture(_ sender: UIGestureRecognizer) {
        if (sender as? UISwipeGestureRecognizer)?.direction == .left {
            changeCar(1)
        } else if (sender as? UISwipeGestureRecognizer)?.direction == .right {
            changeCar(-1)
        }
    }
    
    @IBAction func goBack(_ sender: UIGestureRecognizer) {
        if sender.state == .began {
            self.performSegue(withIdentifier: "goBack", sender: nil)
        }
    }
    
}
