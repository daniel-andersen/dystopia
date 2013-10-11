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

#define BOARD_GAME_STATE_INITIALIZING         0
#define BOARD_GAME_STATE_PLACE_HEROES         1
#define BOARD_GAME_STATE_PLAYERS_TURN_INITIAL 2
#define BOARD_GAME_STATE_PLAYERS_TURN         3
#define BOARD_GAME_STATE_MONSTERS_TURN        4

@interface BoardGame () {
    id<BoardGameProtocol> delegate;

    UIView *boardRecognizedView;

    int level;
    int state;
    
    NSMutableArray *heroesToMove;
    HeroFigure *heroToMove;

    NSMutableArray *monstersToMove;
    HeroFigure *monsterToMove;
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
    [self addSubview:[Board instance]];
}

- (void)startWithLevel:(int)l {
    level = l;
    [[Board instance] loadLevel:level];
    [self startUpdateTimer];
    NSLog(@"Level %i started", level + 1);
}

- (void)startUpdateTimer {
    NSTimer* timer = [NSTimer timerWithTimeInterval:0.1f target:self selector:@selector(update) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
}

- (void)update {
    if (state == BOARD_GAME_STATE_INITIALIZING) {
        [self startPlaceHeroes];
        return;
    }
    if (state == BOARD_GAME_STATE_PLACE_HEROES) {
        [self updatePlaceHeroes];
        return;
    }
    if (state == BOARD_GAME_STATE_PLAYERS_TURN_INITIAL) {
        [self updatePlayersTurnInitial];
    }
    if (state == BOARD_GAME_STATE_PLAYERS_TURN || state == BOARD_GAME_STATE_PLAYERS_TURN_INITIAL) {
        [self updatePlayersTurn];
        return;
    }
}

- (void)startPlaceHeroes {
    NSLog(@"Starting place heroes");
    state = BOARD_GAME_STATE_PLACE_HEROES;
    for (HeroFigure *hero in [Board instance].heroFigures) {
        [hero showBrick];
    }
}

- (void)startInitialPlayersTurn {
    NSLog(@"Starting players turn (initial)");
    [self startPlayersTurn];
    state = BOARD_GAME_STATE_PLAYERS_TURN_INITIAL;
}

- (void)startPlayersTurn {
    NSLog(@"Starting players turn");
    state = BOARD_GAME_STATE_PLAYERS_TURN;
    heroesToMove = [NSMutableArray array];
    for (HeroFigure *hero in [Board instance].heroFigures) {
        if (hero.active) {
            [heroesToMove addObject:hero];
        }
    }
    [self startNextPlayerTurn];
    if (heroToMove == nil) {
        [self startMonstersTurn];
    }
}

- (void)startNextPlayerTurn {
    heroToMove = nil;
    for (HeroFigure *hero in heroesToMove) {
        if (heroToMove == nil && hero.active && hero.recognizedOnBoard) {
            heroToMove = hero;
            [hero.markerView show];
        } else {
            [hero.markerView hide];
        }
    }
    if (heroToMove != nil) {
        [heroesToMove removeObject:heroToMove];
        [[Board instance] showMoveableLocations:[heroToMove floodFillMoveablePositions]];
    }
}

- (void)startMonstersTurn {
    NSLog(@"Starting monsters turn");
    if (state == BOARD_GAME_STATE_PLAYERS_TURN_INITIAL) {
        [self disableNonRecognizedHeroes];
    }
}

- (void)disableNonRecognizedHeroes {
    for (HeroFigure *hero in [Board instance].heroFigures) {
        if (!hero.recognizedOnBoard) {
            hero.active = NO;
        }
    }
}

- (void)updatePlayersTurnInitial {
    [self updateInitialHeroPositions];
    for (HeroFigure *hero in [Board instance].heroFigures) {
        if (hero != heroToMove) {
            [hero hideMarker];
        }
    }
}

- (void)updatePlayersTurn {
    
}

- (void)updatePlaceHeroes {
    [self updateInitialHeroPositions];
    for (HeroFigure *hero in [Board instance].heroFigures) {
        if (hero.recognizedOnBoard) {
            [self startInitialPlayersTurn];
            break;
        }
    }
}

- (void)updateInitialHeroPositions {
    if (![self isBoardReadyForStateUpdate]) {
        return;
    }
    cv::vector<cv::Point> positions;
    cv::vector<cv::Point> searchPositions;
    for (HeroFigure *hero in [Board instance].heroFigures) {
        if (!hero.recognizedOnBoard) {
            searchPositions.push_back(hero.position);
        }
    };
    @synchronized([BoardCalibrator instance].boardImageLock) {
        cv::vector<cv::Point> controlPoints = [[Board instance] randomControlPoints:10];
        positions = [[BrickRecognizer instance] positionOfBricksAtLocations:searchPositions inImage:[BoardCalibrator instance].boardImage controlPoints:controlPoints];
    };
    for (HeroFigure *hero in [Board instance].heroFigures) {
        if (hero.recognizedOnBoard) {
            continue;
        }
        for (int i = 0; i < positions.size(); i++) {
            if (positions[i] == hero.position) {
                NSLog(@"Hero %i found!", i);
                hero.recognizedOnBoard = YES;
                hero.active = YES;
                [hero showMarker];
                [hero hideBrick];
                break;
            }
        }
    }
}

- (bool)isBoardReadyForStateUpdate {
    return [BoardCalibrator instance].boardBounds.bounds.defined && ![BoardCalibrator instance].boardBounds.isBoundsObstructed;
}

@end
