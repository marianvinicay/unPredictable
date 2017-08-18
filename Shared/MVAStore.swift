//
//  MVAStore.swift
//  unPredictable
//
//  Created by Majo on 26/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import StoreKit

class MVAStore: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        if queue.transactions.isEmpty {
            completion?(false, nil)
        }
    }
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased, .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                completion?(true,transaction.payment.productIdentifier)
            case .failed:
                SKPaymentQueue.default().finishTransaction(transaction)
                transactionInProgress = false
                completion?(false, nil)
            default: break
            }
        }
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if response.products.count != 0 {
            productsArray = response.products
        }
    }
    
    var productIDs = ["life":"unpredictable.continueAfterCrash", "lives_car":"unpredictable.lives_car"]
    var productsArray = [SKProduct]()
    var transactionInProgress = false
    private var completion: ((Bool,String?)->())?
    
    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        requestProductInfo()
    }
    
    func buyLife(withCompletion comp: @escaping (Bool,String?)->()) {
        if !transactionInProgress {
            transactionInProgress = true
            if let cLife = productsArray.filter({ $0.productIdentifier == productIDs["life"] }).first {
                let payment = SKPayment(product: cLife)
                SKPaymentQueue.default().add(payment)
                completion = comp
            }
        }
    }
    
    func buyMudiCar(withCompletion comp: @escaping (Bool, String?)->()) {
        if !transactionInProgress {
            transactionInProgress = true
            if let mCar = productsArray.filter({ $0.productIdentifier == productIDs["lives_car"] }).first {
                let payment = SKPayment(product: mCar)
                SKPaymentQueue.default().add(payment)
                completion = comp
            }
        }
    }
    
    func restorePurchases(withCompletion comp: @escaping (Bool, String?)->()) {
        SKPaymentQueue.default().restoreCompletedTransactions()
        completion = comp
    }
    
    func getCarPrice() -> String {
        if let mCar = productsArray.filter({ $0.productIdentifier == productIDs["lives_car"] }).first {
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
