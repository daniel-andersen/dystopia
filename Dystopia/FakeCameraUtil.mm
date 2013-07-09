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

@implementation FakeCameraUtil

+ (UIImage *)fakePerspectiveOnImage:(UIImage *)image {
    CGPoint srcPoints[4] = {CGPointMake(0.0f, 0.0f), CGPointMake(image.size.width, 0.0f), CGPointMake(image.size.width, image.size.height), CGPointMake(0.0f, image.size.height)};
    CGPoint dstPoints[4] = {CGPointMake(50.0f, 50.0f), CGPointMake(image.size.width - 100.0f, 75.0f), CGPointMake(image.size.width - 125.0f, image.size.height - 100.0f), CGPointMake(75.0f, image.size.height - 125.0f)};
    cv::Mat transformation = [CameraUtil findAffineTransformationSrcPoints:srcPoints dstPoints:dstPoints];
    return [CameraUtil affineTransformImage:image withTransformation:transformation];
}

@end
