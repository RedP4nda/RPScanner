//
//  RPScanner.swift
//
// Copyright (c) 2017 Florian PETIT <florianp37@me.com>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import Foundation
import UIKit
import AVFoundation

public protocol RPScannerDelegate {
    func scanCodeDetected(_ code: String, barcodeType: String)
}

open class RPScanner : NSObject, AVCaptureMetadataOutputObjectsDelegate {
    
    var captureSession: AVCaptureSession = AVCaptureSession()
    var captureDevice: AVCaptureDevice = AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    var captureInput: AVCaptureDeviceInput? = nil
    var metadataOutput: AVCaptureMetadataOutput = AVCaptureMetadataOutput()
    open var capturePreview: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer()
    
    open var useFrontCamera: Bool = true {
        didSet(newValue) {
            if useFrontCamera {
                useFrontDevice()
            } else {
                useBackDevice()
            }
        }
    }
    open var viewForPreview: UIView? = nil {
        didSet(newValue) {
            setPreviewLayer()
        }
    }
    open var delegate: RPScannerDelegate? = nil
    
    override public init() {
        super.init()
        
        configurePreset()
        configureInputDevice()
        configureOutput()
        configurePreview()
    }
    
    // MARK: - public interface -
    
    open func start() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureSessionRuntimeError, object: nil, queue: OperationQueue.main, using: {
            (notification) in
            print("*** Fucked-up with capture session")
        })
        NotificationCenter.default.addObserver(self, selector: #selector(RPScanner.captureErrorNotification(_:)), name: NSNotification.Name.AVCaptureSessionRuntimeError, object: nil)
        captureSession.startRunning()
    }
    
    func captureErrorNotification(_ notification: Notification) {
        // TODO: implement
    }
    
    open func stop() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureSessionRuntimeError , object: nil)
        captureSession.stopRunning()
    }
    
    open func reloadScanDetection() {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64(2.5 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)) {
            self.codeDetected = false
        }
    }
    
    open func setSpecificBarcodeRecognition(_ barcodes: [AnyObject]) {
        metadataOutput.metadataObjectTypes = barcodes
    }
    
    
    // MARK: - Protected Implementation -
    
    fileprivate var codeDetected = false
    
    // MARK: - Capture chain configuration
    
    fileprivate func configurePreset() {
        if captureSession.canSetSessionPreset(AVCaptureSessionPresetHigh) {
            captureSession.sessionPreset = AVCaptureSessionPresetHigh
        } else {
            print("Can't set highest preset for video capture")
        }
    }
    
    fileprivate func configureInputDevice() {
        if captureInput != nil {
            captureSession.removeInput(captureInput)
        }
        do {
            self.captureInput = try AVCaptureDeviceInput(device: captureDevice) as AVCaptureDeviceInput?
            captureSession.addInput(captureInput)
        } catch {
            print("error on binding input capture device")
        }
    }
    
    fileprivate func configureOutput() {
        metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureSession.addOutput(metadataOutput)
        metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
    }
    
    fileprivate func configurePreview() {
        do {
            self.capturePreview = AVCaptureVideoPreviewLayer(session: captureSession)
            capturePreview.videoGravity = AVLayerVideoGravityResizeAspect
        }
    }
    
    // MARK: - Devices selection & configuration
    
    fileprivate func getDevice(_ position: AVCaptureDevicePosition) -> AVCaptureDevice {
        for deviceObj in AVCaptureDevice.devices() {
            if let device = deviceObj as? AVCaptureDevice {
                if device.hasMediaType(AVMediaTypeVideo) && device.position == position {
                    return device
                }
            }
        }
        return AVCaptureDevice.defaultDevice(withMediaType: AVMediaTypeVideo)
    }
    
    fileprivate func useFrontDevice() {
        self.captureDevice = getDevice(AVCaptureDevicePosition.front)
        configureInputDevice()
        capturePreview.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
    
    fileprivate func useBackDevice() {
        self.captureDevice = getDevice(AVCaptureDevicePosition.back)
        configureInputDevice()
        capturePreview.videoGravity = AVLayerVideoGravityResizeAspectFill
    }
    
    // MARK: - Video Preview
    
    fileprivate func setPreviewLayer() {
        if self.viewForPreview != nil {
            configurePreview()
            if let subLayers = self.viewForPreview!.layer.sublayers {
                for layer in (subLayers) {
                    layer.removeFromSuperlayer()
                }
            }
            self.viewForPreview?.layer.addSublayer(self.capturePreview)
        }
    }
    
    open func drawLayer(_ layer: CALayer, inContext ctx: CGContext) {
        let scannerLayer = layer as! RPScannerZoneLayer
        if scannerLayer.highlightZone != CGRect.zero {
            ctx.stroke(scannerLayer.highlightZone)
        }
    }
    
    // MARK: - AVCaptureMetadataOutput delegate protocol implomentation
    
    open func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
        
        // only work on the first one
        if codeDetected {
            return
        }
        
        for metaObj in metadataObjects {
            if let metadataObject = metaObj as? AVMetadataObject {
                if metadataObject is AVMetadataMachineReadableCodeObject {
                    let metadataMRCO = metadataObject as! AVMetadataMachineReadableCodeObject
                    playBeep()
                    delegate?.scanCodeDetected(metadataMRCO.stringValue, barcodeType: metadataMRCO.type)
                    NotificationCenter.default.post(name: Notification.Name(rawValue: "scanCodeDetected"), object: self, userInfo: ["code" : metadataMRCO.stringValue, "type" : metadataMRCO.type])
                    codeDetected = true
                    return
                }
                
                if metadataObject is AVMetadataFaceObject {
                    let metadataFO = metadataObject as! AVMetadataFaceObject
                    //print("Face detected : \(metadataFO.faceID) / Type : \(metadataFO.type) / Bounds : \(metadataFO.bounds)")
                    showBoundOnPreviewLayer(metadataFO)
                }
            }
        }
    }
    
    // MARK: - Utility function
    
    func showBoundOnPreviewLayer(_ metadataObject: AVMetadataObject) {
        let bounds = metadataObject.bounds
        
        if bounds != CGRect.zero {
            // TODO: highlight detected face
        }
    }
    
    func metadataBounds(_ uvBounds: CGRect, extends: CGRect) -> CGRect {
        return CGRect(x: uvBounds.origin.x * extends.width,
                          y: (1.0 - uvBounds.origin.y) * extends.height,
                          width: uvBounds.width * extends.width,
                          height: uvBounds.height * extends.height)
    }
    
    // MARK: - RPScannerZoneLayer Class
    
    class RPScannerZoneLayer : CALayer {
        
        var highlightZone: CGRect = CGRect.zero
        
        override func draw(in ctx: CGContext) {
            print("Layer:drawInContext")
            if highlightZone != CGRect.zero {
                ctx.stroke(highlightZone)
            }
        }
    }
    
    // MARK: - System Sound
    
    fileprivate func playBeep() {
        let podBundle = Bundle(for: self.classForCoder)
        guard let bundlePath = podBundle.path(forResource: "RPScanner", ofType: "bundle") else {
            return
        }
        
        guard let bundle = Bundle(path: bundlePath) else {
            return
        }
    
        guard let soundPath = bundle.path(forResource: "beep_scanner_symbol", ofType: "aif") else {
            return
        }
        
        let soundURL = URL(fileURLWithPath: soundPath)
        
        var mySound: SystemSoundID = 0
        
        AudioServicesCreateSystemSoundID(soundURL as CFURL, &mySound)
        AudioServicesPlaySystemSound(mySound)
        
        // Add a vibration
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
    }
    
}
