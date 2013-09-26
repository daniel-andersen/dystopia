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

#import "Board.h"
#import "BorderView.h"

@interface Board () {
    int bricks[BOARD_WIDTH][BOARD_HEIGHT];
    
    BrickView *brickViews[BOARD_BRICK_VIEWS_COUNT];
    int brickViewsCount;

    BorderView *borderView;
    
    int level;
}

@end

@implementation Board

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.backgroundColor = [UIColor blackColor];
    NSLog(@"Board initialized");
}

- (void)loadLevel:(int)l {
    level = l;
    [self loadBoard];
    [self setupBorderView];
    [self setupBrickViews];
    NSLog(@"Level %i loaded", level + 1);
}

- (void)loadBoard {
    for (int i = 0; i < BOARD_HEIGHT; i++) {
        for (int j = 0; j < BOARD_WIDTH; j++) {
            bricks[i][j] = -1;
        }
    }
}

- (void)setupBorderView {
    borderView = [[BorderView alloc] initWithFrame:self.bounds];
    [self addSubview:borderView];
}

- (void)setupBrickViews {
    brickViewsCount = 0;
    [self addBrickOfType:2 atPosition:cv::Point(6, 3)];
    [self addBrickOfType:8 atPosition:cv::Point(7, 6)];
    [self addBrickOfType:8 atPosition:cv::Point(7, 9)];
    [self addBrickOfType:8 atPosition:cv::Point(7, 12)];
    [self addBrickOfType:2 atPosition:cv::Point(6, 15)];
    [self addBrickOfType:5 atPosition:cv::Point(8, 10)];
    [self addBrickOfType:5 atPosition:cv::Point(11, 10)];
    [self addBrickOfType:1 atPosition:cv::Point(14, 9)];
    for (int i = 0; i < brickViewsCount; i++) {
        [self addSubview:brickViews[i]];
    }
}

- (void)addBrickOfType:(int)type atPosition:(cv::Point)position {
    brickViews[brickViewsCount++] = [[BrickView alloc] initWithFrame:[[BoardUtil instance] brickTypeFrame:type position:position] brickType:type];
    CGSize size = [[BoardUtil instance] brickTypeBoardSize:type];
    for (int i = 0; i < size.height; i++) {
        for (int j = 0; j< size.width; j++) {
            bricks[i + (int)position.y][j + (int)position.x] = type;
        }
    }
}

- (bool)hasBrickAtPosition:(cv::Point)position {
    return position.x >= 0 && position.y >= 0 && position.x < BOARD_WIDTH && position.y < BOARD_HEIGHT && bricks[position.y][position.x] != -1;
}

@end
