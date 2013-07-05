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

#import "ExternalDisplay.h"

ExternalDisplay *externalDisplayInstance = nil;

@implementation ExternalDisplay

@synthesize window;
@synthesize screen;

+ (ExternalDisplay *)instance {
    if (externalDisplayInstance == nil) {
        externalDisplayInstance = [[ExternalDisplay alloc] init];
    }
    return externalDisplayInstance;
}

- (void)initialize {
    if ([UIScreen screens].count > 1) {
        screen = [[UIScreen screens] objectAtIndex:1];
        UIScreenMode *bestScreenMode = nil;
        for (UIScreenMode *screenMode in screen.availableModes) {
            NSLog(@"Resolution: %f, %f", screenMode.size.width, screenMode.size.height);
            if (bestScreenMode == nil || screenMode.size.width > bestScreenMode.size.width) {
                bestScreenMode = screenMode;
            }
        }
        NSLog(@"Choose: %f, %f", bestScreenMode.size.width, bestScreenMode.size.height);
        screen.currentMode = bestScreenMode;
    } else {
        NSLog(@"No external displays found!");
        screen = [UIScreen mainScreen];
    }
    window = [[UIWindow alloc] initWithFrame:screen.bounds];
    window.backgroundColor = [UIColor blackColor];
    window.screen = screen;
}

@end
