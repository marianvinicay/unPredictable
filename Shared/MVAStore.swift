//
//  MVAStore.swift
//  unPredictable
//
//  Created by Marian Vinicay on 26/07/2017.
//  Copyright © 2017 Marvin. All rights reserved.
//

import StoreKit

class MVAStore: NSObject, SKProductsRequestDelegate {
    
    //promoted IAPs
    func paymentQueue(_ queue: SKPaymentQueue, shouldAddStorePayment payment: SKPayment, for product: SKProduct) -> Bool {
        switch payment.productIdentifier {
        case productIDs["lives_car"]!:
            if MVAMemory.ownedCars.contains(MVACarNames.playerLives) {
                MVAPopup.createOKPopup(withMessage: "Hooray!\n\nYou've already purchased \(mockUpNames[MVACarNames.playerLives]!) car").present()
                return false
            }
        case productIDs["pcs_car"]!:
            if MVAMemory.ownedCars.contains(MVACarNames.playerPCS) {
                MVAPopup.createOKPopup(withMessage: "Hooray!\n\nYou've already purchased \(mockUpNames[MVACarNames.playerPCS]!) car").present()
                return false
            }
        default: break
        }
        return true
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        transactionInProgress = false
        DispatchQueue.main.async {
            self.completion?(false, "", error)
        }
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        transactionInProgress = false
        if queue.transactions.isEmpty {
            DispatchQueue.main.async {
                self.completion?(false, "", nil)
            }
        }
        MVAPopup.createOKPopup(withMessage: "Purchases were restored").present()
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                DispatchQueue.main.async {
                    self.completion?(true,transaction.payment.productIdentifier,nil)
                }
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                DispatchQueue.main.async {
                    self.completion?(false,"",nil)
                }
            default: break
            }
        }
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.count != 0 {
            productsArray = response.products
        }
    }
    
    #if os(iOS)
    var productIDs = ["life":"unpredictable.continueAfterCrash",
                      "lives_car":"unpredictable.lives_car",
                      "pcs_car":"unpredictable.pcs_car"]
    #elseif os(macOS)
    var productIDs = ["life":"mac.unpredictable.continueAfterCrash",
                      "lives_car":"mac.unpredictable.lives_car",
                      "pcs_car":"mac.unpredictable.pcs_car"]
    #endif
    
    var productsArray = [SKProduct]()
    var transactionInProgress = false
    private var completion: ((Bool, String, Error?)->())?
    
    let mockUpNames = [MVACarNames.playerOrdinary:"Norm",
                       MVACarNames.playerLives:"Mudi",
                       MVACarNames.playerPCS:"Veep"]
    
    override init() {
        super.init()
        requestProductInfo()
    }
    
    func canBuyLife() -> Bool {
        if productsArray.map({ $0.productIdentifier == productIDs["life"] }).isEmpty == false {
            return true
        }
        return false
    }
    
    func buyLife(withCompletion comp: @escaping (Bool, String, Error?)->()) {
        if !transactionInProgress {
            transactionInProgress = true
            if let cLife = productsArray.filter({ $0.productIdentifier == productIDs["life"] }).first {
                let payment = SKPayment(product: cLife)
                SKPaymentQueue.default().add(payment)
                completion = comp
            }
        }
    }
    
    func buyLivesCar(withCompletion comp: @escaping (Bool, String, Error?)->(), andError error: @escaping (()->())) {
        if !transactionInProgress {
            if let mCar = productsArray.filter({ $0.productIdentifier == productIDs["lives_car"] }).first {
                transactionInProgress = true
                let payment = SKPayment(product: mCar)
                SKPaymentQueue.default().add(payment)
                completion = comp
                return
            }
        }
        error()
    }
    
    func buyPCSCar(withCompletion comp: @escaping (Bool, String, Error?)->(), andError error: @escaping (()->())) {
        if !transactionInProgress {
            if let mCar = productsArray.filter({ $0.productIdentifier == productIDs["pcs_car"] }).first {
                transactionInProgress = true
                let payment = SKPayment(product: mCar)
                SKPaymentQueue.default().add(payment)
                completion = comp
                return
            }
        }
        error()
    }
    
    func restorePurchases(withCompletion comp: @escaping (Bool, String, Error?)->()) {
        if !transactionInProgress {
            transactionInProgress = true
            SKPaymentQueue.default().restoreCompletedTransactions()
            completion = comp
        }
    }
    
    func getPrice(forCar carN: String) -> String {
        let carID = carN == MVACarNames.playerLives ? "lives_car":"pcs_car"
        if let mCar = productsArray.filter({ $0.productIdentifier == productIDs[carID] }).first {
            if mCar.price == 0.0 {
                return "FREE"
            } else {
                let numberF = NumberFormatter()
                numberF.numberStyle = .currency
                numberF.locale = mCar.priceLocale
                return numberF.string(from: mCar.price) ?? "BUY"
            }
        } else {
            return "BUY"
        }
    }
    
    func requestProductInfo() {
        if SKPaymentQueue.canMakePayments() {
            let productIdentifiers = Set(productIDs.values)
            let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
            
            productRequest.delegate = self
            productRequest.start()
        }
    }
}
