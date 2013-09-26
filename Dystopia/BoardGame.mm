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

#import "BoardGame.h"
#import "BoardCalibrator.h"
#import "BrickRecognizer.h"

@interface BoardGame () {
    int level;
    id<BoardGameProtocol> delegate;
    
    Board *board;

    UIView *boardRecognizedView;
    
    UIView *tmpBrickPositionView;
}

@end

@implementation BoardGame

- (id)initWithFrame:(CGRect)frame delegate:(id<BoardGameProtocol>)d {
    if (self = [super initWithFrame:frame]) {
        delegate = d;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    board = [[Board alloc] initWithFrame:self.bounds];
    [self addSubview:board];
    
    tmpBrickPositionView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [[BoardUtil instance] singleBrickScreenSize].width * 2.0f, [[BoardUtil instance] singleBrickScreenSize].height * 2.0f)];
    tmpBrickPositionView.layer.contents = (id)[UIImage imageNamed:@"brick_marker.png"].CGImage;
    tmpBrickPositionView.hidden = YES;
    [self addSubview:tmpBrickPositionView];
}

- (void)startWithLevel:(int)l {
    level = l;
    [board loadLevel:level];
    [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(update) userInfo:nil repeats:YES];
    NSLog(@"Level %i started", level + 1);
}

- (void)update {
    [self calculateBrickPosition];
}

- (void)calculateBrickPosition {
    if (![BoardCalibrator instance].boardBounds.bounds.defined || [BoardCalibrator instance].boardBounds.isBoundsObstructed) {
        return;
    }
    cv::vector<cv::Point> bricks;
    for (int y = 0; y < BOARD_HEIGHT; y++) {
        for (int x = 0; x < BOARD_WIDTH; x++) {
            if ([board hasBrickAtPosition:cv::Point(x, y)]) {
                bricks.push_back(cv::Point(x, y));
            }
        }
    }
    cv::vector<float> probs = [[BrickRecognizer instance] probabilitiesOfBricksAtLocations:bricks inImage:[BoardCalibrator instance].boardImage];
    int bestX = -1;
    int bestY = -1;
    float bestProb = -1.0f;
    int idx = 0;
    for (int y = 15; y < 15 + 3; y++) {
        for (int x = 6; x < 6 + 3; x++) {
            if ([board hasBrickAtPosition:cv::Point(x, y)]) {
                if (probs[idx] > bestProb) {
                    bestProb = probs[idx];
                    bestX = x;
                    bestY = y;
                }
                idx++;
            }
        }
    }
    if (bestX == -1 || bestY == -1) {
        tmpBrickPositionView.hidden = YES;
        return;
    }
    tmpBrickPositionView.hidden = NO;

    cv::Point pos = cv::Point(bestX, bestY);
    CGPoint p = [[BoardUtil instance] brickScreenPosition:pos];
    p.x -= (tmpBrickPositionView.frame.size.width - [[BoardUtil instance] singleBrickScreenSize].width) / 2.0f;
    p.y -= (tmpBrickPositionView.frame.size.height - [[BoardUtil instance] singleBrickScreenSize].height) / 2.0f;
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.0f];
    tmpBrickPositionView.frame = CGRectMake(p.x, p.y, tmpBrickPositionView.frame.size.width, tmpBrickPositionView.frame.size.height);
    [CATransaction commit];
}

@end
