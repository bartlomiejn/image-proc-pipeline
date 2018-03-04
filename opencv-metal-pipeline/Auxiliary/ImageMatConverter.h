//
//  ImageMatConverter.h
//  opencv-metal-pipeline
//
//  Created by Bartłomiej Nowak on 04.03.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

@interface ImageMatConverter : NSObject
- (cv::Mat)matFromImage:(UIImage *)image;
- (UIImage *)imageFromMat:(cv::Mat)mat orientation:(UIImageOrientation)orientation;
@end
