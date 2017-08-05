//
//  MVAHealthKit.swift
//  unPredictable
//
//  Created by Majo on 26/07/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//
import Foundation

#if os(iOS) || os(watchOS)
    import HealthKit
    class MVAHealthKit {
        private var healthStore: HKHealthStore?
        private var granted = false
        
        func initiateKit() {
            if HKHealthStore.isHealthDataAvailable() {
                healthStore = HKHealthStore()
            }
            if let mType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.mindfulSession) {
                let shareType = Set([mType])
                healthStore?.requestAuthorization(toShare: shareType, read: nil, completion: { (grn: Bool, err: Error?) in
                    self.granted = grn
                })
            }
        }
        
        func logTime(withStart start: Date) {
            if granted {
                if let mType = HKCategoryType.categoryType(forIdentifier: HKCategoryTypeIdentifier.mindfulSession) {
                    let mSample = HKCategorySample(type: mType, value: 0, start: start, end: Date())
                    healthStore?.save(mSample, withCompletion: { (saved: Bool, err: Error?) in
                        //???
                    })
                }
            }
        }
    }
#else
    class MVAHealthKit {
        func initiateKit() {}
        func logTime(withStart start: Date) {}
    }
#endif
