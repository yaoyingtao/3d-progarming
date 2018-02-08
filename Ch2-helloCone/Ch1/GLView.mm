//
//  GLView.m
//  Ch1
//
//  Created by tomy yao on 2018/1/29.
//  Copyright © 2018年 tomy yao. All rights reserved.
//

#import "GLView.h"
#import "IRenderingEngine.hpp"
#import <OpenGLES/ES2/glext.h>

@interface GLView (){
    struct IRenderingEngine *rendringEngine;
}
@property (nonatomic, strong) EAGLContext *contex;
@property (nonatomic, strong) CAEAGLLayer *eaglLayer;

@property (nonatomic, assign) CGFloat currentDegree;
@property (nonatomic, assign) CGFloat timestamp;


@end

@implementation GLView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupLayer];
        [self setupContex];
        [self setupRenderEngine];
        [self registerRotationNotify];
        [self setupDisplayLink];
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
    rendringEngine->OnRotate((DeviceOrientation)oritation);
    [self render:nil];
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

- (void)setupRenderEngine {
    rendringEngine = CreateRenderer();
    rendringEngine->Initialize(CGRectGetWidth(self.frame), CGRectGetHeight(self.frame));
    [_contex renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}


- (void)render:(CADisplayLink*)displayLink {
    if (displayLink) {
        CGFloat seconds = displayLink.timestamp - self.timestamp;
        self.timestamp = displayLink.timestamp;
        rendringEngine->UpdateAnimation(seconds);
        rendringEngine->Render();
    }

    [_contex presentRenderbuffer:GL_RENDERBUFFER];
}



- (void)setupDisplayLink {
    _timestamp = CACurrentMediaTime();
    CADisplayLink *displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}


@end
