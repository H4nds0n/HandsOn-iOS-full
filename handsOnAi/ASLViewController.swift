//
//  ASLViewController.swift
//  handsOnAi
//
//  Created by Florian Kainberger on 13.12.23.
//

import UIKit
import AVFoundation
import MediaPipeTasksVision

class ASLViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var cameraHostingView: UIView!
    @IBOutlet weak var textView: UITextView!
    
        // Create an AVCaptureSession
    let captureSession = AVCaptureSession()
    var videoOutput: AVCaptureVideoDataOutput?
    var output: AVCaptureMetadataOutput?
    
    private var currentText: String = ""
    private var lastLetterTime: TimeInterval = 0
    private var allRecognizedLetters = [(classIndex: Int, confidence: Float32)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        cameraHostingView.layer.cornerRadius = 20
        cameraHostingView.layer.masksToBounds = true
        textView.layer.cornerRadius = 20
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.setupCamera()
            self.setupModel()
//            self.captureSession.startRunning()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.captureSession.stopRunning()
    }
    
    @IBAction func didTapSaveAndClear(_ sender: Any) {
        var existingArray = UserDefaults.standard.stringArray(forKey: "history") ?? []

        existingArray.append(currentText)
        
            // Save the updated array back to UserDefaults
        UserDefaults.standard.set(existingArray, forKey: "history")
        
        self.currentText = ""
        self.textView.text = ""
    }
    
    
    private func setupCamera() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else { return }
        let input = try? AVCaptureDeviceInput(device: captureDevice)
        
        if let input = input, captureSession.canAddInput(input) {
            captureSession.addInput(input)
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = .resizeAspectFill
        
        DispatchQueue.main.async {
            previewLayer.frame = self.cameraHostingView.layer.bounds
            self.cameraHostingView.layer.addSublayer(previewLayer)
        }
        
        videoOutput = AVCaptureVideoDataOutput()
        guard let videoOutput = videoOutput else {return}
        videoOutput.videoSettings = [
            String(kCVPixelBufferPixelFormatTypeKey): NSNumber(value: kCVPixelFormatType_32BGRA)
        ]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        let queue = DispatchQueue(label: "video-frame-sampler")
            videoOutput.setSampleBufferDelegate(self, queue: queue)
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                
                if let connection = videoOutput.connection(with: .video) {
                    if #available(iOS 17.0, *) {
                        connection.videoRotationAngle = 90.0
                    } else {
                    }
                    
                    if connection.isVideoStabilizationSupported {
                        connection.preferredVideoStabilizationMode = .auto
                    }
                }
            }
        
    }
    
    private func setupModel() {
        if ModelManager.shared.interpreter == nil {
            ModelManager.shared.setupModel()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        captureSession.outputs.forEach { $0.connections.forEach { $0.videoOrientation = .portrait }}
        cameraHostingView.layer.sublayers?.first?.frame = cameraHostingView.layer.bounds
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let mpImage = try? MPImage(sampleBuffer: sampleBuffer) else {return}
        
        guard let result = try? ModelManager.shared.handLandmarkerInterpreter?.detect(image: mpImage) else {return}
        
        let firstHandLandmarks = result.landmarks[0]
        
        var maxX = Float.leastNormalMagnitude
        var minX = Float.greatestFiniteMagnitude
        var maxY = Float.leastNormalMagnitude
        var minY = Float.greatestFiniteMagnitude
        
            // Iterate through the array to find maximum and minimum values
        for landmark in firstHandLandmarks {
            maxX = max(maxX, landmark.x)
            minX = min(minX, landmark.x)
            maxY = max(maxY, landmark.y)
            minY = min(minY, landmark.y)
        }
        
            // Calculate padding values
        let xPadding = abs(maxX - minX) * 0.1
        let yPadding = abs(maxY - minY) * 0.1
        
            // Apply padding and ensure non-negative values
        maxX += min(xPadding, 1)
        minX = max(minX - xPadding, 0.0)
        maxY += min(yPadding, 1)
        minY = max(minY - yPadding, 0.0)
        
        
        
//        
//        let currentFrameTime = getCurrentMillis()
//            // Convert the sample buffer to a CGImage
//        guard let image = imageFromSampleBuffer(sampleBuffer) else {
//            print("no image")
//            return
//        }
//        
//        guard let context = CGContext(data: nil,
//                                      width: image.width, height: image.height,
//                                      bitsPerComponent: 8, bytesPerRow: image.width * 4,
//                                      space: CGColorSpaceCreateDeviceRGB(),
//                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
//            print("[event] no context")
//            return
//        }
//        
//        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
//        guard let imageData = context.data else { 
//            print("no data")
//            return }
//        
//        var inputData = Data()
//        for row in 0 ..< 224 {
//            for col in 0 ..< 224 {
//                
//                let offset = 4 * (row * context.width + col)
//                    // (Ignore offset 0, the unused alpha channel)
//                let red = imageData.load(fromByteOffset: offset+1, as: UInt8.self)
//                let green = imageData.load(fromByteOffset: offset+2, as: UInt8.self)
//                let blue = imageData.load(fromByteOffset: offset+3, as: UInt8.self)
//                var normalizedRed = Float32(red) / 255.0
//                var normalizedGreen = Float32(green) / 255.0
//                var normalizedBlue = Float32(blue) / 255.0
//                
//                    // Append normalized values to Data object in RGB order.
//                let elementSize = MemoryLayout.size(ofValue: normalizedRed)
//                var bytes = [UInt8](repeating: 0, count: elementSize)
//                memcpy(&bytes, &normalizedRed, elementSize)
//                inputData.append(&bytes, count: elementSize)
//                memcpy(&bytes, &normalizedGreen, elementSize)
//                inputData.append(&bytes, count: elementSize)
//                memcpy(&bytes, &normalizedBlue, elementSize)
//                inputData.append(&bytes, count: elementSize)
//            }
//        }
        
        //bounding box for hand
        let boundingBox = CGRect(x: CGFloat(minX), y: CGFloat(minY), width: CGFloat(maxX - minX), height: CGFloat(maxY - minY))
        
        let currentFrameTime = getCurrentMillis()
        
        // Convert the sample buffer to a CGImage
        guard let image = imageFromSampleBuffer(sampleBuffer) else {
            print("no image")
            return
        }
        
        guard let context = CGContext(data: nil,
                                      width: image.width, height: image.height,
                                      bitsPerComponent: 8, bytesPerRow: image.width * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            print("[event] no context")
            return
        }
        
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        guard let imageData = context.data else {
            print("no data")
            return
        }
        
        var inputData = Data()
        // Iterate through the bounding box region
        for row in Int(boundingBox.origin.y) ..< Int(boundingBox.origin.y + boundingBox.size.height) {
            for col in Int(boundingBox.origin.x) ..< Int(boundingBox.origin.x + boundingBox.size.width) {
                    // Make sure the row and column are within valid bounds
                if row >= 0 && row < 224 && col >= 0 && col < 224 {
                    let offset = 4 * (row * context.width + col)
                        // Rest of the code remains the same
                    let red = imageData.load(fromByteOffset: offset + 1, as: UInt8.self)
                    let green = imageData.load(fromByteOffset: offset + 2, as: UInt8.self)
                    let blue = imageData.load(fromByteOffset: offset + 3, as: UInt8.self)
                    var normalizedRed = Float32(red) / 255.0
                    var normalizedGreen = Float32(green) / 255.0
                    var normalizedBlue = Float32(blue) / 255.0
                    
                        // Append normalized values to Data object in RGB order.
                    let elementSize = MemoryLayout.size(ofValue: normalizedRed)
                    var bytes = [UInt8](repeating: 0, count: elementSize)
                    memcpy(&bytes, &normalizedRed, elementSize)
                    inputData.append(&bytes, count: elementSize)
                    memcpy(&bytes, &normalizedGreen, elementSize)
                    inputData.append(&bytes, count: elementSize)
                    memcpy(&bytes, &normalizedBlue, elementSize)
                    inputData.append(&bytes, count: elementSize)
                }
            }
        }
        
            // Run the interpreter
        do {
            try ModelManager.shared.interpreter?.allocateTensors()
            try ModelManager.shared.interpreter?.copy(inputData, toInputAt: 0)
            try ModelManager.shared.interpreter?.invoke()
        } catch {
            print("Error running the interpreter: \(error)")
            return
        }
        
            // Retrieve the model's output
        if let output = try? ModelManager.shared.interpreter?.output(at: 0) {
            let probabilities = UnsafeMutableBufferPointer<Float32>.allocate(capacity: 1000)
            output.data.copyBytes(to: probabilities)
            
            guard let labelPath = Bundle.main.path(forResource: "labels", ofType: "txt"),
                  let fileContents = try? String(contentsOfFile: labelPath) else {
                
                return
            }
            let labels = fileContents.components(separatedBy: "\n")
            
            var highest: (classIndex: Int, confidence: Float32) = (classIndex: 0, confidence: 0)
            for i in labels.indices {
                print("\(labels[i]): \(probabilities[i])")
                if highest.confidence < probabilities[i] {
                    highest = (i, probabilities[i])
                }
            }
            
            DispatchQueue.main.async {
                if currentFrameTime-self.lastLetterTime >= 500 {
                    var classIndexAvg: Double = 0
                    var predictionAvg: Float32 = 0
                    
                    self.allRecognizedLetters.forEach({l in
                        classIndexAvg += Double(l.classIndex)
                        predictionAvg += l.confidence
                    })
                    
                    if self.allRecognizedLetters.count != 0 {
                        classIndexAvg /= Double(self.allRecognizedLetters.count)
                    }
                    
                    print("[a] \(classIndexAvg)")
                    let aIndex:Int = Int(classIndexAvg.rounded())
                    
                    
                    if predictionAvg > 0.8 {
                        self.currentText += labels[aIndex]
                        self.textView.text = "Predicted: \(labels[aIndex])\nConfidence: \(highest.confidence) \n \(self.currentText)"
                        
                    }
                    
                    self.lastLetterTime = currentFrameTime
                    self.allRecognizedLetters = []
                    
                    print("[t] \(self.currentText)")
                } else {
                    if highest.confidence > 0.7 {
                        self.allRecognizedLetters.append(highest)
                    }
                }
                
            }
        }
    }
    
    private func imageFromSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> CGImage? {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        let baseAddress = CVPixelBufferGetBaseAddress(pixelBuffer)
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue)
        let context = CGContext(data: baseAddress,
                                width: width,
                                height: height,
                                bitsPerComponent: 8,
                                bytesPerRow: bytesPerRow,
                                space: colorSpace,
                                bitmapInfo: bitmapInfo.rawValue)
        
        let image = context?.makeImage()
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
        
        return image
    }
    
    
    func getCurrentMillis() -> Double {
        return Date().timeIntervalSince1970 * 1000
    }
}
