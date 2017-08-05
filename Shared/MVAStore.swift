//
//  MVAStore.swift
//  unPredictable
//
//  Created by Majo on 26/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

#if os(iOS) || os(tvOS) || os(macOS)
    import StoreKit
    class MVAStore: NSObject, SKProductsRequestDelegate, SKPaymentTransactionObserver {
        func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
            for transaction in transactions {
                switch transaction.transactionState {
                case SKPaymentTransactionState.purchased:
                    print("Transaction completed successfully.")
                    SKPaymentQueue.default().finishTransaction(transaction)
                    transactionInProgress = false
                    completion?(true)
                    
                case SKPaymentTransactionState.failed:
                    SKPaymentQueue.default().finishTransaction(transaction)
                    transactionInProgress = false
                    completion?(false)
                    
                default:
                    print(transaction.transactionState.rawValue)
                }
            }
        }
        
        func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
            if response.products.count != 0 {
                productsArray = response.products
            }
            else {
                print("There are no products.")
            }
        }
        
        var productIDs = ["unpredictable.continueAfterCrash"]
        var productsArray = [SKProduct]()
        var transactionInProgress = false
        var completion: ((Bool)->())?
        
        override init() {
            super.init()
            requestProductInfo()
            SKPaymentQueue.default().add(self)
        }
        
        func buy(withCompletion comp: @escaping (Bool)->()) {
            if !transactionInProgress {
                transactionInProgress = true
                let payment = SKPayment(product: productsArray.first!)
                SKPaymentQueue.default().add(payment)
                completion = comp
            }
        }
        
        func requestProductInfo() {
            if SKPaymentQueue.canMakePayments() {
                let productIdentifiers = Set(productIDs)
                let productRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
                
                productRequest.delegate = self
                productRequest.start()
            } else {
                print("Cannot perform In App Purchases.")
            }
        }
    }
#elseif os(watchOS)
    class MVAStore {}
#endif
