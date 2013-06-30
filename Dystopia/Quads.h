// Copyright (c) 2012, Daniel Andersen (dani_ande@yahoo.dk)
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

#import <GLKit/GLKit.h>
#import "Textures.h"

#define QUADS_MAX_COUNT 256
#define VERTICES_MAX_COUNT (QUADS_MAX_COUNT * 9 * 3 * sizeof(GLfloat))

typedef struct {
    float x1, y1, z1;
    float x2, y2, z2;
    float x3, y3, z3;
    float x4, y4, z4;
} Quad;

@interface Quads : NSObject {
    
@private
    
    Quad quads[QUADS_MAX_COUNT];
    int quadCount;
    
    Texture texture;
    bool textureToggled;
    
    GLKVector4 color;
    GLKVector4 backgroundColor;
    
    GLfloat vertices[VERTICES_MAX_COUNT];
    
    GLuint vertexArray;
    GLuint vertexBuffer;
    
    bool isOrthoProjection;
    bool depthTestEnabled;
    
    bool faceToCamera;
    
    GLKVector3 translation;
    GLKVector3 rotation;
    
    bool isFixed;
}

@property (readwrite) GLKVector4 color;
@property (readwrite) GLKVector4 backgroundColor;

@property (readwrite) Texture texture;

@property (readwrite) bool isOrthoProjection;
@property (readwrite) bool depthTestEnabled;
@property (readwrite) bool faceToCamera;

@property (readwrite) GLKVector3 translation;
@property (readwrite) GLKVector3 rotation;

- (id) init;
- (void) dealloc;

- (void) beginWithColor:(GLKVector4)col;
- (void) beginWithTexture:(Texture)texture;
- (void) beginWithTexture:(Texture)texture color:(GLKVector4)col;
- (void) end;

- (void) refineTexCoordsX1:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2;

- (void) addQuadVerticalX1:(float)x1 y1:(float)y1 z1:(float)z1 x2:(float)x2 y2:(float)y2 z2:(float)z2;
- (void) addQuadHorizontalX1:(float)x1 z1:(float)z1 x2:(float)x2 z2:(float)z2 y:(float)y;
- (void) addQuadHorizontalX1:(float)x1 z1:(float)z1 x2:(float)x2 z2:(float)z2 x3:(float)x3 z3:(float)z3 x4:(float)x4 z4:(float)z4 y:(float)y;
- (void) addQuadX1:(float)x1 y1:(float)y1 z1:(float)z1 x2:(float)x2 y2:(float)y2 z2:(float)z2 x3:(float)x3 y3:(float)y3 z3:(float)z3 x4:(float)x4 y4:(float)y4 z4:(float)z4;

- (void) render;

@end