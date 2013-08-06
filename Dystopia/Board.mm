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

- (void)setupBrickViews {
    brickViewsCount = 0;
    brickViews[brickViewsCount++] = [[BrickView alloc] initWithFrame:[[BoardUtil instance] brickTypeFrame:0 position:CGPointMake(5, 5)] brickType:0];
    brickViews[brickViewsCount++] = [[BrickView alloc] initWithFrame:[[BoardUtil instance] brickTypeFrame:1 position:CGPointMake(8, 5)] brickType:1];
    brickViews[brickViewsCount++] = [[BrickView alloc] initWithFrame:[[BoardUtil instance] brickTypeFrame:2 position:CGPointMake(5, 8)] brickType:2];
    for (int i = 0; i < brickViewsCount; i++) {
        [self addSubview:brickViews[i]];
    }
}

@end
