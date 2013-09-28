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
#import "BoardUtil.h"

@interface BoardCalibrator () {
    CameraSession *cameraSession;
    
    UIView *calibrationStateView;
    
    CFAbsoluteTime successTime;
    CFAbsoluteTime lastUpdateTime;
}

@end

BoardCalibrator *boardCalibratorInstance = nil;

@implementation BoardCalibrator

@synthesize state;
@synthesize boardBounds;
@synthesize screenPoints;
@synthesize boardImage;
@synthesize boardImageLock;

+ (BoardCalibrator *)instance {
    @synchronized(self) {
        if (boardCalibratorInstance == nil) {
            boardCalibratorInstance = [[BoardCalibrator alloc] init];
        }
        return boardCalibratorInstance;
    }
}

- (id)init {
    if (self = [super init]) {
        boardImageLock = [[NSObject alloc] init];
    }
    return self;
}

- (void)initializeWithFrame:(CGRect)frame cameraSession:(CameraSession *)session {
    cameraSession = session;
    [self initialize];
}

- (void)initialize {
    state = BOARD_CALIBRATION_STATE_UNCALIBRATED;
    boardBounds.bounds.defined = NO;
    [self addCalibrationStateView];
}

- (void)updateBoundsWithImage:(cv::Mat)image {
    boardBounds = [[BoardRecognizer instance] findBoardBoundsFromImage:image];
    if (boardBounds.bounds.defined) {
        state = BOARD_CALIBRATION_STATE_CALIBRATED;
        @synchronized(boardImageLock) {
            boardImage = [self perspectiveCorrectImage:image];
        }
        //[cameraSession lock];
    } else {
        state = BOARD_CALIBRATION_STATE_CALIBRATING;
        //[cameraSession unlock];
    }
    if (DEBUG) {
        dispatch_async(dispatch_get_main_queue(), ^{
            calibrationStateView.backgroundColor = boardBounds.bounds.defined ? [UIColor greenColor] : [UIColor redColor];
        });
    }
}

- (cv::Mat)perspectiveCorrectImage:(cv::Mat)image {
    return [[BoardRecognizer instance] perspectiveCorrectImage:image fromBoardBounds:boardBounds.bounds];
}

- (void)addCalibrationStateView {
    calibrationStateView = [[UIView alloc] initWithFrame:CGRectMake([BoardUtil instance].singleBrickScreenSize.width - 10.0f, [BoardUtil instance].singleBrickScreenSize.height - 10.0f, 10.0f, 10.0f)];
    calibrationStateView.backgroundColor = [UIColor clearColor];
    calibrationStateView.hidden = !DEBUG;
    [self addSubview:calibrationStateView];
}

@end
