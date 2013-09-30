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
#import "ExternalDisplay.h"
#import "PreviewableViewController.h"

@interface BoardGame () {
    int level;
    id<BoardGameProtocol> delegate;
    
    Board *board;

    UIView *boardRecognizedView;
    
    UIView *tmpBrickPositionView[4];
    UIView *tmpBrickView;
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
    
    tmpBrickView = [[UIView alloc] initWithFrame:CGRectMake([[BoardUtil instance] singleBrickScreenSize].width * 7.0f, [[BoardUtil instance] singleBrickScreenSize].height * 10.0f, [[BoardUtil instance] singleBrickScreenSize].width, [[BoardUtil instance] singleBrickScreenSize].height)];
    tmpBrickView.backgroundColor = [UIColor blackColor];
    tmpBrickView.hidden = [ExternalDisplay instance].externalDisplayFound;
    [self addSubview:tmpBrickView];

    for (int i = 0; i < 4; i++) {
        tmpBrickPositionView[i] = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, [[BoardUtil instance] singleBrickScreenSize].width * 2.0f, [[BoardUtil instance] singleBrickScreenSize].height * 2.0f)];
        tmpBrickPositionView[i].layer.contents = (id)[UIImage imageNamed:@"brick_marker.png"].CGImage;
        tmpBrickPositionView[i].hidden = YES;
        [self addSubview:tmpBrickPositionView[i]];
    }
}

- (void)startWithLevel:(int)l {
    level = l;
    [board loadLevel:level];
    NSTimer* timer = [NSTimer timerWithTimeInterval:0.1f target:self selector:@selector(update) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
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
    cv::vector<float> probs;
    @synchronized([BoardCalibrator instance].boardImageLock) {
        probs = [[BrickRecognizer instance] probabilitiesOfBricksAtLocations:bricks inImage:[BoardCalibrator instance].boardImage];
    }
    int bestX[4] = {-1, -1, -1, -1};
    int bestY[4] = {-1, -1, -1, -1};
    float bestProb[4] = {-1.0f, -1.0f, -1.0f, -1.0f};
    int idx = 0;
    for (int y = 0; y < BOARD_HEIGHT; y++) {
        for (int x = 0; x < BOARD_WIDTH; x++) {
            if ([board hasBrickAtPosition:cv::Point(x, y)]) {
                if (probs[idx] > bestProb[3]) {
                    bestProb[3] = probs[idx];
                    bestX[3] = x;
                    bestY[3] = y;
                    for (int j = 2; j >= 0; j--) {
                        if (bestProb[j + 1] > bestProb[j]) {
                            float tmpProb = bestProb[j];
                            int tmpX = bestX[j];
                            int tmpY = bestY[j];
                            bestProb[j] = bestProb[j + 1];
                            bestX[j] = bestX[j + 1];
                            bestY[j] = bestY[j + 1];
                            bestProb[j + 1] = tmpProb;
                            bestX[j + 1] = tmpX;
                            bestY[j + 1] = tmpY;
                        }
                    }
                }
                idx++;
            }
        }
    }
    
    [CATransaction begin];
    [CATransaction setAnimationDuration:0.0f];
    for (int i = 0; i < 4; i++) {
        tmpBrickPositionView[i].alpha = bestX[i] == -1 || bestY[i] == -1 ? 0.5f : 1.0f;
    }
    [CATransaction commit];

    [CATransaction begin];
    [CATransaction setAnimationDuration:0.0f];
    for (int i = 0; i < 4; i++) {
        if (bestX[i] == -1 || bestY[i] == -1) {
            continue;
        }
        tmpBrickPositionView[i].hidden = NO;
    
        cv::Point pos = cv::Point(bestX[i], bestY[i]);
        CGPoint p = [[BoardUtil instance] brickScreenPosition:pos];
        p.x -= (tmpBrickPositionView[i].frame.size.width - [[BoardUtil instance] singleBrickScreenSize].width) / 2.0f;
        p.y -= (tmpBrickPositionView[i].frame.size.height - [[BoardUtil instance] singleBrickScreenSize].height) / 2.0f;
        tmpBrickPositionView[i].frame = CGRectMake(p.x, p.y, tmpBrickPositionView[i].frame.size.width, tmpBrickPositionView[i].frame.size.height);
    }
    [CATransaction commit];

    if (bestX[0] != -1 && bestY[0] != -1) {
        [[PreviewableViewController instance] previewProbabilityOfBrick:bestProb[0] x:bestX[0] y:bestY[0]];
    }
}

@end
