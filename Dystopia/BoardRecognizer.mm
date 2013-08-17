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

float intersectionAcceptDistanceMin = 0.02f;
float intersectionAcceptDistanceMax = 1.5f;

typedef struct {
    cv::Point p1;
    cv::Point p2;
    float angle;
} LineWithAngle;

typedef struct {
    cv::vector<LineWithAngle> lines;
    float angle;
} LineGroup;

@interface BoardRecognizer () {
    //float minContourLength;
    float minContourArea;
    cv::vector<cv::vector<cv::Point>> approx;
    cv::vector<bool> hasBeenApproxed;
}

@end

@implementation BoardRecognizer

- (FourPoints)findBoardBoundsFromImage:(UIImage *)image {
    //minContourLength = (image.size.width * 0.6) * 2.0f + (image.size.height * 0.6f) * 2.0f;
    minContourArea = (image.size.width * 0.7) * (image.size.height * 0.5f);

    cv::Mat img = [image CVMat];
    img = [self smooth:img];
    img = [self grayscale:img];
    img = [self applyCanny:img];
    img = [self dilate:img];
    return [self findContours:img];
}

- (UIImage *)boardBoundsToImage:(UIImage *)image {
    cv::Mat img = [image CVMat];

    cv::Mat originalImg = img.clone();

    img = [self smooth:img];
    img = [self grayscale:img];
    img = [self applyCanny:img];
    img = [self dilate:img];

    // !!!!!!!!!!!!!!!!!!!!!!!
    float groupRadius = 30.0f;
    
    minContourArea = (image.size.width * 0.7) * (image.size.height * 0.5f);

    // Find contours in image
    cv::vector<cv::vector<cv::Point>> contours;
    cv::findContours(img, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);

    // Find all lines that satisfy the minimum length property
    cv::vector<LineWithAngle> linesAndAngles = [self findLinesFromContours:contours minimumLineLength:(image.size.width * 0.2f)];
    if (linesAndAngles.size() == 0) {
        return [UIImage imageWithCVMat:originalImg];
    }

    // Group lines into two groups (horizontal and vertical)
    cv::vector<LineGroup> bestTwoLineGroups = [self findBestTwoLineGroups:[self groupLines:linesAndAngles]];

    // Find all intersections that are not too far away from original line
    cv::vector<cv::Point> validIntersections = [self findValidIntersectionsBetweenLines:bestTwoLineGroups[0].lines andLines:bestTwoLineGroups[1].lines imageSize:image.size];
    if (validIntersections.size() == 0) {
        return [UIImage imageWithCVMat:originalImg];
    }

    // Group intersection points
    cv::vector<cv::Point> groupedPoints = [self groupPoints:validIntersections groupRadius:groupRadius];
    
    // Filter groups by number of enclosing points
    groupedPoints = [self filterGroups:groupedPoints allPoints:validIntersections groupRadius:groupRadius threshold:8];

    // Find best square among points
    cv::vector<cv::Point> squareGroupPoints = [self findBestSquareFromPoints:groupedPoints];
    if (squareGroupPoints.size() != 4) {
        return [UIImage imageWithCVMat:originalImg];
    }

    // Find square from all points close to grouped square points
    cv::vector<cv::Point> squarePoints = [self findSquareFromGroupPoints:squareGroupPoints allPoints:validIntersections groupRadius:groupRadius];

    // ----
    [self drawBestTwoLineGroups:bestTwoLineGroups ontoImage:originalImg];
    [self drawPoints:validIntersections image:originalImg];
    //[self drawPoints:groupedPoints image:originalImg];

    cv::vector<cv::vector<cv::Point>> finalPointsContour = cv::vector<cv::vector<cv::Point>> (1);
    finalPointsContour[0] = squarePoints;
    cv::Scalar color = cv::Scalar(255, 0, 255);
    cv::drawContours(originalImg, finalPointsContour, 0, color);

    return [UIImage imageWithCVMat:originalImg];
}

- (cv::vector<cv::Point>)findSquareFromGroupPoints:(cv::vector<cv::Point>)groupPoints allPoints:(cv::vector<cv::Point>)allPoints groupRadius:(float)radius {
    float radiusSquared = radius * radius;

    cv::vector<cv::Point> squarePoints;
    for (int i = 0; i < groupPoints.size(); i++) {
        for (int j = 0; j < allPoints.size(); j++) {
            if (pointSquaredDistance(groupPoints[i], allPoints[j]) < radiusSquared) {
                squarePoints.push_back(allPoints[j]);
            }
        }
    }

    cv::vector<cv::Point> hull;
    cv::convexHull(squarePoints, hull);
    
    return hull;
}

- (cv::vector<cv::Point>)filterGroups:(cv::vector<cv::Point>)groups allPoints:(cv::vector<cv::Point>)points groupRadius:(float)radius threshold:(int)threshold {
    float radiusSquared = radius * radius;
    
    cv::vector<cv::Point> filteredGroups;

    for (int i = 0; i < groups.size(); i++) {
        int count = 0;
        for (int j = 0; j < points.size(); j++) {
            if (pointSquaredDistance(groups[i], points[j]) < radiusSquared) {
                count++;
            }
        }
        if (count >= threshold) {
            filteredGroups.push_back(groups[i]);
        }
    }
    return filteredGroups;
}

- (cv::vector<cv::Point>)groupPoints:(cv::vector<cv::Point>)points groupRadius:(float)radius {
    float radiusSquared = radius * radius;
    
    cv::vector<cv::Point> groupedPoints;

    for (int i = 0; i < points.size(); i++) {
        bool newGroup = true;
        for (int j = 0; j < groupedPoints.size(); j++) {
            if (pointSquaredDistance(points[i], groupedPoints[j]) < radiusSquared) {
                newGroup = false;
            }
        }
        if (newGroup) {
            groupedPoints.push_back(points[i]);
        }
    }
    return groupedPoints;
}

- (cv::vector<LineWithAngle>)findLinesFromContours:(cv::vector<cv::vector<cv::Point>>)contours minimumLineLength:(float)minimumLineLength {
    cv::vector<LineWithAngle> linesAndAngles = cv::vector<LineWithAngle> (0);
    cv::vector<cv::Point> hull;
    
    float minimumLineLengthSqr = minimumLineLength * minimumLineLength;
    
    for (int i = 0; i < contours.size(); i++) {
        cv::approxPolyDP(cv::Mat(contours[i]), hull, cv::arcLength(cv::Mat(contours[i]), true) * 0.002f, true);
        
        for (int j = 0; j < hull.size(); j++) {
            LineWithAngle lineWithAngle = {
                .p1 = hull[(j + 0) % hull.size()],
                .p2 = hull[(j + 1) % hull.size()]
            };
            
            float deltaX = lineWithAngle.p1.x - lineWithAngle.p2.x;
            float deltaY = lineWithAngle.p1.y - lineWithAngle.p2.y;
            
            if ((deltaX * deltaX) + (deltaY * deltaY) < minimumLineLengthSqr) {
                continue;
            }
            
            lineWithAngle.angle = lineAngle(lineWithAngle.p1, lineWithAngle.p2) * 180.0f / M_PI;
            linesAndAngles.push_back(lineWithAngle);
        }
    }
    return linesAndAngles;
}

- (cv::vector<cv::Point>)findBestSquareFromPoints:(cv::vector<cv::Point>)points {
    cv::vector<cv::Point> bestPoints;
    cv::vector<cv::Point> currentPoints = cv::vector<cv::Point> (4);
    cv::vector<cv::Point> hull;
    
    float minDifferenceFactor = 10000000.0f;
    
    for (int i1 = 0; i1 < points.size(); i1++) {
        currentPoints[0] = points[i1];

        for (int i2 = i1 + 1; i2 < points.size(); i2++) {
            currentPoints[1] = points[i2];
        
            for (int i3 = i2 + 1; i3 < points.size(); i3++) {
                currentPoints[2] = points[i3];
            
                for (int i4 = i3 + 1; i4 < points.size(); i4++) {
                    currentPoints[3] = points[i4];
                    cv::convexHull(currentPoints, hull);
                    
                    float differenceFactor = [self maxCosineFromContour:hull];
                    
                    if (differenceFactor < minDifferenceFactor && [self areSimpleConditionsSatisfied:hull]) {
                        bestPoints = hull;
                        minDifferenceFactor = differenceFactor;
                    }
                }
            }
        }
    }
    return bestPoints;
}

- (cv::vector<cv::Point>)findValidIntersectionsBetweenLines:(cv::vector<LineWithAngle>)lines1 andLines:(cv::vector<LineWithAngle>)lines2 imageSize:(CGSize)imageSize {
    cv::vector<cv::Point> validIntersections;
    for (int i = 0; i < lines1.size(); i++) {
        cv::vector<cv::Point> intersectionPoints;
        float minT1 = 1.0f;
        float maxT1 = 0.0f;
        float minT2 = 1.0f;
        float maxT2 = 0.0f;
        for (int j = 0; j < lines2.size(); j++) {
            cv::Point r;
            cv::Point2f t;
            if ([self isAcceptableIntersectionP1:lines1[i] p2:lines2[j] r:r t:t imageSize:imageSize]) {
                intersectionPoints.push_back(r);
                minT1 = MIN(minT1, t.x);
                maxT1 = MAX(maxT1, t.x);
                minT2 = MIN(minT2, t.y);
                maxT2 = MAX(maxT2, t.y);
            }
        }
        if ([self isWithinAcceptableDistanceMin:minT1] && [self isWithinAcceptableDistanceMax:maxT1] &&
            [self isWithinAcceptableDistanceMin:minT2] && [self isWithinAcceptableDistanceMax:maxT2]) {
            for (int j = 0; j < intersectionPoints.size(); j++) {
                validIntersections.push_back(intersectionPoints[j]);
            }
        }
    }
    return validIntersections;
}

- (bool)isAcceptableIntersectionP1:(LineWithAngle)line1 p2:(LineWithAngle)line2 r:(cv::Point &)r t:(cv::Point2f &)t imageSize:(CGSize)imageSize {
    if (intersection(line1.p1, line1.p2, line2.p1, line2.p2, r, t)) {
        if (r.x >= 0 && r.x < imageSize.width && r.y >= 0 && r.y < imageSize.height) {
            return [self isWithinAcceptableDistance:t.x] && [self isWithinAcceptableDistance:t.y];
        }
    }
    return NO;
}

- (bool)isWithinAcceptableDistance:(float)t {
    return [self isWithinAcceptableDistanceMin:t] || [self isWithinAcceptableDistanceMax:t];
}

- (bool)isWithinAcceptableDistanceMin:(float)t {
    return t > -intersectionAcceptDistanceMax && t < intersectionAcceptDistanceMin;
}

- (bool)isWithinAcceptableDistanceMax:(float)t {
    return t > 1.0f - intersectionAcceptDistanceMin && t < 1.0f + intersectionAcceptDistanceMax;
}

- (void)drawPoints:(cv::vector<cv::Point>)points image:(cv::Mat)image {
    for (int i = 0; i < points.size(); i++) {
        cv::Scalar color = cv::Scalar(255, 0, 255);
        cv::circle(image, points[i], 5.0f, color);
    }
}

- (void)drawBestTwoLineGroups:(cv::vector<LineGroup>)bestTwoLineGroups ontoImage:(cv::Mat)image {
    for (int i = 0; i < 2; i++) {
        for (int j = 0; j < bestTwoLineGroups[i].lines.size(); j++) {
            cv::vector<cv::vector<cv::Point>> line = cv::vector<cv::vector<cv::Point>> (1);
            line[0].push_back(bestTwoLineGroups[i].lines[j].p1);
            line[0].push_back(bestTwoLineGroups[i].lines[j].p2);
            
            cv::Scalar color = cv::Scalar(i == 0 ? 255 : 0, i == 1 ? 255 : 0, 0);
            cv::drawContours(image, line, 0, color);
        }
    }
}

- (cv::vector<LineGroup>)findBestTwoLineGroups:(cv::vector<LineGroup>)lineGroups {
    const float perpendicularAngleEpsilon = 20.0f;
    
    cv::vector<LineGroup> groups;

    int bestGroupSize = 0;
    int bestGroupIndex = 0;
    for (int i = 0; i < lineGroups.size(); i++) {
        if (lineGroups[i].lines.size() > bestGroupSize) {
            bestGroupSize = lineGroups[i].lines.size();
            bestGroupIndex = i;
        }
    }
    groups.push_back(lineGroups[bestGroupIndex]);
    
    float bestAngle = lineGroups[bestGroupIndex].angle;
    int secondBestGroupSize = 0;
    int secondBestGroupIndex = 0;
    for (int i = 0; i < lineGroups.size(); i++) {
        int deltaPerpendicularAngle = angleDelta180(bestAngle + 90.0f, lineGroups[i].angle);
        if (deltaPerpendicularAngle < perpendicularAngleEpsilon && lineGroups[i].lines.size() > secondBestGroupSize) {
            secondBestGroupSize = lineGroups[i].lines.size();
            secondBestGroupIndex = i;
        }
    }
    groups.push_back(lineGroups[secondBestGroupIndex]);
    
    return groups;
}

- (cv::vector<LineGroup>)groupLines:(cv::vector<LineWithAngle>)linesWithAngles {
    int bucketSize = 4;
    int groupAngleSize = 10;
    cv::vector<cv::vector<LineWithAngle>> buckets = cv::vector<cv::vector<LineWithAngle>> (180 / bucketSize);
    for (int i = 0; i < linesWithAngles.size(); i++) {
        int intAngle = (((int)linesWithAngles[i].angle) % 180) / bucketSize;
        buckets[intAngle].push_back(linesWithAngles[i]);
    }

    cv::vector<LineGroup> groups;
    for (int i = 0; i < buckets.size(); i++) {
        if (buckets[i].size() > 0) {
            LineGroup group = {.angle = buckets[i][0].angle};
            for (int j = -(groupAngleSize / 2); j <= groupAngleSize / 2; j++) {
                int idx = (i + j + buckets.size()) % buckets.size();
                for (int k = 0; k < buckets[idx].size(); k++) {
                    group.lines.push_back(buckets[idx][k]);
                }
            }
            groups.push_back(group);
        }
    }
    return groups;
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

    [self resetApproximationsWithContours:contours];
    
    FourPoints boardPoints = [self simpleBoardBoundsFromContours:contours hierarchy:hierarchy];
    if (!boardPoints.defined) {
        //boardPoints = [self simpleObstacledBoardBoundsFromContours:contours hierarchy:hierarchy];
    }
    return boardPoints;
}

- (FourPoints)simpleBoardBoundsFromContours:(cv::vector<cv::vector<cv::Point>>)contours hierarchy:(cv::vector<cv::Vec4i>)hierarchy {
    for (int i = 0; i < contours.size(); i++) {

        // Parent must have 1 child because of dilation; that is, the top border (fx.) transforms from -------- to ========
        int childIndex = hierarchy[i][2];
        if (childIndex == -1) {
            continue;
        }

        [self polygonApproxContour:contours[i] index:i];
        [self polygonApproxContour:contours[childIndex] index:childIndex];

        if ([self areSimpleConditionsSatisfied:approx[i]] && [self areSimpleConditionsSatisfied:approx[childIndex]]) {
            return [self dilatedContoursToBoardPoints:approx[i] withContour:approx[childIndex]];
        }
    }
    FourPoints undefinedPoints = {.defined = NO};
    return undefinedPoints;
}

- (void)polygonApproxContour:(cv::vector<cv::Point>)contour index:(int)index {
    if (hasBeenApproxed[index]) {
        return;
    }
    cv::approxPolyDP(cv::Mat(contour), approx[index], cv::arcLength(cv::Mat(contour), true) * 0.01f, true);
    hasBeenApproxed[index] = true;
}

- (void)resetApproximationsWithContours:(cv::vector<cv::vector<cv::Point>>)contours {
    approx = cv::vector<cv::vector<cv::Point>> (contours.size());
    hasBeenApproxed = cv::vector<bool> (contours.size());
    for (int i = 0; i < contours.size(); i++) {
        hasBeenApproxed[i] = NO;
    }
}

- (FourPoints)simpleObstacledBoardBoundsFromContours:(cv::vector<cv::vector<cv::Point>>)contours hierarchy:(cv::vector<cv::Vec4i>)hierarchy {
    for (int i = 0; i < approx.size(); i++) {
        [self polygonApproxContour:contours[i] index:i];

        if (approx[i].size() < 4) {
            continue;
        }
        if (fabs(cv::contourArea(approx[i])) <= minContourArea) {
            continue;
        }
    
        cv::vector<int> minIndexes = [self fourCornerIndexesFromContour:approx[i]];
    
        cv::vector<cv::Point> squareContour = cv::vector<cv::Point> (4);
        for (int j = 0; j < 4; j++) {
            squareContour[j] = approx[i][minIndexes[j]];
        }
        if (![self areSimpleConditionsSatisfied:squareContour]) {
            continue;
        }
        return [self contourToBoardPoints:squareContour];
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

- (int)maxCosineIndexFromContour:(cv::vector<cv::Point>)contour {
    float maxCosine = 0.0f;
    int maxCosineIndex = 0;
    for (int j = 2; j < contour.size() + 2; j++) {
        float cosine = fabs(angle(contour[j % contour.size()], contour[(j - 2) % contour.size()], contour[(j - 1) % contour.size()]));
        if (cosine > maxCosine) {
            maxCosine = cosine;
            maxCosineIndex = j;
        }
    }
    return maxCosineIndex;
}

- (cv::vector<int>)fourCornerIndexesFromContour:(cv::vector<cv::Point>)contour {
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

float angle(cv::Point pt1, cv::Point pt2, cv::Point pt0) {
    float dx1 = pt1.x - pt0.x;
    float dy1 = pt1.y - pt0.y;
    float dx2 = pt2.x - pt0.x;
    float dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2) / sqrt((dx1*dx1 + dy1*dy1) * (dx2*dx2 + dy2*dy2) + 1e-10);
}

float lineAngle(cv::Point p1, cv::Point p2) {
    return atan2f(p1.y - p2.y, p1.x - p2.x) + M_PI;
}

int angleDelta(int angle1, int angle2) {
    int delta = ABS(angle1 - angle2) % 360;
    return delta > 180 ? 360 - delta : delta;
}

int angleDelta180(int angle1, int angle2) {
    int delta = ABS(angle1 - angle2) % 180;
    return delta > 90 ? 180 - delta : delta;
}

float pointSquaredDistance(cv::Point p1, cv::Point p2) {
    int deltaX = p1.x - p2.x;
    int deltaY = p1.y - p2.y;
    return (deltaX * deltaX) + (deltaY * deltaY);
}

bool intersection(cv::Point o1, cv::Point p1, cv::Point o2, cv::Point p2, cv::Point &r, cv::Point2f &t) {
    cv::Point x = o2 - o1;
    cv::Point d1 = p1 - o1;
    cv::Point d2 = p2 - o2;
    
    float cross = d1.x*d2.y - d1.y*d2.x;
    if (ABS(cross) < /*EPS*/1e-8) {
        return false;
    }
    
    float t1 = (x.x * d2.y - x.y * d2.x) / cross;
    float t2 = (x.x * d1.y - x.y * d1.x) / cross;
    
    r = o1 + d1 * t1;
    t = cv::Point2f(t1, t2);
    
    return true;
}

@end
