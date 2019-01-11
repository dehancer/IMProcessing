//: [Previous](@previous)

import Cocoa

var images = NSImage.imageTypes().map { (name) -> String in
    return name.components(separatedBy: ".").last!
}

print(images)


//: [Next](@next)
