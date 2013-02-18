//
//  SettingsScene.m
//  Darken
//
//  Created by Robert Lummis on 12/9/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

#import "SettingsScene.h"
#import "ChoiceScene.h"
#import "Model.h"
#import "GuideScene.h"
#import "MessageManager.h"
#import "FeedbackScene.h"
#import "RLGameCenter.h"
#import "LocalyticsSession.h"

@implementation SettingsScene
@synthesize loudness;

-(void) dealloc {
    ANNOUNCE
        //    [host release];   //apparently this causing EXEC_BAD_ACCESS the 4th time through here
    [super dealloc];
}
-(void) onEnter {
    ANNOUNCE
    [super onEnter];
}

-(void) onEnterTransitionDidFinish {
    ANNOUNCE
    X.nowInSettingsScene = YES;
    [super onEnterTransitionDidFinish];
}

-(void) onExit {
    ANNOUNCE
    X.nowInSettingsScene = NO;
    [super onExit];
}

+(id) scene {
	ANNOUNCE
    CCScene *sceneNode = [CCScene node];
	SettingsScene *settingsSceneNode = [SettingsScene node];
    [sceneNode addChild:settingsSceneNode z:0];
	return settingsSceneNode;
}

-(id) init {
    ANNOUNCE
    if ( (self = [super init]) ) {
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        w = screenSize.width;
        h = screenSize.height;
//        glClearColor(0.85f, 0.85f, 0.85f, 1.0f);
        host = [CCDirector sharedDirector].openGLView;
        
        leftMargin = 25.f;  //left side of controls
        topMargin = 50.f;   //title is above the top margin
        bottomMargin = h - 25.f;
        labelSpacing = 22.f;
        inset = 10.f;
        
        titleW = 400.f;
        titleH = 40.f;
        titleX = (w - titleW) / 2.f;
        titleY = 10.f;
        
        loudnessLabelY = topMargin;
        loudnessLabelX = leftMargin;
        loudnessLabelH = 20.f;
        loudnessLabelW = 75.f;
        
        loudnessControlX = leftMargin;
        loudnessControlY = loudnessLabelY + labelSpacing;
        loudnessControlW = w - 2.f * loudnessControlX;
        loudnessControlH = 50.f;
        
        rightMargin = leftMargin + loudnessControlW; //right side of controls

        hintsLabelW = 150.f;
        hintsLabelH = 20.f;
        hintsLabelX = leftMargin + 5.f;
        hintsLabelY = loudnessControlY + loudnessControlH + labelSpacing;
        
        hintsButtonX = leftMargin + inset;
        hintsButtonY = hintsLabelY + labelSpacing;
        hintsButtonW = 140.f;
        hintsButtonH = 30.f;
        
        resetHintsButtonW = 140.f;
        resetHintsButtonH = 30.f;
        resetHintsButtonX = leftMargin + inset;
        resetHintsButtonY = hintsButtonY + hintsButtonH + labelSpacing;
        
        resetGameButtonW = 140.f;
        resetGameButtonH = 30.f;
        resetGameButtonY = resetHintsButtonY + resetHintsButtonH + labelSpacing;
        resetGameButtonX = leftMargin + inset;
        
        bugButtonW = 120.f;
        bugButtonH = 30.f;
        bugButtonX = rightMargin - inset - bugButtonW;
        bugButtonY = hintsButtonY;

        bugLabelW = bugButtonW;
        bugLabelH = 20.f;
        bugLabelX = rightMargin - inset - bugButtonW;
        bugLabelY = hintsLabelY;
        
        guideButtonW = bugButtonW;
        guideButtonH = 30.f;
        guideButtonX = rightMargin - inset - guideButtonW;
        guideButtonY = bugButtonY + bugButtonH + labelSpacing;

        doneButtonW = bugButtonW;
        doneButtonH = 30.f;
        doneButtonX = rightMargin - inset - doneButtonW;
        doneButtonY = guideButtonY + guideButtonH + labelSpacing;


        [self addTitle];
        [self addLoudnessControl];
        [self addHintsLabel];
        [self addHintsButton];
        [self addResetHintsButton];
        [self addResetGameButton];
        [self addFeedbackLabel];
        [self addFeedbackButton];
        [self addGuideButton];
        [self addDoneButton];
        [self addVersionBuild];
        
        loudnessControl.selectedSegmentIndex = X.loudnessNumber;
        sae = [SimpleAudioEngine sharedEngine];
//        [sae preloadEffect:@"pluck.wav"];

        if (GRIDFLAG) {
            [self addGrid];
        }
        
        loudnessNumberStart = X.loudnessNumber;
        tutorialsEnabledStart = X.tutorialsEnabled;
    }
    return self;
}

-(void) addGrid {
    for (CGFloat x = 0.f; x < 480.f; x += 50.f) {
        CGRect f = CGRectMake(x, 5.f, 0.5f, 310.f);
        UIView *v = [[UIView alloc] initWithFrame:f];
        v.backgroundColor = [UIColor blueColor];
        [host addSubview:v];
        [v release];
    }
    for (CGFloat y = 0.f; y < 320; y += 50.f) {
        CGRect f = CGRectMake(5.f, y, 470.f, 0.5f);
        UIView *v = [[UIView alloc] initWithFrame:f];
        v.backgroundColor = [UIColor blueColor];
        [host addSubview:v];
        [v release];
    }
}

-(void) addTitle {
    ANNOUNCE
    CGRect frame = CGRectMake(titleX, titleY, titleW, titleH);
    UILabel *title = [[UILabel alloc] initWithFrame:frame];
    title.text = @"Darken Settings";
    title.font = [UIFont fontWithName:@"Helvetica" size:19];
    title.textColor = [UIColor blackColor];
    title.backgroundColor = [UIColor clearColor];
    title.textAlignment = UITextAlignmentCenter;
    [host addSubview:title];
    [title release];
}

-(void) addLoudnessControl {
    ANNOUNCE
    CGRect labelRect = CGRectMake(loudnessLabelX, loudnessLabelY, 
                                  loudnessLabelW, loudnessLabelH);
    UILabel *loudnessLabel = [[UILabel alloc] initWithFrame:labelRect];
    loudnessLabel.text = @"Sounds";
    loudnessLabel.textColor = [UIColor blackColor];
    loudnessLabel.backgroundColor = [UIColor clearColor];
    loudnessLabel.textAlignment = UITextAlignmentLeft;
    loudnessLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
    [host addSubview:loudnessLabel];
    [loudnessLabel release];
    loudnessLabel = nil;

    loudnessControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:
                                                                 [UIImage imageNamed:@"LoudnessIcon0.png"],
                                                                 [UIImage imageNamed:@"LoudnessIcon1.png"],
                                                                 [UIImage imageNamed:@"LoudnessIcon2.png"],
                                                                 [UIImage imageNamed:@"LoudnessIcon3.png"],
                                                                 [UIImage imageNamed:@"LoudnessIcon4.png"], nil]];
    loudnessControl.tintColor = [UIColor colorWithRed:0.0 green:0.3 blue:1.0 alpha:1.0];
    loudnessControl.frame = CGRectMake(loudnessControlX, loudnessControlY, 
                                       loudnessControlW, loudnessControlH);
    loudnessControl.segmentedControlStyle = UISegmentedControlStyleBar;
    [loudnessControl addTarget:self 
                        action:@selector(loudnessChanged:) 
              forControlEvents:UIControlEventValueChanged];
    [host addSubview:loudnessControl];
    [loudnessControl release];
    
}

-(void) loudnessChanged:(id)sender {
    ANNOUNCE
    NSAssert(sender == loudnessControl, @"loudnessChanged: sender is not loudnessControl");
    X.loudnessNumber = loudnessControl.selectedSegmentIndex;
    switch (loudnessControl.selectedSegmentIndex) {
        case 0:
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon0.png"] forSegmentAtIndex:0];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon1gray.png"] forSegmentAtIndex:1];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon2gray.png"] forSegmentAtIndex:2];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon3gray.png"] forSegmentAtIndex:3];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon4gray.png"] forSegmentAtIndex:4];
            [sae setEffectsVolume:[X.modelP gainForLoudnessNumber:X.loudnessNumber]];
            [sae playEffect:@"pluck.wav"];
            break;
            
        case 1:
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon0gray.png"] forSegmentAtIndex:0];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon1.png"] forSegmentAtIndex:1];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon2gray.png"] forSegmentAtIndex:2];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon3gray.png"] forSegmentAtIndex:3];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon4gray.png"] forSegmentAtIndex:4];
            [sae setEffectsVolume:[X.modelP gainForLoudnessNumber:X.loudnessNumber]];
            [sae playEffect:@"pluck.wav"];
            break;
            
        case 2:
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon0gray.png"] forSegmentAtIndex:0];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon1gray.png"] forSegmentAtIndex:1];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon2.png"] forSegmentAtIndex:2];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon3gray.png"] forSegmentAtIndex:3];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon4gray.png"] forSegmentAtIndex:4];
            [sae setEffectsVolume:[X.modelP gainForLoudnessNumber:X.loudnessNumber]];
            [sae playEffect:@"pluck.wav"];
            break;
            
        case 3:
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon0gray.png"] forSegmentAtIndex:0];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon1gray.png"] forSegmentAtIndex:1];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon2gray.png"] forSegmentAtIndex:2];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon3.png"] forSegmentAtIndex:3];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon4gray.png"] forSegmentAtIndex:4];
            [sae setEffectsVolume:[X.modelP gainForLoudnessNumber:X.loudnessNumber]];
            [sae playEffect:@"pluck.wav"];
            break;
            
        case 4:
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon0gray.png"] forSegmentAtIndex:0];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon1gray.png"] forSegmentAtIndex:1];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon2gray.png"] forSegmentAtIndex:2];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon3gray.png"] forSegmentAtIndex:3];
            [loudnessControl setImage:[UIImage imageNamed:@"LoudnessIcon4.png"] forSegmentAtIndex:4];
            [sae setEffectsVolume:[X.modelP gainForLoudnessNumber:X.loudnessNumber]];
            [sae playEffect:@"pluck.wav"];
            break;
            
        default:
            CCLOG(@"selected loudness number is out of range: %d", loudnessControl.selectedSegmentIndex);
            kill( getpid(), SIGABRT );  //crash
            break;
    }
}

    //Hints was the first name for what is now tutorial messages
    //add Hints On/Off label and button
-(void) addHintsLabel {
    ANNOUNCE
    CGRect labelRect = CGRectMake(hintsLabelX, hintsLabelY, hintsLabelW, hintsLabelH);
    hintsLabel = [[UILabel alloc] initWithFrame:labelRect];
    hintsLabel.text = X.tutorialsEnabled ?
            [NSString stringWithFormat:@"Tutorials are ON"] : [NSString stringWithFormat:@"Tutorials are OFF"];
    hintsLabel.textColor = [UIColor blackColor];
    hintsLabel.backgroundColor = [UIColor clearColor];
    hintsLabel.textAlignment = UITextAlignmentCenter;
    hintsLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
    [host addSubview:hintsLabel];
    [hintsLabel release];
}

-(void) addHintsButton {    //now called tutorials
    ANNOUNCE
    CGRect frame = CGRectMake(hintsButtonX, hintsButtonY, 
                                    hintsButtonW, hintsButtonH);
    NSString *title = X.tutorialsEnabled ? @"Turn tutorials off" : @"Turn tutorials on";
    hintsButton = [RLButton buttonWithStyle:RLButtonStyleBlueRoundedRect  
                                     target:self action:@selector(toggleHints) frame:frame];
    hintsButton.text = title;
    [host addSubview:hintsButton];
}

-(void) toggleHints {
    ANNOUNCE    
    X.tutorialsEnabled = X.tutorialsEnabled ? NO : YES;
    hintsLabel.text = X.tutorialsEnabled ? [NSString stringWithFormat:@"Tutorials are ON"]
                                : [NSString stringWithFormat:@"Tutorials are OFF"];
    [hintsButton setTitle:X.tutorialsEnabled ? [NSString stringWithFormat:@"Turn tutorials off"]
                         : [NSString stringWithFormat:@"Turn tutorials on"]
                 forState:UIControlStateNormal];    
}

-(void) addResetGameButton {
    ANNOUNCE
    CGRect frame = CGRectMake(resetGameButtonX, resetGameButtonY, resetGameButtonW, resetGameButtonH);
    resetButton = [RLButton buttonWithStyle:RLButtonStyleBlueRoundedRect 
                                    target:self action:@selector(resetAlert) frame:frame];
    resetButton.text = @"Reset Game";
    [host addSubview:resetButton];
}

-(void) addFeedbackLabel {
    ANNOUNCE
    CGRect labelRect = CGRectMake(bugLabelX, bugLabelY, bugLabelW, bugLabelH);
    bugLabel = [[UILabel alloc] initWithFrame:labelRect];
    bugLabel.numberOfLines = 1;
    bugLabel.text = @"Suggestion or bug";
    bugLabel.backgroundColor = [UIColor clearColor];
    bugLabel.textAlignment = UITextAlignmentCenter;
    bugLabel.font = [UIFont fontWithName:@"Helvetica" size:12];
    [host addSubview:bugLabel];
    [bugLabel release];
    bugLabel = nil;
}

-(void) addFeedbackButton {
    ANNOUNCE
    CGRect frame = CGRectMake(bugButtonX, bugButtonY, bugButtonW, bugButtonH);
    bugButton = [RLButton buttonWithStyle:RLButtonStyleBlueRoundedRect 
                                            target:self action:@selector(doFeedback) frame:frame];
    bugButton.text = @"Feedback";
    [host addSubview:bugButton];
}

-(void) doFeedback {
    ANNOUNCE
    CCArray *subviews = [CCArray arrayWithNSArray:[host subviews]];
    CCTransitionFade *tran = [CCTransitionFade transitionWithDuration:0.5f scene:[ FeedbackScene scene ]];
    [[CCDirector sharedDirector] replaceScene:tran];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

-(void) addGuideButton {
    ANNOUNCE
    CGRect frame = CGRectMake(guideButtonX, guideButtonY, guideButtonW, guideButtonH);
    guideButton = [RLButton buttonWithStyle:RLButtonStyleBlueRoundedRect 
                                     target:self action:@selector(goGuide) frame:frame];
    guideButton.text = @"Getting Started";
    [host addSubview:guideButton];
}

-(void) goGuide {
    ANNOUNCE
    CCArray *subviews = [CCArray arrayWithNSArray:[host subviews]];
    CCTransitionFade *tran = [CCTransitionFade transitionWithDuration:0.5f scene:[ GuideScene scene ]];
    [[CCDirector sharedDirector] replaceScene:tran];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

-(void) addDoneButton {
    ANNOUNCE
    CGRect frame = CGRectMake(doneButtonX, doneButtonY, doneButtonW, doneButtonH);
    doneButton = [RLButton buttonWithStyle:RLButtonStyleBlueRoundedRect 
                                    target:self action:@selector(goDone) frame:frame];
    doneButton.text = @"Continue";
    [host addSubview:doneButton];
}

-(void) goDone {
    ANNOUNCE
    
        //report new loudnessNumber if changed
    if (X.loudnessNumber != loudnessNumberStart) {
//        NSDictionary *d = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:X.loudnessNumber] forKey:@"Loudness after change"];
        NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInteger:X.loudnessNumber], @"Loudness after change", nil];
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Loudness Changed" attributes:d];
    }
    if (X.tutorialsEnabled != tutorialsEnabledStart) {
        NSString *s = X.tutorialsEnabled ? @"ON" : @"OFF";
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:[@"Tutorials turned " stringByAppendingString:s]];
    }
    
    CCArray *subviews = [CCArray arrayWithNSArray:[host subviews]];
    CCTransitionFade *tran = [CCTransitionFade transitionWithDuration:0.5f scene:[ ChoiceScene scene ]];
    [[CCDirector sharedDirector] replaceScene:tran];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

    //advisory messages
-(void) addResetHintsButton {
    ANNOUNCE
    CGRect frame = CGRectMake(resetHintsButtonX, resetHintsButtonY, resetHintsButtonW, resetHintsButtonH);
    resetHintsButton = [RLButton buttonWithStyle:RLButtonStyleBlueRoundedRect 
                                          target:self action:@selector(showHintsAlert) frame:frame];
    resetHintsButton.text = @"Reset Advisories";
    [host addSubview:resetHintsButton];
}

-(void) resetAlert {    //alert #1 called when reset game button tapped
    ANNOUNCE
    resetAlert1 = [[UIAlertView alloc]
                       initWithTitle:@"Reset Darken" 
                       message:@"This will erase your high scores and lock all levels except level one. Your stars and bombs will be reset to their starting quantities. Do you want to proceed?"
                       delegate:self 
                       cancelButtonTitle:@"Cancel" 
                       otherButtonTitles:@"Proceed", nil];
    [resetAlert1 show];
}

-(void) exitAlert {    //this is the 2nd warning given when reset game button is tapped and "Proceed" is chosen in the first alert
    ANNOUNCE
    resetAlert2 = [[UIAlertView alloc]
                       initWithTitle:@"Warning" 
                       message:@"This action can not be undone. Are you sure you want to proceed?"
                       delegate:self
                       cancelButtonTitle:@"Cancel"
                       otherButtonTitles:@"Reset & Restart", nil];
    [resetAlert2 show];
}

-(void) showHintsAlert {    //alert called when reset messages button is tapped
    ANNOUNCE
    hintsResetAlert = [[UIAlertView alloc]
              initWithTitle:@"Reset Advisories" 
              message:@"All advisory messages will be shown, including those you marked \"Don't show again\". Do you want to proceed?" 
              delegate:self
              cancelButtonTitle:@"Cancel" 
              otherButtonTitles:@"Proceed", nil];
    [hintsResetAlert show];
}

-(void) alertView:(id)sender clickedButtonAtIndex:(NSInteger)index {
    ANNOUNCE
    NSAssert(sender == resetAlert1 || sender == resetAlert2 || sender == hintsResetAlert, @"AlertView: unrecognized sender");
    if ( index == 0 ) {
        return; //do nothing; the cancel button was tapped in the alert
    }
    
    if (sender == resetAlert1) {
        [resetAlert1 release];
        resetAlert1 = nil;
        [self exitAlert];
    }
    
    else if (sender == resetAlert2) {
        [resetAlert2 release];
        resetAlert2 = nil;
        [self doReset];
    }
    
    else if (sender == hintsResetAlert) { //reset advisory messages
        NSString *sn;
        if (X.sessionNumber == 1) sn = @"1";
        else if (X.sessionNumber == 2) sn = @"2";
        else if (X.sessionNumber <= 5) sn = @"3 - 5";
        else if (X.sessionNumber <= 10) sn = @"6 - 10";
        else if (X.sessionNumber <= 20) sn = @"11 - 20";
        else if (X.sessionNumber <= 100) sn = @"21 - 100";
        else sn = @"> 100";
        NSDictionary *d = [NSDictionary dictionaryWithObject:sn forKey:@"Session number"];
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Reset Advisories" attributes:d];
        [[MessageManager sharedManager] resetKeyedMessages];
        [hintsResetAlert release];
        hintsResetAlert = nil;
    }
    
    else {
        CCLOG(@"alertView:clickedButtonAtIndex: sender not recognized");
    }
}

-(void) doReset {
    ANNOUNCE
    int r = X.resets + 1;   //number of resets; X.resets will be incremented in Model/launch
    NSDictionary *d;
    if (r == 1) {
        d = [NSDictionary dictionaryWithObject:@"1" forKey:@"Number of Resets"];
    } else if (r <= 4) {
        d = [NSDictionary dictionaryWithObject:@"2 - 4" forKey:@"Number of Resets"];
    } else if (r <= 14) {
        d = [NSDictionary dictionaryWithObject:@"5 - 14" forKey:@"Number of Resets"];
    } else {
        d = [NSDictionary dictionaryWithObject:@">= 15" forKey:@"Number of Resets"];
    }
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Game Reset" attributes:d];
    
    X.choiceCode = cReset;    //make Model/launch reset variables to initial state
    [X.modelP putDefaults];
    
    UIActivityIndicatorView *gear = [[UIActivityIndicatorView alloc]
                                     initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    gear.color = [UIColor blackColor];
    gear.frame = CGRectMake(w/2, h/2, 37, 37);
    gear.hidesWhenStopped = YES;
    [host addSubview:gear];
    host.userInteractionEnabled = NO;
    [gear release];
    [gear startAnimating];
    int spinTime = 1.8;
    CCSequence *seq = [CCSequence actions:
                       [CCDelayTime actionWithDuration:spinTime],
                       [CCCallBlock actionWithBlock:^(void){
        [gear stopAnimating];
        CCArray *subviews = [CCArray arrayWithNSArray:[host subviews]];
        [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
        host.userInteractionEnabled = YES;
        [X.modelP launch];
    }],
                       nil];
    [self runAction:seq];
    
//    CCArray *subviews = [CCArray arrayWithNSArray:[host subviews]];
//    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
//    [X.modelP launch];
}

-(void) addVersionBuild {
    ANNOUNCE
    NSString *versionBuildString = @"Version ";
    versionBuildString = [versionBuildString stringByAppendingString:[self version]];
    versionBuildString = [versionBuildString stringByAppendingString:@" ("];
    versionBuildString = [versionBuildString stringByAppendingString:[self build]];
    versionBuildString = [versionBuildString stringByAppendingString:@")"];
    CCLOG(@"versionBuildString: %@", versionBuildString);
    CGRect labelFrame = CGRectMake(10.f, 3.f, 150.f, 20.f);
    UILabel *versionBuildLabel = [[UILabel alloc] initWithFrame:labelFrame];
    versionBuildLabel.text = versionBuildString;
    versionBuildLabel.font = [UIFont systemFontOfSize:9];
    versionBuildLabel.textColor = [UIColor blackColor];
    versionBuildLabel.backgroundColor = [UIColor clearColor];
    [host addSubview:versionBuildLabel];
    [versionBuildLabel release];
}

-(NSString *) version {
    ANNOUNCE
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

-(NSString *) build {
    ANNOUNCE
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

@end
