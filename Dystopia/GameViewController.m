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
#import "CameraUtil.h"
#import "UIImage+CaptureScreen.h"

@implementation GameViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initialize];
    [self initializeGui];
}

- (void)viewDidAppear:(BOOL)animated {
    [cameraSession start];
}

- (void)viewWillLayoutSubviews {
    cameraPreview.frame = self.view.bounds;
}

- (void)initialize {
    cameraSession = [[CameraSession alloc] initWithDelegate:self];
    
    boardGame = [[BoardGame alloc] initWithLevel:0];
    boardRecognizer = [[BoardRecognizer alloc] init];
}

- (void)initializeGui {
    boardView = [[BoardView alloc] initWithFrame:[ExternalDisplay instance].widescreenBounds];
    [self.view addSubview:boardView];

    calibrationView = [[CalibrationView alloc] initWithFrame:[ExternalDisplay instance].widescreenBounds];
    [self.view addSubview:calibrationView];

    [self setupCameraPreview];
}

- (void)setupCameraPreview {
    cameraPreview = [[UIView alloc] initWithFrame:self.view.bounds];
    cameraPreview.hidden = [ExternalDisplay instance].externalDisplayFound;
    [self.view addSubview:cameraPreview];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 30.0f)];
    label.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.2f];
    label.textColor = [UIColor yellowColor];
    label.text = @"CAMERA PREVIEW";
    [label sizeToFit];
    [cameraPreview addSubview:label];
}

- (void)processFrame:(UIImage *)image {
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.0f];
    if (cameraSession.initialized) {
        cameraPreview.layer.contents = (__bridge_transfer id)image.CGImage;
    } else {
        cameraPreview.layer.contents = (id)image.CGImage;
    }
    [CATransaction commit];
    cameraSession.readyToProcessFrame = YES;
}

- (UIImage *)requestSimulatedImageIfNoCamera {
    cameraPreview.hidden = YES;
    UIImage *image = [UIImage imageWithView:self.view];
    cameraPreview.hidden = NO;
    return image;
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
