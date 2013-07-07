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

#import "CalibrationView.h"
#import "ExternalDisplay.h"

@implementation CalibrationView

const float calibrationBorderPct = 0.025f;
const UIColor *calibrationBorderColor;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initialize];
    }
    return self;
}

- (void)initialize {
    calibrationBorderColor = [UIColor greenColor];
    
    float borderWidth = self.frame.size.width * calibrationBorderPct;
    float borderHeight = self.frame.size.height * calibrationBorderPct;
    
    UIBezierPath *path = [UIBezierPath bezierPath];

    // Top
    [path moveToPoint:CGPointMake(0.0f,                     0.0f)];
    [path addLineToPoint:CGPointMake(self.frame.size.width, 0.0f)];
    [path addLineToPoint:CGPointMake(self.frame.size.width, borderHeight)];
    [path addLineToPoint:CGPointMake(0.0f,                  borderHeight)];
    [path closePath];
    
    // Bottom
    [path moveToPoint:CGPointMake(0.0f,                     self.frame.size.height - borderHeight)];
    [path addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height - borderHeight)];
    [path addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
    [path addLineToPoint:CGPointMake(0.0f,                  self.frame.size.height)];
    [path closePath];

    // Left
    [path moveToPoint:CGPointMake(0.0f,           borderHeight)];
    [path addLineToPoint:CGPointMake(borderWidth, borderHeight)];
    [path addLineToPoint:CGPointMake(borderWidth, self.frame.size.height - borderHeight)];
    [path addLineToPoint:CGPointMake(0.0f,        self.frame.size.height - borderHeight)];
    [path closePath];

    // Right
    [path moveToPoint:CGPointMake(self.frame.size.width - borderWidth,    borderHeight)];
    [path addLineToPoint:CGPointMake(self.frame.size.width,               borderHeight)];
    [path addLineToPoint:CGPointMake(self.frame.size.width,               self.frame.size.height - borderHeight)];
    [path addLineToPoint:CGPointMake(self.frame.size.width - borderWidth, self.frame.size.height - borderHeight)];
    [path closePath];

    CAShapeLayer *borderLayer = [CAShapeLayer layer];
    borderLayer.frame = CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
    borderLayer.fillColor = calibrationBorderColor.CGColor;
    borderLayer.strokeColor = calibrationBorderColor.CGColor;
    borderLayer.path = path.CGPath;

    [self.layer addSublayer:borderLayer];
}

@end
