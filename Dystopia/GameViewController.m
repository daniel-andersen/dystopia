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
#import "ExternalDisplay.h"
#import "UIImage+CaptureScreen.h"
#import "FakeCameraUtil.h"

@implementation GameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialize];
    [self initializeGui];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [cameraSession start];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    [self.view bringSubviewToFront:super.overlayView];
}

- (void)initialize {
    cameraSession = [[CameraSession alloc] initWithDelegate:self];
    
    boardGame = [[BoardGame alloc] initWithLevel:0];
    boardRecognizer = [[BoardRecognizer alloc] init];
    
    gameState = GAME_STATE_CALIBRATION;
}

- (void)initializeGui {
    boardView = [[BoardView alloc] initWithFrame:[ExternalDisplay instance].widescreenBounds];
    [self.view addSubview:boardView];

    calibrationView = [[CalibrationView alloc] initWithFrame:[ExternalDisplay instance].widescreenBounds];
    [self.view addSubview:calibrationView];
}

- (void)processFrame:(UIImage *)image {
    [self calibrateBoard:image];
    [super previewFrame:image];
    cameraSession.readyToProcessFrame = YES;
}

- (void)calibrateBoard:(UIImage *)image {
    if (gameState == GAME_STATE_CALIBRATION) {
        boardPoints = [boardRecognizer findBoardFromImage:image];
        [super previewBoardContour:boardPoints];
    }
}

- (UIImage *)requestSimulatedImageIfNoCamera {
    super.overlayView.hidden = YES;
    UIImage *image = [UIImage imageWithView:self.view];
    UIImage *transformedImage = [FakeCameraUtil fakePerspectiveOnImage:image];
    super.overlayView.hidden = NO;
    return transformedImage;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsLandscape(interfaceOrientation);
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
