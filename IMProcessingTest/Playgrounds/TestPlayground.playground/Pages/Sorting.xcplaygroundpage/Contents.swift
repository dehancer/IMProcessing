//: [Previous](@previous)

import Foundation
import simd

var array = ["mango", "apple", "pear", "apple", "orange", "banana"]
var array2 = [float2(0.6,0.25), float2(0.4,0.31), float2(0.3,0.34), float2(0.72,0.35), float2(0.62,0.38), float2(0.42,0.44)]

mergesort(&array, array.count, MemoryLayout<String>.size, {
    let a = $0.unsafelyUnwrapped.load(as:String.self)
    let b = $1.unsafelyUnwrapped.load(as:String.self)
    if a == b {
        return 0
    }
    else if a < b {
        return -1
    }
    else {
        return 1
    }
})

print(array)

mergesort(&array2, array2.count, MemoryLayout<float2>.size, {
    let a = $0.unsafelyUnwrapped.load(as:float2.self)
    let b = $1.unsafelyUnwrapped.load(as:float2.self)
    if a.y == b.y {
        return 0
    }
    else if a.y < b.y {
        return -1
    }
    else {
        return 1
    }
})

mergesort(&array2, array2.count, MemoryLayout<float2>.size, {
    let a = $0.unsafelyUnwrapped.load(as:float2.self)
    let b = $1.unsafelyUnwrapped.load(as:float2.self)
    if a.x == b.x {
        return 0
    }
    else if a.x < b.x {
        return -1
    }
    else {
        return 1
    }
})


print(array2)

//enum SortType {
//    case Ascending
//    case Descending
//}
//
//struct SortObject<T> {
//    let value:T
//    let startPosition:Int
//    var sortedPosition:Int?
//}
//
//func swiftStableSort<T:Comparable>(array:inout [T], sortType:SortType = .Ascending) {
//    
//    var sortObjectArray = array.enumerated().map{SortObject<T>(value:$0.element, startPosition:$0.offset, sortedPosition:nil)}
//    
//    for s in sortObjectArray {
//        var offset = 0
//        for x in array[0..<s.startPosition]  {
//            if s.value < x {
//                offset += sortType == .Ascending ? -1 : 0
//            }
//            else if s.value > x {
//                offset += sortType == .Ascending ? 0 : -1
//            }
//        }
//        
//        for x in array[s.startPosition+1..<array.endIndex]  {
//            if s.value > x  {
//                offset += sortType == .Ascending ? 1 : 0
//            }
//            else if s.value < x  {
//                offset += sortType == .Ascending ? 0 : 1
//            }
//        }
//        sortObjectArray[s.startPosition].sortedPosition = offset + s.startPosition
//    }
//    
//    for s in sortObjectArray {
//        if let sInd = s.sortedPosition {
//            array[sInd] = s.value
//        }
//    }
//    
//}
//
//swiftStableSort(array: &array, sortType:.Ascending) // ["apple", "apple", "banana", "banana", "mango", "orange", "pear"]
//swiftStableSort(array: &array, sortType:.Descending) // ["pear", "orange", "mango", "banana", "banana", "apple", "apple"]
