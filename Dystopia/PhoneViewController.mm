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

#import "PhoneViewController.h"
#import "GameViewController.h"
#import "ExternalDisplay.h"

extern PreviewableViewController *previewInstance;

@interface PhoneViewController () {
    GameViewController *gameViewController;
    bool started;
}

@end

@implementation PhoneViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupExternalDisplay];
    [self transitionToGame];
    started = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    super.overlayView.hidden = !started;
    [self.view bringSubviewToFront:super.overlayView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)startButtonPressed:(id)sender {
    [gameViewController startGame];
    super.overlayView.hidden = NO;
    started = YES;
}

- (void)setupExternalDisplay {
    [[ExternalDisplay instance] initialize];
}

- (void)transitionToGame {
    gameViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"gameViewController"];
    [ExternalDisplay instance].window.rootViewController = gameViewController;
    [[ExternalDisplay instance].window makeKeyAndVisible];
    previewInstance = [ExternalDisplay instance].externalDisplayFound ? self : gameViewController;
    if (![ExternalDisplay instance].externalDisplayFound) {
        [gameViewController startGame];
    }
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return UIInterfaceOrientationIsPortrait(interfaceOrientation);
}

- (BOOL)shouldAutorotate {
    return YES;
}

@end
