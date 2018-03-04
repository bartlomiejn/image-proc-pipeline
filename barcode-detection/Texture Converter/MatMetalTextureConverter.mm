//
//  MatMetalTextuerConverter.m
//  barcode-detection
//
//  Created by Bartłomiej Nowak on 25.02.2018.
//  Copyright © 2018 Bartłomiej Nowak. All rights reserved.
//

#import "MatMetalTextureConverter.h"
#import <CoreVideo/CoreVideo.h>

using namespace cv;

@interface MatMetalTextureConverter ()
@property (nonatomic) CVMetalTextureCacheRef cache;
@property (nonatomic, strong) id<MTLDevice> device;
@end

@implementation MatMetalTextureConverter

- (instancetype _Nonnull)initWithProcessor:(ImageProcessor* _Nonnull)processor device:(id<MTLDevice> _Nonnull)device {
    self = [super init];
    if (self) {
        [self setDevice:device];
        
        processor.onMatReady = ^(cv::Mat mat) {
            if ([self onTextureReady]) {
                self.onTextureReady([self textureFromMat:mat]);
            }
        };
    }
    return self;
}

- (id<MTLTexture>)textureFromMat:(cv::Mat)image {

    int imageCols = image.cols;
    int imageRows = image.rows;
    
    UInt8 *convertedRawImage = (UInt8*)calloc(imageRows * image.step * 4, sizeof(UInt8));
    
    int bytesPerPixel = sizeof(UInt8);
    int bytesPerRow = bytesPerPixel * image.step;
    
    UInt8 b, g, r, a;
    
    for (int currRow = 0; currRow < imageRows; currRow++) {
        
        int currRowOffset = (int)image.step.buf[0] * currRow;
        int convertedRowOffset = bytesPerRow * currRow;
        
        UInt8* currRowPtr = (UInt8*)(image.data + currRowOffset);
        
        for (int currCol = 0; currCol < imageCols; currCol++) {
            b = (UInt8)(currRowPtr[4 * currCol]);
            g = (UInt8)(currRowPtr[4 * currCol + 1]);
            r = (UInt8)(currRowPtr[4 * currCol + 2]);
            a = (UInt8)(currRowPtr[4 * currCol + 3]);
            
            convertedRawImage[convertedRowOffset + (4 * currCol)] = b;
            convertedRawImage[convertedRowOffset + (4 * currCol + 1)] = g;
            convertedRawImage[convertedRowOffset + (4 * currCol + 2)] = r;
            convertedRawImage[convertedRowOffset + (4 * currCol + 3)] = a;
        }
    }
    
    id<MTLTexture> texture;
    
    MTLTextureDescriptor *descriptor = [MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatBGRA8Unorm
                                                                                          width:imageCols
                                                                                         height:imageRows
                                                                                      mipmapped:NO];
    
    texture = [self.device newTextureWithDescriptor:descriptor];
    
    MTLRegion region = MTLRegionMake2D(0, 0, imageCols, imageRows);
    
    [texture replaceRegion:region mipmapLevel:0 withBytes:convertedRawImage bytesPerRow:bytesPerRow];
    
    free(convertedRawImage);
                                                  
    return texture;
}

@end
