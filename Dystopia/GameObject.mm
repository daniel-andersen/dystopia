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

@interface GameObject () {
}

@end

@implementation GameObject

@synthesize position;
@synthesize brickView;
@synthesize markerView;

- (id)initWithPosition:(cv::Point)p {
    if (self = [super init]) {
        position = p;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.frame = [[BoardUtil instance] brickScreenRect:position];
    [self initializeBrickView];
    [self initializeMarkerView];
}

- (void)initializeBrickView {
    brickView = [[AnimatableBrickView alloc] init];
    brickView.layer.opacity = 0.0f;
    brickView.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
    [self addSubview:brickView];
}

- (void)initializeMarkerView {
    markerView = [[AnimatableBrickView alloc] init];
    markerView.layer.opacity = 0.0f;
    markerView.layer.anchorPoint = CGPointMake(0.5f, 0.5f);
    markerView.layer.contents = (id)[UIImage imageNamed:@"brick_marker.png"].CGImage;
    [self addSubview:markerView];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    brickView.frame = [self brickFrame];
    markerView.frame = [self markerFrame];
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

@end



@implementation MoveableGameObject

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
            movementBoard[i][j] = 0;
        }
    }
    
    cv::vector<cv::Point> positions;
    cv::vector<PositionQueueElement> positionQueue;
    positionQueue.push_back(PositionQueueElement {.position = self.position, .movementCount = 0});

    int queueIndex = 0;
    while (positionQueue.size() > 0 && queueIndex < positionQueue.size()) {
        PositionQueueElement e = positionQueue[queueIndex++];
        if (movementBoard[e.position.y][e.position.x] != 0) {
            continue;
        }
        movementBoard[e.position.y][e.position.x] = 1;
        positions.push_back(e.position);

        if ([self canMoveToLocation:cv::Point(e.position.x - 1, e.position.y) withMovementCount:(e.movementCount + 1)]) {
            positionQueue.push_back(PositionQueueElement {.position = cv::Point(e.position.x - 1, e.position.y), e.movementCount + 1});
        }
        if ([self canMoveToLocation:cv::Point(e.position.x + 1, e.position.y) withMovementCount:(e.movementCount + 1)]) {
            positionQueue.push_back(PositionQueueElement {.position = cv::Point(e.position.x + 1, e.position.y), e.movementCount + 1});
        }
        if ([self canMoveToLocation:cv::Point(e.position.x, e.position.y - 1) withMovementCount:(e.movementCount + 1)]) {
            positionQueue.push_back(PositionQueueElement {.position = cv::Point(e.position.x, e.position.y - 1), e.movementCount + 1});
        }
        if ([self canMoveToLocation:cv::Point(e.position.x, e.position.y + 1) withMovementCount:(e.movementCount + 1)]) {
            positionQueue.push_back(PositionQueueElement {.position = cv::Point(e.position.x, e.position.y + 1), e.movementCount + 1});
        }
    }
    return positions;
}

- (bool)canMoveToLocation:(cv::Point)location withMovementCount:(int)movementCount {
    [NSException raise:NSInternalInconsistencyException format:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)];
    return NO;
}

@end
