//
//  FeedbackScene.h
//  Darken
//
//  Created by Robert Lummis on 7/7/12.
//  Copyright (c) 2012 ElectricTurkey Software. All rights reserved.
//

#import <CoreText/CoreText.h>   //so I can use attributed string
#import <MessageUI/MFMailComposeViewController.h>

@class RLButton;

@interface FeedbackScene : CCScene <MFMailComposeViewControllerDelegate, UIAlertViewDelegate> {
    
    CGFloat w, h;   //screen width & height
    CGFloat leftMargin;  //empty space on the left side of the window
    CGFloat rightMargin;
    CGFloat topMargin;  //empty space at the top of the window
    CGFloat inset;      //added to margin to position buttons
    CGFloat bottomMargin;
    UIView *host;
    
    RLButton *emailButton;
    RLButton *webButton;
    RLButton *doneButton;
    
    CGFloat titleX, titleY, titleW, titleH;
    CGFloat bodyX, bodyY, bodyW, bodyH;
    CGFloat emailButtonX, emailButtonY, emailButtonW, emailButtonH;
    CGFloat webButtonX, webButtonY, webButtonW, webButtonH;
    CGFloat doneButtonX, doneButtonY, doneButtonW, doneButtonH;
}

+(id) scene;

-(void) addTitle;
-(void) addBody;

-(void) addEmailButton;
-(void) addWebButton;
-(void) addDoneButton;

-(void) doEmail;
-(void) doWeb;
-(void) doDone;

@end
