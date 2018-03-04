//
//  ImageProcessor.mm
//  opencv-metal-pipeline
//
//  Created by Bartłomiej Nowak on 11.02.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

#import "ImageProcessor.h"
#import "TomatoDetector.h"
#import <opencv2/opencv.hpp>

using namespace cv;

@interface ImageProcessor ()
@property (nonatomic, strong) TomatoDetector* detector;
@end

@implementation ImageProcessor

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setDetector:[[TomatoDetector alloc] init]];
    }
    return self;
}

- (void)processBuffer:(CMSampleBufferRef _Nonnull)buffer {
    cv::Mat mat = [self matFromBuffer:buffer];
    
    if ([self onMatReady]) {
        cv::Mat output = [self.detector detectTomatoInMat:mat];
        [self onMatReady](output);
    }
}

- (cv::Mat)matFromBuffer:(CMSampleBufferRef _Nonnull)buffer {
    CVImageBufferRef buf = CMSampleBufferGetImageBuffer(buffer);
    
    CVPixelBufferLockBaseAddress(buf, 0);
    
    int width = (int)CVPixelBufferGetWidth(buf);
    int height = (int)CVPixelBufferGetHeight(buf);
    
    // https://gist.github.com/jebai/8108287#gistcomment-2160895
    // One suggestion, based on my experience using this: some iPhone device video streams have padding at the end of
    // each pixelBuffer row, which will result in corrupted images if the Mat auto-calculates the step size. To fix it,
    // manually set the 5th 'step' argument to cv::Mat to CVPixelBufferGetBytesPerRow(pixelBuffer).
    //
    // e.g. a 1920x1080 frame with 4bpp will have 4352 bytesPerRow instead of 4320
    
    Mat mat = cv::Mat(height,
                      width,
                      CV_8UC4,
                      (unsigned char *)CVPixelBufferGetBaseAddress(buf),
                      CVPixelBufferGetBytesPerRow(buf));
    
    CVPixelBufferUnlockBaseAddress(buf, 0);
    
    return mat;
}
@end

