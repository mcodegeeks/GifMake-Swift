//
//  UIView+animatedGIF.swift
//  GifMake-Swift
//
//  Modified by Younghwan Mun on 2016-07-06.
//  Author: Rob Mayoff 2012-01-27
//  The contents of the source repository for these files are dedicated to the public domain, in accordance with the CC0 1.0 Universal Public Domain Dedication, which is reproduced in the file COPYRIGHT.

import UIKit
import ImageIO

extension UIImage {
    
    public class func animatedImageWithGIFData(data: NSData)-> UIImage? {
        guard let source = CGImageSourceCreateWithData(data, nil) else {
            return nil
        }
        return UIImage.animatedImageWithGIFSource(source)
    }
    
    public class func animatedImageWithGIFUrl(url: NSURL)-> UIImage? {
        guard let source = CGImageSourceCreateWithURL(url, nil) else {
            return nil
        }
        return UIImage.animatedImageWithGIFSource(source)
    }
    
    public class func animatedImageWithGIFName(name: String)-> UIImage? {
        guard let bundleURL = NSBundle.mainBundle().URLForResource(name, withExtension: "gif") else {
            return nil
        }
        guard let imageData = NSData(contentsOfURL: bundleURL) else {
            return nil
        }
        return UIImage.animatedImageWithGIFData(imageData)
    }
    
    // private
    private class func animatedImageWithGIFSource(source: CGImageSource)-> UIImage? {
        let count = CGImageSourceGetCount(source)
        var images = [CGImageRef]()
        var delays = [Int]()
        var duration: Int = 0
        
        // Fill arrays
        for i in 0..<count {
            if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                images.append(image)
            }
            
            let delaySeconds = UIImage.delayForImageAtIndex(i, source: source)
            delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
            duration += delays[i]
        }
        
        // Get frames
        let gcd = gcdForArray(delays)
        var frames = [UIImage]()
        for i in 0..<count {
            let frame = UIImage(CGImage: images[Int(i)])
            let frameCount = Int(delays[Int(i)] / gcd)
            for _ in 0..<frameCount {
                frames.append(frame)
            }
        }
        
        let animation = UIImage.animatedImageWithImages(frames, duration: Double(duration) / 1000.0)
        return animation
    }
    
    private class func delayForImageAtIndex(index: Int, source: CGImageSource!)-> Double {
        var delay = 0.1
        // Get dictionaries
        if let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) {
            if let gifProperties: CFDictionaryRef = unsafeBitCast(CFDictionaryGetValue(properties, unsafeAddressOf(kCGImagePropertyGIFDictionary)), CFDictionary.self) {
                // Get delay time
                var delayObject: AnyObject = unsafeBitCast(CFDictionaryGetValue(gifProperties, unsafeAddressOf(kCGImagePropertyGIFUnclampedDelayTime)), AnyObject.self)
                if delayObject.doubleValue == 0 {
                    delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties, unsafeAddressOf(kCGImagePropertyGIFDelayTime)), AnyObject.self)
                }
        
                delay = delayObject as! Double
                if delay < 0.1 {
                    delay = 0.1 // Make sure they're not too fast
                }
            }
        }
        return delay
    }
    
    private class func gcdForArray(array: Array<Int>)-> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        for val in array {
            gcd = UIImage.gcdForPair(val, gcd)
        }
        
        return Int(gcd)
    }
    
    private class func gcdForPair(a: Int, _ b: Int) -> Int {
        var a = a
        var b = b
        
        // Swap for modulo
        if a < b {
            let t = a
            a = b
            b = t
        }
        
        // Get greatest common divisor
        while true {
            let r = a % b
            if r == 0 {
                return b // Found it
            }
            a = b
            b = r
        }
    }

}
