//
//  CameraManager.swift
//  GolfBallDetector
//
//  Created by Dailey, Matthew on 8/7/22.
//

import AVFoundation

protocol CameraManagerProtocol: AVCaptureVideoDataOutputSampleBufferDelegate {
    var pixelBuffer: CVPixelBuffer? { get }
    var pixelBufferPublisher: Published<CVPixelBuffer?>.Publisher { get }
    
    func startCaptureSession()
    func stopCaptureSession()
}

class CameraManager: NSObject, CameraManagerProtocol  {
    
    // MARK: - Public properties
    
    @Published private (set) var pixelBuffer: CVPixelBuffer?
    var pixelBufferPublisher: Published<CVPixelBuffer?>.Publisher { $pixelBuffer }
    
    // MARK: - Private properties
    
    private let videoOutputQueue = DispatchQueue(label: "com.putters.videoOutputQueue")
    private let videoOutput = AVCaptureVideoDataOutput()
    private let session = AVCaptureSession()
    
    // MARK: - Public methods
    
    public func startCaptureSession() {
        // Get camera access
        AVCaptureDevice.requestAccess(for: .video) { authorized in
            if authorized {
                print("Video Capture Authorized")
            }
        }
        configureCaptureSession()
        session.startRunning()
    }
    
    public func stopCaptureSession() {
        session.stopRunning()
    }
    
    // MARK: - Private methods
    
    private func configureCaptureSession() {
        session.beginConfiguration()
        
        // setup video capture device
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Unable to initialize camera")
            return
        }
        
        // setup camera input
        do {
          let cameraInput = try AVCaptureDeviceInput(device: camera)
          if session.canAddInput(cameraInput) {
            session.addInput(cameraInput)
          } else {
            print("Problem adding camera input")
          }
        } catch {
            print("Error caught whilte trying to get the camera input")
        }

        // setup camera output
        if session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)

            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            
            let videoConnection = videoOutput.connection(with: .video)
            videoConnection?.videoOrientation = .portrait
        } else {
            print("Error adding camera output")
        }
        
        // set delegate to self
        videoOutput.setSampleBufferDelegate(self, queue: videoOutputQueue)
        
        session.commitConfiguration()
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate method

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let buffer = sampleBuffer.imageBuffer {
            DispatchQueue.main.async {
                self.pixelBuffer = buffer
            }
        }
    }
}
