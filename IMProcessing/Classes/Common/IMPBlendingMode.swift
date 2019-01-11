//
//  IMPBlendingMode.swift
//  Pods
//
//  Created by denn on 19.08.2018.
//

import Foundation

public extension IMPBlendingMode{
    
    public init?(index: Int) {
        if IMPBlendingMode.list.count <= index || index < 0 { return nil }
        self = IMPBlendingMode.list[index]
    }
    
    public static var list:[IMPBlendingMode]{
        return [.normal, .luminosity, .color, .mix]
    }

    public var name:String {
        switch self {
        case .normal:
            return "Normal"
        case .luminosity:
            return "Luminosity"
        case .color:
            return "Color"
        case .mix:
            return "Mix"
        }
    }
    
    public var index:Int {
        return IMPBlendingMode.list.firstIndex(of: self)!
    }
}
