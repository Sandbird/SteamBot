//
//  MainScene.m
//  PROJECTNAME
//
//  Created by Viktor on 10/10/13.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"
#import "OALSimpleAudio.h"

@interface MainScene()

@property (nonatomic, strong) OALSimpleAudio *audio; // Shared instance for all sounds
@property (nonatomic, strong) id<ALSoundSource> buttonSound; // Source of burnerAudio sound


@end

@implementation MainScene

- (void)didLoadFromCCB {
    
    // Disable the resume button for now
    self.resumeButton.enabled = NO;
    self.audio = [OALSimpleAudio sharedInstance];
    [self.audio preloadEffect:@"liftOff.mp3"];

}

// Load the primary game level
-(void)gameStart
{

    [self.audio playEffect:@"liftOff.mp3"];
    
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
