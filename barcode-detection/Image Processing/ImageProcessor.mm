//
//  ImageProcessor.mm
//  barcode-detection
//
//  Created by Bartłomiej Nowak on 11.02.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

#import "ImageProcessor.h"
#import <opencv2/opencv.hpp>

using namespace cv;

@interface ImageProcessor ()
@end

@implementation ImageProcessor

- (instancetype)init {
    self = [super init];
    if (self) {}
    return self;
}

- (void)processBuffer:(CMSampleBufferRef _Nonnull)buffer {
    
}

- (UIImage* _Nullable)detectBarcodesFromBGRA32SampleBuffer:(CMSampleBufferRef _Nonnull)buffer {
    CVImageBufferRef buf = CMSampleBufferGetImageBuffer(buffer);
    
    CVPixelBufferLockBaseAddress(buf, 0);
    
    int width = (int)CVPixelBufferGetWidth(buf);
    int height = (int)CVPixelBufferGetHeight(buf);
    
    // https://gist.github.com/jebai/8108287#gistcomment-2160895
    // One suggestion, based on my experience using this: some iPhone device video streams have padding at the end of
    // each pixelBuffer row, which will result in corrupted images if the Mat auto-calculates the step size. To fix it,
    // manually set the 5th 'step' argument to cv::Mat to CVPixelBufferGetBytesPerRow(pixelBuffer).
    
    Mat mat = cv::Mat(height,
                      width,
                      CV_8UC4,
                      (unsigned char *)CVPixelBufferGetBaseAddress(buf),
                      CVPixelBufferGetBytesPerRow(buf));
    
    CVPixelBufferUnlockBaseAddress(buf, 0);

    return [self barcodeFromMat:mat];
}

- (UIImage* _Nullable)barcodeFromMat:(cv::Mat)mat {
    Mat grayscale_mat;
    cvtColor(mat, grayscale_mat, CV_BGRA2GRAY);
    
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
    
    std::vector<std::vector<cv::Point>> contours;
    std::vector<Vec4i> hierarchy;
    findContours(dilated, contours, hierarchy, RETR_EXTERNAL, CHAIN_APPROX_SIMPLE);
    
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
    line(mat, pts[0], pts[1], colour);
    line(mat, pts[1], pts[2], colour);
    line(mat, pts[2], pts[3], colour);
    line(mat, pts[3], pts[0], colour);
    
    return [self imageFromMat:mat orientation:UIImageOrientationUp];
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

