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

#import "BrickView.h"

#define CONNECTION_TYPE_VIEW_GLUE 0
#define CONNECTION_TYPE_DOOR      1
#define CONNECTION_TYPE_HALLWAY   2

@interface ConnectionView : UIView

- (id)initWithPosition1:(cv::Point)p1 position2:(cv::Point)p2 type:(int)t;

- (void)show;
- (void)openConnection;
- (void)reveilConnectionForBrickView:(BrickView *)brickView withConnectedViews:(NSArray *)connectedViews;

- (bool)isNextToBrickView:(BrickView *)brickView;
- (bool)isAtPosition:(cv::Point)p;

- (bool)canOpen;

- (void)addGradientViewWithImage:(UIImage *)image extent:(int)extent;

- (CGRect)brickMaskRectPosition1:(cv::Point)p1 position2:(cv::Point)p2;

@property (nonatomic, readonly) cv::Point position1;
@property (nonatomic, readonly) cv::Point position2;

@property (nonatomic, readonly) BrickView *brickView1;
@property (nonatomic, readonly) BrickView *brickView2;

@property (nonatomic, readonly) UIView *maskView;

@property (nonatomic, readonly) int type;

@property (nonatomic, readonly) bool visible;

@property (nonatomic, readonly) bool open;

@property (nonatomic, readonly) CALayer *connectionMaskLayer;
@property (nonatomic, readonly) UIImageView *connectionGradientView;

@end
