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
float touch_X;
CGPoint currentPhysicsPos;
CGPoint currentCorridorPos;
CGPoint velocity;



- (void)didLoadFromCCB {
    
    // Enable touches
    self.userInteractionEnabled = TRUE;

    _pulseOn = FALSE;
    
    // Fire for device
    // particles = [CCParticleSystemQuad particleWithFile:@"fire.plist"];
    self.particles = [CCParticleSystem particleWithFile:@"burnerFire.plist"];
    [self addChild:self.particles z:1];
    self.particles.position = ccp(160, 35);
    
    // Steam for steamBot
    self.steam = [CCParticleSystem particleWithFile:@"steamEffect.plist"];
    [self addChild:self.steam z:1];
    self.steam.visible = FALSE;
    
    self.corridor = [CCBReader load:@"Corridor"];
    [self.physicsNode addChild:self.corridor];
    self.corridor.position = ccp(160.0, 160.0);
    
    col1.base = 0.0f;
    col1.targetheight = 75.0f;
    col1.springConstant = 0.25f;
    col1.left = 0.0f;
    col1.right = 320.0f;
    col1.lookahead = 4.0f; // 2.5f is the default value!! .25 very bouncy.
    
    currentCorridorPos = [self.corridor convertToWorldSpace:ccp(0, 0)];
    velocity = CGPointMake(.33f, .33f);
    
}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    
    CGPoint touchLocation = [touch locationInNode:self];
    touch_X = touchLocation.x;
    _pulseOn = TRUE;
    self.steam.visible = TRUE;
    self.particles.visible = FALSE;
}

-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    _pulseOn = FALSE;
    self.steam.visible = FALSE;
}

-(void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:self];
    touch_X = touchLocation.x;
    
}

-(void)update:(CCTime)delta
{
    float screenHeight = self.scene.boundingBox.size.height;
    
    mY = [self.steamBot convertToWorldSpace:ccp(0, 0)];
    
    self.steam.position = CGPointMake(mY.x,mY.y - 30);
    
    float distanceAboveGround = mY.y - col1.base;
    
    if (_pulseOn) {
        
        // Calculate sideways motion
        float sideWaysPulse;
        if (touch_X < 160) {
            sideWaysPulse = touch_X - 160;
        }else {
            sideWaysPulse = -(160 - touch_X);
        }
        
        [self.steamBot.physicsBody applyImpulse:CGPointMake(sideWaysPulse, 0.0)];
        
        if (mY.y < screenHeight/2) {
            [self.steamBot.physicsBody applyImpulse:CGPointMake(0.0, 100.0f)];
        }else {

            currentPhysicsPos.y -= 10.0;
            currentPhysicsPos.x = 0;
            currentCorridorPos.y -=10.0;


        }
        
    }else {
        // _pulseOn is FALSE, ball is falling
        if (mY.y < screenHeight/2 && currentPhysicsPos.y < 0) {
            currentPhysicsPos.y += 10.0f;
            currentCorridorPos.y += 10.0f;
            if (currentPhysicsPos.y > 0) {
                currentPhysicsPos.y = 0;
            }
            if (currentCorridorPos.y > 160.0) {
                currentCorridorPos.y = 160.0;
            }
            
        }
    }
    
    // Bounce if near the ground
    if (distanceAboveGround < col1.targetheight) {

        [self bounce];
    }
    
    self.physicsNode.position = currentPhysicsPos;
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
