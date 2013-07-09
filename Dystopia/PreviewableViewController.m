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

#import <QuartzCore/QuartzCore.h>

#import "PreviewableViewController.h"
#import "ExternalDisplay.h"

@implementation PreviewableViewController

@synthesize overlayView;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupCameraPreview];
}

- (void)viewWillLayoutSubviews {
    overlayView.frame = self.view.bounds;
    cameraPreview.frame = self.view.bounds;
    [self setButtonFrame:boardButton x:200.0f];
    [self setButtonFrame:cameraPreviewButton x:(self.view.bounds.size.width - 200.0f)];
}

- (void)setupCameraPreview {
    overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
    overlayView.hidden = [ExternalDisplay instance].externalDisplayFound;
    [self.view addSubview:overlayView];
    
    cameraPreview = [[UIView alloc] initWithFrame:self.view.bounds];
    [overlayView addSubview:cameraPreview];

    [self addPreviewLabel];

    boardButton = [self addButtonWithText:@"Board"];
    cameraPreviewButton = [self addButtonWithText:@"Camera"];
    
    [boardButton addTarget:self action:@selector(boardButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cameraPreviewButton addTarget:self action:@selector(cameraPreviewButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    cameraPreviewButton.enabled = NO;
}

- (void)boardButtonPressed:(id)sender {
    cameraPreview.hidden = YES;
    boardButton.enabled = NO;
    cameraPreviewButton.enabled = YES;
}

- (void)cameraPreviewButtonPressed:(id)sender {
    cameraPreview.hidden = NO;
    boardButton.enabled = YES;
    cameraPreviewButton.enabled = NO;
}

- (UIButton *)addButtonWithText:(NSString *)text {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:text forState:UIControlStateNormal];
    [overlayView addSubview:button];
    return button;
}

- (void)setButtonFrame:(UIButton *)button x:(float)x {
    float buttonWidth = 100.0f;
    float buttonHeight = 30.0f;
    button.frame = CGRectMake(x - (buttonWidth / 2.0f), self.view.bounds.size.height - 10.0f - buttonHeight, buttonWidth, buttonHeight);
}

- (void)addPreviewLabel {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 30.0f)];
    label.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.2f];
    label.textColor = [UIColor yellowColor];
    label.text = @"CAMERA PREVIEW";
    [label sizeToFit];
    [cameraPreview addSubview:label];
}

- (void)previewFrame:(UIImage *)image hasCameraSession:(bool)cameraSession {
    if (cameraPreview.hidden) {
        return;
    }
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.0f];
    if (cameraSession) {
        cameraPreview.layer.contents = (__bridge_transfer id)image.CGImage;
    } else {
        cameraPreview.layer.contents = (id)image.CGImage;
    }
    [CATransaction commit];
}

@end
