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
#import "ExternalDisplay.h"

#define LINE_DIRECTION_HORIZONTAL_UP   0
#define LINE_DIRECTION_HORIZONTAL_DOWN 1
#define LINE_DIRECTION_VERTICAL_LEFT   2
#define LINE_DIRECTION_VERTICAL_RIGHT  3

float intersectionAcceptDistanceMin = 0.02f;
float intersectionAcceptDistanceMax = 5.0f;
float squareAngleAcceptMax = 5.0f;
float lineGroupAngleAcceptMax = 15.0f;
float aspectRatioAcceptMax = 0.1f;

typedef struct {
    cv::Point p1;
    cv::Point p2;
    float angle;
} LineWithAngle;

typedef struct {
    cv::vector<LineWithAngle> lines;
    LineWithAngle minLine;
    LineWithAngle maxLine;
    LineWithAngle average;
    float lineDistance;
    float angle;
    int direction;
} LineGroup;

@interface BoardRecognizer () {
    float minContourArea;
    float minLineLength;

    CGSize imageSize;
    CGSize borderSize;
    CGSize borderSizePercent;
    
    float boardAspectRatio;
    
    cv::vector<cv::vector<cv::Point>> approx;
    cv::vector<bool> hasBeenApproxed;
}

@end

BoardRecognizer *boardRecognizerInstance = nil;

@implementation BoardRecognizer

+ (BoardRecognizer *)instance {
    @synchronized(self) {
        if (boardRecognizerInstance == nil) {
            boardRecognizerInstance = [[BoardRecognizer alloc] init];
        }
        return boardRecognizerInstance;
    }
}

- (FourPoints)findBoardBoundsFromImage:(UIImage *)image {
    [self prepareConstantsFromImage:image];

    float thresholdMin[3] = {100.0f,  50.0f, 20.0f};
    float thresholdMax[3] = {300.0f, 150.0f, 30.0f};
    
    // Prepare image
    cv::Mat preparedImage = [image CVMat];
    preparedImage = [self smooth:preparedImage];
    preparedImage = [self grayscale:preparedImage];
    
    // Try different thresholding values for Canny - roughest first
    for (int i = 0; i < 3; i++) {
        cv::Mat img = preparedImage.clone();
        img = [self applyCannyOnImage:img threshold1:thresholdMin[i] threshold2:thresholdMax[i]];
        img = [self dilate:img];
    
        // Find corners
        FourPoints corners = [self findBoardCorners:img];
        if (corners.defined) {
            return corners;
        }
    }
    FourPoints undefinedPoints = {.defined = NO};
    return undefinedPoints;
}

- (UIImage *)perspectiveCorrectImage:(UIImage *)image fromBoardBounds:(FourPoints)boardBounds {
    cv::Mat transformation = [self findTransformationFromBoardBounds:boardBounds];
    return [CameraUtil perspectiveTransformImage:image withTransformation:transformation toSize:[self approxBoardSizeFromBounds:boardBounds]];
}

- (cv::Mat)findTransformationFromBoardBounds:(FourPoints)boardBounds {
    CGSize approxBoardSize = [self approxBoardSizeFromBounds:boardBounds];
    CGSize approxBorderSize = [[BoardUtil instance] borderSizeFromBoardSize:approxBoardSize];
    FourPoints dstPoints = {
        .p1 = CGPointMake(                        (approxBorderSize.width / 2.0f),                          (approxBorderSize.height / 2.0f)),
        .p2 = CGPointMake(approxBoardSize.width - (approxBorderSize.width / 2.0f),                          (approxBorderSize.height / 2.0f)),
        .p3 = CGPointMake(approxBoardSize.width - (approxBorderSize.width / 2.0f), approxBoardSize.height - (approxBorderSize.height / 2.0f)),
        .p4 = CGPointMake(                        (approxBorderSize.width / 2.0f), approxBoardSize.height - (approxBorderSize.height / 2.0f))};
    return [CameraUtil findPerspectiveTransformationSrcPoints:boardBounds dstPoints:dstPoints];
}

- (CGSize)approxBoardSizeFromBounds:(FourPoints)boardBounds {
    cv::vector<cv::Point> bounds;
    bounds.push_back(cv::Point(boardBounds.p1.x, boardBounds.p1.y));
    bounds.push_back(cv::Point(boardBounds.p2.x, boardBounds.p2.y));
    bounds.push_back(cv::Point(boardBounds.p3.x, boardBounds.p3.y));
    bounds.push_back(cv::Point(boardBounds.p4.x, boardBounds.p4.y));
    cv::Rect rect = cv::boundingRect(bounds);
    return CGSizeMake(rect.width, rect.height);
}

- (NSArray *)boardBoundsToImages:(UIImage *)image {
    NSMutableArray *images = [NSMutableArray array];
    
    [self prepareConstantsFromImage:image];

    cv::Mat img = [image CVMat];
    {
        [images addObject:[UIImage imageWithCVMat:img]];
    }

    img = [self smooth:img];
    {
        [images addObject:[UIImage imageWithCVMat:img]];
    }

    img = [self grayscale:img];
    {
        cv::Mat outputImg;
        cv::cvtColor(img, outputImg, CV_GRAY2RGB);
        [images addObject:[UIImage imageWithCVMat:outputImg]];
    }

    img = [self applyCannyOnImage:img threshold1:100.0f threshold2:300.0f];
    {
        cv::Mat outputImg;
        cv::cvtColor(img, outputImg, CV_GRAY2RGB);
        [images addObject:[UIImage imageWithCVMat:outputImg]];
    }

    img = [self dilate:img];
    {
        cv::Mat outputImg;
        cv::cvtColor(img, outputImg, CV_GRAY2RGB);
        [images addObject:[UIImage imageWithCVMat:outputImg]];
    }
    
    cv::vector<cv::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;
    cv::findContours(img, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);

    cv::vector<LineWithAngle> linesAndAngles = [self findLinesFromContours:contours minimumLineLength:MIN(image.size.width, image.size.height) * 0.02f];
    {
        cv::Mat outputImg;
        cv::Scalar color = cv::Scalar(255, 0, 255);
        cv::cvtColor(img, outputImg, CV_GRAY2RGB);
        [self drawLines:linesAndAngles ontoImage:outputImg color:color];
        [images addObject:[UIImage imageWithCVMat:outputImg]];
    }

    cv::vector<cv::vector<LineGroup>> lineGroups = [self divideLinesIntoGroups:linesAndAngles];
    {
        cv::Mat outputImg;
        cv::cvtColor(img, outputImg, CV_GRAY2RGB);
        for (int i = 0; i < lineGroups.size(); i++) {
            for (int j = 0; j < lineGroups[i].size(); j++) {
                cv::Scalar color = cv::Scalar(((i + 0) * 50) % 255, ((i + 100) * 150) % 255, ((i + 0) * 20) % 255);
                [self drawLineGroup:lineGroups[i][j] ontoImage:outputImg withColor:color];
            }
        }
        [images addObject:[UIImage imageWithCVMat:outputImg]];
    }

    cv::vector<cv::vector<LineGroup>> borderLines = [self removeNonBorderLineGroups:lineGroups];
    {
        cv::Mat outputImg;
        cv::cvtColor(img, outputImg, CV_GRAY2RGB);
        for (int i = 0; i < borderLines.size(); i++) {
            for (int j = 0; j < borderLines[i].size(); j++) {
                cv::Scalar color = cv::Scalar(((i + 0) * 50) % 255, ((i + 100) * 150) % 255, ((i + 0) * 20) % 255);
                [self drawLineGroup:borderLines[i][j] ontoImage:outputImg withColor:color];
            }
        }
        [images addObject:[UIImage imageWithCVMat:outputImg]];
    }

    [self findRepresentingLinesInLineGroups:borderLines];
    {
        cv::Mat outputImg;
        cv::cvtColor(img, outputImg, CV_GRAY2RGB);
        for (int i = 0; i < borderLines.size(); i++) {
            for (int j = 0; j < borderLines[i].size(); j++) {
                cv::vector<LineWithAngle> lines;
                lines.push_back(borderLines[i][j].average);
                cv::Scalar color = cv::Scalar(((i + 0) * 50) % 255, ((i + 100) * 150) % 255, ((i + 0) * 20) % 255);
                [self drawLines:lines ontoImage:outputImg color:color];
            }
        }
        [images addObject:[UIImage imageWithCVMat:outputImg]];
    }

    cv::vector<cv::Point> intersectionPoints = [self findIntersectionsFromLineGroups:borderLines];
    {
        cv::Mat outputImg;
        cv::cvtColor(img, outputImg, CV_GRAY2RGB);
        cv::Scalar color = cv::Scalar(255, 0, 255);
        [self drawPoints:intersectionPoints image:outputImg color:color];
        [images addObject:[UIImage imageWithCVMat:outputImg]];
    }

    cv::vector<cv::Point> bestSquare = [self findBestSquareFromPoints:intersectionPoints scoreFunction:^float(cv::vector<cv::Point> hull) {
        return cv::contourArea(hull);
    }];
    if (bestSquare.size() < 4) {
        return images;
    }

    {
        cv::Mat outputImg;
        cv::cvtColor(img, outputImg, CV_GRAY2RGB);
        cv::Scalar color = cv::Scalar(255, 0, 255);
        [self drawPoints:bestSquare image:outputImg color:color];
        [images addObject:[UIImage imageWithCVMat:outputImg]];
        return images;
    }
}

- (void)prepareConstantsFromImage:(UIImage *)image {
    imageSize = image.size;
    
    minContourArea = (imageSize.width * 0.5) * (imageSize.height * 0.5f);
    minLineLength = MIN(imageSize.width, imageSize.height) * 0.1f;
    
    borderSize = [[BoardUtil instance] borderSizeFromBoardSize:imageSize];
    borderSize.width *= 1.5f;
    borderSize.height *= 1.5f;
    
    if ([ExternalDisplay instance].externalDisplayFound) {
        boardAspectRatio = [ExternalDisplay instance].widescreenBounds.size.width / [ExternalDisplay instance].widescreenBounds.size.height;
    } else {
        boardAspectRatio = 1.5f;
    }
}

- (cv::Mat)smooth:(cv::Mat)image {
    cv::GaussianBlur(image, image, cv::Size(3.0f, 3.0f), 1.0f);
    return image;
}

- (cv::Mat)grayscale:(cv::Mat)image {
    cv::cvtColor(image, image, CV_RGB2GRAY);
    return image;
}

- (cv::Mat)applyCannyOnImage:(cv::Mat)image threshold1:(float)threshold1 threshold2:(float)threshold2 {
    cv::Canny(image, image, threshold1, threshold2);
    return image;
}

- (cv::Mat)dilate:(cv::Mat)image {
    cv::Mat element = cv::getStructuringElement(cv::MORPH_RECT, cv::Size(3.0f, 3.0f));
    cv::dilate(image, image, element);
    return image;
}

- (FourPoints)findBoardCorners:(cv::Mat)image {
    FourPoints undefinedPoints = {.defined = NO};
    
    cv::vector<cv::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;
    
    // Find contours
    cv::findContours(image, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    if (contours.size() == 0) {
        return undefinedPoints;
    }
    
    // Find lines from contours
    cv::vector<LineWithAngle> linesAndAngles = [self findLinesFromContours:contours minimumLineLength:MIN(imageSize.width, imageSize.height) * 0.02f];
    if (linesAndAngles.size() < 4) {
        return undefinedPoints;
    }
    
    // Divide lines into groups - "close" lines divided into horizontal (left and right) and vertical (up and down)
    cv::vector<cv::vector<LineGroup>> lineGroups = [self divideLinesIntoGroups:linesAndAngles];
    
    // Remove lines that cannot be border lines. Must have at least 4 "close" lines in group
    cv::vector<cv::vector<LineGroup>> borderLines = [self removeNonBorderLineGroups:lineGroups];
    if (borderLines[0].size() == 0 || borderLines[1].size() == 0 || borderLines[2].size() == 0 || borderLines[3].size() == 0) {
        return undefinedPoints;
    }
    
    // Find average lines that represent each group
    [self findRepresentingLinesInLineGroups:borderLines];

    // Find intersections between all lines
    cv::vector<cv::Point> intersectionPoints = [self findIntersectionsFromLineGroups:borderLines];
    if (intersectionPoints.size() < 4) {
        return undefinedPoints;
    }
    
    // Find best square points
    cv::vector<cv::Point> bestSquarePoints = [self findBestSquareFromPoints:intersectionPoints scoreFunction:^float(cv::vector<cv::Point> hull) {
        return cv::contourArea(hull);
    }];
    if (bestSquarePoints.size() < 4) {
        return undefinedPoints;
    }
    
    // Convert to FourPoints
    return [self squarePointsToSortedBoardPoints:bestSquarePoints];
}

- (FourPoints)squarePointsToSortedBoardPoints:(cv::vector<cv::Point> &)points {
    cv::Point p1 = [self extractSortedPointFromPoints:points referencePoint:CGPointMake(0.0f,            0.0f            )];
    cv::Point p2 = [self extractSortedPointFromPoints:points referencePoint:CGPointMake(imageSize.width, 0.0f            )];
    cv::Point p3 = [self extractSortedPointFromPoints:points referencePoint:CGPointMake(imageSize.width, imageSize.height)];
    cv::Point p4 = [self extractSortedPointFromPoints:points referencePoint:CGPointMake(0.0f,            imageSize.height)];
    FourPoints boardPoints = {
        .defined = YES,
        .p1 = CGPointMake(p1.x, p1.y),
        .p2 = CGPointMake(p2.x, p2.y),
        .p3 = CGPointMake(p3.x, p3.y),
        .p4 = CGPointMake(p4.x, p4.y),
    };
    return boardPoints;
}

- (cv::Point)extractSortedPointFromPoints:(cv::vector<cv::Point> &)points referencePoint:(CGPoint)referencePoint {
    int minIndex = -1;
    float minDistance = 0.0f;
    for (int i = 0; i < points.size(); i++) {
        float deltaX = ABS(points[i].x - referencePoint.x);
        float deltaY = ABS(points[i].y - referencePoint.y);
        float score = deltaX * deltaX + deltaY * deltaY;
        if (score < minDistance || minIndex == -1) {
            minDistance = score;
            minIndex = i;
        }
    }
    return points[minIndex];
}

- (bool)areContourConditionsSatisfied:(cv::vector<cv::Point> &)contour {
    if (contour.size() != 4) {
        return NO;
    }
    if (fabs(cv::contourArea(contour)) < minContourArea) {
        return NO;
    }
    if ([self maxCosineFromContour:contour] > squareAngleAcceptMax * M_PI / 180.0f) {
        return NO;
    }
    if (![self hasCorrectAspectRatio:contour]) {
        return NO;
    }
    return YES;
}

- (bool)hasCorrectAspectRatio:(cv::vector<cv::Point> &)contour {
    float maxWidth = 0.0f;
    float maxHeight = 0.0f;
    for (int i = 0; i < contour.size(); i++) {
        cv::Point p1 = contour[(i + 0) % contour.size()];
        cv::Point p2 = contour[(i + 1) % contour.size()];

        maxWidth = MAX(ABS(p1.x - p2.x), maxWidth);
        maxHeight = MAX(ABS(p1.y - p2.y), maxHeight);
    }
    float aspectRatio = MAX(maxWidth, maxHeight) / MIN(maxWidth, maxHeight);
    return aspectRatio >= boardAspectRatio - aspectRatioAcceptMax && aspectRatio <= boardAspectRatio + aspectRatioAcceptMax;
}

- (bool)isAngleVerticalOrHorizontal:(float)angle {
    int a1 = ABS((int)angle % 90);
    int a = MIN(a1, 90 - a1);
    return a < lineGroupAngleAcceptMax;
}

- (float)maxCosineFromContour:(cv::vector<cv::Point> &)contour {
    float maxCosine = 0.0f;
    for (int j = 2; j < contour.size() + 2; j++) {
        float cosine = fabs(angle(contour[j % contour.size()], contour[(j - 2) % contour.size()], contour[(j - 1) % contour.size()]));
        if (cosine > maxCosine) {
            maxCosine = cosine;
        }
    }
    return maxCosine;
}

- (cv::vector<cv::Point>)findIntersectionsFromLineGroups:(cv::vector<cv::vector<LineGroup>> &)lineGroups {
    cv::vector<cv::Point> intersectionPoints;
    [self addIntersectionsBetweenLineGroups:lineGroups[0] andLineGroups:lineGroups[2] toPoints:intersectionPoints];
    [self addIntersectionsBetweenLineGroups:lineGroups[0] andLineGroups:lineGroups[3] toPoints:intersectionPoints];
    [self addIntersectionsBetweenLineGroups:lineGroups[1] andLineGroups:lineGroups[2] toPoints:intersectionPoints];
    [self addIntersectionsBetweenLineGroups:lineGroups[1] andLineGroups:lineGroups[3] toPoints:intersectionPoints];
    return intersectionPoints;
}

- (cv::vector<cv::Point>)addIntersectionsBetweenLineGroups:(cv::vector<LineGroup> &)lineGroups1 andLineGroups:(cv::vector<LineGroup> &)lineGroups2 toPoints:(cv::vector<cv::Point> &)intersectionPoints {
    for (int i = 0; i < lineGroups1.size(); i++) {
        for (int j = 0; j < lineGroups2.size(); j++) {
            cv::Point r;
            cv::Point2f t;
            if ([self isAcceptableIntersectionLine1:lineGroups1[i].average line2:lineGroups2[j].average r:r t:t]) {
                intersectionPoints.push_back(r);
            }
        }
    }
    return intersectionPoints;
}

- (void)findRepresentingLinesInLineGroups:(cv::vector<cv::vector<LineGroup>> &)lineGroups {
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < lineGroups[i].size(); j++) {
            LineGroup &lineGroup = lineGroups[i][j];
            lineGroup.average.p1 = cv::Point(0, 0);
            lineGroup.average.p2 = cv::Point(0, 0);
            
            for (int k = 0; k < lineGroup.lines.size(); k++) {
                LineWithAngle line = lineGroup.lines[k];
                lineGroup.average.p1.x += line.p1.x;
                lineGroup.average.p1.y += line.p1.y;
                lineGroup.average.p2.x += line.p2.x;
                lineGroup.average.p2.y += line.p2.y;
            }
            lineGroup.average.p1.x /= lineGroup.lines.size();
            lineGroup.average.p1.y /= lineGroup.lines.size();
            lineGroup.average.p2.x /= lineGroup.lines.size();
            lineGroup.average.p2.y /= lineGroup.lines.size();
        }
    }
}

- (cv::vector<cv::vector<LineGroup>>)divideLinesIntoGroups:(cv::vector<LineWithAngle> &)lines {
    cv::vector<cv::vector<LineGroup>> lineGroups = cv::vector<cv::vector<LineGroup>> (4);
    for (int i = 0; i < lines.size(); i++) {
        int direction = [self lineDirection:lines[i]];
        bool addedLine = NO;
        for (int j = 0; j < lineGroups[direction].size(); j++) {
            if (![self doesLine:lines[i] haveSameAngleAsLine:lineGroups[direction][j].minLine]) {
                continue;
            }
            if (![self isLine:lines[i] closeToLine:lineGroups[direction][j].minLine]) {
                continue;
            }
            if (![self isLine:lines[i] closeToLine:lineGroups[direction][j].maxLine]) {
                continue;
            }
            bool doesAllOverlap = YES;
            for (int k = 0; k < lineGroups[direction][j].lines.size(); k++) {
                if (![self doesLine:lines[i] overlapWithLine:lineGroups[direction][j].lines[k]]) {
                    doesAllOverlap = NO;
                    break;
                }
            }
            if (doesAllOverlap) {
                [self updateGroup:lineGroups[direction][j] withLine:lines[i]];
                addedLine = YES;
                break;
            }
        }
        if (!addedLine) {
            lineGroups[direction].push_back([self newLineGroupWithLine:lines[i]]);
        }
    }
    return lineGroups;
}

- (cv::vector<cv::vector<LineGroup>>)removeNonBorderLineGroups:(cv::vector<cv::vector<LineGroup>> &)lineGroups {
    // Must have 4 lines in group, two for each side of the border
    cv::vector<cv::vector<LineGroup>> borderLines = cv::vector<cv::vector<LineGroup>> (4);
    for (int i = 0; i < 4; i++) {
        for (int j = 0; j < lineGroups[i].size(); j++) {
            if (lineGroups[i][j].lines.size() >= 4) {
                borderLines[i].push_back(lineGroups[i][j]);
            }
        }
    }
    return borderLines;
}

- (LineGroup)newLineGroupWithLine:(LineWithAngle)line {
    int direction = [self lineDirection:line];
    cv::vector<LineWithAngle> lineGroupLines;
    lineGroupLines.push_back(line);
    LineGroup lineGroup = {
        .lines = lineGroupLines,
        .minLine = line,
        .maxLine = line,
        .lineDistance = 0.0f,
        .angle = line.angle,
        .direction = direction
    };
    return lineGroup;
}

- (void)updateGroup:(LineGroup &)lineGroup withLine:(LineWithAngle)line {
    lineGroup.lines.push_back(line);
    float distanceToMinLine = [self lineDistance:line fromLine:lineGroup.minLine];
    float distanceToMaxLine = [self lineDistance:line fromLine:lineGroup.maxLine];
    if (distanceToMinLine > lineGroup.lineDistance) {
        lineGroup.lineDistance = distanceToMinLine;
        lineGroup.maxLine = line;
    } else if (distanceToMaxLine > lineGroup.lineDistance) {
        lineGroup.lineDistance = distanceToMaxLine;
        lineGroup.minLine = line;
    }
}

- (bool)doesLine:(LineWithAngle)line1 haveSameAngleAsLine:(LineWithAngle)line2 {
    return angleDelta180(line1.angle, line2.angle) <= 2.0f;
}

- (bool)isLine:(LineWithAngle)line1 closeToLine:(LineWithAngle)line2 {
    float acceptDistance = [self isLineHorizontal:line1] ? borderSize.height : borderSize.width;
    return [self lineDistance:line1 fromLine:line2] < acceptDistance;
}

- (float)lineDistance:(LineWithAngle)line1 fromLine:(LineWithAngle)line2 {
    CGPoint center = [self lineCenter:line2];
    CGPoint delta = CGPointMake(line1.p1.x - line1.p2.x, line1.p1.y - line1.p2.y);
    return ABS(delta.y*center.x - delta.x*center.y + line1.p1.x*line1.p2.y - line1.p2.x*line1.p1.y) / sqrt(delta.x*delta.x + delta.y*delta.y);
}

- (bool)doesLine:(LineWithAngle)line1 overlapWithLine:(LineWithAngle)line2 {
    float maxConnectivityDistance = 2.0f;
    if ([self isLineHorizontal:line1]) {
        return (line1.p1.x - maxConnectivityDistance <= line2.p2.x + maxConnectivityDistance &&
                line1.p2.x + maxConnectivityDistance >= line2.p1.x - maxConnectivityDistance);
    } else {
        return (line1.p1.y - maxConnectivityDistance <= line2.p2.y + maxConnectivityDistance &&
                line1.p2.y + maxConnectivityDistance >= line2.p1.y - maxConnectivityDistance);
    }
}

- (int)lineDirection:(LineWithAngle)line {
    if ([self isLineHorizontal:line]) {
        return [self lineCenter:line].y < imageSize.height / 2.0f ? 0 : 1;
    } else {
        return [self lineCenter:line].x < imageSize.width / 2.0f ? 2 : 3;
    }
}

- (bool)isLineHorizontal:(LineWithAngle)line {
    return line.angle < 45.0f || line.angle > 90.0f + 45.0f;
}

- (CGPoint)lineCenter:(LineWithAngle)line {
    return CGPointMake((line.p1.x + line.p2.x) / 2.0f, (line.p1.y + line.p2.y) / 2.0f);
}

- (cv::vector<LineWithAngle>)findLinesFromContours:(cv::vector<cv::vector<cv::Point>> &)contours minimumLineLength:(float)minimumLineLength {
    cv::vector<LineWithAngle> linesAndAngles = cv::vector<LineWithAngle> (0);
    cv::vector<cv::Point> approxedContour;
    
    float minimumLineLengthSqr = minimumLineLength * minimumLineLength;

    for (int i = 0; i < contours.size(); i++) {
        cv::approxPolyDP(cv::Mat(contours[i]), approxedContour, cv::arcLength(cv::Mat(contours[i]), true) * 0.002f, true);
        
        for (int j = 0; j < approxedContour.size(); j++) {
            LineWithAngle line = {
                .p1 = approxedContour[(j + 0) % approxedContour.size()],
                .p2 = approxedContour[(j + 1) % approxedContour.size()]
            };
            
            float deltaX = line.p1.x - line.p2.x;
            float deltaY = line.p1.y - line.p2.y;
            
            if ((deltaX * deltaX) + (deltaY * deltaY) < minimumLineLengthSqr) {
                continue;
            }

            line.angle = lineAngle(line.p1, line.p2);
            if ([self isAngleVerticalOrHorizontal:line.angle]) {
                linesAndAngles.push_back([self sortLinePointsLeftUp:line]);
            }
        }
    }
    return linesAndAngles;
}

- (LineWithAngle)sortLinePointsLeftUp:(LineWithAngle)line {
    bool horizontal = [self isLineHorizontal:line];
    if ((horizontal && line.p1.x < line.p2.x) || (!horizontal && line.p1.y < line.p2.y)) {
        return line;
    } else {
        LineWithAngle newLine = {
            .p1 = line.p2,
            .p2 = line.p1,
            .angle = line.angle
        };
        return newLine;
    }
}

- (cv::vector<cv::Point>)findBestSquareFromPoints:(cv::vector<cv::Point> &)points scoreFunction:(float(^)(cv::vector<cv::Point> hull))scoreFunction {
    cv::vector<cv::Point> bestPoints;
    cv::vector<cv::Point> currentPoints = cv::vector<cv::Point> (4);
    cv::vector<cv::Point> hull;
    
    float bestScore = -1.0f;

    for (int i1 = 0; i1 < points.size(); i1++) {
        currentPoints[0] = points[i1];

        for (int i2 = i1 + 1; i2 < points.size(); i2++) {
            currentPoints[1] = points[i2];
        
            for (int i3 = i2 + 1; i3 < points.size(); i3++) {
                currentPoints[2] = points[i3];
            
                for (int i4 = i3 + 1; i4 < points.size(); i4++) {
                    currentPoints[3] = points[i4];
                    cv::convexHull(currentPoints, hull);
                    
                    float score = scoreFunction(hull);
                    
                    if (score > bestScore && [self areContourConditionsSatisfied:hull]) {
                        bestPoints = hull;
                        bestScore = score;
                    }
                }
            }
        }
    }
    return bestPoints;
}

- (bool)isAcceptableIntersectionLine1:(LineWithAngle)line1 line2:(LineWithAngle)line2 r:(cv::Point &)r t:(cv::Point2f &)t {
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

- (void)drawPoints:(cv::vector<cv::Point> &)points image:(cv::Mat)image color:(cv::Scalar)color {
    for (int i = 0; i < points.size(); i++) {
        cv::circle(image, points[i], 5.0f, color);
    }
}

- (void)drawBestTwoLineGroups:(cv::vector<LineGroup> &)bestTwoLineGroups ontoImage:(cv::Mat)image {
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

- (void)drawLines:(cv::vector<LineWithAngle> &)lines ontoImage:(cv::Mat)image color:(cv::Scalar)color {
    for (int i = 0; i < lines.size(); i++) {
        cv::vector<cv::vector<cv::Point>> line = cv::vector<cv::vector<cv::Point>> (1);
        line[0].push_back(lines[i].p1);
        line[0].push_back(lines[i].p2);
            
        //cv::Scalar color = cv::Scalar(i % 2 == 0 ? 255 : 0, i % 2 == 1 ? 255 : 0, i % 2 == 0 ? 255 : 0);
        //cv::Scalar color = cv::Scalar(lines[i].angle < 45 ? 255 : 0, lines[i].angle < 45 ? 0 : 255, lines[i].angle < 45 ? 255 : 0);
        //int c = [self isLineHorizontal:lines[i]] ? 255 : 0;
        //cv::Scalar color = cv::Scalar(c, 255 - c, c);
        cv::drawContours(image, line, 0, color);
    }
}

- (void)drawLineGroup:(LineGroup &)lineGroup ontoImage:(cv::Mat)image withColor:(cv::Scalar)color {
    for (int i = 0; i < lineGroup.lines.size(); i++) {
        cv::vector<cv::vector<cv::Point>> line = cv::vector<cv::vector<cv::Point>> (1);
        line[0].push_back(lineGroup.lines[i].p1);
        line[0].push_back(lineGroup.lines[i].p2);

        cv::drawContours(image, line, 0, color);
    }
    cv::vector<cv::vector<cv::Point>> line2 = cv::vector<cv::vector<cv::Point>> (1);
    line2[0].push_back(lineGroup.average.p1);
    line2[0].push_back(lineGroup.average.p2);
    
    cv::Scalar color2 = cv::Scalar(255, 0, 255);
    cv::drawContours(image, line2, 0, color2);
}

float angle(cv::Point pt1, cv::Point pt2, cv::Point pt0) {
    float dx1 = pt1.x - pt0.x;
    float dy1 = pt1.y - pt0.y;
    float dx2 = pt2.x - pt0.x;
    float dy2 = pt2.y - pt0.y;
    return (dx1*dx2 + dy1*dy2) / sqrt((dx1*dx1 + dy1*dy1) * (dx2*dx2 + dy2*dy2) + 1e-10);
}

float lineAngle(cv::Point p1, cv::Point p2) {
    float angle = (atan2f(p1.y - p2.y, p1.x - p2.x) + M_PI) * 180.0f / M_PI;
    if (angle > 180.0f) {
        angle -= 180.0f;
    }
    return angle;
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
