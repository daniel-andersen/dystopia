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

#import "ConnectionView.h"
#import "Board.h"

@implementation ConnectionView

@synthesize position1;
@synthesize position2;

@synthesize brickView1;
@synthesize brickView2;

@synthesize type;

@synthesize visible;
@synthesize open;

- (id)initWithPosition1:(cv::Point)p1 position2:(cv::Point)p2 type:(int)t {
    if (self = [super initWithFrame:[[BoardUtil instance] bricksScreenRectPosition1:p1 position2:p2]]) {
        position1 = p1;
        position2 = p2;
        type = t;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    brickView1 = [[Board instance] brickViewAtPosition:position1];
    brickView2 = [[Board instance] brickViewAtPosition:position2];
    self.backgroundColor = [UIColor clearColor];
    self.hidden = YES;
    visible = NO;
    open = NO;
}

- (void)show {
    visible = YES;
    if (type != CONNECTION_TYPE_DOOR) {
        return;
    }
    self.hidden = NO;
}

- (void)openConnection {
    open = YES;
}

- (void)reveilConnectionForBrickView:(BrickView *)brickView withConnectedViews:(NSArray *)connectedViews {
    [self show];
    
    for (BrickView *brickView in connectedViews) {
        [brickView reveil];
    }
    if (type == CONNECTION_TYPE_CORNER) {
        //[brickView1 reveilConnectionFromPosition:position2 toPosition:position1];
        //[brickView2 reveilConnectionFromPosition:position1 toPosition:position2];
    }
}

- (bool)isNextToBrickView:(BrickView *)brickView {
    return brickView == brickView1 || brickView == brickView2;
}

- (bool)isAtPosition:(cv::Point)p {
    return p == position1 || p == position2;
}

- (bool)canOpen {
    return !open && (type == CONNECTION_TYPE_DOOR || type == CONNECTION_TYPE_CORNER);
}

@end
