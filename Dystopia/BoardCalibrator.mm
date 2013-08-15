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

@interface BoardCalibrator () {
    BoardRecognizer *boardRecognizer;
    
    CameraSession *cameraSession;
    
    CFAbsoluteTime successTime;
    CFAbsoluteTime lastUpdateTime;
}

@end

@implementation BoardCalibrator

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
    state = BOARD_CALIBRATION_STATE_UNCALIBRATED;
    boardBounds.defined = NO;
}

- (void)updateBoundsWithImage:(UIImage *)image {
    boardBounds = [boardRecognizer findBoardBoundsFromImage:image];
    if (boardBounds.defined) {
        [self findCameraToScreenTransformation];
        //[cameraSession lock];
    } else {
        state = BOARD_CALIBRATION_STATE_CALIBRATING;
        //[cameraSession unlock];
    }
}

- (void)findCameraToScreenTransformation {
    CGSize screenSize = [ExternalDisplay instance].widescreenBounds.size;
    FourPoints dstPoints = {.p1 = CGPointMake(0.0f, 0.0f), .p2 = CGPointMake(screenSize.width, 0.0f), .p3 = CGPointMake(screenSize.width, screenSize.height), .p4 = CGPointMake(0.0f, screenSize.height)};
    boardCameraToScreenTransformation = [CameraUtil findPerspectiveTransformationSrcPoints:boardBounds dstPoints:dstPoints];
}

- (void)success {
    state = BOARD_CALIBRATION_STATE_CALIBRATED;
}

@end
