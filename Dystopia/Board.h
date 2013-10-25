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

#import "BrickView.h"
#import "BoardUtil.h"
#import "HeroFigure.h"
#import "MonsterFigure.h"

#define BOARD_BRICK_NONE      0
#define BOARD_BRICK_INVISIBLE 1
#define BOARD_BRICK_VISIBLE   2

@interface Board : UIView

+ (Board *)instance;

- (id)initWithFrame:(CGRect)frame;

- (void)loadLevel:(int)l;

- (bool)shouldOpenDoorAtPosition:(cv::Point)position;
- (void)openDoorAtPosition:(cv::Point)position;

- (void)showMoveableLocations:(cv::vector<cv::Point>)locations;
- (void)hideMoveableLocations;

- (bool)hasBrickAtPosition:(cv::Point)position;
- (bool)hasVisibleBrickAtPosition:(cv::Point)position;
- (bool)hasObjectAtPosition:(cv::Point)position;

- (BrickView *)brickViewAtPosition:(cv::Point)p;

- (void)refreshBrickMap;
- (void)refreshObjectMap;

- (NSMutableArray *)boardObjects;
- (NSMutableArray *)visibleBoardObjects;
- (NSMutableArray *)visibleMonsterFigures;
- (NSMutableArray *)invisibleMonsterFigures;
- (NSMutableArray *)activeMonsterFigures;
- (NSMutableArray *)unrecognizedVisibleMonsterFigures;
- (NSMutableArray *)unrecognizedHeroFigures;

- (cv::vector<cv::Point>)randomControlPoints:(int)count;

@property (nonatomic, retain) NSMutableArray *heroFigures;
@property (nonatomic, retain) NSMutableArray *monsterFigures;

@property (nonatomic, readonly) cv::vector<cv::Point> brickPositions;

@end
