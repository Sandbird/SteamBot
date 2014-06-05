//
//  Obstacle.h
//  SteamBot
//
//  Created by DPayne on 5/2/14.
//  Copyright (c) 2014 Santuary of Darkness. All rights reserved.
//

#import "CCNode.h"

@interface Obstacle : CCNode

-(void)setupRandomPosition;
-(void)restorePosition:(NSMutableArray *)restoreSettings;

@property (nonatomic,strong)CCSprite *leftPole;
@property (nonatomic, strong)CCSprite *rightPole;
@property (nonatomic, strong)NSMutableArray *settings;

@end
