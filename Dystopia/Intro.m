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

#import <QuartzCore/QuartzCore.h>

#import "Intro.h"

#define INTRO_FADE_IN_DURATION 5.0f
#define INTRO_FADE_OUT_DURATION 5.0f
#define INTRO_PRESENT_DURATION 2.0f

@implementation Intro

- (id)initWithFrame:(CGRect)frame delegate:(id<IntroDelegate>)d {
    if (self = [super initWithFrame:frame]) {
        delegate = d;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.backgroundColor = [UIColor blackColor];
    [self setupLogoView];
}

- (void)setupLogoView {
    logoView = [[UIImageView alloc] initWithFrame:self.bounds];
    logoView.image = [UIImage imageNamed:@"trollsahead_logo.png"];
    logoView.transform = CGAffineTransformScale(logoView.transform, 0.5f, 0.5f);
    logoView.contentMode = UIViewContentModeScaleAspectFit;
    logoView.layer.opacity = 0.0f;
    [self addSubview:logoView];
}

- (void)show {
    [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(fadeIn) userInfo:nil repeats:NO];
    //[delegate introFinished];
    NSLog(@"Showing intro");
}

- (void)fadeIn {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:INTRO_FADE_IN_DURATION animations:^{
            logoView.layer.opacity = 1.0f;
        } completion:^(BOOL finished) {
            [NSTimer scheduledTimerWithTimeInterval:INTRO_PRESENT_DURATION target:self selector:@selector(hide) userInfo:nil repeats:NO];
        }];
    });
}

- (void)hide {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:INTRO_FADE_OUT_DURATION animations:^{
            logoView.layer.opacity = 0.0f;
        } completion:^(BOOL finished) {
            NSLog(@"Intro ended");
            [delegate introFinished];
        }];
    });
}

@end
