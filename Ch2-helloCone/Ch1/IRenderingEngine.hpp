//
//  IRenderingEngine.hpp
//  Ch1
//
//  Created by tomy yao on 2018/2/8.
//  Copyright © 2018年 tomy yao. All rights reserved.
//

#ifndef IRenderingEngine_hpp
#define IRenderingEngine_hpp

#include <stdio.h>

enum DeviceOrientation {
    DeviceOrientationUnknown,
    DeviceOrientationPortrait,
    DeviceOrientationPortraitUpsideDown,
    DeviceOrientationLandscapeLeft,
    DeviceOrientationLandscapeRight,
    DeviceOrientationFaceUp,
    DeviceOrientationFaceDown,
};

struct IRenderingEngine* CreateRenderer();

struct IRenderingEngine {
    virtual void Initialize(int width, int height) = 0;
    virtual void Render() const = 0;
    virtual void UpdateAnimation(float timeStep) = 0;
    virtual void OnRotate(DeviceOrientation newOrientation) = 0;
    virtual ~IRenderingEngine() {}
};
#endif /* IRenderingEngine_hpp */
