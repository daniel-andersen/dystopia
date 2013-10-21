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

#import "HeroFigure.h"

const int HERO_MOVEMENT_LENGTH[HEROES_COUNT] = {4, 8, 8, 6, 5};
const NSArray *HERO_MARKER_IMAGE = [NSArray arrayWithObjects:@"marker_dwerf.png", @"marker_archor.png", @"marker_elf.png", @"marker_warrior.png", @"marker_wizard.png", nil];

@interface HeroFigure () {
    int movementLength;
}

@end

@implementation HeroFigure

- (void)initialize {
    [super initialize];
    [self reset];
    super.brickView.image = [UIImage imageNamed:[HERO_MARKER_IMAGE objectAtIndex:self.type]];
    super.brickView.viewAlpha = 0.9f;
}

- (void)reset {
    self.movementLength = HERO_MOVEMENT_LENGTH[self.type];
    self.visible = YES;
    self.active = NO;
}

- (bool)canMoveToLocation:(cv::Point)location withMovementCount:(int)movementCount {
    return movementCount <= self.movementLength;
}

@end
