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

#import "BoardRecognizer.h"
#import "UIImage+OpenCV.h"
#import "BoardUtil.h"
#import "CameraUtil.h"

@interface BoardRecognizer () {
    float threshold;
    float minContourArea;
}

@end

@implementation BoardRecognizer

- (FourPoints)findBoardBoundsFromImage:(UIImage *)image {
    threshold = 80.0f;
    minContourArea = (image.size.width * 0.6) * (image.size.height * 0.6f);

    cv::Mat img = [image CVMat];
    img = [self smooth:img];
    img = [self grayscale:img];
    img = [self applyCanny:img];
    return [self findContours:img];
}

- (UIImage *)boardBoundsToImage:(UIImage *)image {
    cv::Mat img = [image CVMat];
    img = [self smooth:img];
    img = [self grayscale:img];
    img = [self applyCanny:img];
    return [UIImage imageWithCVMat:img];
}

- (cv::Mat)filterAndThreshold:(cv::Mat)image {
    image = [self smooth:image];
    return image;
}

- (cv::Mat)smooth:(cv::Mat)image {
    cv::GaussianBlur(image, image, cv::Size(1.0f, 1.0f), 1.0f);
    return image;
}

- (cv::Mat)grayscale:(cv::Mat)image {
    cv::cvtColor(image, image, CV_RGB2GRAY);
    return image;
}

- (cv::Mat)applyCanny:(cv::Mat)image {
    cv::Canny(image, image, 10, 300);
    //cv::Canny(image, image, threshold, threshold * 3.0f);
    return image;
}

- (FourPoints)findContours:(cv::Mat)image {
    cv::vector<cv::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;

    cv::findContours(image, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    
    cv::vector<cv::Point> approx;
    for (int i = 0; i < contours.size(); i++) {
        cv::approxPolyDP(cv::Mat(contours[i]), approx, 5, true);

        int parentContour = hierarchy[i][3];
        int childContour = hierarchy[i][2];

        bool satisfiesCriterias = YES;
        satisfiesCriterias &= approx.size() == 4;
        satisfiesCriterias &= cv::contourArea(contours[i]) >= minContourArea;
        satisfiesCriterias &= parentContour;
        satisfiesCriterias &= childContour != -1;
        satisfiesCriterias &= cv::contourArea(contours[childContour]) >= minContourArea;

        if (satisfiesCriterias) {
            float maxCosine = 0;
            for (int j = 2; j <= approx.size(); j++) {
                float cosine = fabs(angle(approx[j % approx.size()], approx[j - 2], approx[j - 1]));
                maxCosine = MAX(maxCosine, cosine);
            }
            if (maxCosine < 0.4f) {
                FourPoints boardPoints = {
                    .defined = YES,
                    .p1 = CGPointMake(approx[0].x, approx[0].y),
                    .p2 = CGPointMake(approx[1].x, approx[1].y),
                    .p3 = CGPointMake(approx[2].x, approx[2].y),
                    .p4 = CGPointMake(approx[3].x, approx[3].y),
                };
                return boardPoints;
            }
        }
    }
    FourPoints boardPoints = {.defined = NO};
    return boardPoints;
}

float angle(cv::Point pt1, cv::Point pt2, cv::Point pt0) {
    float dx1 = pt1.x - pt0.x;
    float dy1 = pt1.y - pt0.y;
    float dx2 = pt2.x - pt0.x;
    float dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2) / sqrt((dx1*dx1 + dy1*dy1) * (dx2*dx2 + dy2*dy2) + 1e-10);
}

@end
