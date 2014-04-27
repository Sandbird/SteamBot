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
CGPoint velocity;
CGFloat topMost;
float screenHeight;
float relativeBase;
bool isBurning;

- (void)didLoadFromCCB {
    
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
    [self.obstacles addObject:self.corridor];
    [self.physicsNode addChild:self.corridor];
    self.corridor.position = ccp(160.0, 50.0);
    topMost = self.corridor.position.y + self.corridor.boundingBox.size.height;
    
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
        
        CGFloat topPosition = obstacle.position.y + obstacle.boundingBox.size.height;
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
    
    // Bounce if near the ground
    if (distanceAboveGround < col1.targetheight) {

        isBurning = TRUE;
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

- (void)spawnNewObstacle {
    
    CCNode *walls = [CCBReader load:@"Borders"];
    walls.position = ccp(160.0, topMost);
    [self.obstacles addObject:walls];
    [self.physicsNode addChild:walls];
    
    CGFloat wPos = walls.position.y;
    CGFloat wHeight = walls.boundingBox.size.height;
    
    topMost = wPos + wHeight;
    
    static const CGFloat maxYPosPole = 250.0f;
    static const CGFloat minYPosPole = 70.0f;
    CGFloat random = ((double)arc4random() / ARC4RANDOM_MAX);
    CGFloat range = maxYPosPole - minYPosPole;
    
    CCNode *obstacle = [CCBReader load:@"Poles"];
    obstacle.position = ccp(minYPosPole + (random * range), topMost);
    [self.obstacles addObject:obstacle];
    [self.physicsNode addChild:obstacle];
    
    CCLOG(@"# of obstacles %lu",(unsigned long)self.obstacles.count);
    
    topMost = obstacle.boundingBox.size.height + obstacle.position.y;
    
}

@end
