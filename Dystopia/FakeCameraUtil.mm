// Copyright (c) 2013, Daniel Andersen (daniel@trollsahead.dk)
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
// 3. The name of the author may not be used to endorse or promote products derived
//    from this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
// ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
// WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
// ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
// (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
// ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
// SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "FakeCameraUtil.h"
#import "UIImage+OpenCV.h"
#import "CameraUtil.h"
#import "BoardGame.h"

@interface FakeCameraUtil () {
    UIImage *fakeCameraImage;
    int brickChecked[BOARD_HEIGHT][BOARD_WIDTH];
}

@end

@implementation FakeCameraUtil

FakeCameraUtil *fakeCameraUtilInstance = nil;

+ (FakeCameraUtil *)instance {
    @synchronized(self) {
        if (fakeCameraUtilInstance == nil) {
            fakeCameraUtilInstance = [[FakeCameraUtil alloc] init];
        }
        return fakeCameraUtilInstance;
    }
}

- (id)init {
    if (self = [super init]) {
        for (int i = 0; i < BOARD_HEIGHT; i++) {
            for (int j = 0; j < BOARD_WIDTH; j++) {
                brickChecked[i][j] = 0;
            }
        }
    }
    return self;
}

- (UIImage *)fakePerspectiveOnImage:(UIImage *)image {
    FourPoints srcPoints = {
        .p1 = CGPointMake(0.0f, 0.0f),
        .p2 = CGPointMake(image.size.width, 0.0f),
        .p3 = CGPointMake(image.size.width, image.size.height),
        .p4 = CGPointMake(0.0f, image.size.height)
    };
    FourPoints dstPoints = {
        .p1 = CGPointMake(1.0f, 1.0f),
        .p2 = CGPointMake(image.size.width - 1.0f, 1.0f),
        .p3 = CGPointMake(image.size.width - 1.0f, image.size.height - 1.0f),
        .p4 = CGPointMake(1.0f, image.size.height - 1.0f)
    };
    cv::Mat transformation = [CameraUtil findPerspectiveTransformationSrcPoints:srcPoints dstPoints:dstPoints];
    cv::Mat outputImg = [CameraUtil perspectiveTransformImage:[image CVMat] withTransformation:transformation toSize:image.size];
    return [UIImage imageWithCVMat:outputImg];
}

- (UIImage *)rotateImageToLandscapeMode:(UIImage *)image {
    return [[UIImage alloc] initWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationLeftMirrored];
}

- (UIImage *)fakeOutputImage {
    if (fakeCameraImage == nil) {
        fakeCameraImage = [UIImage imageNamed:@"fake_board_6.png"];
    }
    return fakeCameraImage;
}

- (UIImage *)drawBricksWithSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    for (int i = 0; i < BOARD_HEIGHT; i++) {
        for (int j = 0; j < BOARD_WIDTH; j++) {
            if (brickChecked[i][j]) {
                CGRect rectRotated = [[BoardUtil instance] brickScreenRect:cv::Point(j, i)];
                CGRect rect = CGRectMake(size.width - rectRotated.origin.y - rectRotated.size.height, rectRotated.origin.x, rectRotated.size.height, rectRotated.size.width);
                rect.origin.x += 2.0f;
                rect.origin.y += 2.0f;
                rect.size.width -= 4.0f;
                rect.size.height -= 4.0f;
                CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
                CGContextFillRect(context, rect);
            }
        }
    }
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return outputImage;
}

- (UIImage *)drawBricksOnImage:(UIImage *)image {
    UIGraphicsBeginImageContextWithOptions(image.size, YES, 1.0f);
    
    [image drawAtPoint:CGPointMake(0.0f, 0.0f)];
    CGContextRef context = UIGraphicsGetCurrentContext();
    for (int i = 0; i < BOARD_HEIGHT; i++) {
        for (int j = 0; j < BOARD_WIDTH; j++) {
            if (brickChecked[i][j]) {
                CGRect rect = [[BoardUtil instance] brickScreenRect:cv::Point(j, i)];
                rect.origin.x += 2.0f;
                rect.origin.y += 2.0f;
                rect.size.width -= 4.0f;
                rect.size.height -= 4.0f;
                CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
                CGContextFillRect(context, rect);
            }
        }
    }

    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return outputImage;
}

- (void)clickAtPoint:(cv::Point)p {
    brickChecked[p.y][p.x] = !brickChecked[p.y][p.x];
}

@end
