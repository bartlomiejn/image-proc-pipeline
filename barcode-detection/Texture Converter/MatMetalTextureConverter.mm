//
//  MatMetalTextuerConverter.m
//  barcode-detection
//
//  Created by Bartłomiej Nowak on 25.02.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

#import "MatMetalTextureConverter.h"

using namespace cv;

@interface MatMetalTextureConverter ()
@end

@implementation MatMetalTextureConverter

- (instancetype _Nonnull)initWithProcessor:(ImageProcessor*)processor {
    self = [super init];
    if (self) {
        processor.onMatReady = ^(cv::Mat mat) {
            // TODO: Set me up
        };
    }
    return self;
}

-(void)convert:(cv::Mat)mat {
    
}

@end
