//
//  ContentViewModel.swift
//  GolfBallDetector
//
//  Created by Dailey, Matthew on 8/7/22.
//

import Foundation
import CoreML
import Vision
import CoreImage

protocol CameraViewModelProtocol: ObservableObject {
    var currentFrame: CGImage? { get }
    var boundingBoxes: [IdentifiableBoundingBox]? { get }
    
    func flipAndNormalizeRect(rect: CGRect, width: CGFloat, height: CGFloat) -> CGRect
}

class CameraViewModel: CameraViewModelProtocol {

    // MARK: - Public properties
    
    @Published var currentFrame: CGImage?
    @Published var boundingBoxes: [IdentifiableBoundingBox]?
    
    // MARK: - Private properties
    
    private let cameraManager: CameraManagerProtocol
    
    private let machineLearningQueue = DispatchQueue(label: "com.putters.machineLearningQueue")
    private let context = CIContext()
    private var VNModel: VNCoreMLModel? = try? VNCoreMLModel(for: GolfBallDetector1(configuration: MLModelConfiguration()).model)

    // MARK: - Lifecycle methods
    
    init(cameraManager: CameraManagerProtocol) {
        self.cameraManager = cameraManager
        self.cameraManager.startCaptureSession()
        setupSubscriptions()
    }
    
    deinit {
        self.cameraManager.stopCaptureSession()
    }
    
    // MARK: - Public methods
    
    public func flipAndNormalizeRect(rect: CGRect, width: CGFloat, height: CGFloat) -> CGRect {
        // flip rect coordinates vertically by 180 degrees; SwiftUI sets origin at top left, CoreML uses bottom left
        let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: -1)
        let flippedRect = rect.applying(transform)
        
        // normalize rect according to dimensions of the screen, supplied by a GeometryReader
        return VNImageRectForNormalizedRect(flippedRect, Int(width), Int(height))
    }
    
    
    // MARK: - Private methods

    private func setupSubscriptions() {
        cameraManager.pixelBufferPublisher
          .receive(on: RunLoop.main)
          .compactMap { [weak self] pixelBuffer in
              if let buffer = pixelBuffer {
                  
                  self?.machineLearningQueue.async { [weak self] in
                      self?.runModel(buffer: buffer)
                  }
                  
                  let ciImage = CIImage(cvImageBuffer: buffer)
                  return self?.context.createCGImage(ciImage, from: ciImage.extent)
              }
              return nil
          }
          .assign(to: &$currentFrame)
    }
    
    private func runModel(buffer: CVPixelBuffer) {
        guard let VNModel = VNModel else { return }

        let handler = VNImageRequestHandler(cvPixelBuffer: buffer)
        let request = VNCoreMLRequest(model: VNModel) { [weak self] (request, error) in
            guard error == nil else {
                print("ERROR Received")
                return
            }
            
            if let results = request.results as? [VNRecognizedObjectObservation] {
                var tempBoundingBoxes: [IdentifiableBoundingBox] = []
                for result in results {
                    let identifiableBoundingBox = IdentifiableBoundingBox(CGRect: result.boundingBox)
                    tempBoundingBoxes.append(identifiableBoundingBox)
                }
                
                DispatchQueue.main.async {
                    self?.boundingBoxes = tempBoundingBoxes
                }
            }
        }

        do {
            try handler.perform([request])
        } catch {
            print("Error performing request on VNModel")
        }
    }
}
