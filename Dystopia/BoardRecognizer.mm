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

#define CANNY_THRESHOLDING_MODE_COUNT 3

#define CANNY_THRESHOLDING_MODE_AUTOMATIC   0
#define CANNY_THRESHOLDING_MODE_BRIGHT_ROOM 1
#define CANNY_THRESHOLDING_MODE_DARK_ROOM   2

float intersectionAcceptDistanceMin = 0.02f;
float intersectionAcceptDistanceMax = 5.0f;
float squareAngleAcceptMax = 15.0f;
float lineGroupAngleAcceptMax = 15.0f;
float aspectRatioAcceptMax = 0.1f;
float lineGroupPointDistanceAcceptMax;

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
    
    float boardAspectRatio;
    
    cv::vector<cv::vector<cv::Point>> approx;
    cv::vector<bool> hasBeenApproxed;
    
    int previousCannyThresholdDetectionMode;
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

- (id)init {
    if (self = [super init]) {
        previousCannyThresholdDetectionMode = CANNY_THRESHOLDING_MODE_AUTOMATIC;
    }
    return self;
}
- (BoardBounds)findBoardBoundsFromImage:(cv::Mat)image {
    BoardBounds undefinedBounds = {.bounds = {.defined = NO}};

    cv::vector<cv::vector<cv::Point>> contours[CANNY_THRESHOLDING_MODE_COUNT];
    cv::vector<cv::Vec4i> hierarchy[CANNY_THRESHOLDING_MODE_COUNT];

    // Prepare image
    cv::Mat copiedImage = image.clone();
    [self prepareConstantsFromImage:copiedImage];

    // Prepare image
    cv::Mat preparedImage = [self smooth:copiedImage];

    // Find non-obstructed bounds
    for (int i = 0; i < CANNY_THRESHOLDING_MODE_COUNT; i++) {

        cv::Mat img = preparedImage.clone();

        // Find canny thresholding mode
        int thresholdingMode = [self thresholdingModeForIndex:i];

        // Hardcoded canny levels first
        float thresholdMin;
        float thresholdMax;

        // Canny thresholding min and max
        if (thresholdingMode == CANNY_THRESHOLDING_MODE_AUTOMATIC) {
            float meanThreshold = [self automaticThresholdingMean:img];
            thresholdMin = meanThreshold * 2.0f / 3.0f;
            thresholdMax = meanThreshold * 4.0f / 3.0f;
        } else if (thresholdingMode == CANNY_THRESHOLDING_MODE_BRIGHT_ROOM) {
            thresholdMin = 40;
            thresholdMax = 70;
        } else {
            thresholdMin = 100;
            thresholdMax = 300;
        }
        
        // Canny image
        img = [self applyCannyOnImage:img threshold1:thresholdMin threshold2:thresholdMax];
        img = [self dilate:img];
        
        // Find contours
        cv::findContours(img, contours[i], hierarchy[i], CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
        if (contours[i].size() == 0) {
            return undefinedBounds;
        }
        
        // Find non-obstructed bounds
        FourPoints corners = [self findNonObstructedBoardCornersFromContours:contours[i] hierarchy:hierarchy[i]];
        if (corners.defined) {
            previousCannyThresholdDetectionMode = thresholdingMode;
            BoardBounds bounds = {.bounds = corners, .isBoundsObstructed = NO};
            return bounds;
        }
    }
    
    // Find obstructed bounds
    for (int i = 0; i < CANNY_THRESHOLDING_MODE_COUNT; i++) {

        // Find obstructed bounds
        FourPoints corners = [self findObstructedBoardCornersFromContours:contours[i]];
        if (corners.defined) {
            previousCannyThresholdDetectionMode = [self thresholdingModeForIndex:i];
            BoardBounds bounds = {.bounds = corners, .isBoundsObstructed = YES};
            return bounds;
        }
    }
    
    // Border not found
    return undefinedBounds;
}

- (float)automaticThresholdingMean:(cv::Mat)image {
    // Calculate histogram
    cv::Mat histogram = [self calculateHistogramFromImage:image];

    // Calculate mean value
    int minIndex = 255;
    int maxIndex = 0;
    for (int i = 0; i < 256; i++) {
        float value = histogram.at<float>(i);
        if (value != 0.0f) {
            minIndex = MIN(minIndex, i);
            maxIndex = MAX(maxIndex, i);
        }
    }
    return (minIndex + maxIndex) / 2.0f;
}

- (int)thresholdingModeForIndex:(int)index {
    return (previousCannyThresholdDetectionMode + index) % CANNY_THRESHOLDING_MODE_COUNT;
}

- (cv::Mat)perspectiveCorrectImage:(cv::Mat)image fromBoardBounds:(FourPoints)boardBounds {
    cv::Mat transformation = [self findTransformationFromBoardBounds:boardBounds];
    return [CameraUtil perspectiveTransformImage:image withTransformation:transformation toSize:[self approxBoardSizeFromBounds:boardBounds]];
}

- (cv::Mat)findTransformationFromBoardBounds:(FourPoints)boardBounds {
    CGSize approxBoardSize = [self approxBoardSizeFromBounds:boardBounds];
    FourPoints dstPoints = {
        .p1 = CGPointMake(                 0.0f,                   0.0f),
        .p2 = CGPointMake(approxBoardSize.width,                   0.0f),
        .p3 = CGPointMake(approxBoardSize.width, approxBoardSize.height),
        .p4 = CGPointMake(                 0.0f, approxBoardSize.height)};
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

- (NSArray *)boardBoundsToImages:(UIImage *)img {
    NSMutableArray *images = [NSMutableArray array];

    cv::Mat image = [img CVMat];
    [self prepareConstantsFromImage:image];

    {
        [images addObject:[UIImage imageWithCVMat:image]];
    }

    cv::Mat origImage = image.clone();

    image = [self smooth:image];
    {
        [images addObject:[UIImage imageWithCVMat:image]];
    }

    image = [self grayscale:image];
    {
        cv::Mat outputImg;
        cv::cvtColor(image, outputImg, CV_GRAY2RGB);
        [images addObject:[UIImage imageWithCVMat:outputImg]];
    }

    float meanThreshold = [self automaticThresholdingMean:image];
    float thresholdMin = meanThreshold * 2.0f / 3.0f;
    float thresholdMax = meanThreshold * 4.0f / 3.0f;
    image = [self applyCannyOnImage:image threshold1:thresholdMin threshold2:thresholdMax];
    {
        cv::Mat outputImg;
        cv::cvtColor(image, outputImg, CV_GRAY2RGB);
        [images addObject:[UIImage imageWithCVMat:outputImg]];
    }

    image = [self dilate:image];
    {
        cv::Mat outputImg;
        cv::cvtColor(image, outputImg, CV_GRAY2RGB);
        [images addObject:[UIImage imageWithCVMat:outputImg]];
    }
    
    cv::vector<cv::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;
    cv::findContours(image, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    {
        cv::Mat outputImg = origImage.clone();
        cv::Scalar color = cv::Scalar(255, 0, 255);
        for (int i = 0; i < contours.size(); i++) {
            cv::vector<cv::Point> approxed;
            cv::approxPolyDP(cv::Mat(contours[i]), approxed, cv::arcLength(cv::Mat(contours[i]), true) * 0.002f, true);
            [self drawContour:approxed ontoImage:outputImg withColor:color];
        }
        [images addObject:[UIImage imageWithCVMat:outputImg]];
    }

    cv::vector<LineWithAngle> linesAndAngles = [self findLinesFromContours:contours minimumLineLength:MIN(imageSize.width, imageSize.height) * 0.02f];
    {
        cv::Mat outputImg = origImage.clone();
        cv::Scalar color = cv::Scalar(255, 0, 255);
        [self drawLines:linesAndAngles ontoImage:outputImg color:color];
        [images addObject:[UIImage imageWithCVMat:outputImg]];
    }

    cv::vector<cv::vector<LineGroup>> lineGroups = [self divideLinesIntoGroups:linesAndAngles];
    {
        cv::Mat outputImg = origImage.clone();
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
        cv::Mat outputImg = origImage.clone();
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
        cv::Mat outputImg = origImage.clone();
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
        cv::Mat outputImg = origImage.clone();
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
        cv::Mat outputImg = origImage.clone();
        cv::Scalar color = cv::Scalar(255, 0, 255);
        [self drawPoints:bestSquare image:outputImg color:color];
        [images addObject:[UIImage imageWithCVMat:outputImg]];
        return images;
    }
}

- (void)prepareConstantsFromImage:(cv::Mat)image {
    imageSize = CGSizeMake(image.cols, image.rows);
    
    minContourArea = (imageSize.width * 0.5) * (imageSize.height * 0.5f);
    minLineLength = MIN(imageSize.width, imageSize.height) * 0.1f;
    
    borderSize = [[BoardUtil instance] borderSizeFromBoardSize:imageSize];
    borderSize.width *= 1.2f;
    borderSize.height *= 1.2f;
    
    lineGroupPointDistanceAcceptMax = MAX(borderSize.width, borderSize.height) * 1.5f;
    
    if ([ExternalDisplay instance].externalDisplayFound) {
        boardAspectRatio = [ExternalDisplay instance].widescreenBounds.size.width / [ExternalDisplay instance].widescreenBounds.size.height;
    } else {
        boardAspectRatio = 1.5f;
    }
}

- (cv::Mat)calculateHistogramFromImage:(cv::Mat)image {
    cv::Mat histogram;
    int binCount = 256;
    float range[] = {0, 256};
    const float *histRange = {range};
    cv::calcHist(&image, 1, 0, cv::Mat(), histogram, 1, &binCount, &histRange);
    return histogram;
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

- (FourPoints)findNonObstructedBoardCornersFromContours:(cv::vector<cv::vector<cv::Point>> &)contours hierarchy:(cv::vector<cv::Vec4i> &)hierarchy {
    FourPoints undefinedPoints = {.defined = NO};

    cv::vector<cv::vector<cv::Point>> approxedContours;
    
    for (int i = 0; i < contours.size(); i++) {
        cv::vector<cv::Point> approxed;
        cv::approxPolyDP(cv::Mat(contours[i]), approxed, cv::arcLength(cv::Mat(contours[i]), true) * 0.01f, true);
        approxedContours.push_back(approxed);
    }

    // Find best contour
    int bestContourIndex = [self findBestContourIndex:approxedContours hierarchy:hierarchy];
    if (bestContourIndex == -1) {
        return undefinedPoints;
    } else {
        return [self squarePointsToSortedBoardPoints:approxedContours[bestContourIndex]];
    }
}

- (int)findBestContourIndex:(cv::vector<cv::vector<cv::Point>> &)contours hierarchy:(cv::vector<cv::Vec4i> &)hierarchy {
    // Find all contours that satisfy simple contour properties
    cv::vector<int> contourIndices;
    for (int i = 0; i < contours.size(); i++) {
        if ([self areContourConditionsSatisfied:contours[i]]) {
            contourIndices.push_back(i);
        }
    }

    // Find valid contours - that is, must have three "nearby" children
    cv::vector<int> validContourIndices;
    for (int i = 0; i < contourIndices.size(); i++) {
        float contourArea = cv::contourArea(contours[contourIndices[i]]);
        if ([self hasExactlyFourValidChildren:contours hierarchy:hierarchy validIndices:contourIndices index:contourIndices[i] parentArea:contourArea count:4]) {
            validContourIndices.push_back(contourIndices[i]);
        }
    }

    // Select best contour among the valid ones
    float bestScore = 1000.0f;
    int bestScoreIndex = -1;
    for (int i = 0; i < validContourIndices.size(); i++) {
        float score = [self maxCosineFromContour:contours[validContourIndices[i]]];
        if (score < bestScore) {
            bestScore = score;
            bestScoreIndex = validContourIndices[i];
        }
    }
    return bestScoreIndex;
}

- (bool)hasExactlyFourValidChildren:(cv::vector<cv::vector<cv::Point>> &)contours hierarchy:(cv::vector<cv::Vec4i> &)hierarchy validIndices:(cv::vector<int> &)validIndices index:(int)index parentArea:(float)parentArea count:(int)count {
    // Check if it is contour at all
    if (index == -1) {
        return NO;
    }
    
    // Check if among valid contours
    bool isValid = NO;
    for (int i = 0; i < validIndices.size(); i++) {
        if (validIndices[i] == index) {
            isValid = YES;
        }
    }
    if (!isValid) {
        return NO;
    }

    // Must have contour size "border"-close to outmost parent contour
    if (parentArea / cv::contourArea(contours[index]) > 1.2f) {
        return NO;
    }
    
    // Children must also be valid
    int i = hierarchy[index][2];
    while (i != -1) {
        if ([self hasExactlyFourValidChildren:contours hierarchy:hierarchy validIndices:validIndices index:i parentArea:parentArea count:(count - 1)]) {
            return YES;
        }
        i = hierarchy[i][0];
    }
    return count == 1; // Return true if count is one - last child must not have valid children!
}

- (FourPoints)findObstructedBoardCornersFromContours:(cv::vector<cv::vector<cv::Point>> &)contours {
    FourPoints undefinedPoints = {.defined = NO};
    
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
    /*if (![self hasCorrectAspectRatio:contour]) {
        return NO;
    }*/
    return YES;
}

- (bool)hasCorrectAspectRatio:(cv::vector<cv::Point> &)contour {
    float averageWidth = 0.0f;
    float averageHeight = 0.0f;
    for (int i = 0; i < contour.size(); i++) {
        cv::Point p1 = contour[(i + 0) % contour.size()];
        cv::Point p2 = contour[(i + 1) % contour.size()];

        averageWidth += ABS(p1.x - p2.x);
        averageHeight += ABS(p1.y - p2.y);
    }
    averageWidth /= (float)contour.size();
    averageHeight /= (float)contour.size();
    float aspectRatio = MAX(averageWidth, averageHeight) / MIN(averageWidth, averageHeight);
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
            cv::vector<cv::Point> points;
            LineGroup &lineGroup = lineGroups[i][j];
            for (int k = 0; k < lineGroup.lines.size(); k++) {
                LineWithAngle line = lineGroup.lines[k];
                points.push_back(line.p1);
                points.push_back(line.p2);
            }
            cv::vector<cv::Point> hull;
            cv::convexHull(points, hull);

            cv::RotatedRect box = cv::minAreaRect(cv::Mat(hull));
            if (box.angle < -45.0f) {
                std::swap(box.size.width, box.size.height);
                box.angle += 90.0f;
            }
            
            cv::Point2f vertices[4];
            box.points(vertices);
            
            if (i == LINE_DIRECTION_HORIZONTAL_UP) {
                lineGroup.average.p1 = vertices[1];
                lineGroup.average.p2 = vertices[2];
            }
            if (i == LINE_DIRECTION_HORIZONTAL_DOWN) {
                lineGroup.average.p1 = vertices[0];
                lineGroup.average.p2 = vertices[3];
            }
            if (i == LINE_DIRECTION_VERTICAL_LEFT) {
                lineGroup.average.p1 = vertices[1];
                lineGroup.average.p2 = vertices[0];
            }
            if (i == LINE_DIRECTION_VERTICAL_RIGHT) {
                lineGroup.average.p1 = vertices[2];
                lineGroup.average.p2 = vertices[3];
            }
        }
    }
}

- (cv::vector<cv::vector<LineGroup>>)divideLinesIntoGroups:(cv::vector<LineWithAngle> &)lines {
    cv::vector<cv::vector<LineGroup>> lineGroups = cv::vector<cv::vector<LineGroup>> (4);
    for (int i = 0; i < lines.size(); i++) {
        int direction = [self lineDirection:lines[i]];
        bool addedLine = NO;
        for (int j = 0; j < lineGroups[direction].size(); j++) {
            if (![self doesLine:lines[i] haveSameEndpointsAsLine:lineGroups[direction][j].minLine]) {
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

- (bool)doesLine:(LineWithAngle)line1 haveSameEndpointsAsLine:(LineWithAngle)line2 {
    CGSize deltaP1 = CGSizeMake(ABS(line1.p1.x - line2.p1.x), ABS(line1.p1.y - line2.p1.y));
    CGSize deltaP2 = CGSizeMake(ABS(line1.p2.x - line2.p2.x), ABS(line1.p2.y - line2.p2.y));
    return deltaP1.width < lineGroupPointDistanceAcceptMax && deltaP1.height < lineGroupPointDistanceAcceptMax && deltaP2.width < lineGroupPointDistanceAcceptMax && deltaP2.height < lineGroupPointDistanceAcceptMax;
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

- (void)drawContour:(cv::vector<cv::Point> &)contour ontoImage:(cv::Mat)image withColor:(cv::Scalar)color {
    cv::vector<cv::vector<cv::Point>> contours;
    contours.push_back(contour);
    
    cv::drawContours(image, contours, 0, color);
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
