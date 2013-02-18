//
//  RatingsScene.h
//  Darken
//
//  Created by Robert Lummis on 2/10/12.
//  Copyright 2012 ElectricTurkey Software. All rights reserved.
//

#import "RLButton.h"

@interface RatingsScene : CCLayer <UITextFieldDelegate> {
    float w, h;
    UIView *host;
    
    BOOL gotRating;
    
    float leftMargin, rightMargin, topMargin, bottomMargin;
    float ratingsLabelX, ratingsLabelY, ratingsLabelW, ratingsLabelH;
    float labelSpacing;
    float ratingsControlX, ratingsControlY, ratingsControlW, ratingsControlH;
    float commentFieldX, commentFieldY, commentFieldW, commentFieldH;
    float doneButtonX, doneButtonY, doneButtonW, doneButtonH;
    
    UISegmentedControl *ratingsControl;
    UITextField *commentField;
    RLButton *doneButton;
    RLButton *debugButton;
    NSString *defaultComment;
}

+(id) scene;
-(void) addRatingsControl;
-(void) addCommentField;
-(void) addDoneButton;
-(void) addDebugButton;
-(void) debugTouched;
-(void) doneTouched;
-(void) ratingChanged:(id)sender;
//-(void) sendRatings;

@end
