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

- (cv::vector<float>)probabilitiesOfBricksAtLocations:(cv::vector<cv::Point>)locations inImage:(cv::Mat)image {
    image = [self prepareImage:image];
    cv::vector<float> probabilities;
    for (int i = 0; i < locations.size(); i++) {
        probabilities.push_back([self probabilityOfBrickAtLocation:locations[i] inGrayscaledNormalizedImage:image]);
    }
    return probabilities;
}

- (float)probabilityOfBrickAtLocation:(cv::Point)location inGrayscaledNormalizedImage:(cv::Mat)image {
    cv::Mat brickImage = [self extractBrickImageFromLocation:location image:image];
    cv::Mat histogram = [self calculateHistogramFromImage:brickImage];
    //std::cout << "Histogram: " << std::endl << histogram << std::endl;
    return histogram.at<float>(0) / (float)(brickImage.rows * brickImage.cols);
}

- (cv::Mat)calculateHistogramFromImage:(cv::Mat)image {
    cv::Mat histogram;
    int binCount = HISTOGRAM_BIN_COUNT;
    float range[] = {0, 256};
    const float *histRange = {range};
    cv::calcHist(&image, 1, 0, cv::Mat(), histogram, 1, &binCount, &histRange);
    return histogram;
}

- (UIImage *)extractBrickUIImageFromLocation:(cv::Point)location image:(cv::Mat)image {
    image = [self prepareImage:image];
    cv::Rect rect = [self boardRectFromLocation:location inImage:image];
    image = cv::Mat(image, rect);
    cv::cvtColor(image, image, CV_GRAY2RGB);
    return [UIImage imageWithCVMat:image];
}

- (cv::Mat)extractBrickImageFromLocation:(cv::Point)location image:(cv::Mat)image {
    cv::Rect rect = [self boardRectFromLocation:location inImage:image];
    return cv::Mat(image, rect);
}

- (cv::Rect)boardRectFromLocation:(cv::Point)location inImage:(cv::Mat)image {
    CGSize brickSize = [[BoardUtil instance] singleBrickScreenSizeFromBoardSize:CGSizeMake(image.cols, image.rows)];
    cv::Rect rect;
    rect.x = (float)location.x * brickSize.width;
    rect.y = (float)location.y * brickSize.height;
    rect.width = (int)brickSize.width;
    rect.height = (int)brickSize.height;
    return rect;
}

- (cv::Mat)prepareImage:(cv::Mat)image {
    cv::equalizeHist(image, image);
    return image;
}

@end
