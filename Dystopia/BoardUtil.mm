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
#import "BrickView.h"

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
    brickImages[ 0] = [UIImage imageNamed:@"bricks1.png"]; brickSizes[ 0] = CGSizeMake(3.0f, 3.0f);
    brickImages[ 1] = [UIImage imageNamed:@"bricks2.png"]; brickSizes[ 1] = CGSizeMake(3.0f, 3.0f);
    brickImages[ 2] = [UIImage imageNamed:@"bricks3.png"]; brickSizes[ 2] = CGSizeMake(3.0f, 3.0f);
    brickImages[ 3] = [UIImage imageNamed:@"bricks4.png"]; brickSizes[ 3] = CGSizeMake(3.0f, 3.0f);
    brickImages[ 4] = [UIImage imageNamed:@"bricks5.png"]; brickSizes[ 4] = CGSizeMake(3.0f, 2.0f);
    brickImages[ 5] = [UIImage imageNamed:@"bricks6.png"]; brickSizes[ 5] = CGSizeMake(3.0f, 1.0f);
    brickImages[ 6] = [UIImage imageNamed:@"bricks7.png"]; brickSizes[ 6] = CGSizeMake(2.0f, 1.0f);
    brickImages[ 7] = [UIImage imageNamed:@"bricks8.png"]; brickSizes[ 7] = CGSizeMake(1.0f, 1.0f);
    brickImages[ 8] = [UIImage imageNamed:@"bricks9.png"]; brickSizes[ 8] = CGSizeMake(1.0f, 3.0f);
    brickImages[ 9] = [UIImage imageNamed:@"exit.png"];    brickSizes[ 9] = CGSizeMake(2.0f, 2.0f);
    brickImages[10] = [UIImage imageNamed:@"trap.png"];    brickSizes[10] = CGSizeMake(1.0f, 1.0f);
}

- (UIImage *)brickImageOfType:(int)type {
    return brickImages[type];
}

- (CGSize)singleBrickScreenSize {
    return CGSizeMake([ExternalDisplay instance].widescreenBounds.size.width / BOARD_WIDTH, [ExternalDisplay instance].widescreenBounds.size.height / BOARD_HEIGHT);
}

- (CGSize)singleBrickScreenSizeFromBoardSize:(CGSize)size {
    return CGSizeMake(size.width / BOARD_WIDTH, size.height / BOARD_HEIGHT);
}

- (CGSize)brickTypeBoardSize:(int)type {
    return brickSizes[type];
}

- (CGSize)brickTypeScreenSize:(int)type {
    return CGSizeMake((int)(brickSizes[type].width * [self singleBrickScreenSize].width) + 1.0f, (int)(brickSizes[type].height * [self singleBrickScreenSize].height) + 1.0f);
}

- (CGPoint)brickScreenPosition:(cv::Point)brickBoardPosition {
    return CGPointMake((int)(brickBoardPosition.x * [self singleBrickScreenSize].width) + 1.0f, (int)(brickBoardPosition.y * [self singleBrickScreenSize].height) + 1.0f);
}

- (CGRect)brickScreenRect:(cv::Point)brickBoardPosition {
    CGPoint p = [self brickScreenPosition:brickBoardPosition];
    CGSize size = [self singleBrickScreenSize];
    return CGRectMake(p.x, p.y, size.width, size.height);
}

- (CGRect)bricksScreenRectPosition1:(cv::Point)p1 position2:(cv::Point)p2 {
    CGRect r1 = [self brickScreenRect:p1];
    CGRect r2 = [self brickScreenRect:p2];
    CGPoint p = CGPointMake(MIN(r1.origin.x, r2.origin.x), MIN(r1.origin.y, r2.origin.y));
    CGSize size = CGSizeMake(MAX(r1.origin.x + r1.size.width, r2.origin.x + r2.size.width) - p.x, MAX(r1.origin.y + r1.size.height, r2.origin.y + r2.size.height) - p.y);
    return CGRectMake(p.x, p.y, size.width, size.height);
}

- (CGRect)brickTypeFrame:(int)brickType position:(cv::Point)position {
    return CGRectMake([self brickScreenPosition:position].x,
                      [self brickScreenPosition:position].y,
                      [self brickTypeScreenSize:brickType].width,
                      [self brickTypeScreenSize:brickType].height);
}

- (CGRect)brickViewsBoundingRect:(NSArray *)brickViews {
    CGPoint p1 = CGPointMake(100000.0f, 100000.0f);
    CGPoint p2 = CGPointMake(-1.0f, -1.0f);
    for (BrickView *brickView in brickViews) {
        CGRect brickRect = [self brickTypeFrame:brickView.type position:brickView.position];
        p1.x = MIN(p1.x, brickRect.origin.x);
        p1.y = MIN(p1.y, brickRect.origin.y);
        p2.x = MAX(p2.x, brickRect.origin.x + brickRect.size.width);
        p2.y = MAX(p2.y, brickRect.origin.y + brickRect.size.height);
    }
    return CGRectMake(p1.x, p1.y, p2.x - p1.x, p2.y - p1.y);
}

- (CGSize)borderSizeFromBoardSize:(CGSize)size {
    int countX = ((BOARD_WIDTH * 2) - 2) / 9;
    int countY = ((BOARD_HEIGHT * 2)- 2) / 9;
    
    return CGSizeMake(size.width / ((countX * 9) + 2), size.height / ((countY * 9) + 2));
}

- (CGPoint)cvPointToCGPoint:(cv::Point)p {
    return CGPointMake(p.x, p.y);
}

@end
