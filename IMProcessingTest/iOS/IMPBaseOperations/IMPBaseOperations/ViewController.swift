//
//  ViewController.swift
//  IMPCoreImageMTLKernel
//
//  Created by denis svinarchuk on 05.02.17.
//  Copyright © 2017 Dehancer. All rights reserved.
//

import UIKit
import Photos
import SnapKit
import CoreImage
import MetalPerformanceShaders
import simd

func CGRectMake(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
    return CGRect(x: x, y: y, width: width, height: height)
}

public class TestFilter: IMPFilter {

    lazy var blurFilter:IMPGaussianBlurFilter = IMPGaussianBlurFilter(context: self.context)

    public var blurRadius:Float = 0.2 {
        didSet{
            blurFilter.radius = blurRadius
            //harrisCornerDetector.blurRadius = blurRadius
            dirty = true
        }
    }
    
    public var inputEV:Float = 0 {
        didSet{
            print("exposure MTL EV = \(inputEV)")
            print("exposure CI EV = \(ci_inputEV)")
            //harrisCornerDetector.sensitivity = inputEV
            dirty = true
        }
    }
    
    public var ci_inputEV:Float = 0 {
        didSet{
            exposureFilter.setValue(ci_inputEV, forKey: "inputEV")
            print("exposure MTL EV = \(inputEV)")
            print("exposure CI EV = \(ci_inputEV)")
            harrisCornerDetector.threshold = ci_inputEV
            dirty = true
        }
    }
    
    public var redAmount:Float = 1 {
        didSet{
            dirty = true
        }
    }
    
    lazy var kernelRedBuffer:MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout<Float>.size, options: [])
    lazy var kernelRed:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_red")
        f.optionsHandler = { (kernel,commandEncoder, input, output) in
            var value  = self.redAmount
            var buffer = self.kernelRedBuffer
            memcpy(buffer.contents(), &value, buffer.length)
            commandEncoder.setBuffer(buffer, offset: 0, at: 0)
        }
        return f
    }()
    
    lazy var kernelEVBuffer:MTLBuffer = self.context.device.makeBuffer(length: MemoryLayout<Float>.size, options: [])
    lazy var kernelEV:IMPFunction = {
        let f = IMPFunction(context: self.context, kernelName: "kernel_EV")
        f.optionsHandler = { (kernel,commandEncoder, input, output) in
            var value  = self.inputEV
            var buffer = self.kernelEVBuffer
            memcpy(buffer.contents(), &value, buffer.length)
            commandEncoder.setBuffer(buffer, offset: 0, at: 0)
        }
        return f
    }()
    
    override public func configure() {
        extendName(suffix: "Test filter")

//        addObserver(dirty: { (filter, source, destination) in
//            print("new dirty")
//            self.harrisCornerDetector.source = source
//            self.harrisCornerDetector.process()
//        })
//        
        normailzeSizeFilter.maxSize = 200
        
        add(filter:cannyEdgeDetector) { (destination) in
            self.readLines(destination)
        }
        //add(filter:normailzeSizeFilter)
//
//        add(filter: crosshairGenerator) { (source) in
//            print("crosshairGenerator done.... self.crosshairGenerator.points = \(self.crosshairGenerator.points.count)")
//        }

        //add(function: kernelRed)
        //add(function: kernelEV)
        //add(filter: exposureFilter)
        //add(filter:blurFilter)

        //add(filter:harrisCornerDetector)
        
        harrisCornerDetector.addObserver { (corners:[float2], size:NSSize) in
            print("new corners corners.count = \(corners.count) size = \(size)")
            self.crosshairGenerator.points = corners
            self.harrisCornerDetector.context.runOperation(.async, { 
                //self.houghTransform(points: corners, size: size)
                //self.avarageDistances(points: corners, size: size)
            })
        }
        
        harrisCornerDetector.addObserver(destinationUpdated: { (destination) in
            print("destination done")
        })
        
    }
    
    
    
    class AdjacentPoints {
        
        
        let roundK:Float    = 4
        let minimumDistance:Float = 4
        
        let width:Int
        let height:Int
        let anchor:float2
        init(anchor:float2, size:NSSize) {
            self.anchor=anchor
            width = Int(size.width)
            height = Int(size.height)
        }
        
        func append(point:float2) {
            
            let ax  = round(anchor.x * width.float/roundK) * roundK
            let ay  = round(anchor.y * height.float/roundK) * roundK
            let anchorRound = float2(ax,ay)

            let nx  = round(point.x * width.float/roundK) * roundK
            let ny  = round(point.y * height.float/roundK) * roundK
            let newRound = float2(nx,ny)

            let nd = round(distance(anchorRound, newRound))
            
            //neighbors.append(point)
            
            if neighbors.count > 1 {
                
                var newadd = false
                
                for p in neighbors {
                    let px  = round(p.x * width.float/roundK) * roundK
                    let py  = round(p.y * height.float/roundK) * roundK
                    let pointRound = float2(px,py)

                    let d = round(distance(anchorRound, pointRound))

                    if nd < d && nd >= minimumDistance {
                        newadd = true
                    }
                    
                }
                
                if newadd { neighbors.append(point) }
            }
        }
        
        private var neighbors:[float2] = [float2]()
    }
    
    func avarageDistances(points:[float2], size: NSSize, precision:Float = 0.1){
        let roundK:Float = 3
        
        var neighbors = [Int:[(float2,float2)]]()
        
        for anchor in points {
            let ax  = round(anchor.x * size.width.float/roundK) * roundK
            let ay  = round(anchor.y * size.height.float/roundK) * roundK
            let anchorRound = float2(ax,ay)
            for point in points {
                let px  = round(point.x * size.width.float/roundK) * roundK
                let py  = round(point.y * size.height.float/roundK) * roundK
                let pointRound = float2(px,py)
                let d = round(distance(anchorRound, pointRound))
                
                if neighbors[Int(d)] == nil {
                    neighbors[Int(d)] = [(anchor,point)]
                }
                neighbors[Int(d)]?.append((anchor,point))
            }
        }
        
        for (k,n) in neighbors {
            print(" \(k) = \(n)")
        }
    }
    
    public class Hough {
        
        public class Accumulator {
            public var bins:[Int]
            public let width:Int
            public let height:Int
            public let houghDistance:Float
            
            public func max(r:Int,t:Int) -> Int {
                return bins[(r*width) + t]
            }
            
            public init(imageWidth:Int, imageHeight: Int) {
                houghDistance = (sqrt(2.0) * Float( imageHeight>imageWidth ? imageHeight : imageWidth )) / 2.0
                width  = 180
                height = Int(houghDistance * 2)
                bins = [Int](repeating:0, count: Int(width) * Int(height))
            }
        }
        

        public var slopes:[Int]
        public let accumulator:Accumulator
        public let imageWidth:Int
        public let imageHeight:Int
        public let threshold:Int
        
        public init(image:UnsafeMutablePointer<UInt8>,
                    bytesPerRow:Int,
                    width:Int,
                    height:Int,
                    threshold:Int) {
            self.threshold = threshold
            imageWidth = width
            imageHeight = height
            accumulator = Accumulator(imageWidth: width, imageHeight: height)
            slopes = [Int](repeating:0, count: accumulator.width)
            transform(image: image, bytesPerRow: bytesPerRow, width:width, height:height)
        }
        
        public func getLines() -> [IMPLineSegment] {
            var lines = [IMPLineSegment]()
            
            if accumulator.bins.count == 0 { return lines }
            
            for r in stride(from: 0, to: accumulator.height, by: 1) {
                
                for t in stride(from: 0, to: accumulator.width, by: 1){
                    
                    //Is this point a local maxima (9x9)
                    var max = accumulator.max(r: r, t: t)
                    
                    if max < threshold { continue }
                    
                    var exit = false
                    for ly in stride(from: -4, through: 4, by: 1){
                        for lx in stride(from: -4, through: 4, by: 1) {
                            let newmax = accumulator.max(r: r+ly, t: t+lx)
                            if newmax > max {
                                max = newmax
                                exit = true
                                break
                            }
                            if exit { break }
                        }
                    }
                    
                    if max > accumulator.max(r: r, t: t) { continue }
                    
                    
                    var p0 = float2()
                    var p1 = float2()
                    
                    let theta = Float(t) * M_PI.float / 180.0

                    let rr = Float(r)
                    let h  = Float(accumulator.height)/2
                    let w  = Float(accumulator.width)/2
                    
                    if t >= 45 && t <= 135 {
                        //y = (r - x cos(t)) / sin(t)
                        let x1:Float = 0
                        let y1 = ((rr-h) - ((x1-w) * cos(theta))) / sin(theta) + h
                        let x2 = w
                        let y2 = ((rr-h) - ((x2 - w) * cos(theta))) / sin(theta) + h
                        p0 = float2(x1, y1)
                        p1 = float2(x2, y2)
                    }
                    else {
                        
                        //x = (r - y sin(t)) / cos(t);
                        let y1:Float = 0
                        let x1 = ((rr-h) - ((y1 - h) * sin(theta))) / cos(theta) + w
                        let y2 = h
                        let x2 = ((rr-h)) - ((y2 - h) * sin(theta)) / cos(theta) + w
                        p0 = float2(x1,y1)
                        p1 = float2(x2,y2)
                    }
                    
                    let delim = float2(Float(imageWidth),Float(imageHeight))
                    lines.append(IMPLineSegment(p0: p0/delim,
                                                p1: p1/delim))
                }
            }
            return lines
        }
        
        func transform(image:UnsafeMutablePointer<UInt8>, bytesPerRow:Int, width:Int, height:Int) {
            
            let center_x = Float(width)/2
            let center_y = Float(height)/2
            
            for x in stride(from: 0, to: width, by: 1){
                
                for y in stride(from: 0, to: height, by: 1){
                    
                    let colorByte = image[y * bytesPerRow + x * 4]
                    
                    if colorByte < 1 { continue }
                    
                    for t in stride(from: 0, to: accumulator.width, by: 1){
                        
                        let theta = t.float * M_PI.float / accumulator.width.float
                        
                        let r = (x.float - center_x ) * cos(theta) + (y.float - center_y) * sin(theta)
                        let index = ((round(r + accumulator.houghDistance) * accumulator.width.float)).int + t
                        accumulator.bins[index] += 1
                    }
                }
            }
        }
    }
    
    var rawPixels:UnsafeMutablePointer<UInt8>?
    var imageByteSize:Int = 0
    
    
    deinit {
        rawPixels?.deallocate(capacity: imageByteSize)
    }
    
    private var isReading = false

    private func readLines(_ destination: IMPImageProvider) {
        
        guard !isReading else { return }
        
        isReading = true
        
        guard !isReading else { return }
        
        isReading = true
        
        guard let size = destination.size else { return }
        
        let width       = Int(size.width)
        let height      = Int(size.height)
        
        var bytesPerRow:Int = 0
        if let image = destination.read(bytes: &rawPixels, length: &imageByteSize, bytesPerRow: &bytesPerRow) {
            
            let hough = Hough(image: image,
                              bytesPerRow: bytesPerRow,
                              width: width,
                              height: height,
                              threshold: 90)
            
            let lines = hough.getLines()
            
            for (i,s) in lines.enumerated() {
                let ay = (s.p1.y-s.p0.y)
                let ax = (s.p1.x-s.p0.x)
                if ax != 0 {
                    let a  = ay/ax
                    print("Line[\(i)] result = \(s) degrees = \(atan(a) * 180 / M_PI.float)")
                }
                
            }
            //                for (i,s) in hough.slopes.enumerated() {
            //                    print("Line[\(i)] result = \(s)")
            //                }
        }
        
        isReading = false
    }

    private lazy var normailzeSizeFilter:IMPResampler = IMPResampler(context: self.context, name: "canyEdageResampler")

    private lazy var cannyEdgeDetector:IMPCannyEdgeDetector = IMPCannyEdgeDetector(context: self.context)
    private lazy var crosshairGenerator:IMPCrosshairGenerator = IMPCrosshairGenerator(context: self.context)
    private lazy var harrisCornerDetector:IMPHarrisCornerDetector = IMPHarrisCornerDetector(context: self.context /*IMPContext(lazy: false)*/)
    private lazy var exposureFilter:CIFilter = CIFilter(name:"CIExposureAdjust")!
}


public class DownScaleFilter: IMPFilter {
    
    public var scale:Float = 1.0 {
        didSet{
            lancoz.setValue(scale, forKey: kCIInputScaleKey)
            dirty = true
        }
    }
    
    public override func configure() {
        extendName(suffix: "Downscale input filter")
        super.configure()
        lancoz.setValue(1, forKey: kCIInputScaleKey)
        add(filter: lancoz)
    }
    
    lazy var lancoz:CIFilter = CIFilter(name: "CILanczosScaleTransform")!
}

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{

    let context = IMPContext(lazy: false)
    
    //lazy var imageView:IMPGLView = IMPGLView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
    
    //
    // Test rendering to Metal Layer...
    //
    lazy var imageView:IMPView = IMPView(frame:CGRect(x: 0, y: 0, width: 100, height: 100))
    
    lazy var containerView:UIView = {
        let y = (self.navigationController?.navigationBar.bounds.height)! + UIApplication.shared.statusBarFrame.height
        let v = UIView(frame: CGRectMake( 0, y,
                                          self.view.bounds.size.width,
                                          self.view.bounds.size.height*3/4
        ))
        
        let press = UILongPressGestureRecognizer(target: self, action: #selector(pressHandler(gesture:)) )
        press.minimumPressDuration = 0.05
        v.addGestureRecognizer(press)
        
        return v
    }()

    
    func pressHandler(gesture:UILongPressGestureRecognizer)  {
        if gesture.state == .began{
            imageView.filter?.enabled = false
        }
        else if gesture.state == .ended{
            imageView.filter?.enabled = true
        }
    }
    
    var blurSlider = UISlider(frame: CGRect(x: 0, y: 0, width: 150, height: 10))
    var inputEVSlider = UISlider(frame: CGRect(x: 0, y: 0, width: 150, height: 10))
    var ci_inputEVSlider = UISlider(frame: CGRect(x: 0, y: 0, width: 150, height: 10))
    var redSlider = UISlider(frame: CGRect(x: 0, y: 0, width: 150, height: 10))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(containerView)
        
        imageView.exactResolutionEnabled = false
        imageView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        imageView.frame = containerView.bounds
        imageView.backgroundColor = NSColor.init(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        
        imageView.filter = testFilter
        
        testFilter.blurRadius = 0
        
        containerView.addSubview(imageView)
        
        view.backgroundColor = UIColor.black
        
        let albumButton = UIButton(frame: CGRectMake(0, 0, 90, 90))
        
        albumButton.backgroundColor = UIColor.clear
        albumButton.setImage(UIImage(named: "film-roll"), for: .normal)
        albumButton.addTarget(self, action: #selector(openAlbum(sender:)), for: .touchUpInside)
        view.addSubview(albumButton)
        
        albumButton.snp.makeConstraints { (make) -> Void in
            make.bottom.equalTo(view).offset(-35)
            make.centerX.equalTo(view.snp.centerX).offset(-view.bounds.width/3)
        }
        
        view.addSubview(redSlider)
        redSlider.value = 0
        redSlider.snp.makeConstraints { (make) -> Void in
            make.bottom.equalTo(view).offset(-110)
            make.left.equalTo(albumButton.snp.right).offset(20)
            make.right.equalTo(view.snp.right).offset(-10)
        }

        view.addSubview(inputEVSlider)
        inputEVSlider.value = 0
        inputEVSlider.snp.makeConstraints { (make) -> Void in
            make.bottom.equalTo(view).offset(-80)
            make.left.equalTo(albumButton.snp.right).offset(20)
            make.right.equalTo(view.snp.right).offset(-10)
        }
        
        view.addSubview(ci_inputEVSlider)
        ci_inputEVSlider.value = 0
        ci_inputEVSlider.snp.makeConstraints { (make) -> Void in
            make.bottom.equalTo(view).offset(-50)
            make.left.equalTo(albumButton.snp.right).offset(20)
            make.right.equalTo(view.snp.right).offset(-10)
        }

        view.addSubview(blurSlider)
        blurSlider.value = 0
        blurSlider.snp.makeConstraints { (make) -> Void in
            make.bottom.equalTo(view).offset(-20)
            make.left.equalTo(albumButton.snp.right).offset(20)
            make.right.equalTo(view.snp.right).offset(-10)
        }
        
        redSlider.addTarget(self, action: #selector(redHandler(slider:)), for: .valueChanged)
        blurSlider.addTarget(self, action: #selector(blurHandler(slider:)), for: .valueChanged)
        inputEVSlider.addTarget(self, action: #selector(evHandler(slider:)), for: .valueChanged)
        ci_inputEVSlider.addTarget(self, action: #selector(ci_evHandler(slider:)), for: .valueChanged)
    }
    
    func redHandler(slider:UISlider)  {
        testFilter.context.runOperation(.async){
            self.testFilter.redAmount = slider.value
        }
    }

    func blurHandler(slider:UISlider)  {
        testFilter.context.runOperation(.async) {
            self.testFilter.blurRadius = slider.value * 5
        }
    }

    func evHandler(slider:UISlider)  {
        testFilter.context.runOperation(.async) {
            self.testFilter.inputEV = slider.value * 5
        }
    }
    
    func ci_evHandler(slider:UISlider)  {
        testFilter.context.runOperation(.async) {
            self.testFilter.ci_inputEV = slider.value * 1
        }
    }


    var isAlbumOpened = false
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !isAlbumOpened {
            isAlbumOpened = true
            openAlbum(sender: nil)
        }
    }
    
    func openAlbum(sender:UIButton?)  {
        imagePicker = UIImagePickerController()
    }
    
    var imagePicker:UIImagePickerController!{
        didSet{
            self.imagePicker.delegate = self
            self.imagePicker.allowsEditing = false
            self.imagePicker.sourceType = .photoLibrary
            if let actualPicker = self.imagePicker{
                self.present(actualPicker, animated:true, completion:nil)
            }
        }
    }

    var currentImageUrl:NSURL? = nil
    
    func loadLastImage(size: Float = 0, complete:@escaping ((_ size:Float,_ image:UIImage)->Void)) {
        
        var fetchResult:PHFetchResult<AnyObject>
        
        if let url = currentImageUrl {
            fetchResult = PHAsset.fetchAssets(withALAssetURLs: [url as URL], options: nil) as! PHFetchResult<AnyObject>
            
        }
        else {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
            fetchResult = PHAsset.fetchAssets(with: PHAssetMediaType.image, options: fetchOptions) as! PHFetchResult<AnyObject>
        }
        
        if let lastAsset: PHAsset = fetchResult.lastObject as? PHAsset {
            let manager = PHImageManager.default()
            let imageRequestOptions = PHImageRequestOptions()
            imageRequestOptions.isNetworkAccessAllowed = true
            imageRequestOptions.resizeMode = .exact
            
            func progress(percent: Double, _ error: Error?, _ obj:UnsafeMutablePointer<ObjCBool>, _ options: [AnyHashable : Any]?) {
                print("image loading progress = \(percent, error, obj, options)")
            }
            
            imageRequestOptions.progressHandler = progress
            
            manager.requestImageData(for: lastAsset, options: imageRequestOptions, resultHandler: {
                (imageData, dataUTI, orientation, info) in
                if let imageDataUnwrapped = imageData, let image = UIImage(data: imageDataUnwrapped) {
                    // do stuff with image
                    complete(size, image)
                }
            })
        }
    }
    
    lazy var downScaleFilter:DownScaleFilter = DownScaleFilter(context: self.context)
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let chosenImage:UIImage? = info[UIImagePickerControllerOriginalImage] as? UIImage
        currentImageUrl = info[UIImagePickerControllerReferenceURL] as? NSURL
        
        if let actualImage = chosenImage{
            let bounds = UIScreen.main.bounds
            let screensize = max(bounds.size.width, bounds.size.height) * UIScreen.main.scale
            
            let source = IMPImage(context: context, image: actualImage, maxSize: 0)
        
            NSLog(" start set source with size \(actualImage.size) scaled size = \(screensize) source.size = \(source.image?.extent)")

            imageView.filter?.source = source
        }
        
        picker.dismiss(animated: true, completion: nil)
    }

    lazy var mps:MPSImageGaussianBlur = MPSImageGaussianBlur(device: self.context.device, sigma: 100)
    lazy var blur:CIFilter =  CIFilter(name: "CIGaussianBlur")!
    
    lazy var testFilter:TestFilter = TestFilter(context: self.context)
    
    lazy var vibrance:IMPFilter = {
        let f = IMPFilter(context: self.context)
        if let v = CIFilter(name:"CIVibrance"){
            v.setValue(10, forKey: "inputAmount")
            f.add(filter:v){ (destination) in
                print(" function CIVibrance destination = \(destination)")
            }
        }
        if let i = CIFilter(name:"CIColorInvert"){
            f.add(filter:i){ (destination) in
                print(" function CIColorInvert destination = \(destination)")
            }
        }

        return f
    }()
    
    lazy var filter:IMPFilter = {
        let f = IMPFilter(context: self.context)
        
        f.add(function: IMPFunction(context: self.context, kernelName: "kernel_view")){ (destination) in
            print(" function kernel_view destination = \(destination)")
        }

        f.add(function: "kernel_red")
        
        f.add(function: "kernel_red", fail: { (error) in
            print("error = \(error)")
        })
        
        f.add(function: "kernel_green"){ (destination) in
            print(" function kernel_green destination = \(destination)")
        }
        
        f.add(filter: self.blur)
        f.add(mps:self.mps, withName:"MPSGaussianBlur")
        
        f.remove(filter:self.blur)
        f.remove(filter:"kernel_red")
        
        f.insert(function:"kernel_red", after:"MPSGaussianBlur", fail: { (error) in
            print(" function kernel_red error = \(error)")
        }){ (destination) in
            print(" function kernel_red destination = \(destination)")
        }
        
        f.insert(filter:self.vibrance, before: "kernel_view")
        
        f.remove(filter:self.vibrance)
        
        return f
    }()
}
