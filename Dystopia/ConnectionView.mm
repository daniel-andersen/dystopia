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
#import "ExternalDisplay.h"

@interface ConnectionView () {
    UIView *topBlackView;
    UIView *bottomBlackView;
    UIView *leftBlackView;
    UIView *rightBlackView;
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

- (id)initWithPosition1:(cv::Point)p1 position2:(cv::Point)p2 type:(int)t {
    if (self = [super init]) {
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
    self.frame = CGRectMake(0.0f, 0.0f, [ExternalDisplay instance].widescreenBounds.size.width, [ExternalDisplay instance].widescreenBounds.size.height);
    self.backgroundColor = [UIColor clearColor];
    self.hidden = YES;
    visible = NO;
    open = NO;
}

- (void)show {
    visible = YES;
    if (type == CONNECTION_TYPE_VIEW_GLUE) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hidden = NO;
        [UIView animateWithDuration:BRICKVIEW_OPEN_DOOR_DURATION animations:^{
            [CATransaction begin];
            [CATransaction setAnimationDuration:BRICKVIEW_OPEN_DOOR_DURATION];
            self.alpha = 1.0f;
            [CATransaction commit];
        }];
    });
    self.hidden = NO;
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
            [CATransaction begin];
            [CATransaction setAnimationDuration:BRICKVIEW_OPEN_DOOR_DURATION];
            connectionMaskLayer.opacity = 0.0f;
            [CATransaction commit];
        } completion:^(BOOL finished) {
            self.hidden = YES;
        }];
    });
}

- (void)reveilConnectionForBrickView:(BrickView *)brickView withConnectedViews:(NSArray *)connectedViews {
    [self createOverlayMaskWithViews:connectedViews];
    for (BrickView *brickView in connectedViews) {
        [brickView reveil];
    }
    [self show];
}

- (void)createOverlayMaskWithViews:(NSArray *)brickViews {
    connectionMaskLayer = [CALayer layer];
    connectionMaskLayer.frame = self.layer.bounds;
    connectionMaskLayer.backgroundColor = [UIColor clearColor].CGColor;
    connectionMaskLayer.contents = (id)[self maskOutBrickViews:brickViews].CGImage;
    self.layer.mask = connectionMaskLayer;
}

- (UIImage *)maskOutBrickViews:(NSArray *)brickViews {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 1.0f);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor colorWithWhite:0.0f alpha:1.0f].CGColor);
    
    for (BrickView *brickView in brickViews) {
        CGContextFillRect(context, [[BoardUtil instance] brickTypeFrame:brickView.type position:brickView.position]);
    }
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
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
    connectionGradientView = [[UIImageView alloc] initWithFrame:[[BoardUtil instance] bricksScreenRectPosition1:[self topLeftWithExtent:extent] position2:[self bottomRightWithExtent:extent]]];
    connectionGradientView.backgroundColor = [UIColor clearColor];
    connectionGradientView.image = image;
    connectionGradientView.contentMode = UIViewContentModeScaleToFill;
    [self addSubview:connectionGradientView];
    [self addBlackOutsideGradient];
}

- (void)addBlackOutsideGradient {
    CGPoint p1 = CGPointMake(connectionGradientView.frame.origin.x, connectionGradientView.frame.origin.y);
    CGPoint p2 = CGPointMake(connectionGradientView.frame.origin.x + connectionGradientView.frame.size.width, connectionGradientView.frame.origin.y + connectionGradientView.frame.size.height);
    topBlackView = [self addBlackViewWithFrame:CGRectMake(0.0f, 0.0f, self.bounds.size.width, p1.y)];
    bottomBlackView = [self addBlackViewWithFrame:CGRectMake(0.0f, p2.y, self.bounds.size.width, self.bounds.size.height - p2.y)];
    leftBlackView = [self addBlackViewWithFrame:CGRectMake(0.0f, p1.y, p1.x, p2.y - p1.y)];
    rightBlackView = [self addBlackViewWithFrame:CGRectMake(p2.x, p1.y, self.bounds.size.width - p2.x, p2.y - p1.y)];
}

- (UIView *)addBlackViewWithFrame:(CGRect)frame {
    UIView *view = [[UIView alloc] initWithFrame:frame];
    view.backgroundColor = [UIColor blackColor];
    [self addSubview:view];
    return view;
}

- (cv::Point)topLeftWithExtent:(int)extent {
    return cv::Point(MAX(MIN(self.position1.x, self.position2.x) - extent, 1), MAX(MIN(self.position1.y, self.position2.y) - extent, 1));
}

- (cv::Point)bottomRightWithExtent:(int)extent {
    return cv::Point(MIN(MAX(self.position1.x, self.position2.x) + extent, BOARD_WIDTH - 2), MIN(MAX(self.position1.y, self.position2.y) + extent, BOARD_HEIGHT - 2));
}

@end
