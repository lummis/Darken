//
//  SettingsScene.h
//  Darken
//
//  Created by Robert Lummis on 12/9/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

#import "RLButton.h"
#include "SimpleAudioEngine.h"

@interface SettingsScene : CCLayer <UIAlertViewDelegate> {
    CGFloat w;  //window width
    CGFloat h;  //window height
    CGFloat leftMargin;  //empty space on the left side of the window
    CGFloat rightMargin;
    CGFloat topMargin;  //empty space at the top of the window
    CGFloat inset;      //added to margin to position buttons
    CGFloat bottomMargin;
    UIView *host;
//    UIView *glView;
    
    CGFloat titleX;
    CGFloat titleY;
    CGFloat titleW;
    CGFloat titleH;

    CGFloat labelSpacing;
    CGFloat loudnessLabelX;
    CGFloat loudnessLabelY;
    CGFloat loudnessLabelW;
    CGFloat loudnessLabelH;
    
    CGFloat loudnessControlX;
    CGFloat loudnessControlY;
    CGFloat loudnessControlW;
    CGFloat loudnessControlH;
    
    CGFloat hintsLabelX;
    CGFloat hintsLabelY;
    CGFloat hintsLabelW;
    CGFloat hintsLabelH;
    UILabel *hintsLabel;
    
    CGFloat hintsButtonX;
    CGFloat hintsButtonY;
    CGFloat hintsButtonW;
    CGFloat hintsButtonH;
    RLButton *hintsButton;
    
    CGFloat resetHintsButtonX;
    CGFloat resetHintsButtonY;
    CGFloat resetHintsButtonW;
    CGFloat resetHintsButtonH;
    RLButton *resetHintsButton;
    
    CGFloat resetGameButtonX;
    CGFloat resetGameButtonY;
    CGFloat resetGameButtonW;
    CGFloat resetGameButtonH;
    RLButton *resetButton;
    
    CGFloat bugLabelX;
    CGFloat bugLabelY;
    CGFloat bugLabelW;
    CGFloat bugLabelH;
    UILabel *bugLabel;
    
    CGFloat bugButtonX;
    CGFloat bugButtonY;
    CGFloat bugButtonW;
    CGFloat bugButtonH;
    RLButton *bugButton;
    
    CGFloat guideButtonX;
    CGFloat guideButtonY;
    CGFloat guideButtonW;
    CGFloat guideButtonH;
    RLButton *guideButton;
    
    CGFloat doneButtonW;
    CGFloat doneButtonH;
    CGFloat doneButtonX;
    CGFloat doneButtonY;
    RLButton *doneButton;

    BOOL resetConfirmed;
    UISegmentedControl *loudnessControl;
    int loudness;
    UIImageView *v0, *v1, *v2, *v3, *v4;  
    UIAlertView *resetAlert1;
    UIAlertView *resetAlert2;
    UIAlertView *hintsResetAlert;
    
    SimpleAudioEngine *sae;
    
    int loudnessNumberStart;
    BOOL tutorialsEnabledStart;
    
}

+(id) scene;
-(void) addTitle;
-(void) addLoudnessControl;
-(void) loudnessChanged:(id)sender;
-(void) addGrid;
-(void) addDoneButton;
-(void) goDone;
-(void) addResetGameButton;
-(void) addResetHintsButton;
-(void) addHintsLabel;
-(void) addHintsButton;
-(void) addFeedbackLabel;
-(void) addFeedbackButton;
-(void) addGuideButton;
-(void) goGuide;
-(void) doFeedback;
-(void) toggleHints;
-(void) resetAlert;
-(void) exitAlert;
-(void) doReset;
-(void) showHintsAlert;
-(void) addVersionBuild;
-(NSString *) version;
-(NSString *) build;

@property (nonatomic, assign) int loudness;

@end
