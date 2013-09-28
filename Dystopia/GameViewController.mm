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
    [self.view bringSubviewToFront:[BoardCalibrator instance]];
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

    [[BoardCalibrator instance] initializeWithFrame:self.view.bounds cameraSession:cameraSession];
    [self.view addSubview:[BoardCalibrator instance]];

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
        if (gameState >= GAME_STATE_GAME) {
            cv::Mat grayscaledImage = [self grayscaledImage:image];
            [self calibrateBoard:grayscaledImage];
        }
        [self updateGameStateAccordingToFrame];
        [previewInstance previewFrame:image];
        //NSArray *images = [[BoardRecognizer instance] boardBoundsToImages:image];
        //[previewInstance previewFrame:[images objectAtIndex:5]];
    }
}

- (void)updateGameStateAccordingToFrame {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setFrameUpdateIntervalAccordingToGameState];
        cameraSession.readyToProcessFrame = YES;
    });
}

- (cv::Mat)grayscaledImage:(UIImage *)image {
    cv::Mat img = [image CVMat];
    
    cv::Mat outputImage;
    cv::cvtColor(img, outputImage, CV_RGB2GRAY);
    return outputImage;
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
    [[BoardCalibrator instance] updateBoundsWithImage:image];
}

- (UIImage *)requestSimulatedImageIfNoCamera {
    super.overlayView.hidden = YES;
    UIImage *image = [UIImage imageWithView:self.view];
    image = [FakeCameraUtil fakePerspectiveOnImage:image];
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
