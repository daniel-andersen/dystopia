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

#import "BorderView.h"
#import "ExternalDisplay.h"
#import "BoardUtil.h"

#define BORDER_LEFT         0
#define BORDER_RIGHT        1
#define BORDER_TOP          2
#define BORDER_BOTTOM       3
#define BORDER_TOP_LEFT     4
#define BORDER_TOP_RIGHT    5
#define BORDER_BOTTOM_LEFT  6
#define BORDER_BOTTOM_RIGHT 7

@interface BorderView ()

@end

@implementation BorderView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    NSMutableArray *borderImages = [NSMutableArray arrayWithCapacity:8];
    [borderImages setObject:[UIImage imageNamed:@"border_left.png"        ] atIndexedSubscript:BORDER_LEFT];
    [borderImages setObject:[UIImage imageNamed:@"border_right.png"       ] atIndexedSubscript:BORDER_RIGHT];
    [borderImages setObject:[UIImage imageNamed:@"border_top.png"         ] atIndexedSubscript:BORDER_TOP];
    [borderImages setObject:[UIImage imageNamed:@"border_bottom.png"      ] atIndexedSubscript:BORDER_BOTTOM];
    [borderImages setObject:[UIImage imageNamed:@"border_top_left.png"    ] atIndexedSubscript:BORDER_TOP_LEFT];
    [borderImages setObject:[UIImage imageNamed:@"border_top_right.png"   ] atIndexedSubscript:BORDER_TOP_RIGHT];
    [borderImages setObject:[UIImage imageNamed:@"border_bottom_left.png" ] atIndexedSubscript:BORDER_BOTTOM_LEFT];
    [borderImages setObject:[UIImage imageNamed:@"border_bottom_right.png"] atIndexedSubscript:BORDER_BOTTOM_RIGHT];
    
    UIImage *borderImage = [self drawBorderWithImages:borderImages];
    self.layer.contents = (id)borderImage.CGImage;
}

- (UIImage *)drawBorderWithImages:(NSMutableArray *)borderImages {
    int countX = ((BOARD_WIDTH * 2) - 2) / 9;
    int countY = ((BOARD_HEIGHT * 2)- 2) / 9;
    
    CGSize singleSize = [[BoardUtil instance] borderSizeFromBoardSize:self.bounds.size];
    CGSize stripSize = CGSizeMake(singleSize.width * 9.0f, singleSize.height * 9.0f);

    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [ExternalDisplay instance].screen.scale);

    for (int i = 0; i < countX; i++) {
        float x = (i * stripSize.width) + singleSize.width;
        [borderImages[BORDER_TOP]    drawInRect:CGRectMake(x, 0.0f,                                        stripSize.width, singleSize.height)];
        [borderImages[BORDER_BOTTOM] drawInRect:CGRectMake(x, self.bounds.size.height - singleSize.height, stripSize.width, singleSize.height)];
    }
    
    for (int i = 0; i < countY; i++) {
        float y = (i * stripSize.height) + singleSize.height;
        [borderImages[BORDER_LEFT]  drawInRect:CGRectMake(0.0f,                                      y, singleSize.width, stripSize.height)];
        [borderImages[BORDER_RIGHT] drawInRect:CGRectMake(self.bounds.size.width - singleSize.width, y, singleSize.width, stripSize.height)];
    }

    [borderImages[BORDER_TOP_LEFT] drawInRect:CGRectMake(0.0f, 0.0f, singleSize.width, singleSize.height)];
    [borderImages[BORDER_TOP_RIGHT] drawInRect:CGRectMake(self.bounds.size.width - singleSize.width, 0.0f, singleSize.width, singleSize.height)];
    [borderImages[BORDER_BOTTOM_LEFT] drawInRect:CGRectMake(0.0f, self.bounds.size.height - singleSize.height, singleSize.width, singleSize.height)];
    [borderImages[BORDER_BOTTOM_RIGHT] drawInRect:CGRectMake(self.bounds.size.width - singleSize.width, self.bounds.size.height - singleSize.height, singleSize.width, singleSize.height)];

    UIImage *borderImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return borderImage;
}

@end
