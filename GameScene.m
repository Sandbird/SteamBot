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
#import "OALSimpleAudio.h"

BOOL _pulseOn;

#define ARC4RANDOM_MAX      0x100000000

// info on where to bounce SteamBot

typedef struct {
    CGPoint base;
    float targetheight;
    float springConstant;
    float left;
    float right;
    float lookahead; // increases or decreases bounce
    float triggerHeight;
    
}corridor;

@interface GameScene()

@property (nonatomic, strong) SteamBot *steamBot;
@property (nonatomic, strong) CCPhysicsNode *physicsNode;

@property (nonatomic, strong) CCParticleSystem *particles;
@property (nonatomic, strong) CCNode *leftBorder;
@property (nonatomic, strong) CCNode *rightBorder;

@property (nonatomic, strong) CCNode *corridor;
@property (nonatomic, strong) CCNode *poles;
@property (nonatomic, strong) CCNode *walls;
@property (nonatomic, strong) NSMutableArray *obstacles;
@property (nonatomic, strong) NSMutableArray *obstacleList;
@property (nonatomic, strong) CCNode *waterLevel;
@property (nonatomic, strong) CCNode *steamLevel;
@property (nonatomic, strong) CCNode *steam;

@property (nonatomic, strong) NSMutableArray *backgroundNodes;
@property (nonatomic) NSInteger backgroundIndex;
@property (nonatomic, strong) CCNode *currentBackground;
@property (nonatomic, strong) CCNode *secondaryBackground;
@property (nonatomic, strong) CCNode *waterGaugeLeft;
@property (nonatomic, strong) CCNode *waterGaugeRight;
@property (nonatomic, strong) CCNode *mainBurner;
@property (nonatomic) NSInteger backgroundBase;
@property (nonatomic, strong) CCLabelTTF *scoreLabel;
@property (nonatomic, strong) OALSimpleAudio *audio; // Shared instance for all sounds
@property (nonatomic, strong) id<ALSoundSource> burnerAudio; // Source of burnerAudio sound
@property (nonatomic, strong) id<ALSoundSource> liftOffAudio; // Source of burnerAudio sound
@property (nonatomic, strong) id<ALSoundSource> bumpAudio; // Source of burnerAudio sound


@end

@implementation GameScene

corridor col1;
CGPoint mY;
float touch_X;
CGPoint currentPhysicsPos;
CGPoint currentCorridorPos;
CGPoint currentBackgroundPos;
CGFloat topMost;
CGFloat bottomMost;
float screenHeight;
float relativeBase;
bool isBurning;
float delay;
float timeToNextBlink;
CCAnimationManager  *steamBotAnimation;
bool corridorIsClosed;
CGPoint particlePos;
float soundDelay;


- (void)didLoadFromCCB {
    
    // Set up collision detection
    // Set this class as the delegate
    _physicsNode.collisionDelegate = self;
    // Set collision type
    self.steamBot.physicsBody.collisionType = @"steamBot";
    
    // Enable touches
    self.userInteractionEnabled = TRUE;
    
    self.obstacles = [[NSMutableArray alloc]init];
    self.obstacleList = [[NSMutableArray alloc]init];
    self.backgroundNodes = [[NSMutableArray alloc]init];
    
    CCNode *background1 = [CCBReader load:@"Background"];
    CCNode *background2 = [CCBReader load:@"Background"];
    
    [self.backgroundNodes addObject:background1];
    [self.backgroundNodes addObject:background2];
    self.backgroundIndex = 0;
    
    self.currentBackground = [self.backgroundNodes objectAtIndex:0];
    self.secondaryBackground = [self.backgroundNodes objectAtIndex:1];
    [self addChild:self.currentBackground z:0];
    [self addChild:self.secondaryBackground z:0];
    self.currentBackground.position = ccp(0, 0);
    self.secondaryBackground.position = ccp(0, self.currentBackground.boundingBox.size.height);
    
    _pulseOn = FALSE;
    relativeBase = 0;
    isBurning = FALSE;
    bottomMost = 0;
    delay = 0;
    corridorIsClosed = NO;
    _backgroundBase = 0;
    soundDelay = 0.0f;
    
    
    // Music and audio effects
    self.audio = [OALSimpleAudio sharedInstance];
    [self.audio preloadEffect:@"burnerSteam.wav"];
    [self.audio preloadEffect:@"liftOff.mp3"];
    [self.audio preloadEffect:@"waterDrop01.mp3"];

    
    
    // Fire for device
    self.particles = [CCParticleSystem particleWithFile:@"burnerFire.plist"];
    // [self addChild:self.particles z:3];
    [self.physicsNode addChild:self.particles z:3];
    
    particlePos = CGPointMake(self.mainBurner.position.x, self.mainBurner.position.y + 25.0f);
    self.particles.position = particlePos;
    self.particles.visible = NO;
    
    self.steam = [CCBReader load:@"Steam"];
    self.steam.visible = NO;
    [self.physicsNode addChild:self.steam];
    
    self.corridor = [CCBReader load:@"Corridor"];
    [self.physicsNode addChild:self.corridor];
    self.corridor.position = ccp(160.0, 50.0);
    
    topMost = self.corridor.position.y + self.corridor.boundingBox.size.height;
    
    // Default position for burner column
    col1.base = ccp(160.0f, 0);
    col1.targetheight = 75.0f;
    col1.springConstant = .00001f;
    col1.left = 0.0f;
    col1.right = 320.0f;
    col1.lookahead = .25f; // 2.5f is the default value!! .25 very bouncy.
    col1.triggerHeight = 200.0f;
    
    currentCorridorPos = [self.corridor convertToWorldSpace:ccp(0, 0)];
    
    // Initial delay for blinking of SteamBot (1 to 2 seconds)
    delay = (arc4random() % 3000) / 1000.f;
    steamBotAnimation = self.steamBot.animationManager;
    
    [self.physicsNode setZOrder:1];
    [self.waterLevel setZOrder:2];
    [self.steamLevel setZOrder:2];
    [self.waterGaugeLeft setZOrder:3];
    [self.waterGaugeRight setZOrder:3];
    [self.mainBurner setZOrder:3];
    [self.particles setZOrder:3];
    [self.scoreLabel setZOrder:3];
    [self.steam setZOrder:2];
    [self.steamBot setZOrder:3];

    CGSize winSize = [[CCDirector sharedDirector] viewSize];
    
    self.waterGaugeLeft.position = ccp(0.0f, winSize.height - 175.0f);
    self.waterGaugeRight.position = ccp(320.0f, winSize.height - 175.0f);
    self.waterLevel.position = ccp(self.waterLevel.position.x, self.waterGaugeLeft.position.y + 50.0f);
    self.steamLevel.position = ccp(self.steamLevel.position.x, self.waterGaugeRight.position.y + 50.0f);

}

- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    
    isBurning = FALSE;
    CGPoint touchLocation = [touch locationInNode:self];
    touch_X = touchLocation.x;
    _pulseOn = TRUE;
}

-(void)touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    _pulseOn = FALSE;
}

-(void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:self];
    touch_X = touchLocation.x;
    
}

-(void)update:(CCTime)delta
{
    screenHeight = self.scene.boundingBox.size.height;
    
    self.steam.position = ccp(self.steamBot.position.x, self.steamBot.position.y - 65.0f);
    
    soundDelay += delta;
    
    // Altitude on screen
    self.scoreLabel.string = [NSString stringWithFormat:@"Altitude: %d", (int)(fabsf(self.physicsNode.position.y))];
    
    // Make SteamBot blink
    timeToNextBlink += delta;
    if (timeToNextBlink > delay) {
        [steamBotAnimation runAnimationsForSequenceNamed:@"Blink"];
        delay = ((arc4random() % 3000) / 1000.f) + 1;
        timeToNextBlink = 0;
    }
    // delta = fminf(delta, 0.08f);
    
    mY = [self.steamBot convertToWorldSpace:ccp(0, 0)];
    
    // float distanceAboveGround = self.steamBot.position.y - col1.base.y;
    float distanceAboveGround = self.steamBot.position.y;
    
    
    // Is the ball in the column?
    if (self.steamBot.position.x > col1.left && self.steamBot.position.x < col1.right)
    {
        if (self.steamBot.position.y < col1.triggerHeight && self.steamBot.position.y > col1.base.y + 10.0f) {
            
            self.steamBot.position = ccp(col1.base.x, self.steamBot.position.y);
            self.particles.position = particlePos;
            self.particles.visible = YES; // in column below trigger, turn on fire
            if (distanceAboveGround < col1.targetheight && distanceAboveGround > 0) {
                [self bounce];
                isBurning = YES;
            }

        } else {
            self.particles.visible = NO; // otherwise, turn it off
            isBurning = NO;
        }
        
    }
    
    CGFloat closePoint = 300.0f;
    if (!corridorIsClosed && self.steamBot.position.y > closePoint) {
        CCAnimationManager *corrAnimation = self.corridor.animationManager;
        [corrAnimation runAnimationsForSequenceNamed:@"CloseGap"];
        corridorIsClosed = YES;
        
    }
    
    
    // Ball on burners -- increase pressure, reduce water
    if (isBurning) {
        
        if (![self.burnerAudio playing]) {
            self.burnerAudio = [self.audio playEffect:@"burnerSteam.wav" loop:YES];
        }
        if (self.waterLevel.scaleY > 0) self.steamLevel.scaleY = self.steamLevel.scaleY + (.05 * delta);
        if (self.steamLevel.scaleY > 1.0) {
            self.steamLevel.scaleY = 1.0;
        }
        
        // Reduce water in valve
        if (self.steamLevel.scaleY < 1) self.waterLevel.scaleY = self.waterLevel.scaleY - (0.025 * delta);
        if (self.waterLevel.scaleY < 0) {
            self.waterLevel.scaleY = 0;
        }
    } else {
        if ([self.burnerAudio playing]) {
            [self.burnerAudio stop];
            self.burnerAudio = nil;
        }
    }
    
    // Add obstacles
    while (topMost + self.physicsNode.position.y < screenHeight) {
        [self spawnNewObstacle];
    }
    
    // If obstacles are off the screen, delete them
    NSMutableArray *offScreenObstacles = nil;
    NSMutableArray *onScreenObstacles = nil;
    
    // Scan obstacles for offscreen, replacement
    for (ObstacleInfo *obstInfo in self.obstacleList) {
        
        Obstacle *obstacle;
        
        BOOL obstacleIsOffScreen = [self obstacleOffScreen:obstInfo];
        
        // Should obstacle be restored? (obstacle no onscreen, but should be)
        if (!obstInfo.obstacleInLayer && !obstacleIsOffScreen) {
            // Replace obstacle to position
            // [self restoreObstacle:obstInfo];
            if (!onScreenObstacles) {
                onScreenObstacles = [NSMutableArray array];
            }
            [onScreenObstacles addObject:obstInfo];
            
        } // Obstacle is offscreen, remove it
        else if (obstInfo.obstacleInLayer && obstacleIsOffScreen) {
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
        
        // Check for obstacle collision with various objects inside obstacle
        for (Obstacle *anObstacle in self.obstacles) {
            if (anObstacle.position.y == obstInfo.objectPosition.y) { // This obstacle is onscreen right now
                
                // Is the ball within the borders of this obstacle?
                if (self.steamBot.position.y > anObstacle.position.y && self.steamBot.position.y < anObstacle.position.y + anObstacle.boundingBox.size.height) {
                    NSNumber *boolTemp = [obstInfo.settings objectAtIndex:0];
                    BOOL innerObstExist = boolTemp.boolValue;
                    if (!innerObstExist) break;                    // TODO: Account for NO inner obstacles
                    NSNumber *innerObstSelected =[obstInfo.settings objectAtIndex:1];
                    NSInteger obstacleSel = innerObstSelected.intValue;

                    CGPoint innerObst;
                    switch (obstacleSel) {
                        case 0: // Left Ledge
                            break;
                        case 1: // Right Ledge
                            break;
                        case 2: // Water drop
                            if ([anObstacle hasCollided:mY withThisInnerObstacle:innerObstSelected]) {
                                [self.audio playEffect:@"waterDrop01.mp3"];
                                [anObstacle actOnCollision];
                                obstInfo.settings = anObstacle.settings; // reset settings
                                self.waterLevel.scaleY += .25f;
                                if (self.waterLevel.scaleY> 1.0f) self.waterLevel.scaleY = 1.0f;
                            }
                            break;
                            
                        case 3: // Right burner
                            
                            innerObst = ccp(anObstacle.position.x + 200.0f, anObstacle.position.y + 148.0f);
                            particlePos = CGPointMake(col1.base.x, anObstacle.position.y + 160.0f);
                            col1.base = ccp(innerObst.x, innerObst.y - 10.0f);
                            col1.left = innerObst.x - 50.0f;
                            col1.right = innerObst.x + 50.0f;
                            col1.targetheight = col1.base.y + 76.0f;
                            col1.triggerHeight = col1.base.y + 150.0f;
                            col1.lookahead = 5.0f;
                            col1.springConstant = 0.5f;
                            break;
                        case 4: // Left burner
                            
                            innerObst = ccp(anObstacle.position.x + 120.0f, anObstacle.position.y + 148.0f);
                            particlePos = CGPointMake(col1.base.x, anObstacle.position.y + 160.0f);
                            col1.base = ccp(innerObst.x, innerObst.y - 10.0f);
                            col1.left = innerObst.x - 50.0f;
                            col1.right = innerObst.x + 50.0f;
                            col1.targetheight = col1.base.y + 76.0f;
                            col1.triggerHeight = col1.base.y + 150.0f;
                            col1.lookahead = 5.0f;
                            col1.springConstant = 0.5f;
                            break;
                        default:
                        break;
                    }
                }
                
            }
            
        }
        
    }
    
    // Remove any object in offScreenObstacles from screen and _obstacle array
    for (CCNode *obstacleToRemove in offScreenObstacles) {
        // relativeBase = -obstacleToRemove.position.y;
        [obstacleToRemove removeFromParent];
        [_obstacles removeObject:obstacleToRemove];
    }
    
    // Restore any obstacle in onScreenObstacles
    for (ObstacleInfo *obsInfo in onScreenObstacles) {
        [self restoreObstacle:obsInfo];
    }
    
    // Power the ball
    // if (_pulseOn && self.steamLevel.scaleY > 0) {
    if (_pulseOn) {
        
        self.steam.visible = YES;
        
        if (![self.liftOffAudio playing]) {
            self.liftOffAudio = [self.audio playEffect:@"steamShortBurst.wav" loop:YES];
        }
        
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
        // [self.steamBot.physicsBody applyImpulse:CGPointMake(0.0, 200.0)];
        
        if (mY.y < screenHeight/2) {
            [self.steamBot.physicsBody applyImpulse:CGPointMake(0.0, 200.0)];
        }else {

            currentPhysicsPos.y -= 10.0;
            currentPhysicsPos.x = 0;
            currentCorridorPos.y -=10.0;
            currentBackgroundPos.y -= 10.0f;
        }
        
    }else {
        // _pulseOn is FALSE, ball is falling
        
        self.steam.visible = NO;
        
        if ([self.liftOffAudio playing]) {
            [self.liftOffAudio stop];
            self.liftOffAudio = nil;if ([self.burnerAudio playing]) {
                [self.burnerAudio stop];
                self.burnerAudio = nil;
            }
        }
        
        if (mY.y < screenHeight/2 && currentPhysicsPos.y < relativeBase) {
            
            currentPhysicsPos.y = -(self.steamBot.position.y - (screenHeight/2));
            currentBackgroundPos.y = -((self.steamBot.position.y - (screenHeight/2)) - (_backgroundBase * 1440));
            currentCorridorPos.y = 160 -(self.steamBot.position.y - (screenHeight/2));
            
            if (currentPhysicsPos.y > 0) {
                currentPhysicsPos.y = 0;
                currentBackgroundPos.y = 0;
            }
            if (currentCorridorPos.y > 160.0) {
                currentCorridorPos.y = 160.0;
            }
            
        }
    }
    
    self.physicsNode.position = currentPhysicsPos;
    
    self.currentBackground.position = currentBackgroundPos;
    self.secondaryBackground.position = ccp(0,currentBackgroundPos.y + self.currentBackground.boundingBox.size.height);
    
    // Swap background images when the ball is CLIMBING
    if (self.secondaryBackground.position.y < 0) {
        // Swap secondary and primary backgrounds
        self.currentBackground.position = ccp(0, self.secondaryBackground.boundingBox.size.height + self.currentBackground.boundingBox.size.height + self.currentBackground.position.y);
        self.backgroundIndex++;
        if (self.backgroundIndex > 1) {
            self.backgroundIndex = 0;
        }
        self.currentBackground = [self.backgroundNodes objectAtIndex:self.backgroundIndex];
        NSInteger secIndex = self.backgroundIndex +1;
        if (secIndex > 1) {
            secIndex = 0;
        }
        self.secondaryBackground = [self.backgroundNodes objectAtIndex:secIndex];
        currentBackgroundPos = self.currentBackground.position;
        
        _backgroundBase++;
    }
    
    // Swap background Images when the ball is FALLING
    CGPoint currBackgroundWord = [self.currentBackground convertToWorldSpace:ccp(0, 0)];
    if (currBackgroundWord.y > -10.0f) {
        if (_backgroundBase > 0) {
            // swap secondary and primary backgrounds downward
            self.secondaryBackground.position = ccp(0, self.secondaryBackground.position.y - (2 * self.currentBackground.boundingBox.size.height));
            
            self.backgroundIndex++;
            if (self.backgroundIndex > 1) {
                self.backgroundIndex = 0;
            }
            self.currentBackground = [self.backgroundNodes objectAtIndex:self.backgroundIndex];
            NSInteger secIndex = self.backgroundIndex +1;
            if (secIndex > 1) {
                secIndex = 0;
            }
            self.secondaryBackground = [self.backgroundNodes objectAtIndex:secIndex];
            currentBackgroundPos = self.currentBackground.position;
            _backgroundBase--;
            
        }
        
    }
}

-(void)bounce
{
    CGPoint gravity = self.physicsNode.gravity;
    //float groundDist = self.steamBot.position.y - col1.base.y;
    float groundDist = self.steamBot.position.y;
    
    
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
    
    // Define base obstacle
    Obstacle *obstacle;
    ObstacleInfo *info = [[ObstacleInfo alloc]init];
    
    obstacle = (Obstacle *) [CCBReader load:@"baseObstacle"];
    [obstacle setupRandomPosition];
    obstacle.position = ccp(0, topMost);
    [self.obstacles addObject:obstacle]; // add obstacle to obstacle list
    [self.physicsNode addChild:obstacle]; // add obstacle to screen
    topMost = obstacle.boundingBox.size.height + obstacle.position.y; // new top from current obstacle
    
    info.obstacleInLayer = YES;
    info.settings = obstacle.settings;
    info.objectHeight = obstacle.boundingBox.size.height;
    info.objectPosition = obstacle.position;
    
    // [self.obstacleList addObject:info];
    [self.obstacleList addObject:info];
}

- (void)restoreObstacle:(ObstacleInfo *)info { // Restore previously deleted obstacle
    
    Obstacle *obstacle;
    
    obstacle = (Obstacle *)[CCBReader load:@"baseObstacle"];
    
    [obstacle restorePosition:info.settings]; // Reset position of pole positions
    obstacle.position = info.objectPosition;
    
    [self.obstacles addObject:obstacle]; // add obstacle to list of obstacles
    [self.physicsNode addChild:obstacle]; // add obstacle to screen
    
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

// Collision detection between steamBot and obstacles
-(void)ccPhysicsCollisionPostSolve:(CCPhysicsCollisionPair *)pair steamBot:(CCNode *)nodeA wildcard:(CCNode *)nodeB {
    if (![self.bumpAudio playing] && soundDelay > 0.75f) {
        self.bumpAudio = [self.audio playEffect:@"bump01.mp3"];
        soundDelay = 0.0f;
    }
}

@end
