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

#import "CameraUtil.h"
#import "UIImage+OpenCV.h"

@implementation CameraUtil

+ (UIImage *)imageFromPixelBuffer:(CVImageBufferRef)pixelBuffer {
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);

    CIImage *ciImage = [CIImage imageWithCVPixelBuffer:pixelBuffer];
    CIContext *context = [CIContext contextWithOptions:nil];
    CGImageRef cgImage = [context createCGImage:ciImage fromRect:CGRectMake(0, 0, CVPixelBufferGetWidth(pixelBuffer), CVPixelBufferGetHeight(pixelBuffer))];
    
    UIImage *uiImage = [UIImage imageWithCGImage:cgImage];
    
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    return uiImage;
}

+ (UIImage *)affineTransformImage:(UIImage *)image withTransformation:(cv::Mat)transformation {
    cv::Mat srcImage = [image CVMat];
    cv::Mat transformedImage = [self affineTransformCvMat:srcImage withTransformation:transformation];
    return [UIImage imageWithCVMat:transformedImage];
}

+ (cv::Mat)affineTransformCvMat:(cv::Mat)src withTransformation:(cv::Mat)transformation {
    cv::Mat dst;
    //cv::warpPerspective(src, dst, transformation, src.size());
    warpAffine(src, dst, transformation, src.size());
    return dst;
}

+ (cv::Mat)findAffineTransformationSrcPoints:(CGPoint[])srcP dstPoints:(CGPoint[])dstP {
    cv::Point2f srcPoints[4];
    srcPoints[0] = cv::Point2f(srcP[0].x, srcP[0].y);
    srcPoints[1] = cv::Point2f(srcP[1].x, srcP[1].y);
    srcPoints[2] = cv::Point2f(srcP[2].x, srcP[2].y);
    srcPoints[3] = cv::Point2f(srcP[3].x, srcP[3].y);

    cv::Point2f dstPoints[4];
    dstPoints[0] = cv::Point2f(dstP[0].x, dstP[0].y);
    dstPoints[1] = cv::Point2f(dstP[1].x, dstP[1].y);
    dstPoints[2] = cv::Point2f(dstP[2].x, dstP[2].y);
    dstPoints[3] = cv::Point2f(dstP[3].x, dstP[3].y);
    
    //return cv::getPerspectiveTransform(srcPoints, dstPoints);
    return cv::getAffineTransform(srcPoints, dstPoints);
}

@end
