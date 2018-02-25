//
//  MatMetalTextureConverter.h
//  barcode-detection
//
//  Created by Bartłomiej Nowak on 25.02.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

#import "ImageProcessor.h"

#import <Foundation/Foundation.h>
#import <MetalKit/MetalKit.h>

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#endif

@interface MatMetalTextureConverter : NSObject

@property (nonatomic, copy) void (^onTextureReady)(id<MTLTexture> _Nonnull);

- (instancetype _Nonnull)initWithProcessor:(ImageProcessor* _Nonnull)processor;

#ifdef __cplusplus
-(void)convert:(cv::Mat)mat;
#endif

@end
