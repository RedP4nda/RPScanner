RPScanner
============

[![Build Status](https://travis-ci.org/RedP4nda/RPScanner.svg?branch=master)](https://travis-ci.org/RedP4nda/RPFramework)
[![Twitter](https://img.shields.io/badge/twitter-@Florian_MrCloud-blue.svg?style=flat)](http://twitter.com/Florian_MrCloud)

# Disclaimer:

- This program is still under active development and in its early stage, consider that breaking changes and rewrites could occur before using it in a stable version


RPScanner is a wrapper around AVFoundation to use scanning capabilities of the iPhone Camera to detect Barcodes & QRCodes

- [Features](#features)
- [The Basics](#the-basics)
- [To Do](#to-do)
- [Contributing](#contributing)
- [Installation](#installation)

# Features:

- Barcode types:
- QRCode types:

# The Basics

### How to scan:

Configure Scanner initialization and destruction

```swift
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
```

Implement RPScannerDelegate methods to handle scanned events
```swift
func scanCodeDetected(_ code: String, barcodeType: String) {
  // do something
}


func scanCodeFailedWithError(_ error: NSError) {
  // handle detection error
}
```

# Installation
### Cocoapods
RPFramework can be added to your project using [CocoaPods](http://cocoapods.org) by adding the following lines to your `Podfile`:

```ruby
source 'https://github.com/RedP4nda/Specs'

pod 'RPScanner', '~> 0.9'
```

## Contributors
[![MrCloud](https://avatars2.githubusercontent.com/u/486140?s=100)](https://github.com/MrCloud)

## Partner
<img src="https://github.com/MobileTribe/pandroid/raw/master/pandroid-doc/assets/partner/lm.jpg" width="100" height="100" />

# Contributing

Contributions are very welcome 👍😃.

Before submitting any pull request, please ensure you have run the included tests (if any) and they have passed. If you are including new functionality, please write test cases for it as well.
