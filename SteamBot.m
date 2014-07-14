//
//  SteamBot.m
//  SteamBot
//
//  Created by DPayne on 4/5/14.
//  Copyright (c) 2014 Santuary of Darkness. All rights reserved.
//

#import "SteamBot.h"

@implementation SteamBot


-(id) init
{
    if( (self=[super init]))
    {
        CCLOG(@"SteamBot created");
    }
    return self;
}

- (void)didLoadFromCCB
{
    /* // generate a random number between 0.0 and 2.0
    float delay = (arc4random() % 2000) / 1000.f;
    // call method to start animation after random delay
    [self performSelector:@selector(startBlink) withObject:nil afterDelay:delay]; */
}

- (void)blink
{
    // the animation manager of each node is stored in the 'animationManager' property
    CCAnimationManager* animationManager = self.animationManager;
    // timelines can be referenced and run by name
    [animationManager runAnimationsForSequenceNamed:@"Blink"];
}
@end
