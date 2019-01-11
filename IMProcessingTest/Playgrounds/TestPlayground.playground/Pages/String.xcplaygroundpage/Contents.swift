//: [Previous](@previous)

import Foundation

var str = "Hello, playground"


extension String  {
    var isNumber : Bool {
        get{
           //return !self.isEmpty && self.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
            return !self.isEmpty && Float(self) != nil
        }
    }
}

var n = "0.0000123"

n.isNumber

extension Int {
    public var isPowerOfTwo:Bool {
        /* First x in the below expression is for the case when x is 0 */
        return ((self > 0) && !(( Int(self) & Int(self-1))>0) )
    }
}

4.isPowerOfTwo
3.isPowerOfTwo
1.isPowerOfTwo
16.isPowerOfTwo
11.isPowerOfTwo
15.isPowerOfTwo
14.isPowerOfTwo
64.isPowerOfTwo
512.isPowerOfTwo

512 >> 6

128 >> 6

round(pow(512.0, 1.0/3.0))

//: [Next](@next)
