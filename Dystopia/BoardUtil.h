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

#import <Foundation/Foundation.h>

#import "Util.h"

#ifndef __BOARD_UTIL__
#define __BOARD_UTIL__

    #define BOARD_WIDTH 30
    #define BOARD_HEIGHT 20

    #define BRICK_IMAGES_COUNT 11

    typedef struct {
        FourPoints bounds;
        bool isBoundsObstructed;
    } BoardBounds;

#endif

@interface BoardUtil : NSObject

+ (BoardUtil *)instance;

- (id)init;

- (UIImage *)brickImageOfType:(int)type;

- (CGSize)singleBrickScreenSize;
- (CGSize)singleBrickScreenSizeFromBoardSize:(CGSize)size;

- (CGSize)brickTypeBoardSize:(int)type;
- (CGSize)brickTypeScreenSize:(int)type;

- (CGPoint)brickScreenPosition:(cv::Point)brickBoardPosition;
- (CGRect)brickTypeFrame:(int)brickType position:(cv::Point)position;

- (CGSize)borderSizeFromBoardSize:(CGSize)size;

- (CGPoint)cvPointToCGPoint:(cv::Point)p;

@end
