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

@interface BoardGame () {
    UIView *boardRecognizedView;

    NSMutableArray *heroesToMove;
    HeroFigure *heroToMove;

    NSMutableArray *monstersToMove;
    HeroFigure *monsterToMove;
    
    bool isUpdating;
}

@end

@implementation BoardGame

BoardGame *boardGameInstance;

@synthesize delegate;
@synthesize state;
@synthesize level;

+ (BoardGame *)instance {
    @synchronized(self) {
        if (boardGameInstance == nil) {
            boardGameInstance = [[BoardGame alloc] init];
        }
        return boardGameInstance;
    }
}

- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    state = BOARD_GAME_STATE_INITIALIZING;
    isUpdating = NO;
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
    @synchronized(self) {
        if (isUpdating) {
            return;
        }
        isUpdating = YES;
    }
    @try {
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
    } @finally {
        isUpdating = NO;
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
    [self endMonstersTurn];
    state = BOARD_GAME_STATE_PLAYERS_TURN;
    heroesToMove = [NSMutableArray array];
    for (HeroFigure *hero in [Board instance].heroFigures) {
        if (hero.active) {
            [heroesToMove addObject:hero];
        }
    }
    [self startNextPlayerTurn];
}

- (void)startNextPlayerTurn {
    NSLog(@"Next players turn");
    if (heroToMove != nil) {
        [heroToMove.markerView show];
        [heroesToMove removeObject:heroToMove];
    }
    heroToMove = nil;
    [self endTurn];
    for (HeroFigure *hero in heroesToMove) {
        if (heroToMove == nil && hero.active && hero.recognizedOnBoard) {
            heroToMove = hero;
            [hero.markerView show];
        } else {
            [hero.markerView hide];
        }
    }
    if (heroToMove != nil) {
        NSLog(@"Player %i turn", heroToMove.heroType);
        [[Board instance] showMoveableLocations:[heroToMove floodFillMoveablePositions]];
    } else {
        [self startMonstersTurn];
    }
}

- (void)startMonstersTurn {
    NSLog(@"Starting monsters turn");
    [self endPlayersTurn];
    state = BOARD_GAME_STATE_MONSTERS_TURN;
}

- (void)endPlayersTurn {
    if (state == BOARD_GAME_STATE_PLAYERS_TURN_INITIAL) {
        [self disableNonRecognizedHeroes];
    }
    [self endTurn];
}

- (void)endMonstersTurn {
    [self endTurn];
}

- (void)endTurn {
    [self hideMarkers];
    [[Board instance] refreshBrickMap];
    [[Board instance] refreshObjectMap];
}

- (void)hideMarkers {
    [[Board instance] hideMoveableLocations];
    for (GameObject *object in [[Board instance] boardObjects]) {
        [object hideMarker];
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
    if (![self isBoardReadyForStateUpdate]) {
        return;
    }
    cv::Point position;
    @synchronized([BoardCalibrator instance].boardImageLock) {
        position = [[BrickRecognizer instance] positionOfBrickAtLocations:[heroToMove floodFillMoveablePositions] inImage:[BoardCalibrator instance].boardImage controlPoints:[[Board instance] randomControlPoints:10]];
    };
    if (position != heroToMove.position && position.x != -1) {
        NSLog(@"Hero %i moved to %i, %i", heroToMove.heroType, position.x, position.y);
        [heroToMove moveToPosition:position];
        [self startNextPlayerTurn];
    }
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
        positions = [[BrickRecognizer instance] positionOfBricksAtLocations:searchPositions inImage:[BoardCalibrator instance].boardImage controlPoints:[[Board instance] randomControlPoints:10]];
    };
    for (HeroFigure *hero in [Board instance].heroFigures) {
        if (hero.recognizedOnBoard) {
            continue;
        }
        for (int i = 0; i < positions.size(); i++) {
            if (positions[i] == hero.position) {
                NSLog(@"Hero %i found at %i, %i", hero.heroType, hero.position.x, hero.position.y);
                hero.recognizedOnBoard = YES;
                hero.active = YES;
                [hero showMarker];
                [hero hideBrick];
                if (state == BOARD_GAME_STATE_PLAYERS_TURN_INITIAL) {
                    [heroesToMove addObject:hero];
                }
                break;
            }
        }
    }
}

- (bool)isBoardReadyForStateUpdate {
    return [BoardCalibrator instance].boardBounds.bounds.defined && ![BoardCalibrator instance].boardBounds.isBoundsObstructed;
}

@end
