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

#import "ViewController.h"
#import "Board.h"
#import "Globals.h"
#import "BoardRecognizer.h"

enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXCOORD,
};

@interface ViewController () {
    
@private
    
    Board *board;
    
    float frameSeconds;
    double startTime;
}

@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@end

@implementation ViewController

@synthesize context = _context;
@synthesize effect = _effect;

- (void) didBecomeInactive {
    [board inactivate];
}

- (void) didBecomeActive {
    [board reactivate];
}

- (void) viewDidLoad {
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    openglContext = self.context;
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    self.preferredFramesPerSecond = 60;
    frameSeconds = FRAME_RATE;
    
    [self setupGL];
    
    board = [[Board alloc] init];
	[board createBoard];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 640 * 0.5f, 424 * 0.5f)];
    imageView.image = [[[BoardRecognizer alloc] init] filterAndThresholdUIImage:[UIImage imageNamed:@"test.png"]];
    [self.view addSubview:imageView];
    
    UIImageView *imageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(0.0f, 424 * 0.5f, 640 * 0.5f, 424 * 0.5f)];
    imageView2.image = [UIImage imageNamed:@"test.png"];
    [self.view addSubview:imageView2];

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapFrom:)];
    [self.view addGestureRecognizer:tapRecognizer];
    
    startTime = CFAbsoluteTimeGetCurrent();
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
	self.context = nil;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    NSLog(@"Warning: Low memory!");
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight;
}

- (void)setupGL {
    [EAGLContext setCurrentContext:self.context];
    textureLoader = [[GLKTextureLoader alloc] initWithSharegroup:self.context.sharegroup];
    
    glkEffectNormal = [[GLKBaseEffect alloc] init];
    self.effect = glkEffectNormal;
    
    glEnable(GL_DEPTH_TEST);
    
    [self getScreenSize];
}

- (void)tearDownGL {
    [EAGLContext setCurrentContext:self.context];
    
    self.effect = nil;
}

- (void) getScreenSize {
    screenWidth = [UIScreen mainScreen].bounds.size.width * [UIScreen mainScreen].scale;
    screenHeight = [UIScreen mainScreen].bounds.size.height * [UIScreen mainScreen].scale;
    
    screenWidthNoScale = [UIScreen mainScreen].bounds.size.width;
    screenHeightNoScale = [UIScreen mainScreen].bounds.size.height;
    
    aspectRatio = fabsf(screenWidth / screenHeight);
    
    screenSizeInv[0] = 1.0f / (float) screenWidth;
    screenSizeInv[1] = 1.0f / (float) screenHeight;
    
    refractionConstant = 0.005 * (480.0f / (float) screenHeight);
    
    NSLog(@"Screen size: %i, %i", (int) screenWidth, (int) screenHeight);
}

- (void) handleTapFrom:(UITapGestureRecognizer*)recognizer {
    CGPoint touchLocation = [recognizer locationInView:recognizer.view];
    [board tap:GLKVector2Make(touchLocation.x / screenHeightNoScale, touchLocation.y / screenWidthNoScale)];
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update {
    sceneProjectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspectRatio, 0.1f, 10.0f);
    
    orthoProjectionMatrix = GLKMatrix4MakeOrtho(0.0f, 1.0f, 0.0f, 1.0f, -1.0f, 1.0f);
    orthoModelViewMatrix = GLKMatrix4Identity;
    
    frameSeconds += self.timeSinceLastUpdate;
    if (frameSeconds / FRAME_RATE > 2.0f) {
        frameSeconds = FRAME_RATE * 2.0f;
    }
    while (frameSeconds >= FRAME_RATE) {
        [board update];
        frameSeconds -= FRAME_RATE;
    }
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [board render];
}

@end