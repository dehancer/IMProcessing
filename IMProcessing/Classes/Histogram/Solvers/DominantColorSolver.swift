//
//  DominantColorSolver.swift
//  Pods
//
//  Created by denis svinarchuk on 29.07.17.
//
//

#if os(iOS)
    import UIKit
#else
    import Cocoa
#endif
import simd

///
/// Солвер доминантного цвета изображения в пространстве RGB(Y)
/// Вычисляет среднее значение интенсивностей каждого канала по гистограмме этих каналов
///
public class IMPHistogramDominantColorSolver: NSObject, IMPHistogramSolver {
    
    public var complete:CompleteHandler?
    
    ///
    /// Доминантный (средний) цвет изображения. Используем векторный тип float4 из фреймворка
    /// для работы с векторными типа данных simd
    ///
    public var color=float4()
    
    public func analizer(didUpdate analizer: IMPHistogramAnalyzerProtocol, histogram: IMPHistogram, imageSize: CGSize) {
        for i in 0..<histogram.channels.count{
            let index = IMPHistogram.ChannelNo(rawValue: i)!
            color[i] = histogram.meanOf(channel: index)
        }
    }
}
