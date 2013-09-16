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

#import "BrickRecognizer.h"
#import "UIImage+OpenCV.h"

#define HISTOGRAM_BIN_COUNT (256 / 8)

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

- (cv::vector<float>)probabilitiesOfBrickAtLocations:(cv::vector<cv::Point>)locations inImage:(UIImage *)image {
    cv::vector<float> probabilities;
    cv::Mat img = [self prepareImage:image];
    for (int i = 0; i < locations.size(); i++) {
        probabilities.push_back([self probabilityOfBrickAtLocation:locations[i] inImage:img]);
    }
    return probabilities;
}

- (float)probabilityOfBrickAtLocation:(cv::Point)location inUIImage:(UIImage *)image {
    return [self probabilityOfBrickAtLocation:location inImage:[self prepareImage:image]];
}

- (float)probabilityOfBrickAtLocation:(cv::Point)location inImage:(cv::Mat)image {
    cv::Mat brickImage = [self extractBrickImageFromLocation:location image:image];
    cv::Mat histogram = [self calculateHistogramFromImage:brickImage];
    return histogram.at<float>(0);
}

- (cv::Mat)calculateHistogramFromImage:(cv::Mat)image {
    cv::Mat histogram;
    int binCount = HISTOGRAM_BIN_COUNT;
    float range[] = {0, 256};
    const float *histRange = {range};
    cv::calcHist(&image, 1, 0, cv::Mat(), histogram, 1, &binCount, &histRange);
    return histogram;
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

- (cv::Mat)prepareImage:(UIImage *)image {
    cv::Mat img = [image CVMat];
    cv::cvtColor(img, img, CV_RGB2GRAY);
    return img;
}

@end
