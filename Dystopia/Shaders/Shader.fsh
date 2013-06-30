//
//  Shader.fsh
//  Dystopia
//
//  Created by Daniel Andersen on 6/30/13.
//  Copyright (c) 2013 Daniel Andersen. All rights reserved.
//

varying lowp vec4 colorVarying;

void main()
{
    gl_FragColor = colorVarying;
}
