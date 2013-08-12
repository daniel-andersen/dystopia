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
    //float minContourLength;
    float minContourArea;
}

@end

@implementation BoardRecognizer

- (FourPoints)findBoardBoundsFromImage:(UIImage *)image {
    //minContourLength = (image.size.width * 0.6) * 2.0f + (image.size.height * 0.6f) * 2.0f;
    minContourArea = (image.size.width * 0.5) * (image.size.height * 0.5f);

    cv::Mat img = [image CVMat];
    img = [self smooth:img];
    img = [self grayscale:img];
    img = [self applyCanny:img];
    img = [self dilate:img];
    return [self findContours:img];
}

- (UIImage *)boardBoundsToImage:(UIImage *)image {
    cv::Mat img = [image CVMat];

    img = [self smooth:img];
    img = [self grayscale:img];
    img = [self applyCanny:img];
    img = [self dilate:img];

    // !!!!!!!!!!!!!!!!!!!!!!!
    cv::Mat originalImg = img.clone();
    cv::cvtColor(originalImg, originalImg, CV_GRAY2RGB);

    minContourArea = (image.size.width * 0.7) * (image.size.height * 0.5f);
    cv::vector<cv::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;
    
    cv::findContours(img, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);

    cv::vector<cv::vector<cv::Point>> hulls (contours.size());

    for (int i = 0; i < contours.size(); i++) {
        /*if (cv::arcLength(cv::Mat(contours[i]), true) < minArcLength) {
            continue;
        }*/
        cv::convexHull(cv::Mat(contours[i]), hulls[i]);
        cv::approxPolyDP(hulls[i], hulls[i], cv::arcLength(cv::Mat(hulls[i]), true) * 0.01f, true);

        if (hulls[i].size() < 4 || hulls[i].size() > 8) {
            continue;
        }
        if (fabs(cv::contourArea(hulls[i])) <= 10000.0f) {
            continue;
        }

        cv::vector<int> minIndexes = [self findFourIndexesFromContour:hulls[i]];

        cv::vector<cv::vector<cv::Point>> squareContour (1);
        squareContour[0] = cv::vector<cv::Point> (4);
        for (int j = 0; j < 4; j++) {
            squareContour[0][j] = hulls[i][minIndexes[j]];
        }
        
        cv::Scalar color2 = cv::Scalar(0, 255, 0);
        cv::drawContours(originalImg, squareContour, 0, color2);
        
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

- (cv::Mat)dilate:(cv::Mat)image {
    cv::Mat element = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(3.0f, 3.0f));
    cv::dilate(image, image, element);
    return image;
}

- (FourPoints)findContours:(cv::Mat)image {
    cv::vector<cv::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;

    cv::findContours(image, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
    
    FourPoints boardPoints = [self simpleBoardBoundsFromContours:contours hierarchy:hierarchy];
    if (!boardPoints.defined) {
    }
    return boardPoints;
}

- (FourPoints)simpleBoardBoundsFromContours:(cv::vector<cv::vector<cv::Point>>)contours hierarchy:(cv::vector<cv::Vec4i>)hierarchy {
    for (int i = 0; i < contours.size(); i++) {
        //                                                                                                --------    ========
        // Parent must have 3 children because of dilation; that is, the top border (fx.) transforms from -------- to ========
        int borderIndices[4];
        borderIndices[0] = i;
        borderIndices[1] = borderIndices[0] != -1 ? hierarchy[borderIndices[0]][2] : -1;
        borderIndices[2] = borderIndices[1] != -1 ? hierarchy[borderIndices[1]][2] : -1;
        borderIndices[3] = borderIndices[2] != -1 ? hierarchy[borderIndices[2]][2] : -1;
        if (borderIndices[1] == -1 || borderIndices[2] == -1 || borderIndices[3] == -1) {
            continue;
        }
        
        // Conditions to be satisfied
        cv::vector<cv::vector<cv::Point>> approx (4);
        for (int j = 0; j < 4; j++) {
            cv::convexHull(cv::Mat(contours[borderIndices[j]]), approx[j]);
            cv::approxPolyDP(approx[j], approx[j], cv::arcLength(cv::Mat(approx[j]), true) * 0.01f, true);
            if (![self areSimpleConditionsSatisfied:approx[j]]) {
                goto nextContour;
            }
        }
        return [self dilatedContoursToBoardPoints:approx[2] withContour:approx[3]];
        
    nextContour:
        continue;
    }
    FourPoints undefinedPoints = {.defined = NO};
    return undefinedPoints;
}

- (FourPoints)dilatedContoursToBoardPoints:(cv::vector<cv::Point>)contour1 withContour:(cv::vector<cv::Point>)contour2 {
    contour1 = [self sortPointsInContour:contour1];
    contour2 = [self sortPointsInContour:contour2];
    FourPoints points = {
        .defined = YES,
        .p1 = CGPointMake((contour1[0].x + contour2[0].x) / 2.0f, (contour1[0].y + contour2[0].y) / 2.0f),
        .p2 = CGPointMake((contour1[1].x + contour2[1].x) / 2.0f, (contour1[1].y + contour2[1].y) / 2.0f),
        .p3 = CGPointMake((contour1[2].x + contour2[2].x) / 2.0f, (contour1[2].y + contour2[2].y) / 2.0f),
        .p4 = CGPointMake((contour1[3].x + contour2[3].x) / 2.0f, (contour1[3].y + contour2[3].y) / 2.0f)
    };
    return points;
}

- (cv::vector<cv::Point>)sortPointsInContour:(cv::vector<cv::Point>)contour {
    int topLeftIndex = -1;
    float topLeftSum = 0.0f;
    for (int i = 0; i < contour.size(); i++) {
        float sum = (contour[i].x * contour[i].x) + (contour[i].y * contour[i].y);
        if (topLeftIndex == -1 || sum < topLeftSum) {
            topLeftIndex = i;
            topLeftSum = sum;
        }
    }
    int neighbourIdx1 = (topLeftIndex + contour.size() - 1) % contour.size();
    int neighbourIdx2 = (topLeftIndex + contour.size() + 1) % contour.size();
    int dir = ABS(contour[topLeftIndex].x - contour[neighbourIdx1].x) > ABS(contour[topLeftIndex].x - contour[neighbourIdx2].x) ? -1 : 1;
    
    cv::vector<cv::Point> outPoints = cv::vector<cv::Point> (contour.size());
    for (int i = 0; i < contour.size(); i++) {
        outPoints[i] = contour[topLeftIndex];
        topLeftIndex = (topLeftIndex + contour.size() + dir) % contour.size();
    }
    return outPoints;
}

- (bool)areSimpleConditionsSatisfied:(cv::vector<cv::Point>)contour {
    return (//fabs(cv::arcLength(contour, true)) >= minContourLength &&
            fabs(cv::contourArea(contour)) >= minContourArea &&
            contour.size() == 4 &&
            [self maxCosineFromContour:contour] <= 0.3f);
}

- (float)maxCosineFromContour:(cv::vector<cv::Point>)contour {
    float maxCosine = 0.0f;
    for (int j = 2; j < contour.size() + 2; j++) {
        float cosine = fabs(angle(contour[j % contour.size()], contour[(j - 2) % contour.size()], contour[(j - 1) % contour.size()]));
        if (cosine > maxCosine) {
            maxCosine = cosine;
        }
    }
    return maxCosine;
}

- (cv::vector<int>)findFourIndexesFromContour:(cv::vector<cv::Point>)contour {
    cv::vector<int> indexes = cv::vector<int> (4);
    for (int i = 0; i < indexes.size(); i++) {
        indexes[i] = i;
    }

    cv::vector<int> minIndexes = cv::vector<int> (4);
    float minAngleSum = 1000.0f;

    while (true) {
        float angleSum = [self sumOfAnglesFromContour:contour withIndexes:indexes];
        if (angleSum < minAngleSum) {
            minAngleSum = angleSum;
            minIndexes = indexes;
        }
        if (indexes[0] == contour.size() - 4 && indexes[1] == contour.size() - 3 && indexes[2] == contour.size() - 2 && indexes[3] == contour.size() - 1) {
            break;
        }
        indexes = [self nextIndexes:indexes maxIndex:(contour.size() - 1)];
    }
    return minIndexes;
}

- (cv::vector<int>)nextIndexes:(cv::vector<int>)indexes maxIndex:(int)maxIndex {
    for (int i = 0; i < indexes.size(); i++) {
        int idx = indexes.size() - i - 1;
        if (indexes[idx] < maxIndex - i) {
            indexes[idx]++;
            for (int j = idx + 1; j < indexes.size(); j++) {
                indexes[j] = indexes[idx] + (j - idx);
            }
            return indexes;
        }
    }
    return indexes;
}

- (float)sumOfAnglesFromContour:(cv::vector<cv::Point>)contour withIndexes:(cv::vector<int>)indexes {
    float angleSum = 0.0f;
    for (int i = 2; i < indexes.size() + 2; i++) {
        angleSum += fabs(angle(contour[indexes[i % indexes.size()]], contour[indexes[(i - 2) % indexes.size()]], contour[indexes[(i - 1) % indexes.size()]]));
    }
    return angleSum;
}

- (FourPoints)contourToBoardPoints:(cv::vector<cv::Point>)contour {
    FourPoints boardPoints = {
        .defined = YES,
        .p1 = CGPointMake(contour[0].x, contour[0].y),
        .p2 = CGPointMake(contour[1].x, contour[1].y),
        .p3 = CGPointMake(contour[2].x, contour[2].y),
        .p4 = CGPointMake(contour[3].x, contour[3].y),
    };
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
