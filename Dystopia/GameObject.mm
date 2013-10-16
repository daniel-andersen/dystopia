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

#import "GameObject.h"
#import "BoardUtil.h"
#import "Board.h"

#define MARKER_BLINKING_SPEED 0.5f

@interface GameObject () {
}

@end

@implementation GameObject

@synthesize position;
@synthesize recognizedOnBoard;
@synthesize brickView;
@synthesize markerView;
@synthesize active;
@synthesize type;

- (id)initWithPosition:(cv::Point)p type:(int)t {
    if (self = [super init]) {
        position = p;
        type = t;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.frame = [[BoardUtil instance] brickScreenRect:position];
    [self initializeBrickView];
    [self initializeMarkerView];
    recognizedOnBoard = NO;
}

- (void)initializeBrickView {
    brickView = [[AnimatableBrickView alloc] init];
    brickView.alpha = 0.0f;
    [self addSubview:brickView];
}

- (void)initializeMarkerView {
    markerView = [[AnimatableBrickView alloc] init];
    markerView.viewAlpha = 0.7f;
    markerView.pulseAlpha = 0.3f;
    markerView.image = [UIImage imageNamed:@"brick_marker.png"];
    markerView.alpha = 0.0f;
    [self addSubview:markerView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (!brickView.animating) {
        brickView.frame = [self brickFrame];
    }
    if (!markerView.animating) {
        markerView.frame = [self markerFrame];
    }
}

- (CGRect)brickFrame {
    return CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
}

- (CGRect)markerFrame {
    return CGRectMake(-self.frame.size.width / 2.0f, -self.frame.size.height / 2.0f, self.frame.size.width * 2.0f, self.frame.size.height * 2.0f);
}

- (void)showBrick {
    [brickView show];
}

- (void)hideBrick {
    [brickView hide];
}

- (void)showMarker {
    [markerView show];
}

- (void)hideMarker {
    [markerView hide];
}

- (void)startMarkerPulsing {
    [markerView startPulsing];
}

- (void)stopMarkerPulsing {
    [markerView stopPulsing];
}

- (bool)isValidPosition:(cv::Point)p {
    return p.x >= 0 && p.y >= 0 && p.x < BOARD_WIDTH && p.y < BOARD_HEIGHT;
}

@end



@implementation MoveableGameObject

@synthesize movementLength;

- (void)moveToPosition:(cv::Point)p {
    self.position = p;
    self.frame = [[BoardUtil instance] brickScreenRect:self.position];
}

- (cv::vector<cv::Point>)moveablePositions {
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return cv::vector<cv::Point>();
}

- (cv::vector<cv::Point>)floodFillMoveablePositions {
    typedef struct {
        cv::Point position;
        int movementCount;
    } PositionQueueElement;
    
    int movementBoard[BOARD_HEIGHT][BOARD_WIDTH];
    for (int i = 0; i < BOARD_HEIGHT; i++) {
        for (int j = 0; j < BOARD_WIDTH; j++) {
            cv::Point p = cv::Point(j, i);
            movementBoard[i][j] = [[Board instance] hasBrickAtPosition:p] && ![[Board instance] hasObjectAtPosition:p] ? 0 : -1;
        }
    }
    movementBoard[self.position.y][self.position.x] = 0;
    
    cv::vector<cv::Point> positions;
    cv::vector<PositionQueueElement> positionQueue;
    positionQueue.push_back(PositionQueueElement {.position = self.position, .movementCount = 0});

    int DIR_X[4] = {-1, 1,  0, 0};
    int DIR_Y[4] = { 0, 0, -1, 1};
    
    int queueIndex = 0;
    while (positionQueue.size() > 0 && queueIndex < positionQueue.size()) {
        PositionQueueElement e = positionQueue[queueIndex++];
        if (movementBoard[e.position.y][e.position.x] != 0) {
            continue;
        }
        movementBoard[e.position.y][e.position.x] = 1;
        positions.push_back(e.position);

        for (int i = 0; i < 4; i++) {
            cv::Point p = cv::Point(e.position.x + DIR_X[i], e.position.y + DIR_Y[i]);
            if ([self isValidPosition:p] && [self canMoveToLocation:p withMovementCount:(e.movementCount + 1)]) {
                positionQueue.push_back(PositionQueueElement {.position = p, e.movementCount + 1});
            }
        }
    }
    return positions;
}

- (bool)canMoveToLocation:(cv::Point)location withMovementCount:(int)movementCount {
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return NO;
}

@end
