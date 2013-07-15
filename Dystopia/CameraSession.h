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

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

#define CAMERA_SESSION_DELEGATE_INTERVAL_DEFAULT 0.5f
#define CAMERA_SESSION_DELEGATE_INTERVAL_FAST    0.1f

@protocol CameraSessionDelegate <NSObject>

- (void)processFrame:(UIImage *)image;
- (UIImage *)requestSimulatedImageIfNoCamera;

@end

@interface CameraSession : NSObject <AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureSession *session;
    AVCaptureDevice *device;
    id<CameraSessionDelegate> delegate;
    dispatch_queue_t frameProcessQueue;
    double lastDeliveredFrameTime;
    NSTimer *fakeDeliverFrameTimer;
}

- (id)initWithDelegate:(id<CameraSessionDelegate>)d;

- (void)start;
- (void)stop;

- (void)lock;
- (void)unlock;

@property (readonly) bool initialized;
@property (readwrite) bool readyToProcessFrame;
@property (readwrite) CFTimeInterval delegateProcessFrameInterval;

@end
