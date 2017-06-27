//
//  ViewController.swift
//  VoRk
//
//  Created by KeisukeImai on 2017/06/04.
//  Copyright © 2017年 KeisukeImai. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    var videoOutput: AVCaptureVideoDataOutput!
    var session: AVCaptureSession!
    var dispachQueue: DispatchQueue!
    var detectDispachQueue: DispatchQueue!
    var detector: CIDetector!
    @IBOutlet weak var cameraView: UIView!
    @IBOutlet weak var smileLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.detectDispachQueue = DispatchQueue.init(label: "net.2ggnw.VoRk.feature_detect", attributes: .concurrent)
        self.detector = CIDetector(ofType: CIDetectorTypeFace,
                                  context: nil,
                                  options: [CIDetectorAccuracy: CIDetectorAccuracyHigh])
        self.configureCamera()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func configureCamera() -> Bool {
        var targetDevice: AVCaptureDevice?
        let captureDevices = AVCaptureDeviceDiscoverySession.init(deviceTypes: [.builtInWideAngleCamera],
                                                                  mediaType: AVMediaTypeVideo,
                                                                  position: .back)
        
        if captureDevices == nil {
            return false
        }
        
        for device in (captureDevices?.devices)! {
            targetDevice = device
        }
        
        let input: AVCaptureDeviceInput?
        do {
            input = try AVCaptureDeviceInput(device: targetDevice)
        } catch {
            print("Caught exception!")
            return false
        }
        
        self.videoOutput = AVCaptureVideoDataOutput()
        
        self.dispachQueue = DispatchQueue.init(label: "net.2ggnw.VoRk.video_dispatch_queue")
        self.videoOutput.setSampleBufferDelegate(self, queue: self.dispachQueue)
        
        // init session
        self.session = AVCaptureSession()
        self.session.sessionPreset = AVCaptureSessionPresetMedium
        self.session.addInput(input)
        self.session.addOutput(self.videoOutput)
        
        // layer for preview
        let previewLayer: AVCaptureVideoPreviewLayer = AVCaptureVideoPreviewLayer.init(session: self.session)
        previewLayer.frame = self.cameraView.bounds
        self.cameraView.layer.addSublayer(previewLayer)
        
        self.session.startRunning()
        
        return true
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput!,
                       didOutputSampleBuffer sampleBuffer: CMSampleBuffer!,
                       from connection: AVCaptureConnection!) {
        
        self.detectDispachQueue.async {
            let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            let ciImage = CIImage(cvPixelBuffer: pixelBuffer!)
            
            let random = arc4random_uniform(5)
            if (random == 0) {
                let features = self.detector?.features(in: ciImage, options: [CIDetectorSmile : true])
                for feature in features as! [CIFaceFeature] {
                    print(feature.hasSmile)
                    self.switchSmileLabel(hasSmile: feature.hasSmile)
                }
            }
        }
    }
    
    func switchSmileLabel(hasSmile: Bool) {
        DispatchQueue.main.async {
            self.smileLabel.text = hasSmile ? "true" : "false"
        }
    }
}

