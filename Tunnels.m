//
//  Tunnels.m
//  SteamBot
//
//  Created by DPayne on 5/6/14.
//  Copyright (c) 2014 Santuary of Darkness. All rights reserved.
//

#import "Tunnels.h"

#define ARC4RANDOM_MAX      0x100000000
// visibility on a 3,5-inch iPhone ends a 88 points and we want some meat
static const CGFloat minimumXPositionLeft = 150.0f;
// visibility ends at 480 and we want some meat
static const CGFloat maximumXPositionLeft = 350.0f;
// distance between top and bottom pipe
static const CGFloat poleDistance = 80.0f;

@implementation Tunnels

- (void)didLoadFromCCB {
}

-(void)restorePosition:(NSMutableArray *)restoreSettings{
    _leftBridge = [restoreSettings objectAtIndex:0];
    _rightBridge = [restoreSettings objectAtIndex:1];
}

- (void)setupRandomPosition {
    
    // value between 0.f and 1.f
    CGFloat random = ((double)arc4random() / ARC4RANDOM_MAX);
    CGFloat range = maximumXPositionLeft - minimumXPositionLeft;
    _leftBridge.position = ccp(minimumXPositionLeft + (random * range), _leftBridge.position.y);
    _rightBridge.position = ccp(_leftBridge.position.x + poleDistance, _rightBridge.position.y);
    
    // Save settings for later
    [self.settings addObject:_leftBridge];
    [self.settings addObject:_rightBridge];

}


@end
