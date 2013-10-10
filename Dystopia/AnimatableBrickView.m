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

#import "AnimatableBrickView.h"

#define GAME_OBJECT_BRICK_ANIMATION_DURATION 1.0f

#define GAME_OBJECT_ANIMATION_END_VISIBLE_STATE_UNCHANGED 0
#define GAME_OBJECT_ANIMATION_END_VISIBLE_STATE_VISIBLE   1
#define GAME_OBJECT_ANIMATION_END_VISIBLE_STATE_HIDDEN    2

@interface AnimatableBrickView () {
    int animationEndTransitionState;
}

@end

@implementation AnimatableBrickView

@synthesize viewAlpha = _viewAlpha;
@synthesize visible;
@synthesize animating;

- (id)init {
    if (self = [super init]) {
        animating = NO;
        visible = NO;
        _viewAlpha = 1.0f;
    }
    return self;
}

- (void)show {
    @synchronized(self) {
        if (visible) {
            return;
        }
        if (animating) {
            animationEndTransitionState = GAME_OBJECT_ANIMATION_END_VISIBLE_STATE_VISIBLE;
            return;
        }
        animating = YES;
        visible = YES;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.alpha = 0.0f;
        self.transform = CGAffineTransformMakeScale(2.0f, 2.0f);
        [UIView animateWithDuration:GAME_OBJECT_BRICK_ANIMATION_DURATION animations:^{
            self.alpha = self.viewAlpha;
            self.transform = CGAffineTransformIdentity;
        } completion:^(BOOL finished) {
            if (finished) {
                animating = NO;
                [self updateState];
            }
        }];
    });
}

- (void)hide {
    @synchronized(self) {
        if (!visible) {
            return;
        }
        if (animating) {
            animationEndTransitionState = GAME_OBJECT_ANIMATION_END_VISIBLE_STATE_HIDDEN;
            return;
        }
        animating = YES;
        visible = NO;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        self.transform = CGAffineTransformIdentity;
        self.alpha = self.viewAlpha;
        [UIView animateWithDuration:GAME_OBJECT_BRICK_ANIMATION_DURATION animations:^{
            self.alpha = 0.0f;
            self.transform = CGAffineTransformMakeScale(0.75f, 0.75f);
        } completion:^(BOOL finished) {
            if (finished) {
                animating = NO;
                [self updateState];
            }
        }];
    });
}

- (void)updateState {
    if (animationEndTransitionState == GAME_OBJECT_ANIMATION_END_VISIBLE_STATE_VISIBLE) {
        [self show];
    } else if (animationEndTransitionState == GAME_OBJECT_ANIMATION_END_VISIBLE_STATE_VISIBLE) {
        [self hide];
    }
    animationEndTransitionState = GAME_OBJECT_ANIMATION_END_VISIBLE_STATE_UNCHANGED;
}

- (void)setViewAlpha:(float)viewAlpha {
    _viewAlpha = viewAlpha;
    self.layer.opacity = viewAlpha;
}

- (float)viewAlpha {
    return _viewAlpha;
}

@end
