//
//  TomatoDetector.h
//  opencv-metal-pipeline
//
//  Created by Bartłomiej Nowak on 04.03.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

#import <UIKit/UIKit.h>

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

@interface TomatoDetector : NSObject
-(cv::Mat)detectTomatoInMat:(cv::Mat)mat;
@end
