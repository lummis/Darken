//
//  LoadBoardScene.m
//  Darken
//
//  Created by Robert Lummis on 8/2/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

#import "LoadBoardScene.h"
#import "Board.h"
#import "Model.h"
#import "RLGameCenter.h"
#import "MessageManager.h"

@implementation LoadBoardScene

-(void) dealloc {
    ANNOUNCE
    [super dealloc];
}

-(void) onEnter {
    ANNOUNCE
    [super onEnter];
}

-(void) onEnterTransitionDidFinish {
    ANNOUNCE
    [super onEnterTransitionDidFinish];
}

-(void) onExit {
    ANNOUNCE
    [super onExit];
}

+(id) scene {
    ANNOUNCE

        // 'scene' is an autorelease object.
    CCScene *scene = [CCScene node];
    LoadBoardScene *loadingNode = [LoadBoardScene node];
    loadingNode.isTouchEnabled = NO;
    [scene addChild:loadingNode z:0];

        //    CCLayerGradient *background = [CCLayerGradient layerWithColor:ccc4(230.f, 230.f, 230.f, 255.f)
        //                                                         fadingTo:ccc4(130.f, 130.f, 130.f, 255.f)];
    CCLayerColor *background = [CCLayerColor layerWithColor:BACKGROUNDCOLOR];
    [scene addChild:background z:-1];
    
    return scene;
}

-(id) init {
    ANNOUNCE
    if( (self=[super init]) ) {
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        w = screenSize.width;
        h = screenSize.height;
        
        X.playDeltaTime = 0.;   //initialize per-play counters
        [X.modelP incrementCountForLevel:X.level inCCArray:X.levelStarts];
        X.score = 0;
        X.starsUsedThisPlay = 0;
        X.bombsUsedThisPlay = 0;
        X.movesThisPlay = 0;
        
        NSString *loadingString = [NSString stringWithFormat:@"Loading level %d...", X.level];
        CCLabelTTF *title = [CCLabelTTF 
                             labelWithString:loadingString 
                             fontName:@"Marker Felt" 
                             fontSize:64];
        title.position =  ccp( w * 0.5f, h * 0.6f );
        title.color = ccc3(0, 0, 255);
        [self addChild:title z:1];
        
            //the following statement was in Board scene
        [X.modelP setParameters];   //doesn't change parameters if set by developer
        NSString *details = [NSString stringWithFormat:@"%d shapes and %d colors",
                             X.nShapes, X.nColors];
        CCLabelTTF *subTitle = [CCLabelTTF
                                labelWithString:details
                                fontName:@"Marker Felt"
                                fontSize:36];
        subTitle.position = ccp( w * 0.5f, h * 0.45f );
        subTitle.color = ccc3(0, 0, 255);
        [self addChild:subTitle z:1];
        
        NSUInteger pauseTime = 3;
        
//        if (X.level < FIRSTREPORTEDLEVEL) {
//            NSString *noGCString1 = [NSString stringWithFormat:@" ", FIRSTREPORTEDLEVEL];
//            CCLabelTTF *noGCMsg1 = [CCLabelTTF
//                                       labelWithString:noGCString1
//                                       fontName:[UIFont systemFontOfSize:[UIFont systemFontSize]].fontName
//                                       fontSize:16];
//            noGCMsg1.position = ccp( w * 0.5f, h * 0.22f);
//            noGCMsg1.color = ccBLUE;
//            [self addChild:noGCMsg1];
//            
//            NSString *noGCString2 =
//                    [NSString  stringWithFormat:@"Results are not reported to the Game Center until level %d.", FIRSTREPORTEDLEVEL];
//            CCLabelTTF *noGCMsg2 = [CCLabelTTF
//                                        labelWithString:noGCString2
//                                        fontName:[UIFont systemFontOfSize:[UIFont systemFontSize]].fontName
//                                        fontSize:16];
//            noGCMsg2.position = ccp( w * 0.5f, h * 0.16f);
//            noGCMsg2.color = ccBLUE;
//            [self addChild:noGCMsg2];
//            
//            pauseTime = 4;//seconds to display the "Loading ..." screen
//        } else {
//            pauseTime = 3;
//        }
        
            // must wait at least one frame before loading another scene
            // some countdown is needed to wait for transition from previous scene to this scene to finish
        countdown = 60 * pauseTime;
        CCLOG(@"LoadBoardScene/init; before [self scheduleUpdate]");
        [self scheduleUpdate];
    }
    return self;
}


-(void) update:(ccTime)delta {
    if (!!!countdown--) {    // wait for transition to this scene to finish
        CCLOG(@"LoadBoardScene/update; countdown finished");
        [self unscheduleAllSelectors];
        CCTransitionFade *tran = [CCTransitionFade transitionWithDuration:0.5f scene:[Board boardScene]];
        CCLOG(@"LoadBoardScene/update; before replaceScene:tran ");
        [[CCDirector sharedDirector] replaceScene:tran];
        CCLOG(@"LoadBoardScene/update; after replaceScene:tran ");
    }
}

@end
