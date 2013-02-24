//
//  GuideScene.m
//  Darken
//
//  Created by Robert Lummis on 4/22/12.
//  Copyright 2012 ElectricTurkey Software. All rights reserved.
//

#import "GuideScene.h"
#import "SettingsScene.h"
#import "ChoiceScene.h"
#import "Common.h"
#import "RLButton.h"

@implementation GuideScene

-(void) dealloc{
    [super dealloc];
}

+(id) scene {
	ANNOUNCE
    CCScene *sceneNode = [CCScene node];
	GuideScene *guideSceneNode = [GuideScene node];
    [sceneNode addChild:guideSceneNode z:0];
	return guideSceneNode;
}

-(id) init {
    ANNOUNCE
    if ( (self = [super init]) ) {
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        w = screenSize.width;
        h = screenSize.height;
            //        glClearColor(0.85f, 0.85f, 0.85f, 1.0f);
        host = [CCDirector sharedDirector].openGLView;
        
        [self addTitle];
        [self addTextView];
        [self _addInfo];
        [self addDoneButton];
    }
    return self;
}

-(void) addTitle {
    CGRect titleFrame = CGRectMake(0.f, 8.f, w, 23.f);
    UILabel *title = [[UILabel alloc] initWithFrame:titleFrame];
    title.text = @"Getting Started with Darken";
    title.textColor = [UIColor blackColor];
    title.backgroundColor = [UIColor clearColor];
    title.font = [UIFont fontWithName:@"Helvetica-Bold" size:19];
    title.textAlignment = UITextAlignmentCenter;
    [host addSubview:title];
    [title release];
    
}

-(void) addTextView {
        //side margins match table in ChoiceScene
    CGFloat frameX = 15.f;
    CGFloat frameY = 40.f;
    CGFloat frameW = w - 2.f * frameX;  //450.
    CGFloat frameH = 225.f; //2::1
    CGRect textViewFrame = CGRectMake(frameX, frameY, frameW, frameH);
    textView = [[UITextView alloc] initWithFrame:textViewFrame];
    textView.editable = NO;
    textView.showsVerticalScrollIndicator = YES;
    [textView flashScrollIndicators];
    textView.textColor = [UIColor blackColor];
    textView.backgroundColor = [UIColor whiteColor];
    textView.font = [UIFont fontWithName:@"ChalkboardSE-Regular" size:16];
    textView.text = [self textForDisplay];
    [host addSubview:textView];
    [textView release];
    
        //put a border around the textView
    CGFloat borderThickness = 10.f;
    UIImage *borderImage = [UIImage imageNamed:@"guide_scene_border.png"];
    UIImageView *borderView = [[UIImageView alloc] initWithImage:borderImage];
    CGFloat manual4 = 4.f;  //ad hoc adjustment
    borderView.frame = CGRectMake(frameX - borderThickness, frameY - borderThickness + manual4,
                                  frameW + 2.f * borderThickness, frameH + 2.f * borderThickness);
    [host addSubview:borderView];
    [borderView release];
}

-(void) _addInfo {
    CGFloat frameX = 100.f;
    CGFloat frameY = textView.frame.origin.y + textView.frame.size.height + 10.f;
    CGFloat frameW = w - 2.f * frameX;
    CGFloat frameH = 40.f;
    CGRect frame = CGRectMake(frameX, frameY, frameW, frameH);
    UILabel *info = [[UILabel alloc] initWithFrame:frame];
    [host addSubview:info];
    [info release];
    info.backgroundColor = [UIColor clearColor];
    info.numberOfLines = 1;
    info.adjustsFontSizeToFitWidth = NO;
    info.font = [UIFont systemFontOfSize:14];
    info.text = @"This screen will not appear again.";
    info.textColor = [UIColor redColor];
}

-(NSString *) textForDisplay {
    NSMutableArray *items = [NSMutableArray arrayWithCapacity:5];
    
    [items addObject:@"Tutorial demonstrations are available during levels 1 and 2 but they are turned off by default. To see the tutorials tap the Settings button then tap \"Turn tutorials on\". The tutorials are recommended for new players as they show you the major features of the game.\r\rComplete \"How to Play\" instructions are available on the web at www.darkengame.com.  Happy Darkening!"];
    
    NSString *result = [items objectAtIndex:0];
    for (int i = 1; i < [items count]; i++) {
        result = [result stringByAppendingString:@"\n"];
        result = [result stringByAppendingString:[items objectAtIndex:i]];
    }
    return result;
}

-(void) addDoneButton {
    CGFloat doneButtonW = 70.f;
    CGFloat doneButtonH = 30.f;
    CGFloat doneButtonX = w - textView.frame.origin.x - doneButtonW;
    CGFloat doneButtonY = textView.frame.origin.y + textView.frame.size.height + 16.f;
    
    NSString *doneButtonText = @"Continue";
    CGRect frame = CGRectMake(doneButtonX, doneButtonY, doneButtonW, doneButtonH);
    RLButton *doneButton = [RLButton buttonWithStyle:RLButtonStyleBlueRoundedRect  
                                    target:self action:@selector(goBack) frame:frame];
    doneButton.text = doneButtonText;
    
    [host addSubview:doneButton];
}

-(void) goBack {
    ANNOUNCE
    CCArray *subviews = [CCArray arrayWithNSArray:[host subviews]];
    
    CCTransitionFade *tran;
    if (X.choiceCode == cLevel1) {
            //first play, got here from TitleScene
        tran = [CCTransitionFade transitionWithDuration:0.5f scene:[ ChoiceScene scene ]];
    } else {
            //got here from SettingsScene
        tran = [CCTransitionFade transitionWithDuration:0.5f scene:[ SettingsScene scene ]];
    }
    [[CCDirector sharedDirector] replaceScene:tran];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}


@end
