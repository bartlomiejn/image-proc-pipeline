//
//  ImageProcessor.h
//  barcode-detection
//
//  Created by Bartłomiej Nowak on 11.02.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

@interface ImageProcessor : NSObject

#ifdef __cplusplus
@property (nonatomic, copy) void (^ _Nullable onMatReady)(cv::Mat);
#endif

- (instancetype _Nonnull)init;
- (void)processBuffer:(CMSampleBufferRef _Nonnull)buffer;

@end

