//
//  ModelManager.swift
//  handsOnAi
//
//  Created by Florian Kainberger on 13.12.23.
//

import Foundation
import FirebaseMLModelDownloader
import MediaPipeTasksVision
import TensorFlowLite

class ModelManager: NSObject {
    public static var shared = ModelManager()
    
    public var interpreter: Interpreter?
    public var isSetup = false
    
    public var handLandmarkerInterpreter: HandLandmarker?
    
    override private init() {}
    
    public func setupModel(progressHandler: ((Float)->Void)? = nil) {
//        ModelDownloader.modelDownloader().deleteDownloadedModel(name: "asl_model_mobilenetv2", completion: {_ in
//        })
        let conditions = ModelDownloadConditions(allowsCellularAccess: true)
        ModelDownloader.modelDownloader()
            .getModel(name: "asl_model_mobilenetv2",
                      downloadType: .latestModel, conditions: conditions, progressHandler: { progress in
                print("[m] updated progress \(progress)")
                progressHandler?(progress)
            }) { result in
                print("[m] result \(result)")
                switch (result) {
                    case .success(let customModel):
                        do {
                            if let modelPath = Bundle.main.path(forResource: "hand_landmarker",
                                                                ofType: "task") {
                                
                                let options = HandLandmarkerOptions()
                                options.baseOptions.modelAssetPath = modelPath
                                options.runningMode = .image
                                options.minHandDetectionConfidence = 0.8
                                options.minHandPresenceConfidence = 0.8
                                options.minTrackingConfidence = 0.8
                                options.numHands = 1
                                
                                self.handLandmarkerInterpreter = try? HandLandmarker(options: options)
                            }
                            
                            progressHandler?(1)
                            let interpreter = try Interpreter(modelPath: customModel.path)
                            
                            self.interpreter = interpreter
                        } catch {
                                print("error bad file")
                        }
                    case .failure(let error):
                        print(error)
                }
            }
    }
}

