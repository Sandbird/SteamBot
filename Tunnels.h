//
//  Tunnels.h
//  SteamBot
//
//  Created by DPayne on 5/6/14.
//  Copyright (c) 2014 Santuary of Darkness. All rights reserved.
//

#import "CCNode.h"

@interface Tunnels : CCNode

-(void)setupRandomPosition;
-(void)restorePosition:(NSMutableArray *)restoreSettings;

@property (nonatomic,strong)CCNode *leftBridge;
@property (nonatomic, strong)CCNode *rightBridge;
@property (nonatomic, strong)NSMutableArray *settings;

@end
