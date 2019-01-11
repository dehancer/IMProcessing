//
//  IMPClosing.swift
//  IMPPatchDetectorTest
//
//  Created by Denis Svinarchuk on 03/04/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation

public class IMPClosing:  IMPDilation {
    
    public override var dimensions: IMPMorphology.Dimensions {
        didSet{
            erosion.dimensions = dimensions
        }
    }
    
    public override func configure(complete: IMPFilter.CompleteHandler?) {
        extendName(suffix: "Closing")
        super.configure()
        add(filter: erosion){ (source) in
            complete?(source)
        }
    }
    
    private lazy var erosion: IMPErosion = {
        return IMPErosion(context: self.context)
    }()
}
