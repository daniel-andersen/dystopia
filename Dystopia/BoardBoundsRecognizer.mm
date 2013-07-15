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

#import "BoardBoundsRecognizer.h"
#import "UIImage+OpenCV.h"

@implementation BoardBoundsRecognizer

- (FourPoints)findBoardBoundsFromImage:(UIImage *)image {
    cv::Mat matImage = [image CVMat];
    cv::Mat originalImage = cv::Mat(matImage);
    cv::Mat filteredAndThresholdedImage = [self filterAndThreshold:matImage];
    return [self findContours:filteredAndThresholdedImage originalImage:originalImage];
}

- (UIImage *)boardBoundsToImage:(UIImage *)image {
    cv::Mat img = [image CVMat];
    img = [self smooth:img];
    img = [self convertToHsv:img];
    img = [self applyThreshold:img];
    return [UIImage imageWithCVMat:img];
}

- (cv::Mat)filterAndThreshold:(cv::Mat)image {
    image = [self smooth:image];
    image = [self convertToHsv:image];
    image = [self applyThreshold:image];
    return image;
}

- (cv::Mat)smooth:(cv::Mat)image {
    cv::GaussianBlur(image, image, cv::Size(21.0f, 21.0f), 1.0f);
    return image;
}

- (cv::Mat)convertToHsv:(cv::Mat)image {
    cv::cvtColor(image, image, CV_BGR2HSV);
    return image;
}

- (cv::Mat)applyThreshold:(cv::Mat)image {
    cv::inRange(image, cv::Scalar(30, 50, 150, 0), cv::Scalar(80, 255, 255, 255), image);
    return image;
}

- (FourPoints)findContours:(cv::Mat)image originalImage:(cv::Mat)origImage {
    cv::vector<cv::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;
    
    cv::findContours(image, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, cv::Point(0, 0));
    
    cv::vector<cv::vector<cv::Point>> polys(contours.size());
    
    for (int i = 0; i < polys.size(); i++) {
        int parent = hierarchy[i][3];
        int firstChild = hierarchy[i][2];
        if (parent == -1 && firstChild != -1) {
            int nextChild = hierarchy[firstChild][2];
            if (nextChild == -1) {
                cv::approxPolyDP(cv::Mat(contours[i]), polys[i], 5, true);
                if (polys[i].size() == 4) {
                    FourPoints boardPoints = {
                        .defined = YES,
                        .p1 = CGPointMake(polys[i][0].x, polys[i][0].y),
                        .p2 = CGPointMake(polys[i][1].x, polys[i][1].y),
                        .p3 = CGPointMake(polys[i][2].x, polys[i][2].y),
                        .p4 = CGPointMake(polys[i][3].x, polys[i][3].y),
                    };
                    return boardPoints;
                }
            }
        }
    }
    FourPoints boardPoints = {.defined = NO};
    return boardPoints;
}

@end
