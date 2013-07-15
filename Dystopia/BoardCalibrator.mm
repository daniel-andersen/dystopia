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

#import "BoardCalibrator.h"
#import "CameraSession.h"
#import "CameraUtil.h"
#import "ExternalDisplay.h"

@implementation BoardCalibrator

const float calibrationBorderPct = 0.03f;
const UIColor *calibrationBorderColor;

const float calibrationFadeInterval = 2.0f;
const float calibrationAdjustBrightnessInterval = 1.0f;

@synthesize state;
@synthesize boardBounds;
@synthesize screenPoints;
@synthesize boardCameraToScreenTransformation;

- (id)initWithFrame:(CGRect)frame cameraSession:(CameraSession *)session {
    if (self = [super initWithFrame:frame]) {
        cameraSession = session;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    boardRecognizer = [[BoardRecognizer alloc] init];
    boardBoundsRecognizer = [[BoardBoundsRecognizer alloc] init];
    state = BOARD_CALIBRATION_STATE_UNCALIBRATED;
    borderBrightnessDirection = 1;
    borderBrightness = BOARD_CALIBRATION_BRIGHTNESS_DARK;
    boardBounds.defined = NO;
    [self setupView];
}

- (void)startFindBounds {
    state = BOARD_CALIBRATION_STATE_UNCALIBRATED;
    lastUpdateTime = CFAbsoluteTimeGetCurrent();
    borderBrightnessDirection = 1;
    borderBrightness = BOARD_CALIBRATION_BRIGHTNESS_DARK;
    boardBounds.defined = NO;
    [self fadeCalibrationViewToAlpha:1.0f];
    NSLog(@"Board calibration started");
}

- (void)updateBoundsWithImage:(UIImage *)image {
    if (state != BOARD_CALIBRATION_STATE_CALIBRATING) {
        return;
    }
    CFTimeInterval deltaTime = CFAbsoluteTimeGetCurrent() - lastUpdateTime;
    boardBounds = [boardBoundsRecognizer findBoardBoundsFromImage:image];
    if (boardBounds.defined) {
        if (successTime == 0.0f) {
            successTime = CFAbsoluteTimeGetCurrent();
        }
        [self findCameraToScreenTransformation];
        [self findScreenPoints];
        if (CFAbsoluteTimeGetCurrent() >= successTime + BOARD_CALIBRATION_SUCCESS_ACCEPT_INTERVAL) {
            [self success];
        }
    } else {
        successTime = 0.0f;
        float changeInBrightness = BOARD_CALIBRATION_UNSUCCESS_ADJUST_BRIGHTNESS_ALPHA / deltaTime;
        borderBrightness += changeInBrightness * borderBrightnessDirection;
        if (borderBrightness <= BOARD_CALIBRATION_BRIGHTNESS_DARK) {
            borderBrightness = BOARD_CALIBRATION_BRIGHTNESS_DARK;
            borderBrightnessDirection = 1;
        }
        if (borderBrightness >= BOARD_CALIBRATION_BRIGHTNESS_BRIGHT) {
            borderBrightness = BOARD_CALIBRATION_BRIGHTNESS_BRIGHT;
            borderBrightnessDirection = -1;
        }
        [self adjustCalibrationViewBrightness];
    }
    lastUpdateTime = CFAbsoluteTimeGetCurrent();
}

- (void)findCameraToScreenTransformation {
    CGSize screenSize = [ExternalDisplay instance].widescreenBounds.size;
    FourPoints dstPoints = {.p1 = CGPointMake(0.0f, 0.0f), .p2 = CGPointMake(screenSize.width, 0.0f), .p3 = CGPointMake(screenSize.width, screenSize.height), .p4 = CGPointMake(0.0f, screenSize.height)};
    boardCameraToScreenTransformation = [CameraUtil findAffineTransformationSrcPoints:boardBounds dstPoints:dstPoints];
}

- (void)findScreenPoints {
    screenPoints.p1 = [self affineTransformPoint:boardBounds.p1 transformation:boardCameraToScreenTransformation];
    screenPoints.p2 = [self affineTransformPoint:boardBounds.p2 transformation:boardCameraToScreenTransformation];
    screenPoints.p3 = [self affineTransformPoint:boardBounds.p3 transformation:boardCameraToScreenTransformation];
    screenPoints.p4 = [self affineTransformPoint:boardBounds.p4 transformation:boardCameraToScreenTransformation];
}

- (CGPoint)affineTransformPoint:(CGPoint)p transformation:(cv::Mat)transformation {
    cv::Mat src(3, 1, CV_64F);
    src.at<double>(0, 0) = p.x;
    src.at<double>(1, 0) = p.y;
    src.at<double>(2, 0) = 1.0f;
    cv::Mat dst = transformation * src;
    return CGPointMake(dst.at<double>(0, 0), dst.at<double>(1, 0));
}

- (void)success {
    state = BOARD_CALIBRATION_STATE_CALIBRATED;
    [self fadeCalibrationViewToAlpha:0.0f];
    NSLog(@"Board calibrated!");
}

- (void)fadeCalibrationViewToAlpha:(float)alpha {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (alpha == 1.0f) {
            self.layer.hidden = NO;
        }
        [UIView animateWithDuration:calibrationFadeInterval animations:^{
            self.layer.opacity = alpha;
        } completion:^(BOOL finished) {
            if (alpha == 0.0f) {
                self.layer.hidden = YES;
                state = BOARD_CALIBRATION_STATE_CALIBRATED;
            } else {
                state = BOARD_CALIBRATION_STATE_CALIBRATING;
                successTime = 0.0f;
            }
        }];
    });
}

- (void)adjustCalibrationViewBrightness {
    dispatch_async(dispatch_get_main_queue(), ^{
        [CATransaction begin];
        [CATransaction setAnimationDuration:calibrationAdjustBrightnessInterval];
        borderLayer.fillColor = [self borderColor].CGColor;
        borderLayer.strokeColor = [self borderColor].CGColor;
        [CATransaction commit];
    });
}

- (void)setupView {
    self.hidden = YES;
    self.layer.opacity = 0.0f;
    
    float borderWidth = self.frame.size.width * calibrationBorderPct;
    float borderHeight = self.frame.size.height * calibrationBorderPct;
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    
    // Top
    [path moveToPoint:CGPointMake(0.0f,                     0.0f)];
    [path addLineToPoint:CGPointMake(self.frame.size.width, 0.0f)];
    [path addLineToPoint:CGPointMake(self.frame.size.width, borderHeight)];
    [path addLineToPoint:CGPointMake(0.0f,                  borderHeight)];
    [path closePath];
    
    // Bottom
    [path moveToPoint:CGPointMake(0.0f,                     self.frame.size.height - borderHeight)];
    [path addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height - borderHeight)];
    [path addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
    [path addLineToPoint:CGPointMake(0.0f,                  self.frame.size.height)];
    [path closePath];
    
    // Left
    [path moveToPoint:CGPointMake(0.0f,           borderHeight)];
    [path addLineToPoint:CGPointMake(borderWidth, borderHeight)];
    [path addLineToPoint:CGPointMake(borderWidth, self.frame.size.height - borderHeight)];
    [path addLineToPoint:CGPointMake(0.0f,        self.frame.size.height - borderHeight)];
    [path closePath];
    
    // Right
    [path moveToPoint:CGPointMake(self.frame.size.width - borderWidth,    borderHeight)];
    [path addLineToPoint:CGPointMake(self.frame.size.width,               borderHeight)];
    [path addLineToPoint:CGPointMake(self.frame.size.width,               self.frame.size.height - borderHeight)];
    [path addLineToPoint:CGPointMake(self.frame.size.width - borderWidth, self.frame.size.height - borderHeight)];
    [path closePath];
    
    borderLayer = [CAShapeLayer layer];
    borderLayer.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
    borderLayer.fillColor = [self borderColor].CGColor;
    borderLayer.strokeColor = [self borderColor].CGColor;
    borderLayer.path = path.CGPath;
    
    [self.layer addSublayer:borderLayer];
}

- (UIColor *)borderColor {
    return [UIColor colorWithRed:0.0f green:borderBrightness blue:0.0f alpha:1.0f];
}

@end
