//
//  Explosion.h
//  Darken
//
//  Created by Robert Lummis on 1/10/12.
//  Copyright (c) 2012 ElectricTurkey Software. All rights reserved.
//

#import <Availability.h>
#import "CCParticleSystemPoint.h"
#import "CCParticleSystemQuad.h"

    // build each architecture with the optimal particle system
    // ARMv7, Mac or Simulator use "Quad" particle
#if defined(__ARM_NEON__) || defined(__MAC_OS_X_VERSION_MAX_ALLOWED) || TARGET_IPHONE_SIMULATOR
#define ARCH_OPTIMAL_PARTICLE_SYSTEM CCParticleSystemQuad

    // ARMv6 use "Point" particle
#elif __arm__
#define ARCH_OPTIMAL_PARTICLE_SYSTEM CCParticleSystemPoint
#else
#error(unknown architecture)
#endif

@interface Explosion : ARCH_OPTIMAL_PARTICLE_SYSTEM

@end
