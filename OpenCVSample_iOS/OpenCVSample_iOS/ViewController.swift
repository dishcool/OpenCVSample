//
//  ViewController.swift
//  OpenCVSample_iOS
//
//  Created by Hiroki Ishiura on 2015/08/12.
//  Copyright (c) 2015年 Hiroki Ishiura. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
		
	var session: AVCaptureSession!
	var device: AVCaptureDevice!
	var output: AVCaptureVideoDataOutput!
    
    var imageArray: NSMutableArray = NSMutableArray()

    var lastFrame: UIImage?
    var splitCount: Int = 8

	override func viewDidLoad() {
		super.viewDidLoad()
        
        self.setupImageViews()
        
		// Prepare a video capturing session.
		self.session = AVCaptureSession()
		self.session.sessionPreset = AVCaptureSession.Preset.vga640x480 // not work in iOS simulator
		self.device = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
		if (self.device == nil) {
			print("no device")
			return
		}
		do {
			let input = try AVCaptureDeviceInput(device: self.device)
			self.session.addInput(input)
		} catch {
			print("no device input")
			return
		}
		self.output = AVCaptureVideoDataOutput()
		self.output.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA) ]
		let queue: DispatchQueue = DispatchQueue(label: "videocapturequeue", attributes: [])
		self.output.setSampleBufferDelegate(self, queue: queue)
		self.output.alwaysDiscardsLateVideoFrames = true
		if self.session.canAddOutput(self.output) {
			self.session.addOutput(self.output)
		} else {
			print("could not add a session output")
			return
		}
		do {
			try self.device.lockForConfiguration()
			self.device.activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: 5) // 20 fps
			self.device.unlockForConfiguration()
		} catch {
			print("could not configure a device")
			return
		}
		
		self.session.startRunning()
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	override var shouldAutorotate : Bool {
		return false
	}
	
	func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		
		// Convert a captured image buffer to UIImage.
		guard let buffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			print("could not get a pixel buffer")
			return
		}
		CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
		let image = CIImage(cvPixelBuffer: buffer).oriented(CGImagePropertyOrientation.right)
		let capturedImage = UIImage(ciImage: image)
		CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags.readOnly)
        
        if self.lastFrame != nil {
            let array = OpenCV.calculateDiffArray(from: capturedImage, to: lastFrame!, splitCount: Int32(self.splitCount))
            // Show the result.
            DispatchQueue.main.async(execute: {
                self.displayView.image = capturedImage
                for i in 0...self.imageArray.count - 1 {
                    let imageView = self.imageArray[i] as! UIImageView
                    let alpha : CGFloat = CGFloat(array![i].floatValue)
                    imageView.alpha = alpha
                }
            })
        }
        
        self.lastFrame = capturedImage
	}
    
    lazy var displayView: UIImageView = {
        let rect = self.view.bounds
        let width : CGFloat = rect.size.width
        let height : CGFloat = width / 48.0 * 64.0

        let view = UIImageView(frame: CGRect.init(x: 0, y: 0, width: width, height: height))
        self.view.addSubview(view)
        self.view.sendSubviewToBack(view)
        return view
    }()
    
    func setupImageViews() {
        let n : Int = self.splitCount
        let rect = self.view.bounds
        
        let width : CGFloat = rect.size.width / CGFloat(n)
        let height : CGFloat = width / 48.0 * 64.0

        for i in 0...(n-1) {
            for j in 0...(n-1) {
                let imageView = UIImageView.init(frame: CGRect.init(x: CGFloat(i) * width, y: CGFloat((n-1-j)) * height, width: width, height: height))
                imageView.contentMode = .scaleAspectFill
                imageView.clipsToBounds = true
                imageView.layer.borderColor = UIColor.red.cgColor
                imageView.layer.borderWidth = 1
                imageView.backgroundColor = UIColor.orange

                self.view.addSubview(imageView)
                self.imageArray.add(imageView)
            }
        }
    }
}

