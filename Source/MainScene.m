//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"

@implementation MainScene

- (void)didLoadFromCCB {
    
    // Disable the resume button for now
    self.resumeButton.enabled = NO;
}

// Load the primary game level
-(void)gameStart
{
    CCScene *gameplayScene = [CCBReader loadAsScene:@"GameScene"];
    [[CCDirector sharedDirector] replaceScene:gameplayScene];
}

// Load the primary game level resuming where left off
-(void)resumeStart
{
    
}

// Load options menu
-(void)optionsStart
{
    
}

// Load instructions
-(void)instructionsStart
{
    
}

@end
