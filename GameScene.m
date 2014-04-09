//
//  GameScene.m
//  SteamBot
//
//  Created by DPayne on 4/5/14.
//  Copyright (c) 2014 Santuary of Darkness. All rights reserved.
//

#import "GameScene.h"
#import "SteamBot.h"

BOOL _pulseOn;

// info on where to bounce SteamBot

typedef struct {
    float base;
    float targetheight;
    float springConstant;
    float left;
    float right;
    float lookahead; // increases or decreases bounce
    
}corridor;

@interface GameScene()

@end

@implementation GameScene

corridor col1;
CGPoint mY;

- (void)didLoadFromCCB {
    
    // Enable touches
    self.userInteractionEnabled = TRUE;
    
    // self.steamBot.zOrder = 10;
    
    // create a steamBot from the ccb-file
    // self.steamBot = [CCBReader load:@"SteamBot"];
    
    _pulseOn = FALSE;
    
    // Fire for device
    // particles = [CCParticleSystemQuad particleWithFile:@"fire.plist"];
    self.particles = [CCParticleSystem particleWithFile:@"burnerFire.plist"];
    [self addChild:self.particles z:1];
    self.particles.position = ccp(160, 35);
    
    col1.base = 0.0f;
    col1.targetheight = 50.0f;
    col1.springConstant = 0.25f;
    col1.left = 0.0f;
    col1.right = 320.0f;
    col1.lookahead = 4.0f; // 2.5f is the default value!! .25 very bouncy.
    
    
}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    _pulseOn = TRUE;
}

-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    _pulseOn = FALSE;
}

-(void)update:(CCTime)delta
{
    mY = [self.steamBot convertToWorldSpace:ccp(0, 0)];
    
    
    // mY = self.steamBot.position;
    
    float distanceAboveGround = mY.y - col1.base;
    
    if (_pulseOn) {
        [self.steamBot.physicsBody applyImpulse:CGPointMake(0, 100.0f)];
    }
    
    if (distanceAboveGround < col1.targetheight) {

        [self bounce];
    }
    
}

-(void)bounce
{
    // float sprite_mass = self.steamBot.physicsBody.mass;
    CGPoint gravity = self.physicsNode.gravity;
    float distanceAboveGround = mY.y - col1.base;
    
    // float base = col1.base;
    float speed = _steamBot.physicsBody.velocity.y;
    float springConstant = col1.springConstant;
    distanceAboveGround += col1.lookahead * speed;
    float distanceAwayFromTargetHeight = col1.targetheight - distanceAboveGround;
    
    
    [self.steamBot.physicsBody applyImpulse:CGPointMake(0, springConstant * distanceAwayFromTargetHeight)];
    
    // Negate gravity
    [self.steamBot.physicsBody applyImpulse:CGPointMake(0, -gravity.y)];
}

@end
