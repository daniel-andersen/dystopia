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

@implementation BoardRecognizer

float threshold = 50.0f;

/*- (FourPoints)findBoardBoundsFromImage:(UIImage *)image {
 cv::Mat matImage = [image CVMat];
 cv::Mat originalImage = cv::Mat(matImage);
 cv::Mat filteredAndThresholdedImage = [self filterAndThreshold:matImage];
 return [self findContours:filteredAndThresholdedImage originalImage:originalImage];
 }*/

- (UIImage *)boardEdgesToImage:(UIImage *)image {
    cv::Mat img = [image CVMat];
    cv::Mat origImg = cv::Mat(img);
    img = [self smooth:img];
    img = [self grayscale:img];
    img = [self applyCanny:img];
    img = [self findContours:img originalImage:origImg];
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
    cv::Canny(image, image, threshold, threshold * 3.0f);
    threshold += 5.0f;
    if (threshold > 100.0f) {
        threshold = 50.0f;
    }
    threshold = 50.0f;
    return image;
}

double angle(cv::Point pt1, cv::Point pt2, cv::Point pt0) {
    double dx1 = pt1.x - pt0.x;
    double dy1 = pt1.y - pt0.y;
    double dx2 = pt2.x - pt0.x;
    double dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2)/sqrt((dx1*dx1 + dy1*dy1)*(dx2*dx2 + dy2*dy2) + 1e-10);
}

- (cv::Mat)findContours:(cv::Mat)image originalImage:(cv::Mat)origImage {
    NSMutableArray *polys = [NSMutableArray array];
    cv::vector<cv::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;

    findContours(image, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    
    cv::vector<cv::Point> approx;
    for (int i = 0; i < contours.size(); i++) {
        cv::approxPolyDP(cv::Mat(contours[i]), approx, 5, true);
        if (approx.size() >= 4) {
            double maxCosine = 0;
            for (int j = 2; j <= approx.size(); j++) {
                double cosine = fabs(angle(approx[j % approx.size()], approx[j - 2], approx[j - 1]));
                maxCosine = MAX(maxCosine, cosine);
            }
            if (maxCosine < 0.3) {
                CGPoint contour[approx.size()];
                for (int l = 0; l < approx.size(); l++) {
                    contour[l] = [self cvPointToCGPoint:approx[l]];
                }
                //[polys addObject:contour];
                cv::drawContours(origImage, contours, i, cv::Scalar(255, 0, 0), 1, 8, std::vector<cv::Vec4i>(), 0, cv::Point());
            }
        }
    }
    return origImage;
}

- (CGPoint)cvPointToCGPoint:(cv::Point)p {
    return CGPointMake(p.x, p.y);
}

@end
