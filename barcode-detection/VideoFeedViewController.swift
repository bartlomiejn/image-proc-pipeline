//
//  VideoFeedViewController.swift
//  barcode-detection
//
//  Created by Bartłomiej Nowak on 11.02.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

import UIKit

class VideoFeedViewController: UIViewController {

    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var imageView2: UIImageView!
    
    private let processor = ImageProcessor()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let image = UIImage(named: "barcode_01")!
        imageView.image = image
        
        guard let barcodeImage = processor.barcode(from: image) else {
            return
        }

        imageView2.image = barcodeImage
    }
}

