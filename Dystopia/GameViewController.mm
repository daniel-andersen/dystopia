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

#import "GameViewController.h"
#import "UIImage+OpenCV.h"
#import "ExternalDisplay.h"
#import "UIImage+CaptureScreen.h"
#import "FakeCameraUtil.h"
#import "ExternalDislayCalibrationBorderView.h"
#import "BrickRecognizer.h"

extern PreviewableViewController *previewInstance;

@interface GameViewController () {
    CameraSession *cameraSession;

    ExternalDislayCalibrationBorderView *externalDislayCalibrationBorderView;
    
    BoardCalibrator *boardCalibrator;
    BoardGame *boardGame;
    Intro *intro;
    
    int gameState;
}

@end

@implementation GameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initialize];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.view bringSubviewToFront:boardCalibrator];
    [self.view bringSubviewToFront:super.overlayView];
    if (externalDislayCalibrationBorderView != nil) {
        [self.view bringSubviewToFront:externalDislayCalibrationBorderView];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [cameraSession start];
}

- (void)initialize {
    self.view.backgroundColor = [UIColor blackColor];
    
    cameraSession = [[CameraSession alloc] initWithDelegate:self];

    boardCalibrator = [[BoardCalibrator alloc] initWithFrame:self.view.bounds cameraSession:cameraSession];
    [self.view addSubview:boardCalibrator];

    externalDislayCalibrationBorderView = [[ExternalDislayCalibrationBorderView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:externalDislayCalibrationBorderView];

    gameState = GAME_STATE_AWAITING_START;
}

- (void)startGame {
    [externalDislayCalibrationBorderView removeFromSuperview];
    externalDislayCalibrationBorderView = nil;
    [self startIntro];
}

- (void)processFrame:(UIImage *)image {
    @autoreleasepool {
        cv::Mat img = [image CVMat];

        cv::Mat grayscaledImage;
        cv::cvtColor(img, grayscaledImage, CV_RGB2GRAY);
        
        [self calibrateBoard:grayscaledImage];
        [self updateGameStateAccordingToFrame];
        [previewInstance previewFrame:image boardCalibrator:boardCalibrator];
        //NSArray *images = [[BoardRecognizer instance] boardBoundsToImages:image];
        //[previewInstance previewFrame:[images objectAtIndex:5] boardCalibrator:boardCalibrator];
        [self testBrickProbability];
    }
}

- (void)testBrickProbability {
    if (!boardCalibrator.boardBounds.bounds.defined) {
        return;
    }
    cv::vector<cv::Point> bricks;
    for (int y = 15; y < 15 + 3; y++) {
        for (int x = 6; x < 6 + 3; x++) {
            bricks.push_back(cv::Point(x, y));
        }
    }
    cv::vector<float> probs = [[BrickRecognizer instance] probabilitiesOfBricksAtLocations:bricks inImage:boardCalibrator.boardImage];
    int bestX = -1;
    int bestY = -1;
    float bestProb = -1.0f;
    int idx = 0;
    for (int y = 15; y < 15 + 3; y++) {
        for (int x = 6; x < 6 + 3; x++) {
            if (probs[idx] > bestProb) {
                bestProb = probs[idx];
                bestX = x;
                bestY = y;
            }
            idx++;
        }
    }
    [previewInstance previewProbabilityOfBrick:bestProb x:bestX y:bestY boardImage:boardCalibrator.boardImage];
}

- (void)updateGameStateAccordingToFrame {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setFrameUpdateIntervalAccordingToGameState];
        cameraSession.readyToProcessFrame = YES;
    });
}

- (void)setFrameUpdateIntervalAccordingToGameState {
    cameraSession.delegateProcessFrameInterval = CAMERA_SESSION_DELEGATE_INTERVAL_FAST;
    /*if (boardCalibrator.state != BOARD_CALIBRATION_STATE_CALIBRATED) {
        cameraSession.delegateProcessFrameInterval = CAMERA_SESSION_DELEGATE_INTERVAL_FAST;
    } else {
        cameraSession.delegateProcessFrameInterval = CAMERA_SESSION_DELEGATE_INTERVAL_DEFAULT;
    }*/
}

- (void)startIntro {
    gameState = GAME_STATE_INTRO;
    intro = [[Intro alloc] initWithFrame:self.view.bounds delegate:self];
    [self.view insertSubview:intro atIndex:0];
    [intro show];
}

- (void)introFinished {
    [intro removeFromSuperview];
    [self startBoardGame];
}

- (void)startBoardGame {
    gameState = GAME_STATE_GAME;
    boardGame = [[BoardGame alloc] initWithFrame:self.view.bounds delegate:self];
    [self.view insertSubview:boardGame atIndex:0];
    [boardGame startWithLevel:0];
}

- (void)boardGameFinished {
    NSLog(@"Board game finished!");
}

- (void)calibrateBoard:(cv::Mat)image {
    [boardCalibrator updateBoundsWithImage:image];
}

- (UIImage *)requestSimulatedImageIfNoCamera {
    super.overlayView.hidden = YES;
    UIImage *image = [UIImage imageWithView:self.view];
    image = [FakeCameraUtil fakePerspectiveOnImage:image];
    image = [FakeCameraUtil distortImage:image];
    image = [FakeCameraUtil putHandsInImage:image];
    super.overlayView.hidden = NO;
    return image;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
