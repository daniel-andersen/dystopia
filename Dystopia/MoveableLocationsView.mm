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

#import "MoveableLocationsView.h"
#import "BoardUtil.h"

#define MOVEABLE_LOCATIONS_APPEAR_DURATION 1.0f

@interface MoveableLocationsView () {
    cv::vector<cv::Point> locations;
    NSMutableArray *views;
    UIColor *moveableLocationColor;
}

@end

@implementation MoveableLocationsView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initializeGui];
    }
    return self;
}

- (void)initializeGui {
    self.backgroundColor = [UIColor clearColor];
    self.alpha = 0.0f;
    moveableLocationColor = [UIColor colorWithRed:1.0f green:0.0f blue:0.0f alpha:0.7f];
    views = nil;
}

- (void)showLocations:(cv::vector<cv::Point>)l {
    locations = l;
    if (!self.hidden) {
        [self hideLocations];
        [self performSelector:@selector(createAndShowLocations) withObject:nil afterDelay:MOVEABLE_LOCATIONS_APPEAR_DURATION];
    } else {
        [self createAndShowLocations];
    }
}

- (void)hideLocations {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView animateWithDuration:MOVEABLE_LOCATIONS_APPEAR_DURATION animations:^{
            self.alpha = 0.0f;
        }];
    });
}

- (void)createAndShowLocations {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self createLocationViews];
        [UIView animateWithDuration:MOVEABLE_LOCATIONS_APPEAR_DURATION animations:^{
            self.alpha = 1.0f;
        }];
    });
}

- (void)removeViews {
    if (views == nil) {
        return;
    }
    for (UIView *view in views) {
        [view removeFromSuperview];
    }
    views = nil;
}

- (void)createLocationViews {
    [self removeViews];
    views = [NSMutableArray array];
    for (int i = 0; i < locations.size(); i++) {
        UIView *view = [[UIView alloc] initWithFrame:[[BoardUtil instance] brickScreenRect:locations[i]]];
        view.backgroundColor = moveableLocationColor;
        [self addSubview:view];
    }
}

@end
