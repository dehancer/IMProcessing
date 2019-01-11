//
//  IMPBitonicSort.swift
//  IMPBaseOperations
//
//  Created by Denis Svinarchuk on 20/03/2017.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import Metal
import simd

/**
 * Битоническая соритровка https://en.wikipedia.org/wiki/Bitonic_sorter
 */
public class IMPBitonicSort:IMPContextProvider{

    //
    // MARK - Public
    //
    public var array:[uint2] = [uint2]() {
        didSet {
            
            ///
            /// Пока же, без потери общности, просто копируем данные в GPU, при каждом обновлении
            /// массива
            ///
            
            if array.count>0 {
                
                #if os(OSX)
                    let options:MTLResourceOptions = .storageModeShared
                #else
                    let options:MTLResourceOptions = .storageModeShared
                #endif
                
                arrayBuffer = context.device.makeBuffer(
                    bytes: array,
                    length: MemoryLayout<uint2>.size * self.array.count,
                    options: options)
                
                var size = array.count
                
                arraySizeBuffer = self.context.device.makeBuffer(
                    bytes: &size,
                    length: MemoryLayout.size(ofValue: size),
                    options: .cpuCacheModeWriteCombined)
            }
        }
    }
    
    public var context: IMPContext
    
    public init(context:IMPContext){
        self.context = context
    }
    
    ///
    /// Запуск сортировки
    ///
    public func run(direction:Int) {
        bitonicSort(direction:direction)
    }

    //
    // MARK - Private
    //

    private lazy var function:IMPFunction = IMPFunction(context: self.context, kernelName: "kernel_bitonicSortUInt2")
    
    private var maxThreads:Int{ return function.maxThreads }
    
    private lazy var threads:MTLSize = {
        return MTLSize(width: self.maxThreads, height: 1,depth: 1)
    }()

    // Шаг сотрировки, подготовленные для передачи в контекст ядра
    private lazy var stageBuffer:MTLBuffer = self.context.device.makeBuffer(
        length: MemoryLayout<simd.uint>.size,
        options: .cpuCacheModeWriteCombined)!
    
    // Проход сортировки
    private lazy var passOfStageBuffer:MTLBuffer = self.context.device.makeBuffer(
        length: MemoryLayout<simd.uint>.size,
        options: .cpuCacheModeWriteCombined)!
    
    // Направление сортировки
    private lazy var directionBuffer:MTLBuffer = self.context.device.makeBuffer(
        length: MemoryLayout<simd.uint>.size,
        options: .cpuCacheModeWriteCombined)!
    
    ///
    /// Конфигурируем ядро
    ///
    public func configure(commandEncoder: MTLComputeCommandEncoder) {
        commandEncoder.setBuffer(stageBuffer,       offset: 0, index: 2)
        commandEncoder.setBuffer(passOfStageBuffer, offset: 0, index: 3)
        commandEncoder.setBuffer(directionBuffer,   offset: 0, index: 4)
    }
    
    private var threadgroups = MTLSizeMake(1,1,1)

    private lazy var arrayBuffer:MTLBuffer? = nil
    private lazy var arraySizeBuffer:MTLBuffer? = nil

    // Реализация загрузки данных в ядра
    private func bitonicSort(direction:Int) {
        
        guard let buffer = arrayBuffer else {return}

        let arraySize = simd.uint(array.count)
        let numStages = Int(log2(Float(arraySize)))
        var dir = simd.uint(direction)
        
        memcpy(directionBuffer.contents(), &dir, directionBuffer.length)
        
        if maxThreads > array.count/2 {
            threads.width = array.count/2
            
        }
        else {
            //
            // Если не влезли в размер GPU
            //
            threads.width = function.maxThreads
            threadgroups.width = array.count/2/threads.width
        }
        
        for stage in 0..<numStages {
            

            var stageUint = simd.uint(stage)
            
            // перезаписываем шаг в буфер
            memcpy(stageBuffer.contents(), &stageUint, stageBuffer.length)
            
            for passOfStage in 0..<(stage + 1) {
                
                var passOfStageUint = simd.uint(passOfStage)
                
                // перезаписываем проход
                memcpy(passOfStageBuffer.contents(), &passOfStageUint, passOfStageBuffer.length)
                
                // запускаем
                context.execute(action: { (commandBuffer) in
                    
                    let commandEncoder = self.function.commandEncoder(from: commandBuffer)
                    
                    commandEncoder.setBuffer(buffer, offset: 0, index: 0)
                   // commandEncoder.setBuffer(self.arraySizeBuffer, offset: 0, at: 1)

                    commandEncoder.setBuffer(self.stageBuffer,       offset: 0, index: 1)
                    commandEncoder.setBuffer(self.passOfStageBuffer, offset: 0, index: 2)
                    commandEncoder.setBuffer(self.directionBuffer,   offset: 0, index: 3)
                    
                    commandEncoder.dispatchThreadgroups(self.threadgroups, threadsPerThreadgroup: self.threads)
                    commandEncoder.endEncoding()
                })
            }
        }
        
        memcpy(&array, buffer.contents(), buffer.length)
    }
}
