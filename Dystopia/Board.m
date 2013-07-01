// Copyright (c) 2012, Daniel Andersen (daniel@trollsahead.dk)
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

#import "Board.h"
#import "Globals.h"

@implementation Board

- (id) init {
    if (self = [super init]) {
        [self initialize];
    }
    return self;
}

- (void) initialize {
    textures = [[Textures alloc] init];
    [textures load];
    
    photoOverlay = [[Quads alloc] init];
    [photoOverlay beginWithTexture:wallTexture];
    [photoOverlay setIsOrthoProjection:true];
    [photoOverlay addQuadX1:0.0f y1:0.0f z1:0.0f
                         x2:1.0f y2:0.0f z2:0.0f
                         x3:1.0f y3:1.0f z3:0.0f
                         x4:0.0f y4:1.0f z4:0.0f];
    [photoOverlay end];
    
    //[self setupTextureCache];
    //[self setupCamera:AVCaptureSessionPreset640x480];
    //[self startCapture];
}

- (void) createBoard {
    NSLog(@"Board initialized!");
}

- (void) reactivate {
}

- (void) inactivate {
}

- (void) tap:(GLKVector2)p {
}

- (void) update {
}

- (void) render {
    [self setupPosition];
    //[photoOverlay render];
}

- (void) setupPosition {
    GLKVector3 v = GLKVector3Make(0.0f, 0.0f, 0.0f);
    worldPosition = GLKVector3Make(v.x, -2.5f, v.y);
    sceneModelViewMatrix = GLKMatrix4Rotate(GLKMatrix4Identity, v.z, 0.0f, 1.0f, 0.0f);
    sceneModelViewMatrix = GLKMatrix4Translate(sceneModelViewMatrix, worldPosition.x, worldPosition.y, worldPosition.z);
}

- (void)setupTextureCache {
    NSLog(@"Setup texture cache");
#if defined(__IPHONE_6_0)
    CVReturn error = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, openglContext, NULL, &coreVideoTextureCache);
#else
    CVReturn error = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)openglContext, NULL, &coreVideoTextureCache);
#endif
    if (error) {
        NSAssert(NO, @"Error at CVOpenGLESTextureCacheCreate %d", error);
    }
}

- (void)setupCamera:(NSString *)cameraSessionPreset {
    NSLog(@"Setup camera");
    captureSession = [[AVCaptureSession alloc] init];
    [captureSession beginConfiguration];
    
    if ([captureSession canSetSessionPreset:cameraSessionPreset]) {
        [captureSession setSessionPreset:cameraSessionPreset];
    }
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    /*
     for (AVCaptureDevice *d in devices) {
     if (d.position == AVCaptureDevicePositionFront && [d hasMediaType:AVMediaTypeVideo]) {
     videoDevice = d;
     }
     NSLog(@"device %@", d);
     } //6
     */
    
    NSError *error;
    AVCaptureDeviceInput *videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
    [captureSession addInput:videoInput];
    
    if (error) {
        NSLog(@"video device input %@", error.localizedDescription);
    }
    
    AVCaptureVideoDataOutput *videoOutput = [[AVCaptureVideoDataOutput alloc] init];
	[videoOutput setAlwaysDiscardsLateVideoFrames:NO];
    
	[videoOutput setVideoSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
    
    [videoOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    //    [videoOutput setSampleBufferDelegate:self queue:[GPUImageOpenGLESContext sharedOpenGLESQueue]];
	if ([captureSession canAddOutput:videoOutput]) {
		[captureSession addOutput:videoOutput];
	} else {
		NSLog(@"Couldn't add video output");
	}
    
    [captureSession commitConfiguration];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection  {
    //NSLog(@"got some output data");
    [self processFrame:sampleBuffer];
}

- (void)startCapture {
    [captureSession startRunning];
}

- (void)stopCapture {
    [captureSession stopRunning];
}

- (void)processFrame:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef cameraFrame = CMSampleBufferGetImageBuffer(sampleBuffer);
    int bufferWidth = CVPixelBufferGetWidth(cameraFrame);
    int bufferHeight = CVPixelBufferGetHeight(cameraFrame);
    
	//CMTime currentTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    
    //This code is a modified version of the code from the Camera class of the GPUImage framework https://github.com/BradLarson/GPUImage
    
    CVPixelBufferLockBaseAddress(cameraFrame, 0);
    
    CVOpenGLESTextureRef texture = NULL;
    CVReturn error = CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, coreVideoTextureCache, cameraFrame, NULL, GL_TEXTURE_2D, GL_RGBA, bufferWidth, bufferHeight, GL_BGRA, GL_UNSIGNED_BYTE, 0, &texture);
    
    if (!texture || error) {
        NSLog(@"Camera CVOpenGLESTextureCacheCreateTextureFromImage failed (error: %d)", error);
        return;
    }
    
    // !!!
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(cameraFrame);
    size_t height = CVPixelBufferGetHeight(cameraFrame);
    void *src_buff = CVPixelBufferGetBaseAddress(cameraFrame);
    
    NSData *data = [NSData dataWithBytes:src_buff length:bytesPerRow * height];
    wallTexture = [textures loadTextureFromData:data];
    photoOverlay.texture = wallTexture;
    // !!!
    
    
    outputTexture = CVOpenGLESTextureGetName(texture);
    //        glBindTexture(CVOpenGLESTextureGetTarget(texture), outputTexture);
    glBindTexture(GL_TEXTURE_2D, outputTexture);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    CVPixelBufferUnlockBaseAddress(cameraFrame, 0);
    
    //wallTexture.id = outputTexture;
    //[photoOverlay setTexture:wallTexture];
    
    //[[NSNotificationCenter defaultCenter] postNotificationName:@"NewCameraTextureReady" object:nil];
    
    // Flush the CVOpenGLESTexture cache and release the texture
    CVOpenGLESTextureCacheFlush(coreVideoTextureCache, 0);
    CFRelease(texture);
    //_outputTexture = 0;
}

@end
