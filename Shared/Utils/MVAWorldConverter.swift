//
//  MVAWorldConverter.swift
//  unPredictable
//
//  Created by Marian Vinicay on 28/06/2017.
//  Copyright © 2017 Marvin. All rights reserved.
//

import Foundation

struct MVAWorldConverter {
    static var lengthUnit: String {
        if Locale.current.usesMetricSystem {
            return "KM"
        } else {
            return "MI"
        }
    }
    
    static func pointsSpeedToRealWorld(_ spd: Int) -> Int {
        let kmH = spd/5
        if Locale.current.usesMetricSystem {
            return kmH
        } else {
            let miles = Double(kmH)*0.62
            return Int(round(miles/10)*10)
        }
    }
    
    static func milesToKilometers(_ dist: Double) -> Double {
        return dist/0.63
    }
    
    static func distanceToOdometer(_ dist: Double) -> String {
        let formatter = NumberFormatter()
        formatter.locale = nil
        formatter.decimalSeparator = "."
        formatter.numberStyle = .decimal
        formatter.maximumIntegerDigits = 3
        formatter.minimumIntegerDigits = 3
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        return formatter.string(from: NSNumber(value: dist))!
    }
}
