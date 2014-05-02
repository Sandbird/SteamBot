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
@property (nonatomic,strong)CCNode *leftPole;
@property (nonatomic, strong)CCNode *rightPole;

@end
