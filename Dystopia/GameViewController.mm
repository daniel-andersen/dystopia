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

@interface GameViewController () {
    ExternalDislayCalibrationBorderView *externalDislayCalibrationBorderView;
    
    Intro *intro;
    
    int gameState;
}

@end

@implementation GameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    gameState = GAME_STATE_AWAITING_START;
    [self setupExternalDisplay];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initialize];
    if (gameState == GAME_STATE_AWAITING_START) {
        [self startCalibrationMode];
    }
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.view bringSubviewToFront:[BoardCalibrator instance]];
    [self.view bringSubviewToFront:super.overlayView];
    super.overlayView.hidden = gameState == GAME_STATE_AWAITING_START;
    if (externalDislayCalibrationBorderView != nil) {
        [[ExternalDisplay instance].window bringSubviewToFront:externalDislayCalibrationBorderView];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[CameraSession instance] start];
}

- (void)viewDidDisappear:(BOOL)animated {
    [[CameraSession instance] stop];
}

- (void)initialize {
    self.view.backgroundColor = [UIColor blackColor];
    
    [CameraSession instance].delegate = self;

    [BoardCalibrator instance].frame = self.view.bounds;
    [self.view addSubview:[BoardCalibrator instance]];
}

- (void)setupExternalDisplay {
    [[ExternalDisplay instance] initialize];
    [ExternalDisplay instance].window.backgroundColor = [UIColor blackColor];
}

- (IBAction)startButtonPressed:(id)sender {
    [self startGame];
}

- (void)startCalibrationMode {
    externalDislayCalibrationBorderView = [[ExternalDislayCalibrationBorderView alloc] initWithFrame:[ExternalDisplay instance].screen.bounds];
    [[ExternalDisplay instance].window addSubview:externalDislayCalibrationBorderView];
    [ExternalDisplay instance].window.hidden = [ExternalDisplay instance].externalDisplayFound ? NO : YES;
    
    if (![ExternalDisplay instance].externalDisplayFound) {
        [self startGame];
    }
}

- (void)startGame {
    [externalDislayCalibrationBorderView removeFromSuperview];
    externalDislayCalibrationBorderView = nil;
    super.overlayView.hidden = NO;
    [self startIntro];
}

- (void)processFrame:(UIImage *)image {
    @autoreleasepool {
        if (gameState >= GAME_STATE_GAME) {
            cv::Mat grayscaledImage = [self grayscaledImage:image];
            [self calibrateBoard:grayscaledImage];
        }
        [self updateGameStateAccordingToFrame];
        [self previewFrame:image];
        //NSArray *images = [[BoardRecognizer instance] boardBoundsToImages:image];
        //[self previewFrame:[images objectAtIndex:5]];
    }
}

- (void)updateGameStateAccordingToFrame {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setFrameUpdateIntervalAccordingToGameState];
        [CameraSession instance].readyToProcessFrame = YES;
    });
}

- (cv::Mat)grayscaledImage:(UIImage *)image {
    cv::Mat img = [image CVMat];
    
    cv::Mat outputImage;
    cv::cvtColor(img, outputImage, CV_RGB2GRAY);
    return outputImage;
}

- (void)setFrameUpdateIntervalAccordingToGameState {
    [CameraSession instance].delegateProcessFrameInterval = CAMERA_SESSION_DELEGATE_INTERVAL_FAST;
    /*if (boardCalibrator.state != BOARD_CALIBRATION_STATE_CALIBRATED) {
        cameraSession.delegateProcessFrameInterval = CAMERA_SESSION_DELEGATE_INTERVAL_FAST;
    } else {
        cameraSession.delegateProcessFrameInterval = CAMERA_SESSION_DELEGATE_INTERVAL_DEFAULT;
    }*/
}

- (void)startIntro {
    gameState = GAME_STATE_INTRO;
    intro = [[Intro alloc] initWithFrame:[ExternalDisplay instance].screen.bounds delegate:self];
    [[ExternalDisplay instance].window insertSubview:intro atIndex:0];
    [intro show];
}

- (void)introFinished {
    [intro removeFromSuperview];
    [self startBoardGame];
}

- (void)startBoardGame {
    NSLog(@"Starting game");
    gameState = GAME_STATE_GAME;
    [BoardGame instance].delegate = self;
    [BoardGame instance].frame = [ExternalDisplay instance].screen.bounds;
    [[ExternalDisplay instance].window insertSubview:[BoardGame instance] atIndex:0];
    [[BoardGame instance] startWithLevel:0];
}

- (void)boardGameFinished {
    NSLog(@"Board game finished!");
}

- (void)calibrateBoard:(cv::Mat)image {
    [[BoardCalibrator instance] updateBoundsWithImage:image];
}

- (UIImage *)requestSimulatedImageIfNoCamera {
    //UIImage *image = [[FakeCameraUtil instance] fakeOutputImage];
    UIImage *image;
    if (gameState == GAME_STATE_GAME) {
        image = [UIImage imageWithView:[BoardGame instance]];
        image = [[FakeCameraUtil instance] drawBricksOnImage:image];
        image = [[FakeCameraUtil instance] fakePerspectiveOnImage:image];
    } else {
        image = [[FakeCameraUtil instance] fakeOutputImage];
    }
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
