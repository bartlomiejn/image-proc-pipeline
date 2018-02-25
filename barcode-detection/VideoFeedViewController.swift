//
//  VideoFeedViewController.swift
//  barcode-detection
//
//  Created by Bartłomiej Nowak on 11.02.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

import UIKit
import AVFoundation

class VideoFeedViewController: UIViewController {

    @IBOutlet private weak var metalView: MetalView!
    
    private let videoSource = AVVideoSource()
    private let processor = ImageProcessor()
    private lazy var converter = MatMetalTextureConverter(processor: processor)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
//        guard let image = processor.process else {
//            return
//        }
//
//        DispatchQueue.main.async { [weak imageView] in
//            imageView?.image = image
//        }
    }
    
    func videoSourceDidEncounterError(_ error: Error) {
        print("Video service error: \(error)")
    }
}

