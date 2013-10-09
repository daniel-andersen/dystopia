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
#import "Util.h"
#import "UIImage+OpenCV.h"

#import "BrickRecognizer.h"

PreviewableViewController *previewInstance = nil;

@interface PreviewableViewController () {
    CAShapeLayer *boardBoundsLayer;
    CAShapeLayer *boardGridLayer;
    
    CALayer *brickProbabilityLayer;
    
    UIImageView *cameraPreview;
    UIImageView *boardPreview;
    
    UIButton *boardButton;
    UIButton *cameraPreviewButton;
    UIButton *takeScreenshotButton;
    
    bool takeScreenshot;
}

@end

@implementation PreviewableViewController

@synthesize overlayView;

+ (PreviewableViewController *)instance {
    return previewInstance;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupPreview];
    takeScreenshot = NO;
}

- (void)viewWillLayoutSubviews {
    overlayView.frame = self.view.bounds;
    boardPreview.frame = self.view.bounds;
    cameraPreview.frame = self.view.bounds;
    boardBoundsLayer.frame = self.view.bounds;
    boardGridLayer.frame = self.view.bounds;
    
    [self setButtonFrame:boardButton x:75.0f];
    [self setButtonFrame:cameraPreviewButton x:(self.view.bounds.size.width - 75.0f)];
    [self setButtonFrame:takeScreenshotButton x:(self.view.bounds.size.width / 2.0f)];
}

- (void)setupPreview {
    overlayView = [[UIView alloc] initWithFrame:self.view.bounds];
    overlayView.hidden = [ExternalDisplay instance].externalDisplayFound;
    overlayView.backgroundColor = [UIColor whiteColor];
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
    [self addBoardGridLayer];
    [self addBrickProbabilityLayer];

    [self addCameraPreviewLabel];
    [self addBoardPreviewLabel];

    boardButton = [self addButtonWithText:@"Board"];
    cameraPreviewButton = [self addButtonWithText:@"Camera"];
    takeScreenshotButton = [self addButtonWithText:@"Screenshot"];
    
    [boardButton addTarget:self action:@selector(boardButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [cameraPreviewButton addTarget:self action:@selector(cameraPreviewButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [takeScreenshotButton addTarget:self action:@selector(takeScreenshotButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    cameraPreviewButton.enabled = NO;
}

- (void)boardButtonPressed:(id)sender {
    boardPreview.hidden = NO;
    cameraPreview.hidden = YES;
    boardButton.enabled = NO;
    cameraPreviewButton.enabled = YES;
    boardGridLayer.path = [self calculateBoardGrid].CGPath;
}

- (void)cameraPreviewButtonPressed:(id)sender {
    boardPreview.hidden = YES;
    cameraPreview.hidden = NO;
    boardButton.enabled = YES;
    cameraPreviewButton.enabled = NO;
}

- (void)takeScreenshotButtonPressed:(id)sender {
    takeScreenshot = YES;
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
    boardBoundsLayer.fillColor = [UIColor colorWithRed:1.0f green:0.0f blue:1.0f alpha:0.35f].CGColor;
    boardBoundsLayer.strokeColor = [UIColor colorWithRed:1.0f green:0.0f blue:1.0f alpha:1.0f].CGColor;
    boardBoundsLayer.backgroundColor = [UIColor clearColor].CGColor;
    [cameraPreview.layer addSublayer:boardBoundsLayer];
}

- (void)addBoardGridLayer {
    boardGridLayer = [CAShapeLayer layer];
    boardGridLayer.frame = self.view.bounds;
    boardGridLayer.fillColor = [UIColor clearColor].CGColor;
    boardGridLayer.strokeColor = [UIColor colorWithRed:1.0f green:0.0f blue:1.0f alpha:0.25f].CGColor;
    boardGridLayer.backgroundColor = [UIColor clearColor].CGColor;
    [boardPreview.layer addSublayer:boardGridLayer];
}

- (void)addBrickProbabilityLayer {
    brickProbabilityLayer = [CALayer layer];
    brickProbabilityLayer.frame = self.view.bounds;
    brickProbabilityLayer.backgroundColor = [UIColor clearColor].CGColor;
    [boardPreview.layer addSublayer:brickProbabilityLayer];
}

- (UIBezierPath *)calculateBoardGrid {
    UIBezierPath *boardGridPath = [UIBezierPath bezierPath];
    CGSize brickSize = CGSizeMake(self.view.bounds.size.width / BOARD_WIDTH, self.view.bounds.size.height / BOARD_HEIGHT);
    for (int i = 0; i < BOARD_WIDTH; i++) {
        [boardGridPath moveToPoint:CGPointMake(i * brickSize.width, 0.0f)];
        [boardGridPath addLineToPoint:CGPointMake(i * brickSize.width, self.view.bounds.size.height)];
    }
    for (int i = 0; i < BOARD_HEIGHT; i++) {
        [boardGridPath moveToPoint:CGPointMake(0.0f, i * brickSize.height)];
        [boardGridPath addLineToPoint:CGPointMake(self.view.bounds.size.width, i * brickSize.height)];
    }
    return boardGridPath;
}

- (CGRect)gridRectAtX:(int)x y:(int)y {
    CGSize brickSize = CGSizeMake(self.view.bounds.size.width / BOARD_WIDTH, self.view.bounds.size.height / BOARD_HEIGHT);
    return CGRectMake(x * brickSize.width, y * brickSize.height, brickSize.width, brickSize.height);
}

- (void)previewFrame:(UIImage *)image {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (takeScreenshot) {
            [self takeScreenshotFromImage:image];
            takeScreenshot = NO;
        }
        [self previewCamera:image];
        [self previewBoard:image];
        [self previewBoardBounds:[BoardCalibrator instance].boardBounds];
    });
}

- (void)previewProbabilityOfBrick:(float)probability x:(int)x y:(int)y {
    dispatch_async(dispatch_get_main_queue(), ^{
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.0f];

        brickProbabilityLayer.frame = [self gridRectAtX:x y:y];
        if (probability > 0.5f) {
            brickProbabilityLayer.backgroundColor = [UIColor colorWithRed:1.0f green:0.0f blue:1.0f alpha:probability].CGColor;
        } else {
            brickProbabilityLayer.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f].CGColor;
        }
        
        [CATransaction commit];
    });
}

- (void)previewCamera:(UIImage *)image {
    if (cameraPreview.hidden == NO) {
        cameraPreview.image = image;
    }
}

- (void)previewBoard:(UIImage *)image {
    if (boardPreview.hidden == NO) {
        cv::Mat coloredImage;
        cv::cvtColor([BoardCalibrator instance].boardImage, coloredImage, CV_GRAY2RGB);
        boardPreview.image = [UIImage imageWithCVMat:coloredImage];
    }
}

- (void)hideBoardBounds {
    dispatch_async(dispatch_get_main_queue(), ^{
        boardBoundsLayer.hidden = YES;
    });
}

- (void)previewBoardBounds:(BoardBounds)boardPoints {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!boardPoints.bounds.defined) {
            boardBoundsLayer.hidden = YES;
            return;
        }
        boardBoundsLayer.hidden = NO;
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.0f];

        UIBezierPath *path = [UIBezierPath bezierPath];
        [path moveToPoint:[self scalePointToScreen:boardPoints.bounds.p1]];
        [path addLineToPoint:[self scalePointToScreen:boardPoints.bounds.p2]];
        [path addLineToPoint:[self scalePointToScreen:boardPoints.bounds.p3]];
        [path addLineToPoint:[self scalePointToScreen:boardPoints.bounds.p4]];
        [path closePath];

        boardBoundsLayer.path = path.CGPath;
        boardBoundsLayer.fillColor = boardPoints.isBoundsObstructed ? [UIColor colorWithRed:0.5f green:0.0f blue:1.0f alpha:0.35f].CGColor : [UIColor colorWithRed:1.0f green:0.0f blue:1.0f alpha:0.35f].CGColor;
        [CATransaction commit];
    });
}

- (void)takeScreenshotFromImage:(UIImage *)image {
    NSArray *images = [[BoardRecognizer instance] boardBoundsToImages:image];
    for (int i = 0; i < images.count; i++) {
        [Util saveImage:((UIImage *)[images objectAtIndex:i]) toDocumentsFolderWithPrefix:[NSString stringWithFormat:@"%i", i]];
    }
    NSLog(@"Screenshots saved!");
}

- (CGPoint)scalePointToScreen:(CGPoint)p {
    return CGPointMake(p.x * boardBoundsLayer.frame.size.width / cameraPreview.image.size.width, p.y * boardBoundsLayer.frame.size.height / cameraPreview.image.size.height);
}

@end
