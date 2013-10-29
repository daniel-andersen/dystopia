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

#import "ConnectionView.h"
#import "Board.h"
#import "BoardUtil.h"
#import "ExternalDisplay.h"

@interface ConnectionView () {
    UIImage *gradientImage;
    int gradientExtent;
    UIView *blackOverlayView;
}

@end

@implementation ConnectionView

@synthesize position1;
@synthesize position2;

@synthesize brickView1;
@synthesize brickView2;

@synthesize type;

@synthesize visible;
@synthesize open;

@synthesize connectionMaskLayer;
@synthesize connectionGradientView;

@synthesize maskView;

- (id)initWithPosition1:(cv::Point)p1 position2:(cv::Point)p2 type:(int)t {
    if (self = [super initWithFrame:[[BoardUtil instance] bricksScreenRectPosition1:p1 position2:p2]]) {
        position1 = p1;
        position2 = p2;
        type = t;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    brickView1 = [[Board instance] brickViewAtPosition:position1];
    brickView2 = [[Board instance] brickViewAtPosition:position2];
    maskView = [[UIView alloc] init];
    maskView.hidden = YES;
    self.backgroundColor = [UIColor clearColor];
    self.hidden = YES;
    self.alpha = 0.0f;
    visible = NO;
    open = NO;
}

- (void)show {
    if (visible) {
        return;
    }
    visible = YES;
    if (type == CONNECTION_TYPE_VIEW_GLUE) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hidden = NO;
        [UIView animateWithDuration:BRICKVIEW_OPEN_DOOR_DURATION animations:^{
            self.alpha = 1.0f;
            blackOverlayView.alpha = 0.0f;
        }];
    });
}

- (void)openConnection {
    if (open) {
        return;
    }
    open = YES;
    visible = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hidden = NO;
        [UIView animateWithDuration:BRICKVIEW_OPEN_DOOR_DURATION animations:^{
            maskView.alpha = 0.0f;
            //connectionGradientView.transform = CGAffineTransformRotate(connectionGradientView.transform, M_PI_2);
        } completion:^(BOOL finished) {
            maskView.hidden = YES;
        }];
    });
}

- (void)reveilConnectionForBrickView:(BrickView *)brickView withConnectedViews:(NSArray *)connectedViews {
    if (visible) {
        return;
    }
    [self createMaskViewWithView:brickView connectedViews:connectedViews];
    for (BrickView *brickView in connectedViews) {
        [brickView reveil];
    }
    [self show];
}

- (bool)isNextToBrickView:(BrickView *)brickView {
    return brickView == brickView1 || brickView == brickView2;
}

- (bool)isAtPosition:(cv::Point)p {
    return p == position1 || p == position2;
}

- (bool)canOpen {
    return !open && type != CONNECTION_TYPE_VIEW_GLUE;
}

- (void)addGradientViewWithImage:(UIImage *)image extent:(int)extent {
    gradientImage = image;
    gradientExtent = extent;
}

- (void)createMaskViewWithView:(BrickView *)brickView connectedViews:(NSArray *)brickViews {
    maskView.frame = [[BoardUtil instance] brickViewsBoundingRect:brickViews];
    maskView.backgroundColor = [UIColor clearColor];
    maskView.clipsToBounds = YES;
    
    [self setupMaskLayerWithViews:brickViews];
    [self setupGradientViewForPosition:(brickView == brickView1 ? position1 : position2)];
    [self setupBlackOverlayViews];

    maskView.hidden = NO;
}

- (void)setupMaskLayerWithViews:(NSArray *)brickViews {
    connectionMaskLayer = [CALayer layer];
    connectionMaskLayer.frame = maskView.bounds;
    connectionMaskLayer.backgroundColor = [UIColor clearColor].CGColor;
    connectionMaskLayer.contents = (id)[self maskOutBrickViews:brickViews].CGImage;
    maskView.layer.mask = connectionMaskLayer;
}

- (void)setupGradientViewForPosition:(cv::Point)p {
    if (gradientImage == nil) {
        return;
    }
    CGRect rect = [self brickMaskRectPosition1:[self topLeftWithPosition:p extent:gradientExtent] position2:[self bottomRightWithPosition:p extent:gradientExtent]];
    if (p.x > MIN(self.position1.x, self.position2.x)) {
        rect.origin.x -= [BoardUtil instance].singleBrickScreenSize.width / 2.0f;
    }
    if (p.x < MAX(self.position1.x, self.position2.x)) {
        rect.origin.x += [BoardUtil instance].singleBrickScreenSize.width / 2.0f;
    }
    if (p.y > MIN(self.position1.y, self.position2.y)) {
        rect.origin.y -= [BoardUtil instance].singleBrickScreenSize.height / 2.0f;
    }
    if (p.y < MAX(self.position1.y, self.position2.y)) {
        rect.origin.y += [BoardUtil instance].singleBrickScreenSize.height / 2.0f;
    }
    rect.origin.x -= [BoardUtil instance].singleBrickScreenSize.width / 2.0f;
    rect.origin.y -= [BoardUtil instance].singleBrickScreenSize.height / 2.0f;

    connectionGradientView = [[UIImageView alloc] initWithFrame:rect];
    connectionGradientView.backgroundColor = [UIColor clearColor];
    connectionGradientView.image = gradientImage;
    connectionGradientView.contentMode = UIViewContentModeScaleToFill;
    [self rotateGradientViewForPosition:p];
    [maskView addSubview:connectionGradientView];
}

- (void)rotateGradientViewForPosition:(cv::Point)p {
    /*if (p.x > MIN(self.position1.x, self.position2.x)) {
        connectionGradientView.transform = CGAffineTransformMakeRotation(0.0f);
    }
    if (p.x < MAX(self.position1.x, self.position2.x)) {
        connectionGradientView.transform = CGAffineTransformMakeRotation(M_PI);
    }
    if (p.y > MIN(self.position1.y, self.position2.y)) {
        connectionGradientView.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    if (p.y < MAX(self.position1.y, self.position2.y)) {
        connectionGradientView.transform = CGAffineTransformMakeRotation(M_PI + M_PI_2);
    }*/
}

- (void)setupBlackOverlayViews {
    CGPoint p1 = CGPointMake(connectionGradientView.frame.origin.x, connectionGradientView.frame.origin.y);
    CGPoint p2 = CGPointMake(connectionGradientView.frame.origin.x + connectionGradientView.frame.size.width, connectionGradientView.frame.origin.y + connectionGradientView.frame.size.height);
    
    blackOverlayView = [self addBlackViewWithP1:CGPointMake(0.0f, 0.0f) p2:CGPointMake(maskView.bounds.size.width, maskView.bounds.size.height)];
    
    [self addBlackViewWithP1:CGPointMake(0.0f, 0.0f) p2:CGPointMake(maskView.bounds.size.width, p1.y)];
    [self addBlackViewWithP1:CGPointMake(0.0f, p2.y) p2:CGPointMake(maskView.bounds.size.width, maskView.bounds.size.height)];
    [self addBlackViewWithP1:CGPointMake(0.0f, p1.y) p2:CGPointMake(p1.x, p2.y)];
    [self addBlackViewWithP1:CGPointMake(p2.x, p1.y) p2:CGPointMake(maskView.bounds.size.width, p2.y)];
}

- (UIImage *)maskOutBrickViews:(NSArray *)brickViews {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 1.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0.0f alpha:1.0f].CGColor);
    
    for (BrickView *brickView in brickViews) {
        CGContextFillRect(context, [self brickMaskRect:brickView]);
    }
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}

- (UIView *)addBlackViewWithP1:(CGPoint)p1 p2:(CGPoint)p2 {
    float width = p2.x - p1.x;
    float height = p2.y - p1.y;
    if (width <= 0 || height <= 0) {
        return nil;
    }
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(p1.x, p1.y, width, height)];
    view.backgroundColor = [UIColor blackColor];
    [maskView addSubview:view];
    return view;
}

- (cv::Point)topLeftWithPosition:(cv::Point)p extent:(int)extent {
    return cv::Point(MAX(p.x - extent, 1), MAX(p.y - extent, 1));
}

- (cv::Point)bottomRightWithPosition:(cv::Point)p extent:(int)extent {
    return cv::Point(MIN(p.x + 1 + extent, BOARD_WIDTH - 2), MIN(p.y + 1 + extent, BOARD_HEIGHT - 2));
}

- (CGRect)brickMaskRect:(BrickView *)brickView {
    CGRect brickRect = [[BoardUtil instance] brickTypeFrame:brickView.type position:brickView.position];
    brickRect.origin.x -= maskView.frame.origin.x;
    brickRect.origin.y -= maskView.frame.origin.y;
    return brickRect;
}

- (CGRect)brickMaskRectPosition1:(cv::Point)p1 position2:(cv::Point)p2 {
    CGRect screenRect = [[BoardUtil instance] bricksScreenRectPosition1:p1 position2:p2];
    screenRect.origin.x -= maskView.frame.origin.x;
    screenRect.origin.y -= maskView.frame.origin.y;
    return screenRect;
}

@end
