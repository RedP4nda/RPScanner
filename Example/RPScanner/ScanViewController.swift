//
//  ScanViewController.swift
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

import UIKit
import AVFoundation
import RPScanner

class ScanViewController: UIViewController, RPScannerDelegate {
    
    @IBOutlet var cameraPreview: UIView!
    
    var scanner: RPScanner? = nil
    
    // MARK: - Controller / Views initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initScanner()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        clearScanner()
    }
    
    func initScanner() {
        scanner = RPScanner()
        scanner?.viewForPreview = self.cameraPreview
        scanner?.delegate = self
        scanner?.useFrontCamera = false
        
        if AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) ==  AVAuthorizationStatus.authorized {
            self.scanner?.start()
        } else {
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { (granted :Bool) -> Void in
                if granted == true {
                    self.scanner?.start()
                }
            });
        }
    }
    
    func clearScanner() {
        scanner?.stop()
        self.scanner = nil
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scanner?.capturePreview.frame = self.cameraPreview.bounds
    }
    
    /**
     Only support portrait interface orientation
     
     - returns: supported orientations
     */
    override var supportedInterfaceOrientations : UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.portrait
    }
    
    // MARK: - RPScannerDelegate protocol implementation
    
    func scanCodeDetected(_ code: String, barcodeType: String) {
        print("code: \(code), type: \(barcodeType)")
    }

    
    func scanCodeFailedWithError(_ error: NSError) {
    }
    
}
