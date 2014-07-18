//
//  Obstacle.m
//  SteamBot
//
//  Created by DPayne on 5/2/14.
//  Copyright (c) 2014 Santuary of Darkness. All rights reserved.
//

#import "Obstacle.h"


#define ARC4RANDOM_MAX      0x100000000

static const CGFloat minimumXPositionLeftPole = 275.0f;
static const CGFloat maximumXPositionLeftPole = 475.0f;

// static const CGFloat poleDistance = 80.0f;

@interface Obstacle()

@property (nonatomic, strong) NSMutableArray *obstacleLibrary;
@property NSInteger obstacleSelected;
@property (nonatomic, strong)CCNode *currentObstacle;
@property (nonatomic)BOOL obstacleExists;

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
    self.obstacleSelected = arc4random()%5;
    [self addObstacle:self.obstacleSelected];
    
    // Get random x position (y position static)
    CGFloat random = ((double)arc4random() / ARC4RANDOM_MAX);
    CGFloat range = maximumXPositionLeftPole - minimumXPositionLeftPole;
    CGFloat height = self.boundingBox.size.height/2;
    
    switch (self.obstacleSelected) {
        case 0:
            //leftLedge
            self.currentObstacle.position = ccp(38.0f, height);
            break;
        case 1:
            // rightLedge
            self.currentObstacle.position = ccp(282.0f, height);
            break;
        case 2:
            // Water drop
            self.currentObstacle.position = ccp(random*range, height);
            CCLOG(@"bubble pos: %f",random*range);
            break;
        case 3:
            // Right portable burner
            self.currentObstacle.position = ccp(320.0f, height);
            break;
        case 4:
            // Left portable burner
            self.currentObstacle.position = ccp(0.0f, height);
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

-(BOOL)hasCollided:(CGPoint)ballPos {
    
    CGPoint currentObstaclePos = [self.currentObstacle convertToWorldSpace:ccp(0, 0)];
    if (fabsf(currentObstaclePos.x - ballPos.x) < 50.0f && fabsf(currentObstaclePos.y - ballPos.y)< 20.0f) {
        return true;
    }
    return false;
}

-(void)actOnCollision {
    [self.settings removeAllObjects]; // Remove all info on object
    self.obstacleExists = NO;
    [self.settings addObject:[NSNumber numberWithBool:self.obstacleExists]];
    // Remove secondary obstacle from screen
    [self.currentObstacle removeFromParent];
    
}

@end





