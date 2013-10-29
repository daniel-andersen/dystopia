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

#import "DoorView.h"
#import "Board.h"
#import "Util.h"

#define DOOR_CONNECTION_EXTENT 0

@interface DoorView () {
    UIImageView *doorImageView;
}

@end

@implementation DoorView

@synthesize doorType;

- (id)initWithPosition1:(cv::Point)p1 position2:(cv::Point)p2 doorType:(int)t {
    if (self = [super initWithPosition1:p1 position2:p2 type:CONNECTION_TYPE_DOOR]) {
        doorType = t;
        [self initializeDoor];
    }
    return self;
}

- (void)initializeDoor {
    //[self addGradientViewWithImage:[UIImage imageNamed:@"connection_door.png"] extent:DOOR_CONNECTION_EXTENT];
    [self addGradientViewWithImage:[UIImage imageNamed:@"connection_hallway.png"] extent:DOOR_CONNECTION_EXTENT];

    doorImageView = [[UIImageView alloc] initWithFrame:self.bounds];
    doorImageView.image = [self doorImage];
    [self addSubview:doorImageView];
}

- (UIImage *)doorImage {
    if (ABS(self.position1.x - self.position2.x) == 0) {
        return [UIImage imageNamed:@"door1_horizontal.png"];
    } else {
        return [UIImage imageNamed:@"door1_vertical.png"];
    }
}

@end
