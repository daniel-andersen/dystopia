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

#define HISTOGRAM_BIN_COUNT 32

#define BRICK_RECOGNITION_CONTROL_POINT_BRIGHTNESS_PCT 0.7f

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

- (cv::Point)positionOfBrickAtLocations:(cv::vector<cv::Point>)locations inImage:(cv::Mat)image controlPoint:(cv::Point)controlPoint {
    cv::vector<float> probabilities = [self probabilitiesOfBricksAtLocations:locations inImage:image withControlPoint:controlPoint];
    cv::Point bestPosition = cv::Point(-1, -1);
    float bestProb = -1.0f;
    for (int i = 0; i < probabilities.size() - 2; i++) {
        if (probabilities[i] > bestProb && probabilities[i] > probabilities[probabilities.size() - 1]) {
            bestProb = probabilities[i];
            bestPosition = locations[i];
        }
    }
    return bestPosition;
}

- (cv::vector<cv::Point>)positionOfBricksAtLocations:(cv::vector<cv::Point>)locations inImage:(cv::Mat)image controlPoint:(cv::Point)controlPoint {
    cv::vector<float> probabilities = [self probabilitiesOfBricksAtLocations:locations inImage:image withControlPoint:controlPoint];
    cv::vector<cv::Point> positions;
    NSLog(@"------------");
    for (int i = 0; i < probabilities.size() - 2; i++) {
        if (probabilities[i] > probabilities[probabilities.size() - 1]) {
            positions.push_back(locations[i]);
        }
        NSLog(@"%f vs %f - %f   =   %i", probabilities[i], probabilities[probabilities.size() - 1], probabilities[probabilities.size() - 2], probabilities[i] > probabilities[probabilities.size() - 1] ? 1 : 0);
    }
    return positions;
}

- (cv::vector<float>)probabilitiesOfBricksAtLocations:(cv::vector<cv::Point>)locations inImage:(cv::Mat)image {
    return [self probabilitiesOfBricksAtLocations:locations inImage:image withControlPoint:cv::Point(-1, -1)];
}

- (cv::vector<float>)probabilitiesOfBricksAtLocations:(cv::vector<cv::Point>)locations inImage:(cv::Mat)image withControlPoint:(cv::Point)controlPoint {
    locations.push_back(controlPoint);
    locations.push_back(controlPoint);
    CGSize brickSize = [[BoardUtil instance] singleBrickScreenSizeFromBoardSize:CGSizeMake(image.cols, image.rows)];
    cv::Mat preparedImage = controlPoint.x == -1 ? [self prepareImage:image withLocations:locations brickSize:brickSize] : [self prepareImageWithTwoControlPoints:image withLocations:locations brickSize:brickSize];
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

/*- (float)calculateMedianOfHistogram:(cv::Mat)histogram binCount:(int)binCount brickSize:(CGSize)brickSize {
    float median = 0.0f;
    int pos = 0;
    for (int i = 0; i < binCount; i++) {
        //median += histogram.at<float>(i) * (float)i / (brickSize.width * brickSize.height);
        if (histogram.at<float>(i) > median) {
            pos = i;
            median = histogram.at<float>(i);
        }
    }
    return pos;
}*/

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

- (cv::Mat)prepareImageWithTwoControlPoints:(cv::Mat)image withLocations:(cv::vector<cv::Point>)locations brickSize:(CGSize)brickSize {
    cv::Mat preparedImage = [self prepareImageNoEqualize:image withLocations:locations brickSize:brickSize];
    preparedImage = [self darkenHalfOfLastImage:preparedImage brickSize:brickSize];
    return [self equalizeImage:preparedImage];
}

- (cv::Mat)prepareImage:(cv::Mat)image withLocations:(cv::vector<cv::Point>)locations brickSize:(CGSize)brickSize {
    cv::Mat preparedImage = [self prepareImageNoEqualize:image withLocations:locations brickSize:brickSize];
    return [self equalizeImage:preparedImage];
}

- (cv::Mat)equalizeImage:(cv::Mat)image {
    cv::Mat equalizedImage;
    cv::equalizeHist(image, equalizedImage);
    return equalizedImage;
}

- (cv::Mat)prepareImageNoEqualize:(cv::Mat)image withLocations:(cv::vector<cv::Point>)locations brickSize:(CGSize)brickSize {
    cv::Mat tiledImage = cv::Mat((int)brickSize.height, (int)brickSize.width * locations.size(), image.type());
    for (int i = 0; i < locations.size(); i++) {
        cv::Mat brickImage = [self extractBrickImageFromLocation:locations[i] image:image brickSize:brickSize];
        cv::Rect roi(cv::Point((int)brickSize.width * i, 0), brickImage.size());
        brickImage.copyTo(tiledImage(roi));
    }
    return tiledImage;
}

- (cv::Mat)darkenHalfOfLastImage:(cv::Mat)image brickSize:(CGSize)brickSize {
    for (int i = 0; i < brickSize.height; i++) {
        for (int j = 0; j < brickSize.width / 32; j++) {
            int x = image.cols - j - 1;
            int y = i;
            image.at<uchar>(y, x) = image.at<uchar>(y, x) * BRICK_RECOGNITION_CONTROL_POINT_BRIGHTNESS_PCT;
        }
    }
    return image;
}

@end
