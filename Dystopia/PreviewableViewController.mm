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

#import "PreviewableViewController.h"
#import "ExternalDisplay.h"
#import "BoardUtil.h"
#import "CameraUtil.h"

PreviewableViewController *previewInstance = nil;

@interface PreviewableViewController () {
    UIImageView *cameraPreview;
    CAShapeLayer *boardBoundsLayer;
    
    UIImageView *boardPreview;
    
    UIButton *boardButton;
    UIButton *cameraPreviewButton;
}

@end

@implementation PreviewableViewController

@synthesize overlayView;

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupPreview];
}

- (void)viewWillLayoutSubviews {
    overlayView.frame = self.view.bounds;
    boardPreview.frame = self.view.bounds;
    cameraPreview.frame = self.view.bounds;
    boardBoundsLayer.frame = self.view.bounds;
    
    [self setButtonFrame:boardButton x:75.0f];
    [self setButtonFrame:cameraPreviewButton x:(self.view.bounds.size.width - 75.0f)];
}

- (void)setupPreview {
    overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
    overlayView.hidden = [ExternalDisplay instance].externalDisplayFound;
    overlayView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:overlayView];
    
    cameraPreview = [[UIImageView alloc] initWithFrame:self.view.bounds];
    cameraPreview.contentMode = UIViewContentModeScaleToFill;
    cameraPreview.hidden = NO;
    [overlayView addSubview:cameraPreview];

    boardPreview = [[UIImageView alloc] initWithFrame:self.view.bounds];
    boardPreview.contentMode = UIViewContentModeScaleToFill;
    boardPreview.hidden = YES;
    [overlayView addSubview:boardPreview];

    [self addBoardBoundsLayer];
    [self addCameraPreviewLabel];
    [self addBoardPreviewLabel];

    boardButton = [self addButtonWithText:@"Board"];
    cameraPreviewButton = [self addButtonWithText:@"Camera"];
    
    [boardButton addTarget:self action:@selector(boardButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cameraPreviewButton addTarget:self action:@selector(cameraPreviewButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    cameraPreviewButton.enabled = NO;
}

- (void)boardButtonPressed:(id)sender {
    boardPreview.hidden = NO;
    cameraPreview.hidden = YES;
    boardButton.enabled = NO;
    cameraPreviewButton.enabled = YES;
}

- (void)cameraPreviewButtonPressed:(id)sender {
    boardPreview.hidden = YES;
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

- (void)addCameraPreviewLabel {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 30.0f)];
    label.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.2f];
    label.textColor = [UIColor yellowColor];
    label.text = @"CAMERA PREVIEW";
    [label sizeToFit];
    [cameraPreview addSubview:label];
}

- (void)addBoardPreviewLabel {
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.view.bounds.size.width, 30.0f)];
    label.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.2f];
    label.textColor = [UIColor yellowColor];
    label.text = @"BOARD PREVIEW";
    [label sizeToFit];
    [boardPreview addSubview:label];
}

- (void)addBoardBoundsLayer {
    boardBoundsLayer = [CAShapeLayer layer];
    boardBoundsLayer.frame = self.view.bounds;
    boardBoundsLayer.fillColor = [UIColor colorWithRed:1.0f green:0.0f blue:1.0f alpha:0.25f].CGColor;
    boardBoundsLayer.strokeColor = [UIColor colorWithRed:1.0f green:0.0f blue:1.0f alpha:1.0f].CGColor;
    boardBoundsLayer.backgroundColor = [UIColor clearColor].CGColor;
    [cameraPreview.layer addSublayer:boardBoundsLayer];
}

- (void)previewFrame:(UIImage *)image boardCalibrator:(BoardCalibrator *)boardCalibrator {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self previewCamera:image];
        [self previewBoard:image boardCalibrator:boardCalibrator];
        [self previewBoardBounds:boardCalibrator.boardBounds];
    });
}

- (void)previewCamera:(UIImage *)image {
    if (cameraPreview.hidden == NO) {
        cameraPreview.image = image;
    }
}

- (void)previewBoard:(UIImage *)image boardCalibrator:(BoardCalibrator *)boardCalibrator {
    if (boardPreview.hidden == NO) {
        if (boardCalibrator.boardBounds.defined) {
            boardPreview.image = [CameraUtil perspectiveTransformImage:image withTransformation:boardCalibrator.boardCameraToScreenTransformation];
        } else {
            boardPreview.image = image;
        }
    }
}

- (void)hideBoardBounds {
    dispatch_async(dispatch_get_main_queue(), ^{
        boardBoundsLayer.hidden = YES;
    });
}

- (void)previewBoardBounds:(FourPoints)boardPoints {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!boardPoints.defined) {
            boardBoundsLayer.hidden = YES;
            return;
        }
        boardBoundsLayer.hidden = NO;
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.0f];

        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:[self scalePointToScreen:boardPoints.p1]];
        [path addLineToPoint:[self scalePointToScreen:boardPoints.p2]];
        [path addLineToPoint:[self scalePointToScreen:boardPoints.p3]];
        [path addLineToPoint:[self scalePointToScreen:boardPoints.p4]];
        [path closePath];

        boardBoundsLayer.path = path.CGPath;
        [CATransaction commit];
    });
}

- (CGPoint)scalePointToScreen:(CGPoint)p {
    return CGPointMake(p.x * boardBoundsLayer.frame.size.width / cameraPreview.image.size.width, p.y * boardBoundsLayer.frame.size.height / cameraPreview.image.size.height);
}

@end
