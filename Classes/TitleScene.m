//
//  TitleScene
//  Darken
//
//  Created by Robert Lummis on 9/22/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

#import "TitleScene.h"
#import "ChoiceScene.h"
#import "Model.h"
#import "RLGameCenter.h"

@implementation TitleScene


-(void)dealloc {
    ANNOUNCE
	[super dealloc];
}

+(id) scene {
	ANNOUNCE
	CCScene *scene = [CCScene node];	// 'scene' is an autorelease object
	TitleScene *titleSceneNode = [TitleScene node];
	titleSceneNode.isTouchEnabled = NO;
	[scene addChild:titleSceneNode z:0];
	return titleSceneNode;
}

-(void) onEnter {
    ANNOUNCE
    [super onEnter];
}

-(void) onEnterTransitionDidFinish {
    ANNOUNCE
    [super onEnterTransitionDidFinish];
    if (NO == X.standardUserDefaultsIsCorrupted) return;
    
        //if we get here it's corrupted
    [self showCorruptionAlert];
}

-(id) init {
    ANNOUNCE
    if ( (self = [super init]) ) {
        CCLayerColor *cl = [CCLayerColor layerWithColor:BACKGROUNDCOLOR];
        [self addChild:cl z:-1];
        
        float screenHeight = [[CCDirector sharedDirector] winSize].height;
        float screenWidth = [[CCDirector sharedDirector] winSize].width;
        
        CCLabelTTF *text1 = [CCLabelTTF labelWithString:@"Darken" 
                                               fontName:@"Marker Felt" 
                                               fontSize:120];
        text1.color = ccBLUE;
        text1.position = ccp( screenWidth * 0.5, screenHeight * 0.68 );
        [self addChild:text1 z:0];
        
        NSString *versionBuildString = @"Version ";
        versionBuildString = [versionBuildString stringByAppendingString:[self version]];
        versionBuildString = [versionBuildString stringByAppendingString:@" ("];
        versionBuildString = [versionBuildString stringByAppendingString:[self build]];
        versionBuildString = [versionBuildString stringByAppendingString:@")"];
        CCLOG(@"versionBuildString: %@", versionBuildString);
        CCLabelTTF *versionBuild = [CCLabelTTF labelWithString:versionBuildString 
                                                      fontName:@"Helvetica" 
                                                      fontSize:9];
        versionBuild.color = ccBLACK;
        versionBuild.position = ccp( screenWidth * 0.97, screenHeight * 0.97 );
        versionBuild.anchorPoint = ccp(1.0, 1.0);
        [self addChild:versionBuild z:0];
        
        CCLabelTTF *text2 = [CCLabelTTF labelWithString:@"© 2013 Robert Lummis. All rights reserved." 
                                               fontName:@"Arial" 
                                               fontSize:14];
        text2.color = ccc3(80, 80, 95);
        text2.position = ccp( screenWidth * 0.5, screenHeight * 0.48 );
        [self addChild:text2 z:0];
        
        CCLabelTTF *text3A = [CCLabelTTF labelWithString:@"Loading..." 
                                               fontName:@"Marker Felt" 
                                               fontSize:36];
        text3A.color = ccBLUE;
        text3A.position = ccp( screenWidth * 0.5, screenHeight * 0.35 );
        [self addChild:text3A z:0];
        
        CCLabelTTF *text3B = [CCLabelTTF labelWithString:@"tap the screen to start..."
                                                fontName:@"Marker Felt" 
                                                fontSize:36];
        text3B.color = ccBLUE;
        text3B.position = ccp( screenWidth * 0.5, screenHeight * 0.35 );
        text3B.opacity = 0;
        [self addChild:text3B z:0];
        
        CCLabelTTF *text4 = [CCLabelTTF labelWithString:@"Built with cocos2d" 
                                               fontName:@"Arial" 
                                               fontSize:14];
        text4.color = ccc3(80, 80, 95);
        text4.anchorPoint = ccp( 0.0, 0.0 );
        text4.position = ccp( screenWidth * 0.05, screenHeight * 0.05 );
        [self addChild:text4 z:0];
        
        CCLabelTTF *text5 = [CCLabelTTF labelWithString:@"www.darkengame.com" 
                                               fontName:@"Arial" 
                                               fontSize:14];
        text5.color = ccc3(80, 80, 95);
        text5.anchorPoint = ccp( 1.0, 0.0 );
        text5.position = ccp( screenWidth * 0.95, screenHeight * 0.05 );
        [self addChild:text5 z:0];
        
        float fadeTime = 2.0f;
        CCActionInterval *fadeOutAction = [CCFadeOut actionWithDuration:0.3 * fadeTime];
        CCActionInterval *fadeInAction = [CCFadeIn actionWithDuration:0.3 * fadeTime];
        CCCallFunc *touchEnableAction = [CCCallFunc actionWithTarget:self 
                                                            selector:@selector(enableTouch)];
        CCActionInterval *seqA = [CCSequence actions:[CCDelayTime actionWithDuration:0.8f], fadeOutAction, nil];
        CCActionInterval *seqB = [CCSequence actions:[CCDelayTime actionWithDuration:1.2f], fadeInAction, touchEnableAction, nil];
        [text3A runAction:seqA];
        [text3B runAction:seqB];
    }

    X.titleSceneP = self;
    return self;
}

-(void) enableTouch {
    ANNOUNCE
    self.isTouchEnabled = YES;
    ANNOUNCE
}

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [X.modelP start];   //go to choiceScene (or instructionScene if first launch)
}

-(NSString *) version {
    NSBundle *bundle = [NSBundle mainBundle];
    return [bundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

-(NSString *) build {
    NSBundle *bundle = [NSBundle mainBundle];
    return [bundle objectForInfoDictionaryKey:@"CFBundleVersion"];
}

-(void) showActivityIndicatorThenStart {
    UIActivityIndicatorView *gear = [[UIActivityIndicatorView alloc]
                                     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    gear.color = [UIColor blackColor];
    float h = [[CCDirector sharedDirector] winSize].height;
    float w = [[CCDirector sharedDirector] winSize].width;
    gear.frame = CGRectMake(w/2, h/2, 37, 37);
    gear.hidesWhenStopped = YES;
    UIView *host = [CCDirector sharedDirector].openGLView;
    [host addSubview:gear];
    host.userInteractionEnabled = NO;
    [gear release];
    [gear startAnimating];
    int spinTime = 3;
    CCSequence *seq = [CCSequence actions:
                       [CCDelayTime actionWithDuration:spinTime],
                       [CCCallBlock actionWithBlock:^(void){
                            [gear stopAnimating];
                            host.userInteractionEnabled = YES;
                            CCArray *subviews = [CCArray arrayWithNSArray:[host subviews]];
                            [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                            X.choiceCode = cReset;
                            [X.modelP start];
                        }],
                       nil];
    [self runAction:seq];
}

-(void) showCorruptionAlert {
    ANNOUNCE
    corruptionAlert = [[UIAlertView alloc]
                       initWithTitle:@"Corrupted Game State"
                       message:@"The saved game state was corrupted. Darken must be reset to its beginning state before it can be played again. Darken will now reset itself and restart."
                       delegate:self
                       cancelButtonTitle:@"Reset Game"
                       otherButtonTitles:nil];
    [corruptionAlert show];
}

-(void) alertView:(UIAlertView *)sender clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (sender == corruptionAlert) {
        [corruptionAlert release];
        [X.modelP corruptionRestart];
    } else {    //assuming this class has only one alertview
        CCLOG(@"alertView:clickedButtonAtIndex: sender not recognized");
        kill( getpid(), SIGABRT );
    }
}

@end
