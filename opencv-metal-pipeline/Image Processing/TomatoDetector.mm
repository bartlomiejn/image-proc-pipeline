//
//  TomatoDetector.m
//  opencv-metal-pipeline
//
//  Created by Bartłomiej Nowak on 04.03.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

#import "TomatoDetector.h"

@implementation TomatoDetector

-(cv::Mat)detectTomatoInMat:(cv::Mat)mat {
    using namespace cv;
    
    Mat hsvMat;
    cvtColor(mat, hsvMat, COLOR_BGRA2BGR);
    cvtColor(hsvMat, hsvMat, COLOR_BGR2HSV);
    
    Mat redThresh = [self thresholdedRedMatFromMat:hsvMat];
    
    cvtColor(redThresh, redThresh, COLOR_GRAY2BGR);
    cvtColor(redThresh, redThresh, COLOR_BGR2BGRA);
    
    return redThresh;
}

-(cv::Mat)thresholdedRedMatFromMat:(cv::Mat)hsvMat {
    using namespace cv;
    
    Mat lower_red_hue_range;
    Mat upper_red_hue_range;
    inRange(hsvMat, cv::Scalar(0, 100, 100), cv::Scalar(10, 255, 255), lower_red_hue_range);
    inRange(hsvMat, cv::Scalar(160, 100, 100), cv::Scalar(180, 255, 255), upper_red_hue_range);
    
    Mat outputMat;
    cv::bitwise_or(lower_red_hue_range, upper_red_hue_range, outputMat);
    
    return outputMat;
}

@end
