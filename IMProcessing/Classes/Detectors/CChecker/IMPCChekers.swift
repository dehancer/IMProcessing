//
//  IMPCChekers.swift
//  IMPPatchDetectorTest
//
//  Created by Denis Svinarchuk on 06/04/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import simd

//
// http://xritephoto.com/ph_product_overview.aspx?ID=824&Action=Support&SupportID=5159
//
public let IMPPassportCC24:[[uint3]] = [
    [
        uint3(115,82,68),   // dark skin
        uint3(194,150,130), // light skin
        uint3(98,122,157),  // blue sky
        uint3(87,108,67),   // foliage
        uint3(133,128,177), // blue flower
        uint3(103,189,170)  // bluish flower
    ],
    
    [
        uint3(214,126,44), // orange
        uint3(80,91,166),  // purplish blue
        uint3(193,90,99),  // moderate red
        uint3(94,60,108),  // purple
        uint3(157,188,64), // yellow green
        uint3(224,163,46)  // orange yellow
    ],
    
    [
        uint3(56,61,150),  // blue
        uint3(79,148,73),  // green
        uint3(175,54,60),  // red
        uint3(231,199,31), // yellow
        uint3(187,86,149), // magenta
        uint3(8,133,161),  // cyan
    ],
    
    [
        uint3(243,243,242), // white
        uint3(200,200,200), // neutral 8
        uint3(160,160,160), // neutral 6,5
        uint3(122,122,121), // neutral 5
        uint3(85,85,85),    // neutral 3.5
        uint3(52,52,52)     // black
    ]
]

