//
//  GLView.m
//  Ch1
//
//  Created by tomy yao on 2018/1/29.
//  Copyright © 2018年 tomy yao. All rights reserved.
//

#import "GLView.h"
#import <OpenGLES/ES2/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <QuartzCore/QuartzCore.h>
#import "CC3GLMatrix.h"



typedef struct Vertex {
    float Position[3];
    float Color[4];
}Vertex;


//const Vertex Vertices[] = {
//    {{-0.5, -0.866}, {1, 1, 0.5f, 1}},
//    {{0.5, -0.866},  {1, 1, 0.5f, 1}},
//    {{0, 1},         {1, 1, 0.5f, 1}},
//    {{-0.5, -0.866}, {0.5f, 0.5f, 0.5f}},
//    {{0.5, -0.866},  {0.5f, 0.5f, 0.5f}},
//    {{0, -0.4f},     {0.5f, 0.5f, 0.5f}},
//};
NSInteger allSize = 0;
Vertex *Vertices;

const GLubyte indices[] = {
    0, 1, 2,
    3,4,5
};

static CGFloat rotationSpeed = 0.5;

@interface GLView ()
@property (nonatomic, strong) EAGLContext *contex;
@property (nonatomic, strong) CAEAGLLayer *eaglLayer;

@property (nonatomic, assign) CGFloat currentDegree;


@property (nonatomic, assign) GLuint colorRenderBuffer;
@property (nonatomic, assign) GLuint depthRenderBuffer;
@property (nonatomic, assign) GLuint positionSlot;
@property (nonatomic, assign) GLuint colorSlot;

@property (nonatomic, assign) GLuint projectionUniform;
@property (nonatomic, assign) GLuint modleUniform;

@end

@implementation GLView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self genData];
        [self setupLayer];
        [self setupContex];
        [self setupdepthBuffer];    //必须再renderbuffer之前
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        [self compileShaders];
        [self setupVBO];
        
        [self applyOrthoX:1 Y:1];
        
        [self setupDisplayLink];
//        _floorTexture = [self setupTexture:@"tile_floor.png" texure:GL_TEXTURE0];
//        _fishTexture = [self setupTexture:@"item_powerup_fish.png" texure:GL_TEXTURE1];
//        [self render:nil];
        
    }
    
    return self;
}

- (void)dealloc {
    [self unregisterRotationNotify];
}

- (void)registerRotationNotify {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(rotaionNotify:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)unregisterRotationNotify {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)rotaionNotify:(NSNotification*)notify {
    UIDeviceOrientation oritation = [[UIDevice currentDevice] orientation];
    CGFloat degree = 0;
    switch (oritation) {
        case UIDeviceOrientationPortrait: {
            degree = 0;
        }
            break;
        case UIDeviceOrientationPortraitUpsideDown: {
            degree = 180;
        }
            break;
        case UIDeviceOrientationLandscapeLeft: {
            degree = 270;
        }
            break;
        case UIDeviceOrientationLandscapeRight: {
            degree = 90;
        }
            break;
        default:
            break;
    }
    [self applyRotation:degree];
}

- (void)genData {
    const float coneRadius = 0.5f;
    const float coneHeight = 1;
    NSInteger count = 40;
    
    CGFloat delta = 2*M_PI/count;
    CGFloat theta = 0;
    
    allSize = sizeof(Vertex) * (count*2+count+1);
    Vertices = malloc(allSize);
    for (NSInteger i = 0; i < count*2; i = i+2) {
        CGFloat brightness =  fabsf(sinf(theta));
        
        Vertex *node = Vertices+i;
        node->Position[0] = 0;
        node->Position[1] = 1;
        node->Position[2] = 0;

        node->Color[0] = brightness;
        node->Color[1] = brightness;
        node->Color[2] = brightness;
        node->Color[3] = 1;
        
        Vertex *nextNode = Vertices+i+1;
        nextNode->Position[0] = coneRadius *cos(theta);
        nextNode->Position[1] = 1 - coneHeight;
        nextNode->Position[2] = coneRadius * sin(theta);
        
        nextNode->Color[0] = brightness;
        nextNode->Color[1] = brightness;
        nextNode->Color[2] = brightness;
        nextNode->Color[3] = 1;

        theta += delta;
    }
    
    Vertex *node = Vertices+count*2;
    node->Color[0] = 0.75;
    node->Color[1] = 0.75;
    node->Color[2] = 0.75;
    node->Color[3] = 1;

    node->Position[0] = 0;
    node->Position[1] = 1 - coneHeight;
    node->Position[2] = 0;
    
    theta = 0;
    for (NSInteger i = count*2+1; i < count*2+count+1; i++) {
        Vertex *node = Vertices+i;
        node->Color[0] = 0.75;
        node->Color[1] = 0.75;
        node->Color[2] = 0.75;
        node->Color[3] = 1;

        node->Position[0] = coneRadius *cos(theta);
        node->Position[1] = 1 - coneHeight;
        node->Position[2] = coneRadius *sin(theta);
        theta += delta;
    }
}

+ (Class)layerClass {
    return [CAEAGLLayer class];
}

- (void)setupLayer {
    _eaglLayer = (CAEAGLLayer*)self.layer;
    _eaglLayer.opaque = YES;
}

- (void)setupContex {
    _contex = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_contex) {
        NSLog(@"failed to create contex opengles 3");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_contex]) {
        NSLog(@"failed to set current opengl context");
        exit(1);
    }
    
}

- (void)setupRenderBuffer {
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_contex renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

- (void)setupVBO {
    GLuint VBO;
    glGenBuffers(1, &VBO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, allSize, Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indices), indices, GL_STATIC_DRAW);
}

- (void)setupFrameBuffer {
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderBuffer);
}

- (void)setupdepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
}

- (void)render:(CADisplayLink*)displayLink {
    glClearColor(0.5, 0.5, 0.5, 1.0);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
    
    
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    self.currentDegree += rotationSpeed;
    [self applyRotation:self.currentDegree];
    
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 7*sizeof(float), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE, 7*sizeof(float), 3*sizeof(float));
//    glVertexAttribPointer(_texureSlot, 2, GL_FLOAT, GL_FALSE, 8*sizeof(float), 6*sizeof(float));
    
//    glUniform1i(_textureUniform, 0);
//    glUniform1i(_fishUniform, 1);
    
//    glDrawElements(GL_TRIANGLES, sizeof(indices)/sizeof(indices[0]), GL_UNSIGNED_BYTE, 0);
    
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 40*2);
    glDrawArrays(GL_TRIANGLE_FAN, 40*2, 41);

    [_contex presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)compileShaders {
    GLuint vertexShader = [self compileShader:@"SimpleVertex" withType:GL_VERTEX_SHADER];
    GLuint fragementShader = [self compileShader:@"SimpleFragment" withType:GL_FRAGMENT_SHADER];
    
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragementShader);
    glLinkProgram(programHandle);
    
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    glUseProgram(programHandle);
    
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
//    _texureSlot = glGetAttribLocation(programHandle, "TexturCoord");
//
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
    _modleUniform = glGetUniformLocation(programHandle, "Modelview");
//
//    _textureUniform = glGetUniformLocation(programHandle, "ourTexture");
//    _fishUniform = glGetUniformLocation(programHandle, "fishTexture");
    
    
    
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
//    glEnableVertexAttribArray(_texureSlot);
    
    
}

- (void)setupDisplayLink {
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}


#pragma mark - tool
- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType {
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"glsl"];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"error loading shader");
        exit(1);
    }
    
    GLuint shaderHandle = glCreateShader(shaderType);
    
    const char *shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = [shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    glCompileShader(shaderHandle);
    
    GLuint complieSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &complieSuccess);
    if (complieSuccess == GL_FALSE) {
        GLchar message[256];
        glGetShaderInfoLog(shaderHandle, sizeof(message), 0, &message[0]);
        NSString *messageString = [NSString stringWithUTF8String:message];
        NSLog(@"%@", messageString);
        exit(1);
    }
    return shaderHandle;
}

- (GLuint)setupTexture:(NSString*)fileName texure:(NSInteger)index {
    CGImageRef spirteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spirteImage) {
        NSLog(@"fiale to load image");
        exit(1);
    }
    size_t width = CGImageGetWidth(spirteImage);
    size_t height = CGImageGetHeight(spirteImage);
    
    GLubyte *spirteData = (GLubyte*)calloc(width * height * 4, sizeof(GLubyte));
    CGContextRef spriteContext = CGBitmapContextCreate(spirteData, width, height, 8, width * 4, CGImageGetColorSpace(spirteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spirteImage);
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glActiveTexture(index);
    glBindTexture(GL_TEXTURE_2D, texName);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spirteData);
    
    free(spirteData);
    return texName;
}

- (void)applyOrthoX:(CGFloat)maxX Y:(CGFloat)maxY {
    float a = 1.0f / maxX;
    float b = 1.0f / maxY;
    float ortho[16] = {
        a, 0,  0, 0,
        0, b,  0, 0,
        0, 0, 1, 0,
        0, 0,  0, 1
    };
    
    CC3GLMatrix *rotation = [[CC3GLMatrix alloc] initIdentity];
//    [rotation populateFromFrustumLeft:-1 andRight:1 andBottom:-1 andTop:1 andNear:-1 andFar:1];
    
    [rotation populateOrthoFromFrustumLeft:-1.6 andRight:1.6 andBottom:-2.4 andTop:2.4 andNear:-5 andFar:10];
    glUniformMatrix4fv(_projectionUniform, 1, 0, rotation.glMatrix);
}

- (void)applyRotation:(CGFloat)degrees {
//    float radians = degrees * 3.14159f / 180.0f;
//    float s = sin(radians);
//    float c = cos(radians);
//    float zRotation[16] = {
//        c, s, 0, 0,
//        -s, c, 0, 0,
//        0, 0, 1, 0,
//        0, 0, 0, 1
//    };
    
    CC3GLMatrix *rotation = [[CC3GLMatrix alloc] initIdentity];
    CC3Vector rd = {degrees,degrees, 0};
    
    [rotation translateByZ:-7];
    [rotation rotateBy:rd];

    
    glUniformMatrix4fv(_modleUniform, 1, 0, rotation.glMatrix);
}

@end
