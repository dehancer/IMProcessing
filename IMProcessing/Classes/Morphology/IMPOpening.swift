//
//  IMPOpening.swift
//  IMPPatchDetectorTest
//
//  Created by Denis Svinarchuk on 03/04/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation

public class IMPOpening: IMPErosion {
    
    public override var dimensions: IMPMorphology.Dimensions {
        didSet{
            dilation.dimensions = dimensions
        }
    }
    
    public override func configure(complete: IMPFilter.CompleteHandler?) {
        extendName(suffix: "Opening")
        super.configure()
        add(filter: dilation) { (source) in
            complete?(source)
        }
    }
    
    private lazy var dilation: IMPDilation = {
        return IMPDilation(context: self.context)
    }()
}
