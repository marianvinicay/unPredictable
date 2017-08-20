//
//  MVAStore.swift
//  unPredictable
//
//  Created by Majo on 26/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import StoreKit

class MVAStore: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    
    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        transactionInProgress = false
        completion?(false,"",error)
    }
    
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        transactionInProgress = false
        if queue.transactions.isEmpty {
            self.completion?(false,"",nil)
        }
        let alert = MVAAlert.new(withTitle: nil, andMessage: "Purchases were restored")
        MVAAlert.present(alert)
    }
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                completion?(true,transaction.payment.productIdentifier,nil)
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                completion?(false,"",nil)
            default: break
            }
        }
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.count != 0 {
            productsArray = response.products
        }
    }
    
    var productIDs = ["life":"unpredictable.continueAfterCrash",
                      "lives_car":"unpredictable.lives_car",
                      "pcs_car":"unpredictable.pcs_car"]
    var productsArray = [SKProduct]()
    var transactionInProgress = false
    private var completion: ((Bool, String, Error?)->())?
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
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
            let numberF = NumberFormatter()
            numberF.numberStyle = .currency
            numberF.locale = mCar.priceLocale
            return numberF.string(from: mCar.price) ?? "BUY"
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
