//
//  IMPBoxBlur.swift
//  IMPBaseOperations
//
//  Created by denis svinarchuk on 31.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation

public class IMPBoxBlur: IMPBaseBlur {
    public override func weights(radius inPixels: Int, sigma: Float) -> [Float] {
        let boxWeight = 1.0 / (Float(inPixels * 2) + 1 )
        var weights = [Float]()
        for _ in 0...inPixels {
            weights.append(boxWeight)
        }
        return weights
    }
}
