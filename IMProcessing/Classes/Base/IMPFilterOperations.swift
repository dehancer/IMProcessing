//
//  IMPFilterOperations.swift
//  IMPPatchDetectorTest
//
//  Created by Denis Svinarchuk on 06/04/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Foundation

infix operator => : AdditionPrecedence
infix operator --> : AdditionPrecedence
infix operator ==> : AdditionPrecedence


public extension IMPFilter {
    /// Async redirect source image frame to another filter
    ///
    /// - Parameters:
    ///   - destinationFilter: destination filter which should recieve the same source image frames
    /// - Returns: destination filter
    ///
    @discardableResult public func addRedirection<T:IMPFilter>(to destination:T) ->T {
        addObserver(newSource: { (source) in
            destination.source = source
        })
        return destination
    }
    
    /// Async redirect destination image frame to another filter
    ///
    /// - Parameters:
    ///   - destinationFilter: destination filter which should recieve the same source image frames
    /// - Returns: destination filter
    ///
    @discardableResult public func addDestination<T:IMPFilter>(to destination:T) ->T {
        addObserver(destinationUpdated: { (destinationImage) in
            destination.source = destinationImage
        })
        return destination
    }
    
    /// Async processing result image frames to enclosure process block
    ///
    /// - Parameters:
    ///   - filter: processed filter
    ///   - action: next processing action
    /// - Returns: filter
    ///
    @discardableResult public func addProcessing<T:IMPFilter>(sync:IMPContext.OperationType = .sync,
                                                              action:  ((_ image:IMPImageProvider) -> Void)?=nil) -> T {
        addObserver(destinationUpdated: {(destination) in
            if let a = action {
                self.context.runOperation(sync) {
                    a(destination)
                }
            }
        })
        
        addObserver(newSource:{ (source) in
            self.context.runOperation(sync, {
                self.process()
            })
        })
        
        return self as! T
    }
}

/// Async redirect source image frame to another filter
///
/// - Parameters:
///   - sourceFilter: source image frame updatable filter
///   - destinationFilter: destination filter which should recieve the same source image frames
/// - Returns: destination filter
///
@discardableResult public func =><T:IMPFilter>(sourceFilter:T, destinationFilter:T) -> T {
    return sourceFilter.addRedirection(to: destinationFilter)
}


/// Async redirect result image frames to enclosure process block
///
/// - Parameters:
///   - filter: processed filter
///   - action: next processing action
/// - Returns: filter
///
@discardableResult public func --><T:IMPFilter>(filter:T, action:  @escaping ((_ image:IMPImageProvider) -> Void)) -> T {
    return filter.addProcessing(action: action)
}

/// Async redirect result image frames to next processing filter
///
/// - Parameters:
///   - sourceFilter: source filter which processed image frames
///   - destinationFilter: next filter which should process next processing stage
/// - Returns: next filter
//
@discardableResult public func --><T:IMPFilter>(sourceFilter:T, nextFilter:T) -> T {
    
    sourceFilter.addObserver(newSource:{ (source) in
        sourceFilter.context.runOperation(.async, {
            sourceFilter.process()
        })
    })
    
    sourceFilter.addObserver(destinationUpdated: { (destination) in
        nextFilter.context.runOperation(.async, {
            nextFilter.source = destination
            nextFilter.process()
        })
    })
    
    return nextFilter
}


/// Async redirect source(!) image frames to next processing filter
///
/// - Parameters:
///   - sourceFilter: source filter which processed image frames
///   - destinationFilter: next filter which should process next processing stage
/// - Returns: next filter
//
@discardableResult public func ==><T:IMPFilter>(sourceFilter:T, nextFilter:T) -> T {
    
    sourceFilter.addObserver(newSource:{ (source) in
        sourceFilter.context.runOperation(.async, {
            sourceFilter.process()
        })
    })
    
    sourceFilter.addObserver(newSource: { (source) in
        nextFilter.context.runOperation(.async, {
            nextFilter.source = source
            nextFilter.process()
        })
    })
    
    return nextFilter
}
