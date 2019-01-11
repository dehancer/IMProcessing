//
//  IMPDistribution.swift
//  Pods
//
//  Created by denis svinarchuk on 18.02.17.
//
//
import Foundation
import Accelerate

public extension Int {
    ///  Create gaussian kernel distribution with kernel size in pixels
    ///
    ///  - parameter size:  kernel size
    ///
    ///  - returns: gaussian kernel piecewise distribution
    public var gaussianKernel:[Float]{
        get{
            let size = self % 2 == 1 ? self : self + 1
            
            let epsilon:Float    = 2e-2 / size.float
            var searchStep:Float = 1.0
            var sigma:Float      = 1.0
            while( true )
            {
                
                let kernel = sigma.gaussianKernel(size: size)
                if kernel[0] > epsilon {
                    
                    if searchStep > 0.02  {
                        sigma -= searchStep
                        searchStep *= 0.1
                        sigma += searchStep
                        continue
                    }
                    
                    var retVal = [Float]()
                    
                    for i in 0 ..< size {
                        retVal.append(kernel[i])
                    }
                    return retVal
                }
                
                sigma += searchStep
                
                if sigma > 1000.0{
                    return [0]
                }
            }
        }
    }
}

// MARK: - Gaussian kernel distribution
public extension Float {
    
    ///  Create gaussian kernel distribution with sigma and kernel size
    ///
    ///  - parameter sigma: kernel sigma
    ///  - parameter size:  kernel size, must be odd number
    ///
    ///  - returns: gaussian kernel piecewise distribution
    ///
    public static func gaussianKernel(sigma:Float, size:Int) -> [Float] {
        
        assert(size%2==1, "gaussian kernel size must be odd number...")
        
        var kernel    = [Float](repeating: 0, count: size)
        let mean      = Float(size/2)
        var sum:Float = 0.0
        
        for x in 0..<size {
            kernel[x] = sqrt( exp( -0.5 * (pow((x.float-mean)/sigma, 2.0) + pow((mean)/sigma,2.0)) )
                / (M_2_PI.float * sigma * sigma) )
            sum += kernel[x]
        }
        
        vDSP_vsdiv(kernel, 1, &sum, &kernel, 1, vDSP_Length(kernel.count))
        return kernel
    }
    
    ///  Create gaussian kernel distribution from sigma value with kernel size
    ///
    ///  - parameter size:  kernel size, must be odd number
    ///
    ///  - returns: gaussian kernel piecewise distribution
    ///
    public func gaussianKernel(size:Int) -> [Float] {
        return Float.gaussianKernel(sigma: self, size: size)
    }
}

// MARK: - Gaussian value in certain point of x
public extension Float{
    
    ///  Get gaussian Y point from distripbution of X in certain point
    ///
    ///  - parameter fi:    ƒ
    ///  - parameter mu:    µ
    ///  - parameter sigma: ß
    ///
    ///  - returns: Y value
    public func gaussianPoint(fi:Float, mu:Float, sigma:Float) -> Float {
        //return fi * exp( -(pow(( self - mu ),2)) / (2*pow(sigma, 2)) )
        return fi * exp( -0.5 * pow( ( self - mu )/sigma, 2)) 
    }
    
    ///  Get double pointed gaussian Y point from distripbution of two X points
    ///
    ///  - parameter fi:    float2(ƒ1,ƒ2)
    ///  - parameter mu:    float2(µ1,µ2)
    ///  - parameter sigma: float2(ß1,ß2)
    ///
    ///  - returns: y value
    public func gaussianPoint(fi:float2, mu:float2, sigma:float2) -> Float {
        
        let c1 = self <= mu.x ? 1.float : 0.float
        let c2 = self >= mu.y ? 1.float : 0.float
        
        let y1 = self.gaussianPoint(fi: fi.x, mu: mu.x, sigma: sigma.x) * c1 + (1.0-c1)
        let y2 = self.gaussianPoint(fi: fi.y, mu: mu.y, sigma: sigma.y) * c2 + (1.0-c2)
        
        return y1 * y2
    }
    
    ///  Get normalized gaussian Y point from distripbution of two X points
    ///
    ///  - parameter fi:    ƒ
    ///  - parameter mu:    µ
    ///  - parameter sigma: ß
    ///
    ///  - returns: y value
    public func gaussianPoint(mu:Float, sigma:Float) -> Float {
        return self.gaussianPoint(fi: 1/(sigma*sqrt(2*Float.pi)), mu: mu, sigma: sigma)
    }
    
    ///  Get double normalized gaussian Y point from distripbution of two X points
    ///
    ///  - parameter fi:    float2(ƒ1,ƒ2)
    ///  - parameter mu:    float2(µ1,µ2)
    ///  - parameter sigma: float2(ß1,ß2)
    ///
    ///  - returns: Y value
    public func gaussianPoint(mu:float2, sigma:float2) -> Float {
        return self.gaussianPoint(fi:float2(1), mu: mu, sigma: sigma)
    }
    
    ///  Create linear range X points within range
    ///
    ///  - parameter r: range
    ///
    ///  - returns: X list
    static func range(_ r:Range<Int>) -> [Float]{
        return range(start: Float(r.lowerBound), step: 1, end: Float(r.upperBound))
    }
    
    
    ///  Create linear range X points within range scaled to particular value
    ///
    ///  - parameter r: range
    ///
    ///  - returns: X list
    static func range(_ r:Range<Int>, scale:Float) -> [Float]{
        var r = range(start: Float(r.lowerBound), step: 1, end: Float(r.upperBound))
        var denom:Float = 0
        vDSP_maxv(r, 1, &denom, vDSP_Length(r.count))
        denom /= scale
        vDSP_vsdiv(r, 1, &denom, &r, 1, vDSP_Length(r.count))
        return r
    }
    
    
    ///  Create linear range X points within range of start/end with certain step
    ///
    ///  - parameter start: start value
    ///  - parameter step:  step, must be less then end-start
    ///  - parameter end:   end, must be great the start
    ///
    ///  - returns: X list
    static func range(start:Float, step:Float, end:Float) -> [Float] {
//        let size       = Int((end-start)/step)
//        
//        var h:[Float]  = [Float](repeating: 0, count: size)
//        var zero:Float = start
//        var v:Float    = step
//        
//        vDSP_vramp(&zero, &v, &h, 1, vDSP_Length(size))
//        
        precondition(start <= end, "start must be no larger than end.")
        
        var startFloat = Float(start)
        var endFloat = Float(end)
        let size   = Int((end-start)/step)
        var result = [Float](repeating: 0.0, count: size)
        
        vDSP_vgen(&startFloat, &endFloat, &result, 1, vDSP_Length(size))
        return result
        
    }
}

// MARK: - Gaussian distribution
public extension Sequence where Iterator.Element == Float {
    
    ///  Create gaussian distribution of discrete values of Y's from mean parameters
    ///
    ///  - parameter fi:    ƒ
    ///  - parameter mu:    µ
    ///  - parameter sigma: ß
    ///
    ///  - returns: discrete gaussian distribution
    public func gaussianDistribution(fi:Float, mu:Float, sigma:Float) -> [Float]{
        var a = [Float]()
        for i in self{
            a.append(i.gaussianPoint(fi: fi, mu: mu, sigma: sigma))
        }
        return a
    }
    
    ///  Create gaussian distribution of discrete values of Y points from two points of means
    ///
    ///  - parameter fi:    float2(ƒ1,ƒ2)
    ///  - parameter mu:    float2(µ1,µ2)
    ///  - parameter sigma: float2(ß1,ß2)
    ///
    ///  - returns: discrete gaussian distribution
    public func gaussianDistribution(fi:float2, mu:float2, sigma:float2) -> [Float]{
        var a = [Float]()
        for i in self{
            a.append(i.gaussianPoint(fi: fi, mu: mu, sigma: sigma))
        }
        return a
    }
    
    ///  Create normalized gaussian distribution of discrete values of Y's from mean parameters
    ///
    ///  - parameter mu:    µ
    ///  - parameter sigma: ß
    ///
    ///  - returns: discrete gaussian distribution
    public func gaussianDistribution(mu:Float, sigma:Float) -> [Float]{
        return self.gaussianDistribution(fi: 1/(sigma*sqrt(2*Float.pi)), mu: mu, sigma: sigma)
    }
    
    ///  Create normalized gaussian distribution of discrete values of Y points from two points of means
    ///
    ///  - parameter mu:    float2(µ1,µ2)
    ///  - parameter sigma: float2(ß1,ß2)
    ///
    ///  - returns: discrete gaussian distribution
    public func gaussianDistribution(mu:float2, sigma:float2) -> [Float]{
        return self.gaussianDistribution(fi: float2(1/(sigma.x*sigma.y*sqrt(2*Float.pi))), mu: mu, sigma: sigma)
    }
}


///
/// In two dimensions, the circular Gaussian function is the distribution function for uncorrelated variates X and Y having
/// a bivariate normal distribution and equal standard deviation sigma=sigma_x=sigma_y,
///
public extension Collection where Iterator.Element == [Float] {
    
    ///  Create 2D gaussian distribution of discrete values of X/Y's
    ///
    ///  - parameter fi:    ƒ
    ///  - parameter mu:    µ
    ///  - parameter sigma: ß
    ///
    ///  - returns: discrete 2D gaussian distribution
    ///
    /// http://mathworld.wolfram.com/GaussianFunction.html
    ///
    public func gaussianDistribution(fi:Float, mu:float2, sigma:float2) -> [Float]{
        if self.count != 2 {
            fatalError("CollectionType must have 2 dimension Float array with X-points and Y-points lists...")
        }
        
        var a  = [Float]()
        for y in self[1 as! Self.Index]{
            let yd = pow(( y - mu.y ),2) / (2*pow(sigma.y, 2))
            for x in self[0 as! Self.Index]{
                let xd = pow(( x - mu.x ),2) / (2*pow(sigma.x, 2))
                a.append(fi * exp( -(xd+yd) ))
            }
        }
        return a
    }
    
    ///  Create normalized 2D gaussian distribution of discrete values of X/Y's
    ///
    ///  - parameter mu:    µ
    ///  - parameter sigma: ß
    ///
    ///  - returns: discrete 2D gaussian distribution
    ///
    /// http://mathworld.wolfram.com/GaussianFunction.html
    ///
    public func gaussianDistribution(mu:float2, sigma:float2) -> [Float]{
        if self.count != 2 {
            fatalError("CollectionType must have 2 dimension Float array with X-points and Y-points lists...")
        }
        let fi = 1/(sigma.x*sigma.y*sqrt(2*Float.pi))
        
        return gaussianDistribution(fi: fi, mu: mu, sigma: sigma)
    }
    
}
