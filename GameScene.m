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
#import "Tunnels.h"

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
@property (nonatomic, strong) NSMutableArray *obstacleLibrary;
@property (nonatomic, strong) NSMutableArray *obstacleList;
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
        
    // Enable touches
    self.userInteractionEnabled = TRUE;
    
    self.obstacles = [[NSMutableArray alloc]init];
    self.obstacleLibrary = [[NSMutableArray alloc]init];
    self.obstacleList = [NSMutableArray array];

    _pulseOn = FALSE;
    relativeBase = 0;
    isBurning = FALSE;
    bottomMost = 0;
    
    // Fire for device
    // particles = [CCParticleSystemQuad particleWithFile:@"fire.plist"];
    self.particles = [CCParticleSystem particleWithFile:@"burnerFire.plist"];
    [self addChild:self.particles z:1];
    self.particles.position = ccp(160, 35);
    
    // Steam for steamBot
    self.steam = [CCParticleSystem particleWithFile:@"steamEffect.plist"];
    [self addChild:self.steam z:1];
    self.steam.visible = FALSE;
    
    // Load corridor and poles names
    [self.obstacleLibrary addObject:@"Corridor"];
    [self.obstacleLibrary addObject:@"Poles"];
    [self.obstacleLibrary addObject:@"Tunnels"];
    
    // Corridor used only once and is the first obstacle;
    NSString *corrString = [self.obstacleLibrary objectAtIndex:0];
    self.corridor = [CCBReader load:corrString];
    
    
    [self.physicsNode addChild:self.corridor];
    self.corridor.position = ccp(160.0, 50.0);
    // [self.obstacles addObject:self.corridor];
    
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
    
    // TODO: Change method of tracking obstacles on and off screen
    
    // If obstacles are off the screen, delete them
    NSMutableArray *offScreenObstacles = nil;
    NSMutableArray *onScreenObstacles = nil;
    
    // Obstacles to delete or to replace
    for (ObstacleInfo *obstInfo in self.obstacleList) {
        
        Obstacle *obstacle;
        
        BOOL obstacleIsOffScreen = [self obstacleOffScreen:obstInfo];
        
        // Should obstacle be restored?
        if (!obstInfo.obstacleInLayer && !obstacleIsOffScreen) {
            // Replace obstacle to position
            // [self restoreObstacle:obstInfo];
            if (!onScreenObstacles) {
                onScreenObstacles = [NSMutableArray array];
            }
            [onScreenObstacles addObject:obstInfo];
            
        } else if (obstInfo.obstacleInLayer && obstacleIsOffScreen) {
            // obstacle is on layer and is offscreen (both required)
            obstInfo.obstacleInLayer = NO; // Mark obstacle as off layer
            for (Obstacle *obstacleToCheck in self.obstacles) {
                if (obstacleToCheck.position.y == obstInfo.objectPosition.y) {
                    obstacle = obstacleToCheck;
                }
            }
            
            if (!offScreenObstacles) {
                offScreenObstacles = [NSMutableArray array];
            }
            [offScreenObstacles addObject:obstacle];
            
        }
        
    }
    
    // Remove any object in offScreenObstacles from screen and _obstacle array
    for (CCNode *obstacleToRemove in offScreenObstacles) {
        // relativeBase = -obstacleToRemove.position.y;
        [obstacleToRemove removeFromParent];
        [_obstacles removeObject:obstacleToRemove];
        CCLOG(@"Obstacle removed");
    }
    
    // Restore any obstacle in onScreenObstacles
    for (ObstacleInfo *obsInfo in onScreenObstacles) {
        [self restoreObstacle:obsInfo];
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
            [self.steamBot.physicsBody applyImpulse:CGPointMake(0.0, 500.0f)];
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
    
    // Define different kinds of obstacles
    Obstacle *obstacle;
    ObstacleInfo *info = [[ObstacleInfo alloc]init];
    
    obstacle = (Obstacle *) [CCBReader load:@"Poles"];
    [obstacle setupRandomPosition];
    obstacle.position = ccp(160.0, topMost);
    [self.obstacles addObject:obstacle]; // add obstacle to obstacle list
    [self.physicsNode addChild:obstacle]; // add obstacle to screen
    topMost = obstacle.boundingBox.size.height + obstacle.position.y; // new top from current obstacle
    
    info.obstacleInLayer = YES;
    info.settings = obstacle.settings;
    info.objectHeight = obstacle.boundingBox.size.height;
    info.objectPosition = obstacle.position;
    
    // [self.obstacleList addObject:info];
    [self.obstacleList addObject:info];
    
    CCLOG(@"Obstacle count %d",self.obstacleList.count);
    
}

- (void)restoreObstacle:(ObstacleInfo *)info { // Restore previously deleted obstacle
    
    Obstacle *obstacle;
    
    obstacle = (Obstacle *)[CCBReader load:@"Poles"];
    [obstacle restorePosition:info.settings]; // Reset position of pole positions
    obstacle.position = info.objectPosition;
    [self.obstacles addObject:obstacle]; // add obstacle to list of obstacles
    [self.physicsNode addChild:obstacle]; // add obstacle to screen
    CCLOG(@"Obstacle restored");
    
    info.obstacleInLayer = YES; // indicate that object is on screen
    
    // If object is top of screen, change topMost
    CGFloat obstacleTop = obstacle.boundingBox.size.height + obstacle.position.y;
    if (obstacleTop > topMost) {
        topMost = obstacleTop;
    }
    
    // NSString *restoredObstacle = [self.obstacleLibrary objectAtIndex:info.obstacleType];
    
}

-(BOOL)obstacleOffScreen:(ObstacleInfo *)info {
    
    BOOL isOffScreen = NO;
    
    // Find obstacles off the bottom and top of the screen
    CGFloat bottomOfObstacle = info.objectPosition.y;
    
    CGFloat topOfObstacle = info.objectPosition.y  + info.objectHeight;
    
    // top of obstacle is below the bottom of the screen
    if (topOfObstacle < abs(self.physicsNode.position.y)) {
        isOffScreen = YES;
    }
    
    // bottom of obstacle is above the top of the screen
    if (bottomOfObstacle > abs(self.physicsNode.position.y) + self.scene.boundingBox.size.height) {
        isOffScreen = YES;
    }
    return isOffScreen;
    
}

@end
