//
//  VideoFeedViewController.swift
//  barcode-detection
//
//  Created by Bartłomiej Nowak on 11.02.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

import UIKit
import AVFoundation
import Metal

class VideoFeedViewController: UIViewController {

    private lazy var metalView = MetalView(device: device)
    
    private let videoSource = AVVideoSource()
    private let processor = ImageProcessor()
    private lazy var converter = MatMetalTextureConverter(processor: processor, device: device)
    
    private let device = MTLCreateSystemDefaultDevice()!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(metalView)
        metalView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: metalView.topAnchor),
            view.leadingAnchor.constraint(equalTo: metalView.leadingAnchor),
            view.bottomAnchor.constraint(equalTo: metalView.bottomAnchor),
            view.trailingAnchor.constraint(equalTo: metalView.trailingAnchor)
        ])
        
        converter.onTextureReady = { [weak self] texture in
            self?.metalView.set(texture)
        }
        
        videoSource.delegate = self
        videoSource.setup(withPixelFormat: .bgra32)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        videoSource.resume()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        videoSource.suspend()
    }
}

extension VideoFeedViewController: AVVideoSourceDelegate {
    
    func videoSourceDidOutputFrame(withBuffer sampleBuffer: CMSampleBuffer, pixelFormat: PixelFormat) {
        processor.processBuffer(sampleBuffer)
    }
    
    func videoSourceDidEncounterError(_ error: Error) {
        print("Video service error: \(error)")
    }
}

