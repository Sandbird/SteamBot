//
//  ObjectInfo.h
//  SteamBot
//
//  Created by DPayne on 5/2/14.
//  Copyright (c) 2014 Santuary of Darkness. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ObstacleInfo : NSObject

@property (nonatomic,readwrite)NSInteger obstacleType;
@property (nonatomic, readwrite)NSInteger positionInArray;
@property (nonatomic,readwrite)CGPoint objectPosition;
@property (nonatomic, readwrite)CGFloat objectHeight;
@property (nonatomic, readwrite)BOOL obstacleInLayer;
@property (nonatomic, readwrite)BOOL obstacleOnScreen;
@property (nonatomic, strong) NSMutableArray *settings;

@end
