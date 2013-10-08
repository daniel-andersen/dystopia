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
#import "HeroFigure.h"

#define BOARD_GAME_STATE_INITIALIZING 0
#define BOARD_GAME_STATE_PLACE_HEROES 1
#define BOARD_GAME_STATE_PLAYER_TURN  2

@interface BoardGame () {
    int level;
    id<BoardGameProtocol> delegate;
    
    Board *board;

    UIView *boardRecognizedView;

    int state;

    NSMutableArray *heroFigures;
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
    state = BOARD_GAME_STATE_INITIALIZING;
    board = [[Board alloc] initWithFrame:self.bounds];
    [self addSubview:board];
}

- (void)startWithLevel:(int)l {
    level = l;
    [board loadLevel:level];

    [self resetFigures];

    [self startUpdateTimer];
    NSLog(@"Level %i started", level + 1);
}

- (void)startUpdateTimer {
    NSTimer* timer = [NSTimer timerWithTimeInterval:0.1f target:self selector:@selector(update) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)resetFigures {
    if (heroFigures != nil) {
        for (HeroFigure *hero in heroFigures) {
            [hero removeFromSuperview];
        }
    }
    heroFigures = [NSMutableArray array];
    [heroFigures addObject:[[HeroFigure alloc] initWithHeroType:HERO_DWERF position:cv::Point(7, 10)]];
    [heroFigures addObject:[[HeroFigure alloc] initWithHeroType:HERO_WARRIOR position:cv::Point(9, 10)]];
    [heroFigures addObject:[[HeroFigure alloc] initWithHeroType:HERO_ELF position:cv::Point(11, 10)]];
    for (HeroFigure *hero in heroFigures) {
        [self addSubview:hero];
    }
}

- (void)switchToState:(int)s {
    state = s;
    if (state == BOARD_GAME_STATE_PLACE_HEROES) {
        [self placeHeroes];
    }
}

- (void)placeHeroes {
    for (HeroFigure *hero in heroFigures) {
        [hero showBrick];
    }
}

- (void)update {
    if (state == BOARD_GAME_STATE_INITIALIZING) {
        [self switchToState:BOARD_GAME_STATE_PLACE_HEROES];
        return;
    }
    if (state == BOARD_GAME_STATE_PLACE_HEROES) {
        [self updatePlaceHeroes];
        return;
    }
}

- (void)updatePlaceHeroes {
    if (![self isBoardReadyForStateUpdate]) {
        return;
    }
    cv::vector<cv::Point> searchPositions;
    for (HeroFigure *hero in heroFigures) {
        searchPositions.push_back(hero.position);
    };
    cv::vector<cv::Point> positions;
    @synchronized([BoardCalibrator instance].boardImageLock) {
        positions = [[BrickRecognizer instance] positionOfBricksAtLocations:searchPositions inImage:[BoardCalibrator instance].boardImage controlPoint:cv::Point(13, 10)];
    };
    for (HeroFigure *hero in heroFigures) {
        bool recognized = NO;
        for (int i = 0; i < positions.size(); i++) {
            if (positions[i] == hero.position) {
                recognized = YES;
            }
        }
        if (recognized) {
            [hero showMarker];
            [hero hideBrick];
        } else {
            [hero hideMarker];
            [hero showBrick];
        }
    }
}

- (bool)isBoardReadyForStateUpdate {
    return [BoardCalibrator instance].boardBounds.bounds.defined && ![BoardCalibrator instance].boardBounds.isBoundsObstructed;
}

@end
