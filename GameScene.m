//
//  GameScene.m
//  SteamBot
//
//  Created by DPayne on 4/5/14.
//  Copyright (c) 2014 Santuary of Darkness. All rights reserved.
//

#import "GameScene.h"
#import "SteamBot.h"
#import "Obstacle.h"
#import "ObstacleInfo.h"

BOOL _pulseOn;

#define ARC4RANDOM_MAX      0x100000000

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

@property (nonatomic, strong) CCNode *steamBot;
@property (nonatomic, strong) CCPhysicsNode *physicsNode;

@property (nonatomic, strong) CCParticleSystem *particles;
@property (nonatomic, strong) CCParticleSystem *steam;

@property (nonatomic, strong) CCNode *leftBorder;
@property (nonatomic, strong) CCNode *rightBorder;

@property (nonatomic, strong) CCNode *corridor;
@property (nonatomic, strong) CCNode *poles;
@property (nonatomic, strong) CCNode *walls;
@property (nonatomic, strong) NSMutableArray *obstacles;
@property (nonatomic, strong) CCNode *waterLevel;
@property (nonatomic, strong) CCNode *steamLevel;

@end

@implementation GameScene

corridor col1;
CGPoint mY;
float touch_X;
CGPoint currentPhysicsPos;
CGPoint currentCorridorPos;
CGFloat topMost;
CGFloat bottomMost;
float screenHeight;
float relativeBase;
bool isBurning;

- (void)didLoadFromCCB {
    
    ObstacleInfo *oInfo = [ObstacleInfo alloc];
    
    // Enable touches
    self.userInteractionEnabled = TRUE;
    
    self.obstacles = [[NSMutableArray alloc]init];

    _pulseOn = FALSE;
    relativeBase = 0;
    isBurning = FALSE;
    
    // Fire for device
    // particles = [CCParticleSystemQuad particleWithFile:@"fire.plist"];
    self.particles = [CCParticleSystem particleWithFile:@"burnerFire.plist"];
    [self addChild:self.particles z:1];
    self.particles.position = ccp(160, 35);
    
    // Steam for steamBot
    self.steam = [CCParticleSystem particleWithFile:@"steamEffect.plist"];
    [self addChild:self.steam z:1];
    self.steam.visible = FALSE;
    
    // Corridor used only once and is the first obstacle;
    self.corridor = [CCBReader load:@"Corridor"];
    
    
    [self.physicsNode addChild:self.corridor];
    self.corridor.position = ccp(160.0, 50.0);
    [self.obstacles addObject:self.corridor];
    
    oInfo.index = 0;
    oInfo.objectPosition = self.corridor.position;
    oInfo.objectHeight = self.corridor.boundingBox.size.height;
    
    topMost = self.corridor.position.y + self.corridor.boundingBox.size.height;
    
    col1.base = 0.0f;
    col1.targetheight = 75.0f;
    col1.springConstant = .00001f;
    col1.left = 0.0f;
    col1.right = 320.0f;
    col1.lookahead = .25f; // 2.5f is the default value!! .25 very bouncy.
    
    currentCorridorPos = [self.corridor convertToWorldSpace:ccp(0, 0)];
    
}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    
    isBurning = FALSE;
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
    
    delta = fminf(delta, 0.08f);
    
    screenHeight = self.scene.boundingBox.size.height;
    
    mY = [self.steamBot convertToWorldSpace:ccp(0, 0)];
    
    self.steam.position = CGPointMake(mY.x,mY.y - 30);
    
    float distanceAboveGround = mY.y - col1.base;
    
    
    // Ball on burners -- increase pressure, reduce water
    if (isBurning) {
        
        // Move level using time to account for different devices
        self.steamLevel.scaleY = self.steamLevel.scaleY + (.05 * delta);
        
        if (self.steamLevel.scaleY > 1.0) {
            self.steamLevel.scaleY = 1.0;
        }
        
        // Reduce water in valve
        if (self.steamLevel.scaleY < 1) {
            self.waterLevel.scaleY = self.waterLevel.scaleY - (.01 * delta);
        }
        if (self.waterLevel.scaleY < 0) {
            self.waterLevel.scaleY = 0;
        }
    }
    
    // Add obstacles
    while (topMost + self.physicsNode.position.y < screenHeight) {
        [self spawnNewObstacle];
    }
    
    // If lower obstacles are off the screen, delete them
    NSMutableArray *offScreenObstacles = nil;
    
    // Find off screen obstacles and add them of offScreenObstacle array
    for (CCNode *obstacle in _obstacles) {
        
        // CGFloat topPosition = obstacle.position.y + obstacle.boundingBox.size.height;
        CGFloat topPosition = obstacle.position.y +
        obstacle.boundingBox.size.height;
        if (topPosition < abs(self.physicsNode.position.y)/2) {
            if (!offScreenObstacles) {
                offScreenObstacles = [NSMutableArray array];
            }
            [offScreenObstacles addObject:obstacle];
        }
    }
    
    // Remove any object in offScreenObstacles from screen and _obstacle array
    for (CCNode *obstacleToRemove in offScreenObstacles) {
        relativeBase = -obstacleToRemove.position.y;
        [obstacleToRemove removeFromParent];
        [_obstacles removeObject:obstacleToRemove];
    }
    
    // Power the ball
    if (_pulseOn) {
        
        // reduce pressure
        self.steamLevel.scaleY = self.steamLevel.scaleY - (.05 * delta);
        if (self.steamLevel.scaleY < 0) {
            self.steamLevel.scaleY = 0;
        }
        
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
        if (mY.y < screenHeight/2 && currentPhysicsPos.y < relativeBase) {
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
    
    /* CGPoint speed = self.steamBot.physicsBody.velocity;
    if (speed.y < 1.0 && speed.y > -1.0) {
        [self.steamBot.physicsBody applyImpulse:ccp(0, 500.0f)];
    }*/
    
    // Bounce if near the ground
    if (distanceAboveGround < col1.targetheight) {

        [self bounce];
        isBurning = TRUE;
    }
    
    
    self.physicsNode.position = currentPhysicsPos;
}

 -(void)bounce
{
    // float sprite_mass = self.steamBot.physicsBody.mass;
    CGPoint gravity = self.physicsNode.gravity;
    float groundDist = mY.y - col1.base;
    
    // float base = col1.base;
    float speed = _steamBot.physicsBody.velocity.y;
    float springConstant = col1.springConstant;
    groundDist += col1.lookahead * speed;
    float distanceAwayFromTargetHeight = col1.targetheight - groundDist;
    
    CGPoint springPulse = CGPointMake(0, springConstant * distanceAwayFromTargetHeight);
    
    [self.steamBot.physicsBody applyImpulse:springPulse];
    
    CGPoint gravPulse = ccpMult(gravity, -self.steamBot.physicsBody.mass/4);
    
    // Reduce pulse depending on speed of steamBot
    gravPulse.y = gravPulse.y - self.steamBot.physicsBody.velocity.y;
    
    // Negate gravity
    [self.steamBot.physicsBody applyImpulse:gravPulse];
    

}

- (void)spawnNewObstacle {
    
    CCNode *walls = [CCBReader load:@"Borders"];
    walls.position = ccp(160.0, topMost);
    Obstacle *lastObstacle;
    lastObstacle = [self.obstacles lastObject];
    
    [self.obstacles addObject:walls];
    [self.physicsNode addChild:walls];
    
    CGFloat wPos = walls.position.y;
    CGFloat wHeight = walls.boundingBox.size.height;
    topMost = wPos + wHeight;
    
    Obstacle *obstacle = (Obstacle *)[CCBReader load:@"Poles"];
    [obstacle setupRandomPosition];
    
    lastObstacle = [self.obstacles lastObject];
    obstacle.position = ccp(160.0f, topMost);
    
    [self.obstacles addObject:obstacle];
    [self.physicsNode addChild:obstacle];
    
    topMost = obstacle.boundingBox.size.height + obstacle.position.y;
    
}

@end
