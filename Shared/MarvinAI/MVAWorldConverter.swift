//
//  MVAWorldConverter.swift
//  (un)Predictable
//
//  Created by Majo on 28/06/2017.
//  Copyright © 2017 MarVin. All rights reserved.
//

import Foundation

struct MVAWorldConverter {
    static func toKMHFromPoints(_ pts: Double) -> Measurement<UnitLength> {
        return Measurement(value: pts/5, unit: UnitLength.kilometers)
    }
}
