//
//  RatingsScene.m
//  Darken
//
//  Created by Robert Lummis on 2/10/12.
//  Copyright 2012 ElectricTurkey Software. All rights reserved.
//

#import "RatingsScene.h"
#import "Model.h"
#import "ChoiceScene.h"
//#import "Mailer.h"

@implementation RatingsScene

-(void) dealloc {
    ANNOUNCE
    [super dealloc];
}

+(id) scene {
	ANNOUNCE
    CCScene *scene = [CCScene node];
	RatingsScene *ratingsSceneNode = [RatingsScene node];
    [scene addChild:ratingsSceneNode z:0];
	return scene;
}

-(id) init {
    ANNOUNCE
    if ( (self = [super init]) ) {
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        w = screenSize.width;
        h = screenSize.height;
        glClearColor(198.f/255.f, 156.f/255.f, 109.f/255.f, 1.0f);
        host = [CCDirector sharedDirector].openGLView;
//        UIView *glView = [CCDirector sharedDirector].openGLView;
//        host = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 480, 320)];
//        [glView addSubview:host];
        
        leftMargin = 25.f;  //left side of controls
        topMargin = 20.f;
        bottomMargin = h - 25.f;
        labelSpacing = 22.f;
        
        ratingsLabelY = topMargin;
        ratingsLabelX = leftMargin;
        ratingsLabelH = 20.f;
        ratingsLabelW = 250.f;
        
        ratingsControlX = leftMargin;
        rightMargin = leftMargin;
        ratingsControlY = ratingsLabelY + labelSpacing;
        ratingsControlW = w - leftMargin - rightMargin;
        ratingsControlH = 30.f;

        commentFieldX = leftMargin;
        commentFieldY = ratingsControlY + ratingsControlH + 50.f;
        commentFieldW = w - leftMargin - rightMargin;
        commentFieldH = 30.f;
        
        doneButtonW = 110.f;
        doneButtonH = 30.f;
        doneButtonX = w - rightMargin - doneButtonW;
        doneButtonY = 250.f;
        
        gotRating = NO;
        [self addRatingsControl];
        [self addCommentField];
        [self addDoneButton];
        [self addDebugButton];
        
        defaultComment = @"-";
    }
    return self;
}

-(void) addRatingsControl {
    ANNOUNCE
    CGRect labelRect = CGRectMake(ratingsLabelX, ratingsLabelY, 
                                  ratingsLabelW, ratingsLabelH);
    UILabel *ratingsLabel = [[UILabel alloc] initWithFrame:labelRect];
    ratingsLabel.text = @"Rate the parameters just played...";
    ratingsLabel.textColor = [UIColor blackColor];
    ratingsLabel.backgroundColor = [UIColor clearColor];
    ratingsLabel.textAlignment = UITextAlignmentLeft;
    ratingsLabel.font = [UIFont fontWithName:@"Helvetica" size:14];
    [host addSubview:ratingsLabel];
    [ratingsLabel release];
    ratingsLabel = nil;
    
    NSArray *ratingNames = [NSArray arrayWithObjects:@"<easy", @"easy", @"good", @"hard", @">hard", nil];
    ratingsControl = [[UISegmentedControl alloc] initWithItems:ratingNames] ;
    ratingsControl.frame = CGRectMake(ratingsControlX, ratingsControlY, 
                                       ratingsControlW, ratingsControlH);
    ratingsControl.segmentedControlStyle = UISegmentedControlStyleBar;
    [ratingsControl addTarget:self 
                        action:@selector(ratingChanged:) 
              forControlEvents:UIControlEventValueChanged];
    [host addSubview:ratingsControl];
    [ratingsControl release];
}

-(void) ratingChanged:(id)sender {
    ANNOUNCE
    NSAssert(sender == ratingsControl, @"ratingChanged: sender is not ratingsControl");
    X.rating = ratingsControl.selectedSegmentIndex;
    gotRating = YES;
}

-(void) addCommentField {
    ANNOUNCE
    commentField = [[UITextField alloc] initWithFrame:CGRectMake(commentFieldX, commentFieldY, commentFieldW, commentFieldH)];
    commentField.textColor = [UIColor blackColor];
    commentField.font = [UIFont systemFontOfSize:16];
    commentField.placeholder = @"<optional single-line comment>";
    commentField.backgroundColor = [UIColor whiteColor];
    commentField.borderStyle = UITextBorderStyleBezel;
    commentField.returnKeyType = UIReturnKeyDone;
    commentField.keyboardType = UIKeyboardTypeDefault;
    commentField.clearButtonMode = UITextFieldViewModeAlways;
    commentField.delegate = self;
    commentField.text = defaultComment;
    [host addSubview:commentField];
    [commentField release];
}

    //delegate method
-(BOOL) textFieldShouldClear:(UITextField *)textField {
    ANNOUNCE
    return YES;
}

    //delegate method
-(BOOL) textFieldShouldReturn:(UITextField *)textField {
    ANNOUNCE
        //if user touches commentField, bringing up keyboard, and then touches done without entering text, length is 0
        //if user doesn't touch commentField at all this method is not called
    if ([commentField.text length] == 0) {
        commentField.text = @"--";
    }
    [commentField resignFirstResponder];
    return YES;
}

    //delegate method
-(BOOL) textFieldShouldBeginEditing:(UITextField *)textField {
    ANNOUNCE
    return YES;
}

    //delegate method
-(void) textFieldDidBeginEditing:(UITextField *)textField {
    ANNOUNCE
}

    //delegate method
-(void) textFieldDidEndEditing:(UITextField *)textField {
    ANNOUNCE
}

    //delegate method - this is called on every char typed by user
-(BOOL) textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    ANNOUNCE
    return YES;
}

-(void) addDoneButton {
    ANNOUNCE
    CGRect frame = CGRectMake(doneButtonX, doneButtonY, doneButtonW, doneButtonH);
    doneButton = [RLButton buttonWithStyle:RLButtonStyleBlueRoundedRect 
                                    target:self action:@selector(doneTouched) frame:frame];
    doneButton.text = @"Done";
    [host addSubview:doneButton];
}

-(void) addDebugButton {
    CGRect frame = CGRectMake(leftMargin, doneButtonY - 50.f, doneButtonW, doneButtonH);
    debugButton = [RLButton buttonWithStyle:RLButtonStyleBlueRoundedRect 
                                        target:self action:@selector(debugTouched) frame:frame];
    debugButton.text = @"Debug";
    [host addSubview:debugButton];
}

-(void) debugTouched {
    ANNOUNCE
}

-(void) doneTouched {
    ANNOUNCE
    if (gotRating == NO) return;
    
//    [self sendRatings];
    
    NSString *completionText = X.completedFlag ? @"Completed. " : @"Failed.    ";
        //arg of stringByAppendingString must not be nil
    if (commentField.text == nil) {
        commentField.text = defaultComment;
    }
    NSString *comment = [completionText stringByAppendingString:commentField.text];
    [X.modelP outputParametersForLevel:X.level 
                               rating:ratingsControl.selectedSegmentIndex 
                              comment:comment];
    
        //in LoadBoardScene countdown has to be long enough to let this fade transition finish
        //get subviews before starting scene transition
    CCArray *subviews = [CCArray arrayWithNSArray:[host subviews]];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    
//    [host removeFromSuperview];
//    [host release];

    if (X.completedFlag == YES) {
        [X.modelP completed];
    }
//    } else {
//        [X.modelP failed];
//    }
}

//-(void) sendRatings {
//    ANNOUNCE
//    NSString *to = @"robert.lummis@gmail.com";
//    NSString *subject = @"test mail from Darken";
//    NSString *body = @"This is the body text for a test message";
//    Mailer *mailer = [[[Mailer alloc] initWithNibName:nil bundle:nil] autorelease];
//    [mailer emailTo:to subject:subject body:body];
//}


@end
