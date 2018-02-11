//
//  ImageProcessor.mm
//  barcode-detection
//
//  Created by Bartłomiej Nowak on 11.02.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

#import "ImageProcessor.hh"
#import <opencv2/opencv.hpp>

using namespace cv;

@interface ImageProcessor ()
@end

@implementation ImageProcessor

- (UIImage* _Nullable)barcodeFromImage:(UIImage* _Nonnull)image {
    Mat mat = [self matFromImage:image];
    
    Mat grayscale_mat;
    cvtColor(mat, grayscale_mat, CV_RGBA2GRAY);
    
    // Gradient magnitude generation using Scharr operator
    
    Mat gradient_x, gradient_y;
    Sobel(grayscale_mat, gradient_x, CV_16S, 1, 0, -1); // ksize = -1 uses the Scharr operator
    Sobel(grayscale_mat, gradient_y, CV_16S, 0, 1, -1);
    
    Mat subtracted_grad, abs_subtracted;
    subtract(gradient_x, gradient_y, subtracted_grad);
    convertScaleAbs(subtracted_grad, abs_subtracted);
    
    // Blurring and thresholding
    
    Mat blurred;
    blur(abs_subtracted, blurred, cv::Size(9, 9));
    
    Mat thresholded;
    threshold(blurred, thresholded, 225, 255, CV_THRESH_BINARY);
    
    // Closing of gaps, barcode blob generation
    
    Mat morphed;
    morphologyEx(thresholded, morphed, MORPH_CLOSE, getStructuringElement(MORPH_RECT, cv::Point(21, 7)));
    
    Mat eroded, dilated;
    Mat defaultKernel = getStructuringElement(MORPH_RECT, cv::Point(3, 3));
    Point2i anchor = cv::Point(-1, -1);
    int iters = 4;
    erode(morphed, eroded, defaultKernel, anchor, iters);
    dilate(eroded, dilated, defaultKernel, anchor, iters);
    
    // Contours for the biggest blob (presumably our barcode)
    
    Mat cpy = dilated;
    std::vector<std::vector<cv::Point>> contours;
    std::vector<Vec4i> hierarchy;
    findContours(cpy, contours, hierarchy, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);
    
    if (contours.size() == 0) {
        return nil;
    }
    
    std::sort(contours.begin(),
              contours.end(),
              [] (const std::vector<cv::Point>& p_vec1, const std::vector<cv::Point>& p_vec2) {
                  return contourArea(p_vec1) > contourArea(p_vec2);
              });
    
    // Compute the rotated bounding box of the biggest blob
    
    cv::Mat boundingPts;
    cv::RotatedRect boundingRect = minAreaRect(contours[0]);
    boxPoints(boundingRect, boundingPts);
    
    Mat bBoxContours = Mat::zeros(dilated.rows, dilated.cols, CV_8UC3);
    cv::RNG rng;
    Scalar colour = cv::Scalar(rng.uniform(0, 255), rng.uniform(0, 255), rng.uniform(0, 255));
    
    Point2f pts[4];
    boundingRect.points(pts);
    line(bBoxContours, pts[0], pts[1], colour);
    line(bBoxContours, pts[1], pts[2], colour);
    line(bBoxContours, pts[2], pts[3], colour);
    line(bBoxContours, pts[3], pts[0], colour);
    
    return [self imageFromMat:bBoxContours orientation:UIImageOrientationUp];
}

- (instancetype)init {
    self = [super init];
    if (self) {}
    return self;
}

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
    NSData *data = [NSData dataWithBytes: mat.data length: mat.elemSize() * mat.total()];
    
    CGColorSpaceRef colorSpace = mat.elemSize() == 1 ? CGColorSpaceCreateDeviceGray() : CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    int cols = mat.cols;
    int rows = mat.rows;
    
    CGImageRef imageRef = CGImageCreate(cols,
                                        rows,
                                        8,                                          // Bits per component
                                        8 * mat.elemSize(),                         // Bits per pixel
                                        mat.step[0],                                // Bytes per row
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

