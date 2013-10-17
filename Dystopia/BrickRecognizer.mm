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

//#include <stdio.h>
//#include <stdlib.h>

#import "BrickRecognizer.h"
#import "UIImage+OpenCV.h"

#define HISTOGRAM_BIN_COUNT 8

#define BRICK_RECOGNITION_MINIMUM_MEDIAN_DELTA 50.0f
#define BRICK_RECOGNITION_MINIMUM_PROBABILITY 0.4f

BrickRecognizer *brickRecognizerInstance = nil;

@implementation BrickRecognizer

+ (BrickRecognizer *)instance {
    @synchronized(self) {
        if (brickRecognizerInstance == nil) {
            brickRecognizerInstance = [[BrickRecognizer alloc] init];
        }
        return brickRecognizerInstance;
    }
}

- (cv::Point)positionOfBrickAtLocations:(cv::vector<cv::Point>)locations inImage:(cv::Mat)image {
    CGSize brickSize = [[BoardUtil instance] singleBrickScreenSizeFromBoardSize:CGSizeMake(image.cols, image.rows)];
    
    cv::Mat brickImages = [self tiledImageFromLocations:locations inImage:image];
    
    MedianMinMax medianMinMax = [self medianMinMaxFromLocations:locations inTiledImage:brickImages brickSize:brickSize];
    //NSLog(@"Median: %f - %f = %f", medianMinMax.min, medianMinMax.max, medianMinMax.max - medianMinMax.min);
    if (medianMinMax.max - medianMinMax.min < BRICK_RECOGNITION_MINIMUM_MEDIAN_DELTA) {
        return cv::Point(-1, -1);
    }
    cv::vector<float> probabilities = [self probabilitiesOfBricksAtLocations:locations inImage:image];
    float maxProbability = [self maxProbabilityFromProbabilities:probabilities];
    float secondMaxProbability = [self secondMaxProbabilityFromProbabilities:probabilities];
    //NSLog(@"%f", maxProbability);
    if (maxProbability < BRICK_RECOGNITION_MINIMUM_PROBABILITY || secondMaxProbability >= BRICK_RECOGNITION_MINIMUM_PROBABILITY) {
        return cv::Point(-1, -1);
    }
    //NSLog(@"BRICK!");
    return [self maxProbabilityPositionFromLocations:locations probabilities:probabilities];
}

- (cv::vector<cv::Point>)positionOfBricksAtLocations:(cv::vector<cv::Point>)locations inImage:(cv::Mat)image controlPoints:(cv::vector<cv::Point>)controlPoints {
    CGSize brickSize = [[BoardUtil instance] singleBrickScreenSizeFromBoardSize:CGSizeMake(image.cols, image.rows)];

    cv::vector<cv::Point> positions;
    for (int i = 0; i < locations.size(); i++) {
        cv::vector<cv::Point> brickLocations = [self allLocationsFromLocation:locations[i] controlPoints:controlPoints];
        cv::Mat brickImages = [self tiledImageFromLocations:brickLocations inImage:image];
        MedianMinMax medianMinMax = [self medianMinMaxFromLocations:brickLocations inTiledImage:brickImages brickSize:brickSize];
        //NSLog(@"Median %i: %f - %f = %f", i, medianMinMax.min, medianMinMax.max, medianMinMax.max - medianMinMax.min);
        if (medianMinMax.max - medianMinMax.min < BRICK_RECOGNITION_MINIMUM_MEDIAN_DELTA) {
            continue;
        }
        cv::vector<float> probabilities = [self probabilitiesOfBricksAtLocations:brickLocations inImage:image];
        float maxProbability = [self maxProbabilityFromProbabilities:probabilities];
        float secondMaxProbability = [self secondMaxProbabilityFromProbabilities:probabilities];
        if (maxProbability < BRICK_RECOGNITION_MINIMUM_PROBABILITY || secondMaxProbability >= BRICK_RECOGNITION_MINIMUM_PROBABILITY) {
            continue;
        }
        cv::Point maxProbPosition = [self maxProbabilityPositionFromLocations:brickLocations probabilities:probabilities];
        if (maxProbPosition == locations[i]) {
            positions.push_back(locations[i]);
        }
    }
    return positions;
}

- (float)maxProbabilityFromProbabilities:(cv::vector<float>)probabilities {
    float maxProb = 0.0f;
    for (int i = 0; i < probabilities.size(); i++) {
        maxProb = MAX(maxProb, probabilities[i]);
    }
    return maxProb;
}

- (float)secondMaxProbabilityFromProbabilities:(cv::vector<float>)probabilities {
    float maxProb = 0.0f;
    float secondMaxProb = 0.0f;
    for (int i = 0; i < probabilities.size(); i++) {
        if (probabilities[i] > maxProb) {
            secondMaxProb = maxProb;
            maxProb = probabilities[i];
        }
    }
    return secondMaxProb;
}

- (cv::Point)maxProbabilityPositionFromLocations:(cv::vector<cv::Point>)locations probabilities:(cv::vector<float>)probabilities {
    float maxProb = 0.0f;
    int maxProbIndex = 0;
    for (int i = 0; i < locations.size(); i++) {
        if (probabilities[i] > maxProb) {
            maxProb = probabilities[i];
            maxProbIndex = i;
        }
    }
    return locations[maxProbIndex];
}

- (MedianMinMax)medianMinMaxFromLocations:(cv::vector<cv::Point>)locations inTiledImage:(cv::Mat)tiledImage brickSize:(CGSize)brickSize {
    MedianMinMax medianMinMax = {.min = 256.0f, .max = 0.0f};
    for (int i = 0; i < locations.size(); i++) {
        cv::Mat brickImage = [self extractBrickImageFromIndex:i inTiledImage:tiledImage brickSize:brickSize];
        cv::Mat histogram = [self calculateHistogramFromImage:brickImage binCount:256];
        float median = [self calculateMedianOfHistogram:histogram binCount:256 brickSize:brickSize];
        medianMinMax.min = MIN(median, medianMinMax.min);
        medianMinMax.max = MAX(median, medianMinMax.max);
    }
    return medianMinMax;
}

- (cv::Mat)tiledImageFromLocations:(cv::vector<cv::Point>)locations inImage:(cv::Mat)image {
    CGSize brickSize = [[BoardUtil instance] singleBrickScreenSizeFromBoardSize:CGSizeMake(image.cols, image.rows)];
    return [self prepareImageWithoutEqualizing:image withLocations:locations brickSize:brickSize];
}

- (cv::vector<cv::Point>)allLocationsFromLocation:(cv::Point)location controlPoints:(cv::vector<cv::Point>)controlPoints {
    cv::vector<cv::Point> allLocations;
    allLocations.push_back(location);
    for (int i = 0; i < controlPoints.size(); i++) {
        allLocations.push_back(controlPoints[i]);
    }
    return allLocations;
}

- (cv::vector<cv::Point>)allLocationsFromLocations:(cv::vector<cv::Point>)locations controlPoints:(cv::vector<cv::Point>)controlPoints {
    cv::vector<cv::Point> allLocations;
    for (int i = 0; i < locations.size(); i++) {
        allLocations.push_back(locations[i]);
    }
    for (int i = 0; i < controlPoints.size(); i++) {
        allLocations.push_back(controlPoints[i]);
    }
    return allLocations;
}

- (cv::vector<float>)probabilitiesOfBricksAtLocations:(cv::vector<cv::Point>)locations inImage:(cv::Mat)image {
    CGSize brickSize = [[BoardUtil instance] singleBrickScreenSizeFromBoardSize:CGSizeMake(image.cols, image.rows)];
    cv::Mat preparedImage = [self prepareImage:image withLocations:locations brickSize:brickSize];
    cv::vector<float> probabilities;
    for (int i = 0; i < locations.size(); i++) {
        probabilities.push_back([self probabilityOfBrickAtIndex:i inTiledImage:preparedImage brickSize:brickSize]);
    }
    return probabilities;
}

- (float)probabilityOfBrickAtIndex:(int)index inTiledImage:(cv::Mat)tiledImage brickSize:(CGSize)brickSize {
    cv::Mat equalizedBrickImage = [self extractBrickImageFromIndex:index inTiledImage:tiledImage brickSize:brickSize];
    cv::Mat equalizedHistogram = [self calculateHistogramFromImage:equalizedBrickImage binCount:HISTOGRAM_BIN_COUNT];
    return equalizedHistogram.at<float>(0) / (float)(equalizedBrickImage.rows * equalizedBrickImage.cols);
}

- (float)calculateMedianOfHistogram:(cv::Mat)histogram binCount:(int)binCount brickSize:(CGSize)brickSize {
    float median = 0.0f;
    for (int i = 0; i < binCount; i++) {
        median += histogram.at<float>(i) * (float)i / (brickSize.width * brickSize.height);
    }
    return median;
}

- (float)calculateModeOfHistogram:(cv::Mat)histogram binCount:(int)binCount brickSize:(CGSize)brickSize {
    float max = 0.0f;
    int mode = 0;
    for (int i = 0; i < binCount; i++) {
        if (histogram.at<float>(i) > max) {
            max = histogram.at<float>(i);
            mode = i;
        }
    }
    return mode;
}

- (cv::Mat)calculateHistogramFromImage:(cv::Mat)image binCount:(int)binCount {
    cv::Mat histogram;
    float range[] = {0, 256};
    const float *histRange = {range};
    cv::calcHist(&image, 1, 0, cv::Mat(), histogram, 1, &binCount, &histRange);
    return histogram;
}

- (cv::Mat)extractBrickImageFromLocation:(cv::Point)location image:(cv::Mat)image brickSize:(CGSize)brickSize {
    cv::Rect rect = [self boardRectFromLocation:location inImage:image brickSize:brickSize];
    return cv::Mat(image, rect);
}

- (cv::Mat)extractBrickImageFromIndex:(int)index inTiledImage:(cv::Mat)image brickSize:(CGSize)brickSize {
    cv::Rect rect = cv::Rect((int)brickSize.width * index, 0, (int)brickSize.width, (int)brickSize.height);
    return cv::Mat(image, rect);
}

- (cv::Rect)boardRectFromLocation:(cv::Point)location inImage:(cv::Mat)image brickSize:(CGSize)brickSize {
    cv::Rect rect;
    rect.x = (float)location.x * brickSize.width;
    rect.y = (float)location.y * brickSize.height;
    rect.width = (int)brickSize.width;
    rect.height = (int)brickSize.height;
    return rect;
}

- (cv::Mat)prepareImage:(cv::Mat)image withLocations:(cv::vector<cv::Point>)locations brickSize:(CGSize)brickSize {
    cv::Mat preparedImage = [self prepareImageWithoutEqualizing:image withLocations:locations brickSize:brickSize];
    return [self equalizeImage:preparedImage];
}

- (cv::Mat)prepareImageWithoutEqualizing:(cv::Mat)image withLocations:(cv::vector<cv::Point>)locations brickSize:(CGSize)brickSize {
    cv::Mat tiledImage = cv::Mat((int)brickSize.height, (int)brickSize.width * locations.size(), image.type());
    for (int i = 0; i < locations.size(); i++) {
        cv::Mat brickImage = [self extractBrickImageFromLocation:locations[i] image:image brickSize:brickSize];
        cv::Rect roi(cv::Point((int)brickSize.width * i, 0), brickImage.size());
        brickImage.copyTo(tiledImage(roi));
    }
    return tiledImage;
}

- (cv::Mat)equalizeImage:(cv::Mat)image {
    cv::Mat equalizedImage;
    cv::equalizeHist(image, equalizedImage);
    return equalizedImage;
}

@end
