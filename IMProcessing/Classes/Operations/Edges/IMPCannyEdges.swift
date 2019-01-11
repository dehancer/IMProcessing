//
//  IMPCannyEdgeDetection.swift
//  IMPCameraManager
//
//  Created by denis svinarchuk on 10.03.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation
import Metal

/** This applies the edge detection process described by John Canny in
 
 Canny, J., A Computational Approach To Edge Detection, IEEE Trans. Pattern Analysis and Machine Intelligence, 8(6):679–698, 1986.
 
 and implemented in OpenGL ES by
 
 A. Ensor, S. Hall. GPU-based Image Analysis on Mobile Devices. Proceedings of Image and Vision Computing New Zealand 2011.
 
 It starts with a conversion to luminance, followed by an accelerated 9-hit Gaussian blur. A Sobel operator is applied to obtain the overall
 gradient strength in the blurred image, as well as the direction (in texture sampling steps) of the gradient. A non-maximum suppression filter
 acts along the direction of the gradient, highlighting strong edges that pass the threshold and completely removing those that fail the lower
 threshold. Finally, pixels from in-between these thresholds are either included in edges or rejected based on neighboring pixels.
 
 Sources:  https://github.com/BradLarson/GPUImage2

 */

public class IMPCannyEdges: IMPResampler{
    
    public static let defaultBlurRadius:Float = 2
    
    public var blurRadius:Float {
        set{
            blurFilter.radius = newValue
            dirty = true
        }
        get { return blurFilter.radius }
    }
    
    public var upperThreshold:Float {
        set{
            directionalNonMaximumSuppression.upperThreshold = newValue
            dirty = true
        }
        get { return directionalNonMaximumSuppression.upperThreshold }
    }
    
    public var lowerThreshold:Float {
        set{
            directionalNonMaximumSuppression.lowerThreshold = newValue
            dirty = true
        }
        get { return directionalNonMaximumSuppression.lowerThreshold }
    }

    
    public override func configure(complete:CompleteHandler?=nil) {
        
        extendName(suffix: "CannyEdgeDetector")
        super.configure()
            
        blurRadius = IMPCannyEdges.defaultBlurRadius

        add(function: luminance)
        add(filter: blurFilter)
        add(filter: sobelEdgeFilter)
        add(filter: directionalNonMaximumSuppression)
        add(filter: weakPixelInclusion){ (source) in
            complete?(source)
        }
    }
    
    private lazy var luminance:IMPFunction = IMPFunction(context: self.context, kernelName: "kernel_luminance")
    
    private lazy var blurFilter:IMPGaussianBlur = IMPGaussianBlur(context: self.context)
    private lazy var directionalNonMaximumSuppression:IMPDirectionalNonMaximumSuppression = IMPDirectionalNonMaximumSuppression(context: self.context)

    private lazy var sobelEdgeFilter:IMPSobelEdges = IMPSobelEdges(context: self.context)
    //private lazy var sobelEdgeFilter:IMPDerivative = IMPDerivative(context: self.context, functionName: "fragment_directionalSobelEdge")
    //private lazy var sobelEdgeFilter:IMPSobelEdgesGradient = IMPSobelEdgesGradient(context: self.context)
    
    private lazy var weakPixelInclusion:IMPDerivative = IMPDerivative(context: self.context, functionName: "fragment_weakPixelInclusion")
}
