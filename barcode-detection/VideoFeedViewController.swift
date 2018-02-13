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

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageView2: UIImageView!
    
    private let videoSource = VideoSource()
    private let processor = ImageProcessor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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

extension VideoSourceDelegate {
    
    func videoSourceDidOutputFrame(withBuffer sampleBuffer: CMSampleBuffer, pixelFormat: PixelFormat) {
        process
    }
    
    func videoSourceDidEncounterError(_ error: Error) {
        print("Video service error: \(error)")
    }
}

