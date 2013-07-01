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

#import "Quads.h"
#import "Globals.h"

@implementation Quads

@synthesize color;
@synthesize backgroundColor;

@synthesize texture;

@synthesize isOrthoProjection;
@synthesize depthTestEnabled;
@synthesize faceToCamera;

@synthesize translation;
@synthesize rotation;

- (id) init {
    if (self = [super init]) {
        isFixed = false;
        isOrthoProjection = false;
        depthTestEnabled = true;
        faceToCamera = false;
        translation = GLKVector3Make(0.0f, 0.0f, 0.0f);
        rotation = GLKVector3Make(0.0f, 0.0f, 0.0f);
        backgroundColor = GLKVector4Make(0.0f, 0.0f, 0.0f, 0.0f);
    }
    return self;
}

- (void) dealloc {
    if (quadCount != 0) {
	    glDeleteBuffers(1, &vertexBuffer);
		glDeleteVertexArraysOES(1, &vertexArray);
    }
}

- (void) beginWithColor:(GLKVector4)col {
    quadCount = 0;
    textureToggled = false;
    color = col;
}

- (void) beginWithTexture:(Texture)tex {
    [self beginWithTexture:tex color:GLKVector4Make(1.0f, 1.0f, 1.0f, 1.0f)];
}

- (void) beginWithTexture:(Texture)tex color:(GLKVector4)col {
    quadCount = 0;
    texture = tex;
    textureToggled = true;
    color = col;
}

- (void) end {
    if (quadCount == 0 || isFixed) {
        return;
    }
    isFixed = true;
    int v = 0;
    for (int i = 0; i < quadCount; i++) {
        // Triangle 1
        vertices[v + 0] = quads[i].x1;
        vertices[v + 1] = quads[i].y1;
        vertices[v + 2] = quads[i].z1;
        vertices[v + 3] = texture.texCoordX2;
        vertices[v + 4] = texture.texCoordY2;
		v += 8;
        
        vertices[v + 0] = quads[i].x2;
        vertices[v + 1] = quads[i].y2;
        vertices[v + 2] = quads[i].z2;
        vertices[v + 3] = texture.texCoordX2;
        vertices[v + 4] = texture.texCoordY1;
		v += 8;
        
        vertices[v + 0] = quads[i].x3;
        vertices[v + 1] = quads[i].y3;
        vertices[v + 2] = quads[i].z3;
        vertices[v + 3] = texture.texCoordX1;
        vertices[v + 4] = texture.texCoordY1;
		v += 8;
        
        // Triangle 2
        vertices[v + 0] = quads[i].x3;
        vertices[v + 1] = quads[i].y3;
        vertices[v + 2] = quads[i].z3;
        vertices[v + 3] = texture.texCoordX1;
        vertices[v + 4] = texture.texCoordY1;
		v += 8;
        
        vertices[v + 0] = quads[i].x4;
        vertices[v + 1] = quads[i].y4;
        vertices[v + 2] = quads[i].z4;
        vertices[v + 3] = texture.texCoordX1;
        vertices[v + 4] = texture.texCoordY2;
		v += 8;
        
        vertices[v + 0] = quads[i].x1;
        vertices[v + 1] = quads[i].y1;
        vertices[v + 2] = quads[i].z1;
        vertices[v + 3] = texture.texCoordX2;
        vertices[v + 4] = texture.texCoordY2;
		v += 8;
	}
    [self calculateNormals];
    
    glGenVertexArraysOES(1, &vertexArray);
    glBindVertexArrayOES(vertexArray);
    
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), BUFFER_OFFSET(0));
    
    if (textureToggled) {
    	glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    	glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), BUFFER_OFFSET(3));
    } else {
    	glDisableVertexAttribArray(GLKVertexAttribTexCoord0);
    }
    
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 8 * sizeof(GLfloat), BUFFER_OFFSET(5));
    
    glBindVertexArrayOES(0);
}

- (void) refineTexCoordsX1:(float)x1 y1:(float)y1 x2:(float)x2 y2:(float)y2 {
    textureSetTexCoords(&texture, x1, y1, x2, y2);
}

- (void) calculateNormals {
    int v = 0;
    for (int i = 0; i < quadCount * 2; i++) {
        GLKVector3 p1 = GLKVector3Make(vertices[v +  0 + 0], vertices[v +  0 + 1], vertices[v +  0 + 2]);
        GLKVector3 p2 = GLKVector3Make(vertices[v +  8 + 0], vertices[v +  8 + 1], vertices[v +  8 + 2]);
        GLKVector3 p3 = GLKVector3Make(vertices[v + 16 + 0], vertices[v + 16 + 1], vertices[v + 16 + 2]);
        
        GLKVector3 v1 = GLKVector3Subtract(p2, p1);
        GLKVector3 v2 = GLKVector3Subtract(p3, p1);
        
        GLKVector3 n = GLKVector3Normalize(GLKVector3CrossProduct(v1, v2));
        
        vertices[v + 5] = n.x;
        vertices[v + 6] = n.y;
        vertices[v + 7] = n.z;
        v += 8;
        
        vertices[v + 5] = n.x;
        vertices[v + 6] = n.y;
        vertices[v + 7] = n.z;
        v += 8;
        
        vertices[v + 5] = n.x;
        vertices[v + 6] = n.y;
        vertices[v + 7] = n.z;
        v += 8;
    }
}

- (void) addQuadVerticalX1:(float)x1 y1:(float)y1 z1:(float)z1 x2:(float)x2 y2:(float)y2 z2:(float)z2 {
    [self addQuadX1:x2 y1:y1 z1:z2 x2:x2 y2:y2 z2:z2 x3:x1 y3:y2 z3:z1 x4:x1 y4:y1 z4:z1];
}

- (void) addQuadHorizontalX1:(float)x1 z1:(float)z1 x2:(float)x2 z2:(float)z2 y:(float)y {
    [self addQuadX1:x1 y1:y z1:z1 x2:x1 y2:y z2:z2 x3:x2 y3:y z3:z2 x4:x2 y4:y z4:z1];
}

- (void) addQuadHorizontalX1:(float)x1 z1:(float)z1 x2:(float)x2 z2:(float)z2 x3:(float)x3 z3:(float)z3 x4:(float)x4 z4:(float)z4 y:(float)y {
    [self addQuadX1:x1 y1:y z1:z1 x2:x2 y2:y z2:z2 x3:x3 y3:y z3:z3 x4:x4 y4:y z4:z4];
}

- (void) addQuadX1:(float)x1 y1:(float)y1 z1:(float)z1 x2:(float)x2 y2:(float)y2 z2:(float)z2 x3:(float)x3 y3:(float)y3 z3:(float)z3 x4:(float)x4 y4:(float)y4 z4:(float)z4 {
    if (quadCount >= QUADS_MAX_COUNT) {
        NSLog(@"Too many quads!");
    }
    quads[quadCount].x1 = x1;
    quads[quadCount].y1 = y1;
    quads[quadCount].z1 = z1;
    quads[quadCount].x2 = x2;
    quads[quadCount].y2 = y2;
    quads[quadCount].z2 = z2;
    quads[quadCount].x3 = x3;
    quads[quadCount].y3 = y3;
    quads[quadCount].z3 = z3;
    quads[quadCount].x4 = x4;
    quads[quadCount].y4 = y4;
    quads[quadCount].z4 = z4;
    quadCount++;
}

- (void) render {
	if (!textureToggled) {
    	glEnable(GL_BLEND);
    	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    } else if (texture.blendEnabled) {
        glEnable(GL_BLEND);
        glBlendFunc(texture.blendSrc, texture.blendDst);
    } else {
        glDisable(GL_BLEND);
    }
    
    if (!depthTestEnabled || isOrthoProjection) {
        glDisable(GL_DEPTH_TEST);
    }
    
    glEnable(GL_CULL_FACE);
    glCullFace(GL_BACK);
    
    GLKBaseEffect *glkEffect = glkEffectNormal;
    
    glkEffect.texture2d0.name = texture.id;
    glkEffect.texture2d0.enabled = textureToggled ? GL_TRUE : GL_FALSE;
    
    glkEffect.useConstantColor = YES;
    glkEffect.constantColor = color;
    
    GLKMatrix4 modelViewMatrix = isOrthoProjection ? orthoModelViewMatrix : sceneModelViewMatrix;
    modelViewMatrix = GLKMatrix4Translate(modelViewMatrix, translation.x, translation.y, translation.z);
	if (faceToCamera) {
        modelViewMatrix.m00 = 1.0f; modelViewMatrix.m01 = 0.0f; modelViewMatrix.m02 = 0.0f;
        modelViewMatrix.m10 = 0.0f; modelViewMatrix.m11 = 1.0f; modelViewMatrix.m12 = 0.0f;
        modelViewMatrix.m20 = 0.0f; modelViewMatrix.m21 = 0.0f; modelViewMatrix.m22 = 1.0f;
    } else {
        if (rotation.x != 0.0f) {
            modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, rotation.x, 1.0f, 0.0f, 0.0f);
        }
        if (rotation.y != 0.0f) {
            modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, rotation.y, 0.0f, 1.0f, 0.0f);
        }
        if (rotation.z != 0.0f) {
            modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, rotation.z, 0.0f, 0.0f, 1.0f);
        }
    }
    
    glkEffect.transform.modelviewMatrix = modelViewMatrix;
    glkEffect.transform.projectionMatrix = isOrthoProjection ? orthoProjectionMatrix : sceneProjectionMatrix;
    
    [glkEffect prepareToDraw];
    
    glBindVertexArrayOES(vertexArray);
    glDrawArrays(GL_TRIANGLES, 0, quadCount * 6);

    if (!depthTestEnabled || isOrthoProjection) {
        glEnable(GL_DEPTH_TEST);
    }
}

@end