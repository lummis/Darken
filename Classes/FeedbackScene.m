//
//  FeedbackScene.m
//  Darken
//
//  Created by Robert Lummis on 7/7/12.
//  Copyright (c) 2012 ElectricTurkey Software. All rights reserved.
//

#import "FeedbackScene.h"
#import "SettingsScene.h"
#import "RLButton.h"
#import "LocalyticsSession.h"

@implementation FeedbackScene

-(void) dealloc {
    [super dealloc];
}

+(id) scene {
	ANNOUNCE
    CCScene *sceneNode = [CCScene node];
	FeedbackScene *feedbackSceneNode = [FeedbackScene node];
    [sceneNode addChild:feedbackSceneNode z:0];
	return feedbackSceneNode;
}

-(id) init {
    ANNOUNCE
    if ( (self = [super init]) ) {
        CGSize screenSize = [[CCDirector sharedDirector] winSize];
        w = screenSize.width;
        h = screenSize.height;
        host = [CCDirector sharedDirector].openGLView;
        
        leftMargin = 25.f;  //left side of controls
        rightMargin = 25.f;
        inset = 20.f;
        topMargin = 45.f;   //title is above the top margin
        bottomMargin = 50.f;    // space for buttons at the bottom (size of the space, not its position)
        
        titleW = w - leftMargin - rightMargin;
        titleH = 30.f;
        titleX = leftMargin;
        titleY = topMargin - titleH;
        
        bodyW = w - leftMargin - rightMargin;
        bodyH = h - topMargin - bottomMargin - 6.f;
        bodyX = leftMargin;
        bodyY = topMargin;
        
        emailButtonW = 70.f;
        emailButtonH = 25.f;
        emailButtonX = leftMargin + inset;
        emailButtonY = h - 0.5f * (bottomMargin + emailButtonH);
        
        webButtonW = 80.f;
        webButtonH = 25.f;
        webButtonX = 0.5f * (w - webButtonW);
        webButtonY = h - 0.5f * (bottomMargin + webButtonH);
        
        doneButtonW = 70.f;
        doneButtonH = 25.f;
        doneButtonX = w - rightMargin - inset - doneButtonW;
        doneButtonY = h - 0.5f * (bottomMargin + doneButtonH);
        
        [self addTitle];
        [self addBody];
        [self addEmailButton];
//        [self addWebButton];
        [self addDoneButton];
        
    }
    return self;
}

-(void) addTitle {
    CGRect frame = CGRectMake(titleX, titleY, titleW, titleH);
    UILabel *title = [[UILabel alloc] initWithFrame:frame];
    title.font = [UIFont boldSystemFontOfSize:26];
    title.textAlignment = UITextAlignmentCenter;
    title.backgroundColor = [UIColor clearColor];
    [host addSubview:title];
    [title release];
    title.text = @"Darken Feedback";
}

-(void) addBody {
    ANNOUNCE
    CGRect frame = CGRectMake(bodyX, bodyY, bodyW, bodyH);
    UILabel *body = [[UILabel alloc] initWithFrame:frame];
    body.font = [UIFont systemFontOfSize:17];
    body.textAlignment = UITextAlignmentLeft;
    body.numberOfLines = 0;
    body.lineBreakMode = UILineBreakModeWordWrap;
    body.backgroundColor = [UIColor clearColor];
    [host addSubview:body];
    [body release];
    
    NSString *bodyText = @"Please help improve Darken by telling us about anything \
that doesn't work right or that you just don't like. Help make Darken as good as it can be.\n\nTo provide feedback with a web browser go to darkengame.com and click on \"Give Us Your Feedback\".\n\n\
To submit feedback directly from your device tap the \"Email\" button below.";
    
    body.text = bodyText;
}

-(void) addEmailButton{
    ANNOUNCE
    CGRect frame = CGRectMake(emailButtonX, emailButtonY, emailButtonW, emailButtonH);
    emailButton = [RLButton buttonWithStyle:RLButtonStyleBlueRoundedRect
                                     target:self action:@selector(doEmail) frame:frame];
    emailButton.text = @"Email";
    [host addSubview:emailButton];
}

-(void) doEmail {
    ANNOUNCE
    if (!!! [MFMailComposeViewController canSendMail] ) {
        CCLOG(@"can't send mail.");
        
        UIAlertView *av = [[[UIAlertView alloc] initWithTitle:@"Can't Send Mail"
                                             message:@"It seems that mail is not set up on this device. You can give feedback at www.darkengame.com."
                                            delegate:self
                                   cancelButtonTitle:@"OK"
                                   otherButtonTitles:nil] autorelease];
        [av show];
        return;
    } else {
        CCLOG(@"can send mail.");
    
        MFMailComposeViewController *mvc = [[[MFMailComposeViewController alloc] init] autorelease];
        mvc.mailComposeDelegate = self;
        [mvc setSubject:@"My feedback"];
        [mvc setToRecipients:[NSArray arrayWithObject:@"feedback@darkengame.com"]];
        [mvc setMessageBody:@"Add your comments here." isHTML:NO];
        [X.rvcP presentModalViewController:mvc animated:YES];
    }
}

-(void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    CCLOG(@"Can't send mail alert closed.");
}

-(void) mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result 
                        error:(NSError *)error {
    NSString *mailComposeControllerResult;
    switch (result) {
        case MFMailComposeResultCancelled:
            CCLOG(@"mail compose result: cancelled");
            mailComposeControllerResult = @"cancelled";
            break;
        case MFMailComposeResultSaved:
            CCLOG(@"mail compose result: saved");
            mailComposeControllerResult = @"saved";
            break;
        case MFMailComposeResultSent:
            CCLOG(@"mail compose result: sent");
            mailComposeControllerResult = @"sent";
            break;
        case MFMailComposeResultFailed:
            CCLOG(@"mail compose result: failed");
            mailComposeControllerResult = @"failed";
            break;
        default:
            CCLOG(@"mail compose result: unexpected result");
            mailComposeControllerResult = @"other reason";
            break;
    }
    CCLOG(@"MFMail error: %@", error);
    [X.rvcP dismissModalViewControllerAnimated:YES];
    NSDictionary *d = [NSDictionary dictionaryWithObject:mailComposeControllerResult forKey:@"Result"];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Feedback" attributes:d];
}

-(void) addWebButton{
    ANNOUNCE
    CGRect frame = CGRectMake(webButtonX, webButtonY, webButtonW, webButtonH);
    webButton = [RLButton buttonWithStyle:RLButtonStyleBlueRoundedRect
                                     target:self action:@selector(doWeb) frame:frame];
    webButton.text = @"Web Site";
    [host addSubview:webButton];
}

-(void) doWeb {
    ANNOUNCE
}

-(void) addDoneButton {
    ANNOUNCE
    CGRect frame = CGRectMake(doneButtonX, doneButtonY, doneButtonW, doneButtonH);
    doneButton = [RLButton buttonWithStyle:RLButtonStyleBlueRoundedRect  
                                     target:self action:@selector(doDone) frame:frame];
    doneButton.text = @"Done";
    [host addSubview:doneButton];
}

-(void) doDone {
    ANNOUNCE
    CCArray *subviews = [CCArray arrayWithNSArray:[host subviews]];
    CCTransitionFade *tran = [CCTransitionFade transitionWithDuration:0.5f scene:[ SettingsScene scene ]];
    [[CCDirector sharedDirector] replaceScene:tran];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

@end
