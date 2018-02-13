//
//  VideoSource.swift
//  barcode-detection
//
//  Created by Bartłomiej Nowak on 13.02.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

import AVFoundation

enum PixelFormat {
    case bgra32
    case yCbCrBiPlanar420
    
    var coreVideoType: OSType {
        switch self {
            case .bgra32:
                return kCVPixelFormatType_32BGRA
            case .yCbCrBiPlanar420:
                return kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        }
    }
}

protocol VideoSourceDelegate: class {
    func videoSourceDidOutputFrame(withBuffer sampleBuffer: CMSampleBuffer, pixelFormat: PixelFormat)
    func videoSourceDidEncounterError(_ error: Error)
}

final class VideoSource: NSObject {
    
    struct BufferRetrievalFailure: Error {}
    struct InsufficientVideoAuthorization: Error {}
    struct SessionInitializationFailure: Error {}
    
    weak var delegate: VideoSourceDelegate?
    
    private let session = AVCaptureSession()
    private var discoverySession = AVCaptureDevice.DiscoverySession(
        deviceTypes: [.builtInDualCamera, .builtInWideAngleCamera],
        mediaType: .video,
        position: .back
    )
    private var deviceInput: AVCaptureDeviceInput!
    private let videoOutput = AVCaptureVideoDataOutput()
    
    private let sessionQueue = DispatchQueue(label: "camera-service.session")
    
    private var captureDevice: AVCaptureDevice? {
        return .default(.builtInDualCamera, for: .video, position: .back)
            ?? .default(.builtInWideAngleCamera, for: .video, position: .back)
            ?? .default(.builtInWideAngleCamera, for: .video, position: .front)
    }
    
    private var pixelFormat: PixelFormat!
    
    func setup(withPixelFormat pixelFormat: PixelFormat) {
        self.pixelFormat = pixelFormat
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                break
            case .notDetermined:
                requestVideoAuthorization()
            default:
                delegate?.videoSourceDidEncounterError(InsufficientVideoAuthorization())
        }
        
        sessionQueue.async { [weak self] in
            self?.setupAVSession()
        }
    }
    
    func resume() {
        sessionQueue.async { [weak session] in
            session?.startRunning()
        }
    }
    
    func suspend() {
        sessionQueue.async { [weak session] in
            session?.stopRunning()
        }
    }
    
    private func requestVideoAuthorization() {
        sessionQueue.suspend()
        
        AVCaptureDevice.requestAccess(for: .video) { [weak sessionQueue, weak delegate] isAuthorized in
            guard isAuthorized else {
                delegate?.videoSourceDidEncounterError(InsufficientVideoAuthorization())
                return
            }
            
            sessionQueue?.resume()
        }
    }
    
    private func setupAVSession() {
        session.beginConfiguration()
        
        session.sessionPreset = .high
        
        setupVideoInput()
        setupVideoOutput()
        
        session.commitConfiguration()
    }
    
    private func setupVideoInput() {
        guard
            let videoDevice = captureDevice,
            let deviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            session.canAddInput(deviceInput)
        else {
            fatalError("Could not retrieve suitable capture device or configure video device input.")
        }
        
        self.deviceInput = deviceInput
        
        session.addInput(deviceInput)
    }
    
    private func setupVideoOutput() {
        guard session.canAddOutput(videoOutput) else {
            fatalError("Could not configure photo input.")
        }
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videosource.output"))
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(pixelFormat.coreVideoType)]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        session.addOutput(videoOutput)
        
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
    }
}

extension VideoSource: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        delegate?.videoSourceDidOutputFrame(withBuffer: sampleBuffer, pixelFormat: pixelFormat)
    }
}
