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
#import "ExternalDisplay.h"
#import "MoveableLocationsView.h"
#import "DoorView.h"

@interface Board () {
    int brickMap[BOARD_HEIGHT][BOARD_WIDTH];
    int brickVisibilityMap[BOARD_HEIGHT][BOARD_WIDTH];
    int objectMap[BOARD_HEIGHT][BOARD_WIDTH];
    
    NSMutableArray *brickViews;
    NSMutableArray *connectionsViews;

    MoveableLocationsView *moveableLocationsView;
    
    BorderView *borderView;
    
    int level;
}

@end

@implementation Board

Board *boardInstance = nil;

@synthesize brickPositions;
@synthesize heroFigures;
@synthesize monsterFigures;

+ (Board *)instance {
    @synchronized(self) {
        if (boardInstance == nil) {
            boardInstance = [[Board alloc] initWithFrame:[ExternalDisplay instance].widescreenBounds];
        }
        return boardInstance;
    }
}

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.backgroundColor = [UIColor blackColor];
    moveableLocationsView = [[MoveableLocationsView alloc] initWithFrame:self.bounds];
    [self addSubview:moveableLocationsView];
    NSLog(@"Board initialized");
}

- (void)layoutSubviews {
    [self bringSubviewToFront:moveableLocationsView];
}

- (void)loadLevel:(int)l {
    level = l;
    [self loadBoard];
    [self setupBorderView];
    [self initializeFigures];
}

- (void)loadBoard {
    brickViews = [NSMutableArray array];
    [self addBrickOfType:0 atPosition:cv::Point(3, 3)];
    [self addBrickOfType:0 atPosition:cv::Point(6, 3)];
    [self addBrickOfType:8 atPosition:cv::Point(7, 6)];
    [self addBrickOfType:8 atPosition:cv::Point(7, 9)];
    [self addBrickOfType:8 atPosition:cv::Point(7, 12)];
    [self addBrickOfType:2 atPosition:cv::Point(6, 15)];
    [self addBrickOfType:5 atPosition:cv::Point(8, 10)];
    [self addBrickOfType:5 atPosition:cv::Point(11, 10)];
    [self addBrickOfType:1 atPosition:cv::Point(14, 9)];
    for (BrickView *brickView in brickViews) {
        [self addSubview:brickView];
    }

    connectionsViews = [NSMutableArray array];
    [self addDoorAtPosition1:cv::Point(7, 5) position2:cv::Point(7, 6) type:DOOR_TYPE_NORMAL];
    [self addDoorAtPosition1:cv::Point(7, 14) position2:cv::Point(7, 15) type:DOOR_TYPE_NORMAL];
    [self addDoorAtPosition1:cv::Point(13, 10) position2:cv::Point(14, 10) type:DOOR_TYPE_NORMAL];
    [self addConnectionViewAtPosition1:cv::Point(7, 10) position2:cv::Point(8, 10) type:CONNECTION_TYPE_CORNER];
    [self addConnectionViewAtPosition1:cv::Point(5, 4) position2:cv::Point(6, 5) type:CONNECTION_TYPE_VIEW_GLUE];
    [self addConnectionViewAtPosition1:cv::Point(7, 8) position2:cv::Point(7, 9) type:CONNECTION_TYPE_VIEW_GLUE];
    [self addConnectionViewAtPosition1:cv::Point(7, 11) position2:cv::Point(7, 12) type:CONNECTION_TYPE_VIEW_GLUE];
    [self addConnectionViewAtPosition1:cv::Point(10, 10) position2:cv::Point(11, 10) type:CONNECTION_TYPE_VIEW_GLUE];
    for (ConnectionView *connectionView in connectionsViews) {
        [self addSubview:connectionView];
    }

    [self makeBrickViewVisible:[brickViews objectAtIndex:0]];

    [self refreshBrickMap];
}

- (void)setupBorderView {
    borderView = [[BorderView alloc] initWithFrame:self.bounds];
    [self addSubview:borderView];
}

- (void)addConnectionViewAtPosition1:(cv::Point)position1 position2:(cv::Point)position2 type:(int)type {
    [connectionsViews addObject:[[ConnectionView alloc] initWithPosition1:position1 position2:position2 type:type]];
}

- (void)addDoorAtPosition1:(cv::Point)position1 position2:(cv::Point)position2 type:(int)type {
    [connectionsViews addObject:[[DoorView alloc] initWithPosition1:position1 position2:position2 doorType:type]];
}

- (void)addBrickOfType:(int)type atPosition:(cv::Point)position {
    [brickViews addObject:[[BrickView alloc] initWithPosition:position type:type]];
}

- (void)makeBrickViewVisible:(BrickView *)brickView {
    if (brickView.visible) {
        return;
    }
    [brickView show];
    for (ConnectionView *connectionView in connectionsViews) {
        if ([connectionView isNextToBrickView:brickView]) {
            [connectionView show];
            if (connectionView.type == CONNECTION_TYPE_VIEW_GLUE) {
                [self makeBrickViewVisible:connectionView.brickView1];
                [self makeBrickViewVisible:connectionView.brickView2];
            }
            [connectionView reveilConnection];
        }
    }
    [self refreshBrickMap];
}

- (void)refreshBrickPositions {
    brickPositions = cv::vector<cv::Point>();
    for (int i = 0; i < BOARD_HEIGHT; i++) {
        for (int j = 0; j < BOARD_WIDTH; j++) {
            cv::Point p = cv::Point(j, i);
            if ([self hasVisibleBrickAtPosition:p]) {
                brickPositions.push_back(p);
            }
        }
    }
}

- (void)refreshBrickMap {
    for (int i = 0; i < BOARD_HEIGHT; i++) {
        for (int j = 0; j < BOARD_WIDTH; j++) {
            brickMap[i][j] = -1;
            brickVisibilityMap[i][j] = BOARD_BRICK_NONE;
        }
    }
    for (BrickView *brickView in brickViews) {
        for (int i = 0; i < brickView.size.height; i++) {
            for (int j = 0; j < brickView.size.width; j++) {
                brickMap[i + brickView.position.y][j + brickView.position.x] = brickView.type;
                brickVisibilityMap[i + brickView.position.y][j + brickView.position.x] = brickView.visible ? BOARD_BRICK_VISIBLE : BOARD_BRICK_INVISIBLE;
            }
        }
    }
    [self refreshBrickPositions];
}

- (void)refreshObjectMap {
    for (int i = 0; i < BOARD_HEIGHT; i++) {
        for (int j = 0; j < BOARD_WIDTH; j++) {
            objectMap[i][j] = -1;
        }
    }
    NSMutableArray *objects = [self boardObjects];
    for (GameObject *object in objects) {
        objectMap[object.position.y][object.position.x] = 1;
    }
}

- (bool)shouldOpenDoorAtPosition:(cv::Point)position {
    for (ConnectionView *connectionView in connectionsViews) {
        if ([connectionView canOpen] && [connectionView isAtPosition:position]) {
            return YES;
        }
    }
    return NO;
}

- (void)openDoorAtPosition:(cv::Point)position {
    for (ConnectionView *connectionView in connectionsViews) {
        if ([connectionView canOpen] && [connectionView isAtPosition:position]) {
            [self makeBrickViewVisible:connectionView.brickView1];
            [self makeBrickViewVisible:connectionView.brickView2];
            [connectionView openConnection];
        }
    }
}

- (void)showMoveableLocations:(cv::vector<cv::Point>)locations {
    [moveableLocationsView showLocations:locations];
}

- (void)hideMoveableLocations {
    [moveableLocationsView hideLocations];
}

- (bool)hasBrickAtPosition:(cv::Point)position {
    return position.x >= 0 && position.y >= 0 && position.x < BOARD_WIDTH && position.y < BOARD_HEIGHT && brickMap[position.y][position.x] != -1;
}

- (bool)hasVisibleBrickAtPosition:(cv::Point)position {
    return position.x >= 0 && position.y >= 0 && position.x < BOARD_WIDTH && position.y < BOARD_HEIGHT && brickVisibilityMap[position.y][position.x] == BOARD_BRICK_VISIBLE;
}

- (bool)hasObjectAtPosition:(cv::Point)position {
    return position.x >= 0 && position.y >= 0 && position.x < BOARD_WIDTH && position.y < BOARD_HEIGHT && objectMap[position.y][position.x] != -1;
}

- (BrickView *)brickViewAtPosition:(cv::Point)p {
    for (BrickView *brickView in brickViews) {
        if (p.x >= brickView.position.x && p.x < brickView.position.x + brickView.size.width &&
            p.y >= brickView.position.y && p.y < brickView.position.y + brickView.size.height) {
            return brickView;
        }
    }
    return nil;
}

- (void)initializeFigures {
    [self initializeHeroFigures];
    [self initializeMonsterFigures];
}

- (void)initializeHeroFigures {
    if (heroFigures != nil) {
        for (HeroFigure *hero in heroFigures) {
            [hero removeFromSuperview];
        }
    }
    heroFigures = [NSMutableArray array];
    [heroFigures addObject:[[HeroFigure alloc] initWithPosition:cv::Point(4, 3) type:HERO_WIZARD]];
    [heroFigures addObject:[[HeroFigure alloc] initWithPosition:cv::Point(5, 5) type:HERO_WARRIOR]];
    [heroFigures addObject:[[HeroFigure alloc] initWithPosition:cv::Point(6, 4) type:HERO_DWERF]];
    [heroFigures addObject:[[HeroFigure alloc] initWithPosition:cv::Point(7, 3) type:HERO_ELF]];
    for (HeroFigure *hero in heroFigures) {
        [self addSubview:hero];
    }
    [self refreshObjectMap];
}

- (void)initializeMonsterFigures {
    if (monsterFigures != nil) {
        for (MonsterFigure *monster in monsterFigures) {
            [monster removeFromSuperview];
        }
    }
    monsterFigures = [NSMutableArray array];
    for (MonsterFigure *monster in monsterFigures) {
        [self addSubview:monster];
    }
    [self refreshObjectMap];
}

- (cv::vector<cv::Point>)randomControlPoints:(int)count {
    cv::vector<cv::Point> controlPoints;
    int drawSize = brickPositions.size();
    int indices[drawSize];
    for (int i = 0; i < drawSize; i++) {
        indices[i] = i;
    }
    while (drawSize > 0 && controlPoints.size() < count) {
        int index = rand() % drawSize;
        cv::Point position = brickPositions[indices[index]];
        if (![self hasObjectAtPosition:position]) {
            controlPoints.push_back(position);
        }
        indices[index] = indices[drawSize - 1];
        drawSize--;
    }
    return controlPoints;
}

- (NSMutableArray *)boardObjects {
    NSMutableArray *figures = [NSMutableArray array];
    [figures addObjectsFromArray:heroFigures];
    [figures addObjectsFromArray:monsterFigures];
    return figures;
}

@end
