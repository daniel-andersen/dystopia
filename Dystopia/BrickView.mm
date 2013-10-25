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

#import "BrickView.h"
#import "BoardUtil.h"
#import "Board.h"

@interface BrickView () {
    CALayer *connectionMaskLayer;
}

@end

@implementation BrickView

@synthesize type;
@synthesize position;
@synthesize size;
@synthesize visible;

- (id)initWithPosition:(cv::Point)p type:(int)t {
    if (self = [super initWithFrame:[[BoardUtil instance] brickTypeFrame:t position:p]]) {
        position = p;
        type = t;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.size = [[BoardUtil instance] brickTypeBoardSize:type];
    self.layer.contents = (id)[[BoardUtil instance] brickImageOfType:type].CGImage;
    self.hidden = YES;
    visible = NO;
}

/*- (void)createConnectionOverlay {
    connectionMaskLayer = [CALayer layer];
    connectionMaskLayer.backgroundColor = [UIColor clearColor].CGColor;
    connectionMaskLayer.frame = self.layer.bounds;
    self.layer.mask = connectionMaskLayer;
}

- (void)reveilConnectionFromPosition:(cv::Point)p1 toPosition:(cv::Point)p2 {
    if (visible) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self setupGradientFromPosition:p1 toPosition:p2];
        self.alpha = 0.0f;
        self.hidden = NO;
        [UIView animateWithDuration:BRICKVIEW_OPEN_DOOR_DURATION animations:^{
            self.alpha = 1.0f;
        }];
    });
}

- (void)setupGradientFromPosition:(cv::Point)p1 toPosition:(cv::Point)p2 {
    CGPoint p = [[BoardUtil instance] brickScreenPosition:cv::Point(p2.x - self.position.x, p2.y - self.position.y)];
    connectionMaskLayer.backgroundColor = [UIColor clearColor].CGColor;
    connectionMaskLayer.contents = (id)[Util radialGradientWithSize:self.bounds.size centerPosition:p radius:MAX(self.bounds.size.width, self.bounds.size.height)].CGImage;
}*/

- (void)reveil {
    self.hidden = NO;
}

- (void)show {
    self.hidden = NO;
    visible = YES;
    
    /*if (visible) {
        return;
    }
    visible = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hidden = NO;
        [UIView animateWithDuration:BRICKVIEW_OPEN_DOOR_DURATION animations:^{
            [CATransaction begin];
            [CATransaction setAnimationDuration:BRICKVIEW_OPEN_DOOR_DURATION];
            //self.alpha = 1.0f;
            connectionMaskLayer.backgroundColor = [UIColor blackColor].CGColor;
            [CATransaction commit];
        }];
    });*/
}

- (bool)containsPosition:(cv::Point)p {
    return p.x >= position.x && p.y >= position.y && p.x < position.x + size.width && p.y < position.y + size.height;
}

@end
