//
//  MessageManager.h
//  Darken
//
//  Created by Robert Lummis on 7/3/12.
//  Copyright (c) 2012 ElectricTurkey Software. All rights reserved.
//
//  MessageManager is a singleton

//#import "MessageViewController.h"

@interface MessageManager : UIView {
    
        //keyedMessages is a collection of message types with
        //fields: text, key, type, show (== @"YES" or @"NO") all NSStrings

    CGFloat w, h; //window width & height
    UIView *messageView;
    UIButton *leftButton;

    @private
        //underscore variables are unchanged between show... and remove...
//        NSString *_type;
//        NSString *_text;
//        NSString *_title;
        NSString *_key;
    id callBackTarget;
    SEL callBackSelector;
    id savedAccelerometerDelegate;
        
    enum buttonChoices {
        buttonMin,
        dismissButton,  //the right button used with type checkbox
        okButton,       //the center button used with type ok
        noButton,       //the NO used with type NO-YES
        yesButton,      //the YES used with type NO-YES
        buttonMax
    };
    
}

+(MessageManager *) sharedManager;
+(id)allocWithZone:(NSZone *)zone;

    //type "OK" means a single "OK" response button in the center
    //type "checkbox" means a check box for 'Don't show ...' and a "Dismiss" button
    //type "NO-YES" has "NO" and "YES" response buttons.

-(void) setMessageWithTitle:(NSString *)title 
                       text:(NSString *)text 
                       type:(NSString *)type 
                        key:(NSString *)key
                      delay:(CGFloat)delay;
-(void) showMessageWithKey:(NSString *)key atEndNotify:(id)target selector:(SEL)selector;
-(void) enqueueMessageWithText:(NSString *)text title:(NSString *)title delay:(CGFloat)delay onQueue:(CCArray *)queue;
-(void) enqueueMessageWithKey:(NSString *)key onQueue:(CCArray *)queue;
-(void) showQueuedMessages;
-(void) resetKeyedMessages;
-(void) _showMessageWithTitle:(NSString *)title type:(NSString *)type text:(NSString *)text;
-(void) _checkboxTouched;
-(void) _removeMessage:(id)sender;
-(void) clearQueue:(CCArray *)queue;
-(void) _showMessageWithTitle:(NSString *)title type:(NSString *)type text:(NSString *)textString;

@end
