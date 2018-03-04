//
//  ImageMatConverter.m
//  opencv-metal-pipeline
//
//  Created by Bartłomiej Nowak on 04.03.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

#import "ImageMatConverter.h"
#import <UIKit/UIKit.h>

using namespace cv;

@implementation ImageMatConverter

- (Mat)matFromImage:(UIImage *)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    Mat matImage(rows, cols, CV_8UC4); // 8 bits per component, RGBA
    
    CGContextRef contextRef = CGBitmapContextCreate(matImage.data,
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    matImage.step[0],           // Bytes per row
                                                    colorSpace,
                                                    kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    return matImage;
}

- (UIImage *)imageFromMat:(Mat)mat orientation:(UIImageOrientation)orientation {
    cv::Mat cvtedMat;
    cvtColor(mat, cvtedMat, CV_BGRA2RGB);
    
    NSData *data = [NSData dataWithBytes: cvtedMat.data length: cvtedMat.elemSize() * cvtedMat.total()];
    
    CGColorSpaceRef colorSpace = cvtedMat.elemSize() == 1 ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB();
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    CGImageRef imageRef = CGImageCreate(cvtedMat.cols,
                                        cvtedMat.rows,
                                        8,                                          // Bits per component
                                        8 * cvtedMat.elemSize(),                         // Bits per pixel
                                        cvtedMat.step[0],                                // Bytes per row
                                        colorSpace,
                                        kCGImageAlphaNone | kCGBitmapByteOrderDefault,
                                        provider,
                                        NULL,                                       // Decode
                                        false,                                      // Should interpolate
                                        kCGRenderingIntentDefault);
    
    UIImage *uiImage = [UIImage imageWithCGImage:imageRef scale:1 orientation:orientation];
    
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return uiImage;
}


@end
