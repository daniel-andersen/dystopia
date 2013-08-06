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

#import "BrickView.h"
#import "BoardUtil.h"

@implementation BrickView

@synthesize brickType;
@synthesize visible;

- (id)initWithFrame:(CGRect)frame brickType:(int)b {
    if (self = [super initWithFrame:frame]) {
        brickType = b;
        [self initialize];
    }
    return self;
}

- (void)initialize {
    self.layer.contents = (id)[[BoardUtil instance] brickImageOfType:brickType].CGImage;
    
    if (brickType == 0) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake([[BoardUtil instance] singleBrickScreenSize].width, [[BoardUtil instance] singleBrickScreenSize].height, [[BoardUtil instance] singleBrickScreenSize].width, [[BoardUtil instance] singleBrickScreenSize].height)];
        view.backgroundColor = [UIColor blackColor];
        [self addSubview:view];
    }
}

@end
