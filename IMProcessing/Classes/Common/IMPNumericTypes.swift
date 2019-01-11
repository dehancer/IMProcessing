//
//  IMPNumericTypes.swift
//  IMPCoreImageMTLKernel
//
//  Created by denis svinarchuk on 11.02.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif

public extension String {
    
    public var floatValue: Float {
        return (self as NSString).floatValue
    }
    public var intValue: Int {
        return (self as NSString).integerValue
    }
    public var isNumeric: Bool {
        if Float(self) != nil {
            return true
        }
        else if Int(self) != nil {
            return true
        }
        return false
    }
}

public extension Double{
    
    public var int:Int{
        get{
            return Int(self)
        }
        set(newValue){
            self = Double(newValue)
        }
    }
    
    public var float:Float{
        get{
            return Float(self)
        }
        set(newValue){
            self = Double(newValue)
        }
    }
    public var cgfloat:CGFloat{
        get{
            return CGFloat(self)
        }
        set(newValue){
            self = Double(newValue)
        }
    }
}

public extension Float{
    
    public var double:Double{
        get{
            return Double(self)
        }
        set(newValue){
            self = Float(newValue)
        }
    }
    public var int:Int{
        get{
            return self.isFinite ? Int(self):Int.max
        }
        set(newValue){
            self = Float(newValue)
        }
    }
    public var cgfloat:CGFloat{
        get{
            return CGFloat(self)
        }
        set(newValue){
            self = Float(newValue)
        }
    }
}


public extension Float {
    /// Convert radians to degrees
    public var degrees:Float{
        return self * (180 / Float.pi)
    }
    /// Convert degrees to radians
    public var radians:Float{
        return self * (Float.pi / 180)
    }
}

public extension Int {
    
    public var double:Double{
        get{
            return Double(self)
        }
        set(newValue){
            self = Int(newValue)
        }
    }
    
    public var float:Float{
        get{
            return Float(self)
        }
        set(newValue){
            self = Int(newValue)
        }
    }
    public var cgfloat:CGFloat{
        get{
            return CGFloat(self)
        }
        set(newValue){
            self = Int(newValue)
        }
    }
    
    /// Function to check if x is power of 2
    public var isPowerOfTwo:Bool {
        /* First x in the below expression is for the case when x is 0 */
        return ((self > 0) && !(( Int(self) & Int(self-1))>0) )
    }
}

public extension CGFloat{
    public var float:Float{
        get{
            return Float(self)
        }
        set(newValue){
            self = CGFloat(newValue)
        }
    }
}
