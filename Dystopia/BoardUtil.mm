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

#import "BoardUtil.h"
#import "ExternalDisplay.h"

BoardUtil *boardUtilInstance = nil;

@interface BoardUtil () {
    UIImage *brickImages[BRICK_IMAGES_COUNT];
    CGSize brickSizes[BRICK_IMAGES_COUNT];
}

@end

@implementation BoardUtil

+ (BoardUtil *)instance {
    @synchronized(self) {
        if (boardUtilInstance == nil) {
            boardUtilInstance = [[BoardUtil alloc] init];
        }
        return boardUtilInstance;
    }
}

- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    [self loadBricks];
}

- (void)loadBricks {
    brickImages[0] = [UIImage imageNamed:@"bricks1.png"]; brickSizes[0] = CGSizeMake(3.0f, 3.0f);
    brickImages[1] = [UIImage imageNamed:@"bricks2.png"]; brickSizes[1] = CGSizeMake(3.0f, 3.0f);
    brickImages[2] = [UIImage imageNamed:@"bricks3.png"]; brickSizes[2] = CGSizeMake(3.0f, 3.0f);
    brickImages[3] = [UIImage imageNamed:@"bricks4.png"]; brickSizes[3] = CGSizeMake(3.0f, 3.0f);
    brickImages[4] = [UIImage imageNamed:@"bricks5.png"]; brickSizes[4] = CGSizeMake(3.0f, 2.0f);
    brickImages[5] = [UIImage imageNamed:@"bricks6.png"]; brickSizes[5] = CGSizeMake(3.0f, 1.0f);
    brickImages[6] = [UIImage imageNamed:@"bricks7.png"]; brickSizes[6] = CGSizeMake(2.0f, 1.0f);
    brickImages[7] = [UIImage imageNamed:@"bricks8.png"]; brickSizes[7] = CGSizeMake(1.0f, 1.0f);
    brickImages[8] = [UIImage imageNamed:@"exit.png"];    brickSizes[8] = CGSizeMake(2.0f, 2.0f);
    brickImages[9] = [UIImage imageNamed:@"trap.png"];    brickSizes[9] = CGSizeMake(1.0f, 1.0f);
}

- (UIImage *)brickImageOfType:(int)type {
    return brickImages[type];
}

- (CGSize)singleBrickScreenSize {
    return CGSizeMake([ExternalDisplay instance].widescreenBounds.size.width / BOARD_WIDTH, [ExternalDisplay instance].widescreenBounds.size.height / BOARD_HEIGHT);
}

- (CGSize)brickTypeBoardSize:(int)type {
    return brickSizes[type];
}

- (CGSize)brickTypeScreenSize:(int)type {
    return CGSizeMake(brickSizes[type].width * [self singleBrickScreenSize].width, brickSizes[type].height * [self singleBrickScreenSize].height);
}

- (CGPoint)brickScreenPosition:(CGPoint)brickBoardPosition {
    return CGPointMake(brickBoardPosition.x * [self singleBrickScreenSize].width, brickBoardPosition.y * [self singleBrickScreenSize].height);
}

- (CGRect)brickTypeFrame:(int)brickType position:(CGPoint)position {
    return CGRectMake([self brickScreenPosition:position].x,
                      [self brickScreenPosition:position].y,
                      [self brickTypeScreenSize:brickType].width,
                      [self brickTypeScreenSize:brickType].height);
}

- (CGPoint)cvPointToCGPoint:(cv::Point)p {
    return CGPointMake(p.x, p.y);
}

@end
