//
//  IMPHistogramAnalyzer.swift
//  Pods
//
//  Created by Denis Svinarchuk on 29/06/2017.
//
//

import Foundation


///
/// Common protocol defines histogram class API.
///
public protocol IMPHistogramAnalyzerProtocol:IMPFilterProtocol {
    
    ///
    /// Histogram updates handler.
    ///
    typealias UpdateHandler =  ((_ histogram:IMPHistogram) -> Void)
    
    var colorSpace:IMPColorSpace {set get}
    var region:IMPRegion {set get}
    var histogram:IMPHistogram {set get }
    
    func add(solver:IMPHistogramSolver, complete:IMPHistogramSolver.CompleteHandler?)
}

///
/// Histogram solvers protocol. Solvers define certain computations to calculate measurements metrics such as:
/// 1. histogram range (dynamic range)
/// 2. get peaks and valyes
/// 3. ... etc
///
public protocol IMPHistogramSolver {

    typealias CompleteHandler =  ((_ histogram:IMPHistogramSolver) -> Void)

    var complete:CompleteHandler? {set get}
    func analizer(
        didUpdate analizer: IMPHistogramAnalyzerProtocol,
        histogram: IMPHistogram,
        imageSize: CGSize)
}


public extension IMPHistogramSolver {
    public func executeComplete(){
            complete?(self)
    }
}

public extension IMPHistogramAnalyzerProtocol {
    public func setCenterRegion(inPercent value:Float){
        let half = value/2.0
        region = IMPRegion(
            left:   0.5 - half,
            right:  1.0 - (0.5+half),
            top:    0.5 - half,
            bottom: 1.0 - (0.5+half)
        )
    }
}

public class IMPHistogramAnalyzer: IMPDetector, IMPHistogramAnalyzerProtocol{

    public var colorSpace:IMPColorSpace = .rgb {didSet{ dirty = true }}

    public var region = IMPRegion()
    
    public var histogram = IMPHistogram() {
        didSet{
            channelsToCompute = histogram.channels.count
        }
    }
    
    public override func configure(complete: IMPFilterProtocol.CompleteHandler?) {
        extendName(suffix: "HistogramAnalyzer")
        
        super.configure()
        
        analizerComplite = complete
        
        partialHistogramKernel.threadsPerThreadgroup = MTLSize(width: self.regionSize, height: self.regionSize, depth: 1)
        partialHistogramKernel.preferedDimension     = MTLSize(width: gridDimension.width*self.regionSize, height: gridDimension.height*self.regionSize, depth: 1)
        
        accumHistogramKernel.threadsPerThreadgroup   = MTLSize(width: histogram.size, height: 1, depth: 1)
        accumHistogramKernel.preferedDimension       = MTLSize(width: histogram.size * channelsToCompute, height: 1, depth: 1)
        
        addObserver(newSource: { (source) in
            if self.partialBuffer.length < MemoryLayout<IMPHistogramBuffer>.size * Int(self.numParts) {
                self.partialBuffer = self.partialBufferGetter()
            }
        })
        
        self
            .add(function: partialHistogramKernel)
            .add(function: accumHistogramKernel){ (result) in
            //.addObserver(destinationUpdated: { (result) in
                self.context.execute(
                    .sync,
                    wait: true,
                    complete: {
                        if result.texture == nil {
                            self.histogram.clear()
                        }
                        else {
                            self.histogram.update(data: self.completeBuffer.contents())
                        }
                        self.executeSolverObservers()
                        //complete?(result)
                },
                    action: { (dest) in })
            }
    //)
    }

    ///
    ///
    ///
    public func add(solver:IMPHistogramSolver, complete:IMPHistogramSolver.CompleteHandler?=nil){
        var s = solver
        s.complete = complete
        solvers.append(s)
    }

    private var analizerComplite:IMPFilterProtocol.CompleteHandler?
    
    public func executeSolverObservers() {
        guard let srcSize = source?.size else { return }
        if observersEnabled {
            for s in solvers {
                let size = destinationSize ?? srcSize
                s.analizer(didUpdate: self, histogram: self.histogram, imageSize: size)
                s.executeComplete()
            }
        }
        if let result = self.source {
            analizerComplite?(result)
        }
    }

    private var channelsToCompute:Int = 4 { didSet { dirty = true } }

    private lazy var partialHistogramKernel:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_partialHistogram")
        
        f.optionsHandler = { [weak self] (function, command, input, output) in
            
            guard let self = self else { return }
            
            command.setBuffer(self.partialBuffer,       offset: 0, index: 0)
            
            command.setBytes(&self.region, length: MemoryLayout.size(ofValue: self.region),   index: 1)
            
            var np = self.channelsToCompute;
            command.setBytes(&np, length: MemoryLayout.size(ofValue: np),   index: 2)
           
            var cs = self.colorSpace.index
            command.setBytes(&cs,length:MemoryLayout.size(ofValue: cs),index:3)

        }
        
        return f
    }()

    private lazy var accumHistogramKernel:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_accumHistogram")
        
        f.optionsHandler = { [weak self] (function, command, input, output) in

            guard let self = self else { return }
            
            command.setBuffer(self.partialBuffer,  offset: 0, index: 0)
            command.setBuffer(self.completeBuffer, offset: 0, index: 1)
            
            var np = self.numParts;
            command.setBytes(&np, length: MemoryLayout.size(ofValue: np),   index: 2)
            
            np = self.channelsToCompute;
            command.setBytes(&np, length: MemoryLayout.size(ofValue: np),   index: 3)
        }
        
        return f
    }()
    
    private var gridDimension:MTLSize {
        return MTLSize(width: 16, height: 16, depth: 1);
    }
    
    private var numParts:Int {
        return  gridDimension.width*gridDimension.height;
    }

    private func partialBufferGetter() -> MTLBuffer {
        //
        // to echange data should be .storageModeShared!!!!
        //
        return context.device.makeBuffer(length: MemoryLayout<IMPHistogramBuffer>.size * numParts, options: . storageModePrivate)!
    }
    
    private func completeBufferGetter() -> MTLBuffer {
        //
        // to echange data should be .storageModeShared!!!!
        //
        return self.context.device.makeBuffer(length: MemoryLayout<IMPHistogramBuffer>.size, options: .storageModeShared)!
    }
    
    private lazy var partialBuffer:MTLBuffer = self.partialBufferGetter()

    private lazy var completeBuffer:MTLBuffer = self.completeBufferGetter()

    private var solvers:[IMPHistogramSolver] = [IMPHistogramSolver]()

}
