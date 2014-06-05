//
//  Obstacle.m
//  SteamBot
//
//  Created by DPayne on 5/2/14.
//  Copyright (c) 2014 Santuary of Darkness. All rights reserved.
//

#import "Obstacle.h"


#define ARC4RANDOM_MAX      0x100000000
// visibility on a 3,5-inch iPhone ends a 88 points and we want some meat
static const CGFloat minimumXPositionLeftPole = 275.0f;
// visibility ends at 480 and we want some meat
static const CGFloat maximumXPositionLeftPole = 475.0f;
// distance between top and bottom pipe
static const CGFloat poleDistance = 80.0f;

@implementation Obstacle

- (void)didLoadFromCCB {
    self.settings = [[NSMutableArray alloc]init];
}

-(void)restorePosition:(NSMutableArray *)restoreSettings{
    NSValue *leftPos = [restoreSettings objectAtIndex:0];
    NSValue *rightPos = [restoreSettings objectAtIndex:1];
    _leftPole.position = leftPos.CGPointValue;
    _rightPole.position = rightPos.CGPointValue;
}

- (void)setupRandomPosition {
    
    // value between 0.f and 1.f
    CGFloat random = ((double)arc4random() / ARC4RANDOM_MAX);
    CGFloat range = maximumXPositionLeftPole - minimumXPositionLeftPole;
    _leftPole.position = ccp(minimumXPositionLeftPole + (random * range), _leftPole.position.y);
    _rightPole.position = ccp(_leftPole.position.x + poleDistance, _rightPole.position.y);
    
    // Remember these settings for later
    [self.settings addObject:[NSValue valueWithCGPoint:_leftPole.position]];
    [self.settings addObject:[NSValue valueWithCGPoint:_rightPole.position]];
    
}


@end





