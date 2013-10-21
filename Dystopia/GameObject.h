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

#import <UIKit/UIKit.h>

#import "AnimatableBrickView.h"

#define GAME_OBJECT_MOVE_ANIMATION_DURATION 1.0f

@interface GameObject : UIView

- (id)initWithPosition:(cv::Point)p type:(int)t;

- (void)initialize;

- (void)showBrick;
- (void)hideBrick;

- (void)showMarker;
- (void)hideMarker;

- (void)startMarkerPulsing;
- (void)stopMarkerPulsing;

- (bool)isValidPosition:(cv::Point)p;

@property (nonatomic) cv::Point position;

@property (nonatomic) bool recognizedOnBoard;

@property (nonatomic, retain, readonly) AnimatableBrickView *brickView;
@property (nonatomic, retain, readonly) AnimatableBrickView *markerView;

@property (nonatomic) bool visible;
@property (nonatomic) bool active;
@property (nonatomic, readonly) int type;

@end



@interface MoveableGameObject : GameObject

- (void)moveToPosition:(cv::Point)p;

- (cv::vector<cv::Point>)moveablePositions;
- (cv::vector<cv::Point>)floodFillMoveablePositions;

- (bool)canMoveToLocation:(cv::Point)location withMovementCount:(int)movementCount;

@property (nonatomic) int movementLength;

@end
