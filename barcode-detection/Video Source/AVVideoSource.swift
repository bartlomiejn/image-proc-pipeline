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
    case yCbCrBiPlanar420FullRange
    
    /**
     Returns the CV type that corresponds to the enum case.
     
     kCVPixelFormatType are decimal numbers, which when converted to hex and then to ASCII give meaningful values, e.g.
     
     `kCVPixelFormatType_32BGRA` -> `BGRA`
     
     `kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange` -> `420v`
     
     `kCVPixelFormatType_420YpCbCr8BiPlanarFullRange` -> `420f`
     
     These are the three values that are available on an iPhone 8+ which i'm using for testing purposes. According to
     SO link below, these 3 were also available on 4S so all of them should be always available.
    */
    var coreVideoType: OSType {
        switch self {
            case .bgra32:
                return kCVPixelFormatType_32BGRA
            case .yCbCrBiPlanar420:
                // https://stackoverflow.com/questions/10126776/difference-between-full-range-420f-and-video-range-420v-for-ycrcb-pixel-form
                //
                // Video range means that the Y component only uses the byte values from 16 to 235 (for some historical
                // reasons). Full range uses the full range of a byte, namely 0 to 255.
                //
                // The chroma components (Cb, Cr) always use full range.
                return kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
            case .yCbCrBiPlanar420FullRange:
                return kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        }
    }
}

protocol AVVideoSourceDelegate: class {
    func videoSourceDidOutputFrame(withBuffer sampleBuffer: CMSampleBuffer, pixelFormat: PixelFormat)
    func videoSourceDidEncounterError(_ error: Error)
}

final class AVVideoSource: NSObject {
    
    struct BufferRetrievalFailure: Error {}
    struct InsufficientVideoAuthorization: Error {}
    struct SessionInitializationFailure: Error {}
    
    weak var delegate: AVVideoSourceDelegate?
    
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
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : Int(pixelFormat.coreVideoType)]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        
        session.addOutput(videoOutput)
        
        videoOutput.connection(with: .video)?.videoOrientation = .portrait
    }
}

extension AVVideoSource: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        delegate?.videoSourceDidOutputFrame(withBuffer: sampleBuffer, pixelFormat: pixelFormat)
    }
}
