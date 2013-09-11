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

#import "FakeCameraUtil.h"
#import "UIImage+OpenCV.h"
#import "CameraUtil.h"

@implementation FakeCameraUtil

+ (UIImage *)fakePerspectiveOnImage:(UIImage *)image {
    FourPoints srcPoints = {.p1 = CGPointMake(0.0f, 0.0f), .p2 = CGPointMake(image.size.width, 0.0f), .p3 = CGPointMake(image.size.width, image.size.height), .p4 = CGPointMake(0.0f, image.size.height)};
    FourPoints dstPoints = {.p1 = CGPointMake(15.0f, 25.0f), .p2 = CGPointMake(image.size.width - 15.0f, 25.0f), .p3 = CGPointMake(image.size.width - 15.0f, image.size.height - 25.0f), .p4 = CGPointMake(15.0f, image.size.height - 25.0f)};
    cv::Mat transformation = [CameraUtil findPerspectiveTransformationSrcPoints:srcPoints dstPoints:dstPoints];
    return [CameraUtil perspectiveTransformImage:image withTransformation:transformation toSize:image.size];
}

+ (UIImage *)distortImage:(UIImage *)image {
    UIGraphicsBeginImageContext(image.size);
    [image drawAtPoint:CGPointZero];
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, 1.0f);
    //CGContextStrokeRect(context, CGRectMake(10.0f, 10.0f, image.size.width - 20.0f, image.size.height - 20.0f));
    
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();
    
    return destImage;
}

+ (UIImage *)putHandsInImage:(UIImage *)image {
    CGSize handSize = CGSizeMake(30.0f, 100.0f);
    
    UIGraphicsBeginImageContext(image.size);
    [image drawAtPoint:CGPointZero];
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetLineWidth(context, 1.0f);

    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    //CGContextFillEllipseInRect(context, CGRectMake(70.0f, image.size.height - handSize.height, handSize.width, handSize.height));
    //CGContextFillEllipseInRect(context, CGRectMake(image.size.width - 90.0f, image.size.height - handSize.height, handSize.width, handSize.height));
    //CGContextFillEllipseInRect(context, CGRectMake((image.size.width - handSize.width) / 2.0f, image.size.height - handSize.height, handSize.width, handSize.height));
    //CGContextFillEllipseInRect(context, CGRectMake((image.size.width - handSize.width) / 2.0f, -20.0f, handSize.width, handSize.height));

    CGContextSetFillColorWithColor(context, [UIColor blackColor].CGColor);
    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
    //CGContextFillRect(context, CGRectMake(70.0f, image.size.height - handSize.height, handSize.width / 2.0f, handSize.height));
    //CGContextFillRect(context, CGRectMake(image.size.width - 90.0f, image.size.height - handSize.height, handSize.width / 2.0f, handSize.height));
    //CGContextFillRect(context, CGRectMake((image.size.width - handSize.width) / 2.0f, image.size.height - handSize.height, handSize.width / 2.0f, handSize.height));
    //CGContextFillRect(context, CGRectMake((image.size.width - handSize.width) / 2.0f, -20.0f, handSize.width / 2.0f, handSize.height));
    
    UIImage *destImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return destImage;
}

@end
