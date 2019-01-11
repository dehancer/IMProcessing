//
//  NSimage(IMProcessing).swift
//  CryptoSwift
//
//  Created by denn on 13.08.2018.
//


#if os(OSX)

import AppKit


//public extension NSImage {
//
//    public func resize(factor level: CGFloat) -> NSImage {
//        let _image = self
//        let newRect: NSRect = NSMakeRect(0, 0, _image.size.width, _image.size.height)
//
//        let imageSizeH: CGFloat = _image.size.height * level
//        let imageSizeW: CGFloat = _image.size.width * level
//
//        let newImage = NSImage(size: NSMakeSize(imageSizeW, imageSizeH))
//        newImage.lockFocus()
//        NSGraphicsContext.current?.imageInterpolation = NSImageInterpolation.medium
//
//        _image.draw(in: NSMakeRect(0, 0, imageSizeW, imageSizeH), from: newRect, operation: .sourceOver, fraction: 1)
//        newImage.unlockFocus()
//
//        return newImage
//    }
//
//    convenience init(color: NSColor, size: NSSize) {
//        self.init(size: size)
//        lockFocus()
//        color.drawSwatch(in: NSMakeRect(0, 0, size.width, size.height))
//        unlockFocus()
//    }
//
//    public static var typeExtensions:[String] {
//        return NSImage.imageTypes.map { (name) -> String in
//            return name.components(separatedBy: ".").last!
//        }
//    }
//
//    public class func getMeta(contentsOf url: URL) -> [String: AnyObject]? {
//        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
//        guard let properties =  CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [String: AnyObject] else { return nil }
//        return properties
//    }
//
//    public class func getSize(contentsOf url: URL) -> NSSize? {
//        guard let properties = NSImage.getMeta(contentsOf: url) else { return nil }
//        if let w = properties[kCGImagePropertyPixelWidth as String]?.floatValue,
//            let h = properties[kCGImagePropertyPixelHeight as String]?.floatValue {
//            return NSSize(width: w.cgfloat, height: h.cgfloat)
//        }
//        return nil
//    }
//
//    public class func thumbNail(contentsOf url: URL, size max: Int) -> NSImage? {
//
//        guard let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
//
//        let options = [
//            kCGImageSourceShouldAllowFloat as String: true as NSNumber,
//            kCGImageSourceCreateThumbnailWithTransform as String: false as NSNumber,
//            kCGImageSourceCreateThumbnailFromImageAlways as String: true as NSNumber,
//            kCGImageSourceThumbnailMaxPixelSize as String: max as NSNumber
//            ] as CFDictionary
//
//        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options) else { return nil }
//
//        return NSImage(cgImage: thumbnail, size: NSSize(width: max, height: max))
//    }
//}

#endif
