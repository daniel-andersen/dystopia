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
    boardGridLayer.frame = self.view.bounds;
    boardContourLayer.frame = self.view.bounds;
    
    [self setButtonFrame:boardButton x:75.0f];
    [self setButtonFrame:cameraPreviewButton x:(self.view.bounds.size.width - 75.0f)];
    
    [self drawBoardGrid];
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

    [self addBoardGridLayer];
    [self addBoardContourLayer];
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

- (void)addBoardGridLayer {
    boardGridLayer = [CAShapeLayer layer];
    boardGridLayer.frame = self.view.bounds;
    boardGridLayer.fillColor = [UIColor clearColor].CGColor;
    boardGridLayer.strokeColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.75f].CGColor;
    boardGridLayer.backgroundColor = [UIColor clearColor].CGColor;
    [self drawBoardGrid];
    [boardPreview.layer addSublayer:boardGridLayer];
}

- (void)addBoardContourLayer {
    boardContourLayer = [CAShapeLayer layer];
    boardContourLayer.frame = self.view.bounds;
    boardContourLayer.fillColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.35f].CGColor;
    boardContourLayer.strokeColor = [UIColor colorWithWhite:1.0f alpha:0.75f].CGColor;
    boardContourLayer.backgroundColor = [UIColor clearColor].CGColor;
    [cameraPreview.layer addSublayer:boardContourLayer];
}

- (void)previewFrame:(UIImage *)image boardCalibrator:(BoardCalibrator *)boardCalibrator {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self previewCamera:image];
        [self previewBoard:image boardCalibrator:boardCalibrator];
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
            boardPreview.image = [CameraUtil affineTransformImage:image withTransformation:boardCalibrator.boardCameraToScreenTransformation];
            boardGridLayer.hidden = NO;
        } else {
            boardPreview.image = image;
            boardGridLayer.hidden = YES;
        }
    }
}

- (void)hideBoardContour {
    dispatch_async(dispatch_get_main_queue(), ^{
        boardContourLayer.hidden = YES;
    });
}

- (void)drawBoardGrid {
    dispatch_async(dispatch_get_main_queue(), ^{
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.0f];
        
        UIBezierPath *path = [UIBezierPath bezierPath];
        for (int i = 0; i < BOARD_WIDTH; i++) {
            float x = i * self.view.bounds.size.width / BOARD_WIDTH;
            float y1 = 0.0f;
            float y2 = self.view.bounds.size.height;
            [path moveToPoint:CGPointMake(x, y1)];
            [path addLineToPoint:CGPointMake(x, y2)];
        }
        for (int i = 0; i < BOARD_HEIGHT; i++) {
            float x1 = 0;
            float x2 = self.view.bounds.size.width;
            float y = i * self.view.bounds.size.height / BOARD_HEIGHT;
            [path moveToPoint:CGPointMake(x1, y)];
            [path addLineToPoint:CGPointMake(x2, y)];
        }
        
        boardGridLayer.path = path.CGPath;
        [CATransaction commit];
    });
}

- (void)previewBoardContour:(FourPoints)boardPoints {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!boardPoints.defined) {
            boardContourLayer.hidden = YES;
        }
        boardContourLayer.hidden = NO;
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.0f];

        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:[self scalePointToScreen:boardPoints.p1]];
        [path addLineToPoint:[self scalePointToScreen:boardPoints.p2]];
        [path addLineToPoint:[self scalePointToScreen:boardPoints.p3]];
        [path addLineToPoint:[self scalePointToScreen:boardPoints.p4]];
        [path closePath];

        boardContourLayer.path = path.CGPath;
        [CATransaction commit];
    });
}

- (CGPoint)scalePointToScreen:(CGPoint)p {
    return CGPointMake(p.x * boardContourLayer.frame.size.width / cameraPreview.image.size.width, p.y * boardContourLayer.frame.size.height / cameraPreview.image.size.height);
}

@end
