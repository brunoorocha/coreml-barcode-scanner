//
//  ViewController.swift
//  core-ml-project
//
//  Created by Bruno Rocha on 02/07/19.
//  Copyright © 2019 Bruno Rocha. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class ViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    var requests: [VNRequest] = []
    let session = AVCaptureSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        startLiveVideo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
        startBarcodeDetection()
        session.startRunning()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
        session.stopRunning()
    }
    
    override func viewDidLayoutSubviews() {
        imageView.layer.sublayers?[0].frame = imageView.bounds
    }

    func startLiveVideo() {
        session.sessionPreset = AVCaptureSession.Preset.high
        
        guard let captureDevice = AVCaptureDevice.default(for: AVMediaType.video) else { return }
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        let deviceOutput = AVCaptureVideoDataOutput()
        deviceOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
        deviceOutput.setSampleBufferDelegate(self, queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.default))
        
        session.addInput(deviceInput)
        session.addOutput(deviceOutput)
        
        let imageLayer = AVCaptureVideoPreviewLayer(session: session)
        imageLayer.frame = imageView.bounds
        imageView.layer.addSublayer(imageLayer)
        
        session.startRunning()
    }
    
    func startTextDetection() {
        let textRequest = VNDetectTextRectanglesRequest(completionHandler: self.detectTextHandler)
        textRequest.reportCharacterBoxes = true
        requests = [textRequest]
    }
    
    func startBarcodeDetection() {
        let barcodeDetectRequest = VNDetectBarcodesRequest(completionHandler: self.handleDetectedBarcode)
        barcodeDetectRequest.symbologies = [.Aztec, .EAN13]
        requests = [barcodeDetectRequest]
    }
    
    func handleDetectedBarcode(request: VNRequest, error: Error?) {
        if let nsError = error as NSError? {
            print(nsError.localizedDescription)
            return
        }
        
        DispatchQueue.main.async {
            if !self.session.isRunning { return }
            guard let results = request.results as? [VNBarcodeObservation] else { return }
            if let result = results.first {
                print(result.payloadStringValue ?? "")
                if let code = result.payloadStringValue {
                    self.performSegue(withIdentifier: "ProductDetails", sender: code)
                }
            }
        }
    }
    
    func detectTextHandler(request: VNRequest, error: Error?) {
        guard let observations = request.results else {
            print("no result")
            return
        }
        let result = observations.map { $0 as? VNTextObservation }
        
        DispatchQueue.main.async {
            self.imageView.layer.sublayers?.removeSubrange(1...)
            
            for region in result {
                guard let rg = region else { return }
                self.highlightWord(box: rg)
            }
        }
    }
    
    func highlightWord(box: VNTextObservation) {
        guard let boxes = box.characterBoxes else { return }
        
        var maxX: CGFloat = 9999.0
        var maxY: CGFloat = 9999.0
        var minX: CGFloat = 0.0
        var minY: CGFloat = 0.0
        
        for char in boxes {
            if (char.bottomLeft.x < maxX) {
                maxX = char.bottomLeft.x
            }
            
            if (char.bottomRight.x > minX) {
                minX = char.bottomRight.x
            }
            
            if (char.bottomRight.y < maxY) {
                maxY = char.bottomRight.y
            }
            
            if (char.topRight.y > minY) {
                minY = char.topRight.y
            }
        }
        
        let xCord = maxX * imageView.frame.size.width
        let yCord = (1 - minY) * imageView.frame.size.height
        let width = (minX - maxX) * imageView.frame.size.width
        let height = (minY - maxY) * imageView.frame.size.height
        
        let outline = CALayer()
        outline.frame = CGRect(x: xCord, y: yCord, width: width, height: height)
        outline.borderWidth = 2.0
        outline.borderColor = UIColor.cyan.cgColor
        
        imageView.layer.addSublayer(outline)
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let camData = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
            requestOptions = [.cameraIntrinsics:camData]
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation.init(rawValue: 6) ?? .up, options: requestOptions)
        
        do {
            try imageRequestHandler.perform(self.requests)
        } catch {
            print(error)
        }
    }
}

extension ViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ProductDetails" {
            if let nextViewController = segue.destination as? ProductDetailsViewController {
                guard let code = sender as? String else { return }
                nextViewController.barcode = code
            }
        }
    }
}
