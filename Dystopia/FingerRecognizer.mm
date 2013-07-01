// Copyright (c) 2012, Daniel Andersen (daniel@trollsahead.dk)
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

#import "FingerRecognizer.h"
#import "UIImage+OpenCV.h"

@implementation FingerRecognizer

- (NSArray *)findFingersInImage:(UIImage *)image {
    cv::Mat matImage = [image CVMat];
    cv::Mat smoothedImage = cvCreateImage(cv::Size(image.size.width, image.size.height), 8, 3);

    cv::GaussianBlur(matImage, smoothedImage, cv::Size(5,5), 1.5f);

    return NULL;
}

- (UIImage *)filterAndThresholdUIImage:(UIImage *)image {
    return [UIImage imageWithCVMat:[self filterAndThreshold:[image CVMat]]];
}

- (cv::Mat)filterAndThreshold:(cv::Mat)image {
    //image = [self smooth:image];
    image = [self convertToHsv:image];
    //image = [self applyThreshold:image];
    return image;
}

- (cv::Mat)smooth:(cv::Mat)image {
    cv::GaussianBlur(image, image, cv::Size(11.0f, 11.0f), 1.0f);
    cv::medianBlur(image, image, 11.0f);
    return image;
}

- (cv::Mat)convertToHsv:(cv::Mat)image {
    cv::cvtColor(image, image, CV_BGR2HSV);
    return image;
}

- (cv::Mat)applyThreshold:(cv::Mat)image {
    cv::inRange(image, cv::Scalar(110, 0, 0, 0), cv::Scalar(125, 255, 255, 255), image);
    return image;
}

@end
