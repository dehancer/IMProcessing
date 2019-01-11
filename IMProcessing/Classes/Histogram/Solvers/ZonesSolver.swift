//
//  ZonesSolver.swift
//  Pods
//
//  Created by denis svinarchuk on 29.07.17.
//
//

import Accelerate

public class IMPHistogramZonesSolver: NSObject, IMPHistogramSolver {
    
    public struct Zones{
        
        ///                           0  I  II  III  IV  V   VI   VII  VIII  IX   X    XI
        public static let indices  = [0, 1, 33, 57,  72, 94, 118, 143, 169,  197, 225, 255]
        
        /// Zone steps
        public var steps    = [Float](repeating: 0, count: Zones.indices.count)
        
        /// Balance
        public var balance  = float3(0)
        
        /// Spots
        public var spots    = float3(0)
        
        /// Range
        public var range    = float3(0)
        
        public init() {}
        
        public mutating func update( histogram:inout [Float], binCount:Float){
            
            var zone_value:Float = 0
            
            for i in 0 ..< steps.count {
                
                let index = Zones.indices[i]
                
                if (i==0 || i==11) {
                    steps[i] = histogram[index]/binCount
                }
                else{
                    let ie = Zones.indices[i+1]
                    let address = UnsafePointer<Float>(histogram)+index
                    vDSP_sve(address, 1, &zone_value, vDSP_Length( ie-index ))
                    steps[i]=zone_value/binCount
                }
            }
            
            balance.x = subzoneSum(histogram: &histogram, multiply: &shadowsWeights)/binCount
            balance.y = subzoneSum(histogram: &histogram, multiply: &midWeights)/binCount
            balance.z = subzoneSum(histogram: &histogram, multiply: &highlightsWeights)/binCount
            
            balance = balance.normalized()
            
            spots.x = steps[3]
            spots.y = steps[5]
            spots.z = steps[7]
            
            spots = spots.normalized()
            
            range.x = steps[1]+steps[2]+steps[3]
            range.y = steps[4]+steps[5]+steps[6]
            range.z = steps[7]+steps[8]+steps[9]
            
            range = range.normalized()
        }
        
        private static let line =  Float.range(0..<256, scale: 1)
        
        fileprivate var shadowsWeights    = Zones.line.gaussianDistribution(fi:1, mu: 0,   sigma: 0.1)
        fileprivate var midWeights        = Zones.line.gaussianDistribution(fi:1, mu: 0.5, sigma: 0.1)
        fileprivate var highlightsWeights = Zones.line.gaussianDistribution(fi:1, mu: 1.0, sigma: 0.2)
        
        private func subzoneSum( histogram:inout [Float], multiply:inout [Float]) -> Float {
            var sum:Float = 0
            var tmp = [Float](repeating: 0, count: multiply.count)
            vDSP_vmul(histogram, 1, multiply, 1, &tmp, 1, vDSP_Length(multiply.count))
            vDSP_sve(tmp, 1, &sum, vDSP_Length(multiply.count))
            return sum
        }
    }
    
    public var complete:CompleteHandler?

    public var zones = Zones()
    
    public func analizer(didUpdate analizer: IMPHistogramAnalyzerProtocol, histogram: IMPHistogram, imageSize: CGSize) {
        var h = histogram[.w]
        zones.update(histogram: &h, binCount: histogram.countOfBins(forChannel: .w))
    }
}
