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

#import <QuartzCore/QuartzCore.h>
#import "Textures.h"
#import "Globals.h"

Texture wallTexture;

Texture textureMake(GLuint id) {
    Texture texture;
    texture.texCoordX1 = 0.0f;
    texture.texCoordY1 = 0.0f;
    texture.texCoordX2 = 1.0f;
    texture.texCoordY2 = 1.0f;
    texture.blendEnabled = false;
    texture.id = id;
    texture.released = false;
    return texture;
}

Texture textureCopy(Texture texture, float texCoordX1, float texCoordY1, float texCoordX2, float texCoordY2) {
    Texture newTexture;
    newTexture.id = texture.id;
    newTexture.blendEnabled = texture.blendEnabled;
    newTexture.blendSrc = texture.blendSrc;
    newTexture.blendDst = texture.blendDst;
    newTexture.texCoordX1 = texCoordX1;
    newTexture.texCoordY1 = texCoordY1;
    newTexture.texCoordX2 = texCoordX2;
    newTexture.texCoordY2 = texCoordY2;
    newTexture.released = false;
    return newTexture;
}

void textureCopyTo(Texture src, Texture *dst) {
    dst->id = src.id;
    dst->blendEnabled = src.blendEnabled;
    dst->blendSrc = src.blendSrc;
    dst->blendDst = src.blendDst;
    dst->texCoordX1 = src.texCoordX1;
    dst->texCoordY1 = src.texCoordY1;
    dst->texCoordX2 = src.texCoordX2;
    dst->texCoordY2 = src.texCoordY2;
    dst->released = false;
}

void textureRelease(Texture *texture) {
    if (texture->released) {
        return;
    }
    glDeleteTextures(1, &texture->id);
    texture->released = true;
}

void textureSetTexCoords(Texture *texture, float texCoordX1, float texCoordY1, float texCoordX2, float texCoordY2) {
    texture->texCoordX1 = texCoordX1;
    texture->texCoordY1 = texCoordY1;
    texture->texCoordX2 = texCoordX2;
    texture->texCoordY2 = texCoordY2;
}

void textureSetBlend(Texture *texture, GLenum blendSrc, GLenum blendDst) {
    texture->blendEnabled = true;
    texture->blendSrc = blendSrc;
    texture->blendDst = blendDst;
}

@implementation Textures

- (void) load {
    wallTexture = [self loadTexture:@"test.png"];
}

- (void) dealloc {
    NSLog(@"Releasing textures");
    textureRelease(&wallTexture);
}

- (Texture) loadTextureFromData:(NSData*)data {
    NSError *error = nil;
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithContentsOfData:data options:nil error:&error];
    if (error) {
        NSLog(@"Error loading texture: %@", error);
    }
    return [self textureFromTextureInfo:textureInfo repeat:false];
}

- (Texture) loadTexture:(NSString*)filename {
    return [self loadTexture:filename repeat:false];
}

- (Texture) loadTexture:(NSString*)filename repeat:(bool)repeat {
    NSLog(@"Loading texture: %@", filename);
    return [self loadTextureWithImage:[UIImage imageNamed:filename] repeat:repeat];
}

- (Texture) loadTextureWithImage:(UIImage*)image repeat:(bool)repeat {
    NSError *error = nil;
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:image.CGImage options:nil error:&error];
    if (error) {
        NSLog(@"Error loading texture: %@", error);
    }
    return [self textureFromTextureInfo:textureInfo repeat:repeat];
}

- (void) loadTextureWithImageAsync:(UIImage*)image texture:(Texture*)texture {
    [textureLoader textureWithCGImage:image.CGImage options:nil queue:NULL completionHandler:^(GLKTextureInfo *textureInfo, NSError *error) {
        if (error) {
            NSLog(@"Error loading texture asynchronously: %@", error);
            return;
        }
        textureCopyTo([self textureFromTextureInfo:textureInfo repeat:false], texture);
    }];
}

- (Texture) textureFromTextureInfo:(GLKTextureInfo*)textureInfo repeat:(bool)repeat {
    glBindTexture(GL_TEXTURE_2D, textureInfo.name);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    if (repeat) {
	    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    }
	glBindTexture(GL_TEXTURE_2D, 0);
    Texture texture = textureMake(textureInfo.name);
    texture.width = textureInfo.width;
    texture.height = textureInfo.height;
    texture.imageWidth = textureInfo.width;
    texture.imageHeight = textureInfo.height;
    return texture;
}

@end