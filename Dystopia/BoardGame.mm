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

#define BOARD_GAME_NEXT_OBJECT_DELAY 1.5f
#define BOARD_GAME_NEXT_OBJECT_PAUSE 1.0f

@interface BoardGame () {
    UIView *boardRecognizedView;

    NSMutableArray *objectsToMoveInTurn;
    MoveableGameObject *objectToMove;
    
    NSMutableArray *heroFigureMoveOrder;
    
    bool isUpdating;
    bool readyForBrickRecognition;
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
    readyForBrickRecognition = NO;
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
            if ([self isBoardReadyForStateUpdate]) {
                state = BOARD_GAME_WAITING_FOR_INITIALIZED;
                [self performSelector:@selector(startPlaceHeroes) withObject:nil afterDelay:BRICKVIEW_OPEN_DOOR_DURATION];
            }
            return;
        }
        [self recognizeMonsters];
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
        if (state == BOARD_GAME_STATE_MONSTERS_TURN) {
            [self updateMonstersTurn];
            return;
        }
    } @finally {
        isUpdating = NO;
    }
}

- (void)startPlaceHeroes {
    NSLog(@"Starting place heroes");
    state = BOARD_GAME_STATE_PLACE_HEROES;
    readyForBrickRecognition = YES;
    heroFigureMoveOrder = [NSMutableArray array];
    for (HeroFigure *hero in [Board instance].heroFigures) {
        [hero showBrick];
    }
}

- (void)startInitialPlayersTurn {
    NSLog(@"Starting players turn (initial)");
    state = BOARD_GAME_STATE_PLAYERS_TURN_INITIAL;
    [self setObjectsToMove:[Board instance].heroFigures];
    [self nextObjectTurn];
}

- (void)startNewTurns {
    switch (state) {
        case BOARD_GAME_STATE_PLAYERS_TURN_INITIAL:
            [self disableNonRecognizedHeroes];
        case BOARD_GAME_STATE_PLAYERS_TURN:
            [self startMonstersTurn];
            break;
        case BOARD_GAME_STATE_MONSTERS_TURN:
            [self startPlayersTurn];
            break;
    }
    [self nextObjectTurn];
}

- (void)startPlayersTurn {
    NSLog(@"Starting players turn");
    state = BOARD_GAME_STATE_PLAYERS_TURN;
    [self setObjectsToMove:heroFigureMoveOrder];
}

- (void)startMonstersTurn {
    NSLog(@"Starting monsters turn");
    state = BOARD_GAME_STATE_MONSTERS_TURN;
    [self setObjectsToMove:[[Board instance] activeMonsterFigures]];
}

- (void)setObjectsToMove:(NSMutableArray *)objects {
    objectsToMoveInTurn = [NSMutableArray array];
    for (MoveableGameObject *object in objects) {
        if (object.active) {
            [objectsToMoveInTurn addObject:object];
        }
    }
}

- (void)nextObjectTurnAfterPause {
    readyForBrickRecognition = NO;
    [self hideMarkers];
    if ([objectToMove isKindOfClass:[HeroFigure class]] && [[Board instance] shouldOpenDoorAtPosition:objectToMove.position]) {
        [[Board instance] openDoorAtPosition:objectToMove.position];
        [self performSelector:@selector(nextObjectTurn) withObject:nil afterDelay:(BRICKVIEW_OPEN_DOOR_DURATION + BOARD_GAME_NEXT_OBJECT_PAUSE)];
    } else {
        [self performSelector:@selector(nextObjectTurn) withObject:nil afterDelay:BOARD_GAME_NEXT_OBJECT_PAUSE];
    }
}

- (void)nextObjectTurn {
    readyForBrickRecognition = YES;
    [self hideMarkers];
    if (objectToMove != nil) {
        [objectsToMoveInTurn removeObject:objectToMove];
        objectToMove = nil;
    }
    [[Board instance] refreshBrickMap];
    [[Board instance] refreshObjectMap];
    for (MoveableGameObject *object in objectsToMoveInTurn) {
        if (objectToMove == nil && object.active) {
            objectToMove = object;
            [self showPulsingMarkerViewForObject:object];
        } else {
            [self hideMarkerViewForObject:object];
        }
    }
    if (objectToMove != nil) {
        NSLog(@"Object %i turn", objectToMove.type);
        [[Board instance] showMoveableLocations:[objectToMove floodFillMoveablePositions]];
    } else {
        [self startNewTurns];
    }
}

- (void)endTurn {
    [self performSelector:@selector(nextObjectTurnAfterPause) withObject:nil afterDelay:BOARD_GAME_NEXT_OBJECT_DELAY];
}

- (void)hideMarkers {
    [[Board instance] hideMoveableLocations];
    for (GameObject *object in [[Board instance] boardObjects]) {
        [object hideMarker];
    }
}

- (void)disableNonRecognizedHeroes {
    NSMutableArray *remainingFigures = [NSMutableArray array];
    for (HeroFigure *hero in [Board instance].heroFigures) {
        if (!hero.recognizedOnBoard) {
            [hero hideBrick];
            hero.active = NO;
        } else {
            [remainingFigures addObject:hero];
        }
    }
    [Board instance].heroFigures = remainingFigures;
}

- (void)updatePlayersTurnInitial {
    [self updateInitialHeroPositions];
    for (HeroFigure *hero in [Board instance].heroFigures) {
        if (hero != objectToMove) {
            [hero hideMarker];
        }
    }
}

- (void)updatePlayersTurn {
    if ([self updateObjectMovement]) {
        [self endTurn];
    }
}

- (void)updateMonstersTurn {
    if ([self updateObjectMovement]) {
        [self endTurn];
    }
}

- (bool)updateObjectMovement {
    if (![self isBoardReadyForStateUpdate]) {
        return NO;
    }
    cv::Point position;
    @synchronized([BoardCalibrator instance].boardImageLock) {
        position = [[BrickRecognizer instance] positionOfBrickAtLocations:[objectToMove floodFillMoveablePositions] inImage:[BoardCalibrator instance].boardImage];
    };
    if (position != objectToMove.position && position.x != -1) {
        NSLog(@"Object %i moved to %i, %i", objectToMove.type, position.x, position.y);
        [objectToMove moveToPosition:position];
        return YES;
    } else {
        return NO;
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
    if (![self isBoardReadyForStateUpdate] || !readyForBrickRecognition) {
        return;
    }
    cv::vector<cv::Point> positions;
    cv::vector<cv::Point> searchPositions;
    for (HeroFigure *hero in [[Board instance] unrecognizedHeroFigures]) {
        searchPositions.push_back(hero.position);
    };
    @synchronized([BoardCalibrator instance].boardImageLock) {
        positions = [[BrickRecognizer instance] positionOfBricksAtLocations:searchPositions inImage:[BoardCalibrator instance].boardImage controlPoints:[[Board instance] randomControlPoints:10]];
    };
    for (HeroFigure *hero in [[Board instance] unrecognizedHeroFigures]) {
        for (int i = 0; i < positions.size(); i++) {
            if (positions[i] == hero.position) {
                NSLog(@"Hero %i found at %i, %i", hero.type, hero.position.x, hero.position.y);
                hero.recognizedOnBoard = YES;
                hero.active = YES;
                [hero showMarker];
                [hero hideBrick];
                [heroFigureMoveOrder addObject:hero];
                if (state == BOARD_GAME_STATE_PLAYERS_TURN_INITIAL) {
                    [objectsToMoveInTurn addObject:hero];
                }
                break;
            }
        }
    }
}

- (void)recognizeMonsters {
    if (![self isBoardReadyForStateUpdate] || !readyForBrickRecognition) {
        return;
    }
    NSArray *unrecognizedMonsterFigures = [[Board instance] unrecognizedVisibleMonsterFigures];
    if (unrecognizedMonsterFigures.count == 0) {
        return;
    }
    cv::vector<cv::Point> positions;
    cv::vector<cv::Point> searchPositions;
    for (MonsterFigure *monsterFigure in unrecognizedMonsterFigures) {
        searchPositions.push_back(monsterFigure.position);
    };
    @synchronized([BoardCalibrator instance].boardImageLock) {
        positions = [[BrickRecognizer instance] positionOfBricksAtLocations:searchPositions inImage:[BoardCalibrator instance].boardImage controlPoints:[[Board instance] randomControlPoints:10]];
    };
    for (MonsterFigure *monsterFigure in unrecognizedMonsterFigures) {
        for (int i = 0; i < positions.size(); i++) {
            if (positions[i] == monsterFigure.position) {
                NSLog(@"Monster %i found at %i, %i", monsterFigure.type, monsterFigure.position.x, monsterFigure.position.y);
                monsterFigure.recognizedOnBoard = YES;
                if (monsterFigure != objectToMove && !monsterFigure.markerView.visible) {
                    [monsterFigure showMarker];
                    [monsterFigure hideMarker];
                }
                [monsterFigure hideBrick];
            }
        }
    }
}

- (void)showPulsingMarkerViewForObject:(GameObject *)object {
    [self bringSubviewToFront:object];
    [object startMarkerPulsing];
}

- (void)showBrickViewForObject:(GameObject *)object {
    [self bringSubviewToFront:object];
    [object showBrick];
}

- (void)hideMarkerViewForObject:(GameObject *)object {
    [object hideMarker];
}

- (void)hideBrickViewForObject:(GameObject *)object {
    [object hideBrick];
}

- (bool)isBoardReadyForStateUpdate {
    return [BoardCalibrator instance].boardBounds.bounds.defined && ![BoardCalibrator instance].boardBounds.isBoundsObstructed;
}

@end
