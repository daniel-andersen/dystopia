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

#import "ConnectorsView.h"
#import "ConnectionView.h"
#import "DoorView.h"
#import "HallwayConnectionView.h"

ConnectorsView *connectorsViewInstance = nil;

@interface ConnectorsView ()

@end

@implementation ConnectorsView

@synthesize connectionViews;
@synthesize connectionMaskViews;

+ (ConnectorsView *)instance {
    @synchronized (self) {
        if (connectorsViewInstance == nil) {
            connectorsViewInstance = [[ConnectorsView alloc] init];
        }
        return connectorsViewInstance;
    }
}

- (id)init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    connectionViews = [NSMutableArray array];
    connectionMaskViews = [NSMutableArray array];
}

- (void)addConnectionViewAtPosition1:(cv::Point)position1 position2:(cv::Point)position2 type:(int)type {
    [self addConnectionView:[[ConnectionView alloc] initWithPosition1:position1 position2:position2 type:type]];
}

- (void)addDoorAtPosition1:(cv::Point)position1 position2:(cv::Point)position2 type:(int)type {
    [self addConnectionView:[[DoorView alloc] initWithPosition1:position1 position2:position2 doorType:type]];
}

- (void)addHallwayConnectionAtPosition1:(cv::Point)position1 position2:(cv::Point)position2 {
    [self addConnectionView:[[HallwayConnectionView alloc] initWithPosition1:position1 position2:position2]];
}

- (void)addConnectionView:(ConnectionView *)connectionView {
    [connectionViews addObject:connectionView];
    [self addSubview:connectionView];
    
    [connectionMaskViews addObject:connectionView.maskView];
    [self addSubview:connectionView.maskView];
    
    [self sortViews];
}

- (void)sortViews {
    for (UIView *view in connectionViews) {
        [self bringSubviewToFront:view];
    }
}

- (bool)shouldOpenDoorAtPosition:(cv::Point)position {
    for (ConnectionView *connectionView in connectionViews) {
        if ([connectionView canOpen] && [connectionView isAtPosition:position]) {
            return YES;
        }
    }
    return NO;
}

- (NSMutableArray *)reveilConnection:(ConnectionView *)connectionView {
    NSMutableArray *connectedBrickViews = [NSMutableArray array];
    if (!connectionView.brickView1.visible) {
        [connectedBrickViews addObjectsFromArray:[self reveilConnection:connectionView forBrickView:connectionView.brickView1]];
    }
    if (!connectionView.brickView2.visible) {
        [connectedBrickViews addObjectsFromArray:[self reveilConnection:connectionView forBrickView:connectionView.brickView2]];
    }
    return connectedBrickViews;
}

- (NSMutableArray *)reveilConnection:(ConnectionView *)connectionView forBrickView:(BrickView *)brickView {
    NSMutableArray *connectedBrickViews = [self connectedBrickViewsForView:brickView];
    [connectionView reveilConnectionForBrickView:brickView withConnectedViews:connectedBrickViews];
    return connectedBrickViews;
}

- (NSMutableArray *)reveilConnectedBrickViewsForBrickView:(BrickView *)brickView {
    NSMutableArray *connectedBrickViews = [self connectedBrickViewsForView:brickView];
    for (BrickView *connectedBrickView in connectedBrickViews) {
        [connectedBrickView show];
    }
    return connectedBrickViews;
}

- (NSMutableArray *)reveilClosedConnectedBrickViewsForBrickViews:(NSMutableArray *)brickViews {
    NSMutableArray *viewsToReveil = [NSMutableArray array];
    for (BrickView *brickView in brickViews) {
        for (ConnectionView *connectionView in connectionViews) {
            if (![connectionView isNextToBrickView:brickView] || connectionView.type == CONNECTION_TYPE_VIEW_GLUE) {
                continue;
            }
            if (![brickViews containsObject:connectionView.brickView1]) {
                NSMutableArray *connectedBrickViews = [self connectedBrickViewsForView:connectionView.brickView1];
                [connectionView reveilConnectionForBrickView:connectionView.brickView1 withConnectedViews:connectedBrickViews];
                [viewsToReveil addObjectsFromArray:connectedBrickViews];
            }
            if (![brickViews containsObject:connectionView.brickView2]) {
                NSMutableArray *connectedBrickViews = [self connectedBrickViewsForView:connectionView.brickView2];
                [connectionView reveilConnectionForBrickView:connectionView.brickView2 withConnectedViews:connectedBrickViews];
                [viewsToReveil addObjectsFromArray:connectedBrickViews];
            }
        }
    }
    return viewsToReveil;
}

- (NSMutableArray *)connectedBrickViewsForView:(BrickView *)brickView {
    NSMutableArray *views = [NSMutableArray array];
    [self addConnectedBrickViewsForView:brickView toViews:views];
    return views;
}

- (void)addConnectedBrickViewsForView:(BrickView *)brickView toViews:(NSMutableArray *)views {
    [views addObject:brickView];
    for (ConnectionView *connectionView in connectionViews) {
        if (![connectionView isNextToBrickView:brickView] || connectionView.type != CONNECTION_TYPE_VIEW_GLUE) {
            continue;
        }
        if (![views containsObject:connectionView.brickView1]) {
            [self addConnectedBrickViewsForView:connectionView.brickView1 toViews:views];
        }
        if (![views containsObject:connectionView.brickView2]) {
            [self addConnectedBrickViewsForView:connectionView.brickView2 toViews:views];
        }
    }
}

@end
