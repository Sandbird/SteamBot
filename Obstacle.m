//
//  Obstacle.m
//  SteamBot
//
//  Created by DPayne on 5/2/14.
//  Copyright (c) 2014 Santuary of Darkness. All rights reserved.
//

#import "Obstacle.h"
#import "OALSimpleAudio.h"



#define ARC4RANDOM_MAX      0x100000000

// static const CGFloat poleDistance = 80.0f;

@interface Obstacle()

@property (nonatomic, strong) NSMutableArray *obstacleLibrary;
@property (nonatomic)BOOL obstacleExists;
@property (nonatomic, strong) OALSimpleAudio *audio; // Shared instance for all sounds



@end

@implementation Obstacle

- (void)didLoadFromCCB {
    self.settings = [[NSMutableArray alloc]init];
    
    self.obstacleLibrary = [[NSMutableArray alloc]init];
    
    // list of objects available for display
    [self.obstacleLibrary addObject:@"leftLedge"];
    [self.obstacleLibrary addObject:@"rightLedge"];
    [self.obstacleLibrary addObject:@"WaterDroplet"];
    [self.obstacleLibrary addObject:@"burnerRight"];
    [self.obstacleLibrary addObject:@"portableBurnerLeft"];
    
    [self.audio preloadEffect:@"waterDrop01.mp3"];
    
    self.currentObstacle.physicsBody.collisionType = @"obstacle";
    self.currentObstacle.physicsBody.sensor = TRUE;

    
}

-(void)restorePosition:(NSMutableArray *)restoreSettings{
    
    // See if secondary object exists
    NSNumber *doesItExist = [restoreSettings objectAtIndex:0];
    self.obstacleExists = doesItExist.boolValue;
    if (self.obstacleExists) {
        // Find previous obstacle and restore
        NSNumber *objectType = [restoreSettings objectAtIndex:1];
        NSInteger index = objectType.integerValue;
        [self addObstacle:index];
    
        NSValue *position = [restoreSettings objectAtIndex:2];
        self.currentObstacle.position = position.CGPointValue;
    }
    
}

- (void)setupRandomPosition {
    
    // Indicate there is a secondary obstacle
    self.obstacleExists = YES;
    [self.settings addObject:[NSNumber numberWithBool:self.obstacleExists]];

    // Select internal obstacle at random from obstacle library
    self.obstacleSelected = arc4random_uniform(5);
    [self addObstacle:self.obstacleSelected];
    
    // Get random x position (y position static)
    CGFloat bubbleX = (double)arc4random_uniform(270) + 30;
    CGFloat height = self.boundingBox.size.height/2;
    
    switch (self.obstacleSelected) {
        case 0:
            //leftLedge
            self.currentObstacle.position = ccp(0.0f, height);
            break;
        case 1:
            // rightLedge
            self.currentObstacle.position = ccp(320.0f, height);
            break;
        case 2:
            // Water drop
            self.currentObstacle.position = ccp(bubbleX, height);
            break;
        case 3:
            // Right portable burner
            self.currentObstacle.position = ccp(200.0f, height);
            break;
        case 4:
            // Left portable burner
            self.currentObstacle.position = ccp(120.0f, height);
            break;
            
        default:
            break;
    }
    [self.settings addObject:[NSValue valueWithCGPoint:self.currentObstacle.position]];
}

-(void)addObstacle:(NSUInteger)index{
    
    // NSLog(@"Object Selected = %d",self.obstacleSelected);
    NSString *obstacle = [self.obstacleLibrary objectAtIndex:index];
    self.currentObstacle = [CCBReader load:obstacle];
    [self addChild:self.currentObstacle];
    // Save obstacle selected
    [self.settings addObject:[NSNumber numberWithInteger:self.obstacleSelected]];
}

-(BOOL)hasCollided:(CGPoint)ballPos withThisInnerObstacle:(NSNumber *)innerObst{
    
    // Locate obstacle in screen space
    CGPoint obstacleWorld = [self.currentObstacle convertToWorldSpace:ccp(0, 0)];
    CGPoint obstacleOffset;
    NSInteger thisInnerObst = innerObst.integerValue;
    self.obstacleSelected = thisInnerObst;
    
    switch (self.obstacleSelected) {
        case 0:
            //leftLedge
            break;
        case 1:
            // rightLedge
            break;
        case 2:
            // Water drop
            if (fabsf(obstacleWorld.x - ballPos.x) < 50.0f && fabsf(obstacleWorld.y - ballPos.y)< 20.0f) {
                CCLOG(@"Ball collision!");
                return true;
            }
            break;
        case 3:
            // Right portable burner
            obstacleOffset = ccp(obstacleWorld.x - 100.0, 0);
            if (ballPos.x > obstacleOffset.x - 25.0f || ballPos.x < obstacleOffset.x + 25.0f) {
                if (ballPos.y < obstacleWorld.y + 50.0) {
                    return true;
                }
            }
            break;
        case 4:
            // Left portable burner
            break;
            
        default:
            break;
    }
    return false;
}

-(void)actOnCollision {
    
    switch (self.obstacleSelected) {
        case 0:
            //leftLedge
            break;
        case 1:
            // rightLedge
            break;
        case 2:
            // Water drop
            // TODO: Account for only one object in this array
            [self.settings removeAllObjects]; // Remove all info on object
            self.obstacleExists = NO;
            [self.settings addObject:[NSNumber numberWithBool:self.obstacleExists]];
            // Remove secondary obstacle from screen
            [self.currentObstacle removeFromParent];
            break;
        case 3:
            // Right portable burner
            break;
        case 4:
            // Left portable burner
            break;
            
        default:
            break;
    }
}

@end





