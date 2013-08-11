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
    float minContourArea;
}

@end

@implementation BoardRecognizer

- (FourPoints)findBoardBoundsFromImage:(UIImage *)image {
    minContourArea = (image.size.width * 0.6) * (image.size.height * 0.6f);

    cv::Mat img = [image CVMat];
    img = [self smooth:img];
    img = [self grayscale:img];
    img = [self applyCanny:img];
    img = [self erode:img];
    return [self findContours:img];
}

- (UIImage *)boardBoundsToImage:(UIImage *)image {
    cv::Mat img = [image CVMat];

    img = [self smooth:img];
    img = [self grayscale:img];
    img = [self applyCanny:img];
    img = [self erode:img];

    // !!!!!!!!!!!!!!!!!!!!!!!
    cv::Mat originalImg = img.clone();
    cv::cvtColor(originalImg, originalImg, CV_GRAY2RGB);

    minContourArea = (image.size.width * 0.6) * (image.size.height * 0.6f);
    cv::vector<cv::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;
    
    cv::findContours(img, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);

    cv::vector<cv::vector<cv::Point>> hulls (contours.size());

    for (int i = 0; i < contours.size(); i++) {
        if (fabs(cv::contourArea(contours[i])) <= 10000.0f) {
            continue;
        }
        cv::convexHull(cv::Mat(contours[i]), hulls[i]);
        cv::approxPolyDP(hulls[i], hulls[i], cv::arcLength(cv::Mat(hulls[i]), true) * 0.005f, true);

        /*if (hulls[i].size() > 5) {
            continue;
        }*/
        cv::Scalar color = cv::Scalar(0, 255, 0);
        cv::drawContours(originalImg, hulls, i, color);

        NSLog(@"------------------------");
        NSLog(@"%i", (int)hulls[i].size());
        for (int j = 2; j < hulls[i].size() + 2; j++) {
            float cosine = fabs(angle(hulls[i][j % hulls[i].size()], hulls[i][(j - 2) % hulls[i].size()], hulls[i][(j - 1) % hulls[i].size()]));
            NSLog(@"Cosine: %f", cosine);
        }
    
        /*cv::vector<cv::vector<cv::Point>> approx (1);
        approx[0] = cv::vector<cv::Point> (4);
        int k = 0;
        for (int j = 0; j < hulls[i].size(); j++) {
            if (j == minCosineIdx[0] || j == minCosineIdx[1] || j == (minCosineIdx[0] - 1 + hulls[i].size()) % hulls[i].size() || j == (minCosineIdx[1] - 1 + hulls[i].size()) % hulls[i].size() || j == minCosineIdx[1] || j == (minCosineIdx[0] + 1 + hulls[i].size()) % hulls[i].size() || j == (minCosineIdx[1] + 1 + hulls[i].size()) % hulls[i].size()) {
                approx[0][k++] = hulls[i][j];
                NSLog(@"-- %i", j);
                if (k >= 4) {
                    break;
                }
            }
        }
        cv::Scalar color2 = cv::Scalar(0, 0, 255);
        cv::drawContours(originalImg, approx, 0, color2);*/
    }
    // !!!!!!!!!!!!!!!!!!!!!!!
    return [UIImage imageWithCVMat:originalImg];
}

- (cv::Mat)filterAndThreshold:(cv::Mat)image {
    image = [self smooth:image];
    return image;
}

- (cv::Mat)smooth:(cv::Mat)image {
    cv::GaussianBlur(image, image, cv::Size(3.0f, 3.0f), 1.0f);
    return image;
}

- (cv::Mat)grayscale:(cv::Mat)image {
    cv::cvtColor(image, image, CV_RGB2GRAY);
    return image;
}

- (cv::Mat)applyCanny:(cv::Mat)image {
    cv::Canny(image, image, 100, 300);
    return image;
}

- (cv::Mat)erode:(cv::Mat)image {
    cv::Mat element = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(3.0f, 3.0f));
    cv::dilate(image, image, element);
    return image;
}

- (FourPoints)findContours:(cv::Mat)image {
    cv::vector<cv::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;

    cv::findContours(image, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    
    FourPoints boardPoints = [self findSimpleBoardBoundsFromContours:contours hierachy:hierarchy];
    if (boardPoints.defined) {
        return boardPoints;
    } else {
        boardPoints = [self findBrokenBoardBoundsFromContours:contours hierachy:hierarchy];
    }
    return boardPoints;
}

- (FourPoints)findSimpleBoardBoundsFromContours:(cv::vector<cv::vector<cv::Point>>)contours hierachy:(cv::vector<cv::Vec4i>)hierarchy {
    cv::vector<cv::Point> approx;
    cv::vector<cv::vector<cv::Point>> hulls (contours.size());

    FourPoints bestMatchedPoints = {.defined = NO};
    int bestMatchedConditionsSatisfied = 0;

    for (int i = 0; i < contours.size(); i++) {
        cv::convexHull(cv::Mat(contours[i]), hulls[i]);
        cv::approxPolyDP(hulls[i], approx, cv::arcLength(cv::Mat(hulls[i]), true) * 0.005f, true);

        for (int conditionsCount = 5; conditionsCount >= 2; conditionsCount--) {
            if ([self areSimpleBoardBoundsConditionsSatisfiedWithContours:contours hierachy:hierarchy approx:approx conditionsCount:conditionsCount contourIndex:i]) {
                float maxCosine = 0;
                for (int j = 2; j < approx.size() + 2; j++) {
                    float cosine = fabs(angle(approx[j % approx.size()], approx[(j - 2) % approx.size()], approx[(j - 1) % approx.size()]));
                    maxCosine = MAX(maxCosine, cosine);
                }
                int conditionsMatched = maxCosine < 0.4f ? (conditionsCount + 1) : conditionsCount;
                if (conditionsMatched > bestMatchedConditionsSatisfied) {
                    bestMatchedConditionsSatisfied = conditionsMatched;
                    bestMatchedPoints = {
                        .defined = YES,
                        .p1 = CGPointMake(approx[0].x, approx[0].y),
                        .p2 = CGPointMake(approx[1].x, approx[1].y),
                        .p3 = CGPointMake(approx[2].x, approx[2].y),
                        .p4 = CGPointMake(approx[3].x, approx[3].y),
                    };
                }
            }
        }
    }
    return bestMatchedPoints;
}

- (bool)areSimpleBoardBoundsConditionsSatisfiedWithContours:(cv::vector<cv::vector<cv::Point>>)contours hierachy:(cv::vector<cv::Vec4i>)hierarchy approx:(cv::vector<cv::Point>)approx conditionsCount:(int)conditionsCount contourIndex:(int)i {
    int parentContour = hierarchy[i][3];
    int childContour = hierarchy[i][2];
    
    return ((conditionsCount < 1 || fabs(cv::contourArea(contours[i])) >= minContourArea) &&
            (conditionsCount < 2 || approx.size() == 4) &&
            (conditionsCount < 3 || parentContour == -1) &&
            (conditionsCount < 4 || childContour != -1) &&
            (conditionsCount < 5 || cv::contourArea(contours[childContour]) >= minContourArea));
}

- (FourPoints)findBrokenBoardBoundsFromContours:(cv::vector<cv::vector<cv::Point>>)contours hierachy:(cv::vector<cv::Vec4i>)hierarchy {
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
