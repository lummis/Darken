//
//  MessageManager.m
//  Darken
//
//  Created by Robert Lummis on 7/3/12.
//  Copyright (c) 2012 ElectricTurkey Software. All rights reserved.
//

#import "MessageManager.h"
#import "RLButton.h"
#import "RootViewController.h"
#import "DarkenAppDelegate.h"
#import "Board.h"

static MessageManager *sharedManager = nil;
static NSMutableDictionary *keyedMessages = nil;

@implementation MessageManager

-(void) dealloc {
    [messageView release];
    [super dealloc];
}

+(MessageManager *)sharedManager {
    @synchronized(self) {
        if (sharedManager == nil) {
            [[[self alloc] init] autorelease]; // assignment not done here - autorelease for static analyzer
        }
    }
    return sharedManager;	
}

+ (id)allocWithZone:(NSZone *)zone {
    @synchronized(self) {
        if (sharedManager == nil) {
        	sharedManager = [super allocWithZone:zone];
        	return sharedManager;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil	
}

-(id)init { //don't need to implement init unless we need to allocate something other than ivars
    ANNOUNCE
    if ( (self = [super init]) ) {
        
        keyedMessages = [[NSMutableDictionary dictionaryWithCapacity:1] retain];
        CGSize winSize = [[CCDirector sharedDirector] winSize];
        w = winSize.width;
        h = winSize.height;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;	
}

- (id)retain {
    return self;	
}

- (unsigned)retainCount {
    return UINT_MAX;  //denotes an object that cannot be released	
}

- (oneway void)release {    //without 'oneway' the compiler gives a warning
        //do nothing
}

- (id)autorelease {
    return self;	
}

-(void) setMessageWithTitle:(NSString *)title 
                       text:(NSString *)text 
                       type:(NSString *)type 
                        key:(NSString *)key
                      delay:(CGFloat)delay {
    ANNOUNCE
    if (text == nil || key == nil) {
        CCLOG(@"setMessageWithTitle... called with text == nil || key == nil");
        return;
    }
    
    if (type == nil) {
        type = @"ok";
    }
        //title and text copies are released in _showMessageWithTitle:type:text;
    NSMutableDictionary *message = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                             title, @"title",
                             text, @"text",
                             type, @"type",
                             [NSNumber numberWithFloat:delay], @"delay",
                             key, @"key",
                             nil];
    [keyedMessages setObject:message forKey:key];
    if ( [X.showMessageAgain objectForKey:key] == nil ) {
        [X.showMessageAgain setObject:@"YES" forKey:key];   // store YES if this key isn't already present
    }
}

-(void) showMessageWithKey:(NSString *)key atEndNotify:(id)target selector:(SEL)selector {
    ANNOUNCE
    if ( [keyedMessages objectForKey:key] == nil ) {
        CCLOG(@"showMessageWithKey:; no such key: %@", key);
        return;
    }
    callBackTarget = target;
    callBackSelector = selector;
    
    if ( [[X.showMessageAgain objectForKey:key] isEqualToString:@"YES"] ) {
        _key = key;
        NSDictionary *message = [keyedMessages objectForKey:key];
        [self _showMessageWithTitle:[message objectForKey:@"title"]
                               type:[message objectForKey:@"type"]
                               text:[message objectForKey:@"text"]];
    } else {
        if (X.nowInBoardScene) {
            [X.boardP makeReady];
            [[SimpleAudioEngine sharedEngine] playEffect:@"errorBuzz.wav"];
        }
        return;
    }
}

-(void) enqueueMessageWithText:(NSString *)text title:(NSString *)title delay:(CGFloat)delay onQueue:(CCArray *)queue {
    ANNOUNCE
        //don't permit duplicate messages on the same queue
    
    if ( [queue count] > 0 ) {
        for (int i = 0; i < [queue count]; i++) {
            NSDictionary *item = [queue objectAtIndex:i];
            if ( [[item valueForKey:@"text"] isEqualToString:text] && [[item valueForKey:@"title"] isEqualToString:title] ) {
                return; //don't enter dup
            }
        }
    }
    
     //tempText and tempTitle are released in _showMessageWithTitle:type:text:
    
    NSDictionary *msg = [NSDictionary dictionaryWithObjectsAndKeys:text, @"text",
                         title, @"title",
                         @"OK", @"type",
                         [NSNumber numberWithFloat:delay], @"delay",
                         nil, @"key",
                         nil];
    [queue insertObject:msg atIndex:0];
}

-(void) enqueueMessageWithKey:(NSString *)key onQueue:(CCArray *)queue {
    ANNOUNCE
        //skip dups
    if ( [queue count] > 0 ) {
        for (int i = 0; i < [queue count]; i++) {
            if ( [[[queue objectAtIndex:i] valueForKey:@"key"] isEqualToString:key] ) {
                return; //don't enter dup
            }
        }
    }
    NSDictionary *msg = [keyedMessages objectForKey:key];
    [queue insertObject:msg atIndex:0];
}

-(void) showQueuedMessages {
    ANNOUNCE
    if (X.messageQueueBeingShown == YES) {
        return;
    }
    CCArray *queue = nil;
    id sceneP = nil;
    if ( X.nowInBoardScene ) {
        queue = X.boardSceneMessageQueue;
        sceneP = X.boardP;
    } else if ( X.nowInChoiceScene ) {
        queue = X.choiceSceneMessageQueue;
        sceneP = X.choiceSceneP;
    }
    if ( [queue count] > 0 ) {
        X.messageQueueBeingShown = YES;
        callBackTarget = self;
        callBackSelector = @selector(showQueuedMessages);
        NSDictionary *msg = [[queue.lastObject copy] autorelease];  //the block below retains title, type, & text and releases them at end
        [queue removeLastObject];
        NSString *title = [msg objectForKey:@"title"];
        NSString *type = [msg objectForKey:@"type"];
        NSString *text = [msg objectForKey:@"text"];
        CGFloat messageDelay = [[msg objectForKey:@"delay"] floatValue];
        _key = [msg objectForKey:@"key"];
        CCLOG(@"_key, X.showMessageAgain: %@, %@", _key, X.showMessageAgain);
        
        if ( _key && [ [X.showMessageAgain objectForKey:_key] isEqualToString:@"NO" ] ) {
            CCLOG(@"going back to showQueuedMessages to show the next message");
            X.messageQueueBeingShown = NO;
            [self showQueuedMessages];    //show the next message
        } else {
            CCLOG(@"title: %@", title);
            CCLOG(@"type: %@", type);
            CCLOG(@"text: %@", text);
            CCSequence *seq = [CCSequence actions:
                              [CCDelayTime actionWithDuration:messageDelay],
                              [CCCallBlock actionWithBlock:
                                ^(void){
                                    [[MessageManager sharedManager] _showMessageWithTitle:title type:type text:text];
                                }], //next message will be shown because of callback in _removeMessage
                              nil];
            ANNOUNCE
            [sceneP runAction:seq];
        }
    } else {
        X.messageQueueBeingShown = NO;
    }
}

-(void) _checkboxTouched {
    ANNOUNCE
    leftButton.selected = leftButton.selected ? NO : YES;
}

-(void) _removeMessage:(id)sender {
    ANNOUNCE
    [UIAccelerometer sharedAccelerometer].delegate = savedAccelerometerDelegate;    //needs to be first
    [savedAccelerometerDelegate release];
    [[NSNotificationCenter defaultCenter] postNotification:
         [NSNotification notificationWithName:@"messageRemoved" object:self userInfo:nil]];
    [X.boardP makeReady];
    NSAssert( [(id)sender isKindOfClass:[UIButton class] ] , @"removeMessage; sender is wrong class");
    UIButton *b = (UIButton *)sender;
    if ( b.tag == dismissButton && leftButton.selected && _key ) {
        [X.showMessageAgain setObject:@"NO" forKey:_key];
    }

    CGFloat fadeOutTime = 0.4f;
    [UIView animateWithDuration:fadeOutTime animations:^{ 
        messageView.alpha = 0.0f; 
    } completion:^(BOOL finished){ 
        [messageView removeFromSuperview];
        X.messageQueueBeingShown = NO;
        X.messageIsShowing = NO;
        if (callBackTarget != nil) [callBackTarget performSelector:callBackSelector];
    }];
}

-(void) clearQueue:(CCArray *)queue {
    if ( [queue count] > 0 ) {
        [queue removeAllObjects];
    }
}

-(void) resetKeyedMessages {
    ANNOUNCE
    NSArray *keys = [keyedMessages allKeys];
    for (NSString *key in keys) {
        [X.showMessageAgain setObject:@"YES" forKey:key];
    }
}

-(void) _showMessageWithTitle:(NSString *)title type:(NSString *)type text:(NSString *)textString {
    ANNOUNCE
    NSString *errorMessage = [NSString stringWithFormat:@"_showMessageWithTitle::: called with invalid type: %@", type];
    NSAssert( [type isEqualToString:@"OK"] || [type isEqualToString:@"ok"]
                 || [type isEqualToString: @"checkbox"]
                 || [type isEqualToString: @"NO-YES"] || [type isEqualToString:@"no-yes"],
             errorMessage );
    X.messageIsShowing = YES;
    [X.boardP makeUnReady];
    savedAccelerometerDelegate = [[[UIAccelerometer sharedAccelerometer] delegate] retain];
        //delegate will be the instance of Board
    [UIAccelerometer sharedAccelerometer].delegate = nil;
    
    CGFloat frameW = 300.f; //these are the coordinates of messageView relative to the window
    CGFloat frameH = 250.f;
    CGFloat frameX = (w - frameW) / 2.f;
    CGFloat frameY = (h - frameH) / 2.f;
    
    CGRect messageFrame = CGRectMake(frameX, frameY, frameW, frameH);
    messageView = [[UIView alloc] initWithFrame:messageFrame];
//    messageView.backgroundColor = [UIColor colorWithRed:0.95f green:0.95f blue:1.0f alpha:1.0f];
    messageView.backgroundColor = [UIColor clearColor]; //had white background but white corners stuck out. Now white is in msgFrame.png
    messageView.clipsToBounds = NO; //this is the default
    
/*
    CGFloat borderThickness = 8.f;
    UIImage *hBorder = [UIImage imageNamed:@"brownFrameHorizontal.png"];
    UIImage *vBorder = [UIImage imageNamed:@"brownFrameVertical.png"];
    UIImageView *rightBorder = [[UIImageView alloc] initWithImage:vBorder];
    rightBorder.frame = CGRectMake(frameW - borderThickness, 0.f, borderThickness, frameH);
    [messageView addSubview:rightBorder];
    [rightBorder release];
    UIImageView *topBorder = [[UIImageView alloc] initWithImage:hBorder];
    topBorder.frame = CGRectMake(0.f, -1.f, frameW, borderThickness);    //-1 seems to correct an anomaly
    [messageView addSubview:topBorder];
    [topBorder release];
    UIImageView *bottomBorder = [[UIImageView alloc] initWithImage:hBorder];
    bottomBorder.frame = CGRectMake(0.f, frameH - borderThickness, frameW, borderThickness);
    [messageView addSubview:bottomBorder];
    [bottomBorder release];
    UIImageView *leftBorder = [[UIImageView alloc] initWithImage:vBorder];
    leftBorder.frame = CGRectMake(0.f, 0.f, borderThickness, frameH);
    [messageView addSubview:leftBorder];
    [leftBorder release];
*/
    
    UIImage *msgFrame = [UIImage imageNamed:@"msgFrame.png"];
    UIImageView *msgFrameView = [[UIImageView alloc] initWithImage:msgFrame];
    [messageView addSubview:msgFrameView];
    [msgFrameView release];
    
    UIView *glview = [CCDirector sharedDirector].openGLView;
    [glview addSubview:messageView];
    
    CGFloat margin = 15.f;
    CGFloat buttonSpaceHeight = 50.f;
    
	//title
    float titleHeight;
    if (title != nil) {
        titleHeight = 30.f;
        CGRect titleRect = CGRectMake(margin,
                                      margin,
                                      messageView.bounds.size.width - 2 * margin,
                                      titleHeight);
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleRect];
        titleLabel.backgroundColor = [UIColor clearColor];
        [messageView addSubview:titleLabel];
        [titleLabel release];
        titleLabel.font = [UIFont fontWithName:@"Thonburi-Bold" size:20];
        titleLabel.textColor = [UIColor darkGrayColor];
        titleLabel.textAlignment = UITextAlignmentCenter;
        titleLabel.numberOfLines = 1;
        titleLabel.shadowColor = [UIColor blackColor];
        titleLabel.text = title;
    } else {
        titleHeight = 0.f;
    }
    
	//text
    CGRect textLabelRect = CGRectMake(margin,
                                      margin + titleHeight,
                                      messageView.bounds.size.width - 2 * margin,
                                      messageView.bounds.size.height - buttonSpaceHeight - margin - titleHeight);
    UILabel *textLabel = [[UILabel alloc] initWithFrame:textLabelRect];
    textLabel.backgroundColor = [UIColor clearColor];
    [messageView addSubview:textLabel];
    [textLabel release];
    textLabel.font = [UIFont fontWithName:@"Optima-Regular" size:15];
    textLabel.textColor = [UIColor darkGrayColor];
    textLabel.textAlignment = UITextAlignmentCenter;
    textLabel.numberOfLines = 0;    //as many as are needed
    textLabel.shadowColor = [UIColor blackColor];
    textLabel.lineBreakMode = UILineBreakModeWordWrap;
    textLabel.text = textString;
    
	//button positions and sizes
    CGFloat rightButtonWidth = 70.f;
    CGFloat rightButtonHeight = 30.f;
    CGFloat rightButtonX = 0.85f * messageView.bounds.size.width - rightButtonWidth;
    
    CGFloat leftButtonLabelWidth = 100.f;
    CGFloat leftButtonLabelHeight = 20.f;
    CGFloat leftButtonLabelX = 0.05f * messageView.bounds.size.width;
    CGFloat leftButtonLabelY = messageView.bounds.size.height - 0.5f * (buttonSpaceHeight + leftButtonLabelHeight);
    CGFloat leftButtonWidth = 27.5f;    //keep width::height = 5/4
    CGFloat leftButtonHeight = 22.f;
    CGFloat leftButtonX = leftButtonLabelX + leftButtonLabelWidth + 5.f;
    
    CGFloat centerButtonWidth = 70.f;
    CGFloat centerButtonHeight = 30.f;
    
    if ( [type isEqualToString:@"checkbox"] ) {
        
		//checkbox (leftButton) when type == checkbox
        CGRect leftButtonFrame = CGRectMake( 
                                            leftButtonX, messageView.frame.size.height - 0.5f * (buttonSpaceHeight + leftButtonHeight),
                                            leftButtonWidth, leftButtonHeight);
        
        leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
        leftButton.frame = leftButtonFrame;
        [leftButton setImage:[UIImage imageNamed:@"checkboxUnchecked.png"] forState:UIControlStateNormal];
        [leftButton setImage:[UIImage imageNamed:@"checkboxChecked.png"] forState:UIControlStateSelected];
        leftButton.showsTouchWhenHighlighted = NO;
        [leftButton addTarget:self action:@selector(_checkboxTouched) forControlEvents:UIControlEventTouchUpInside];
        [messageView addSubview:leftButton];
		//        leftButton.userInteractionEnabled = YES;
        
		//"Don't show again" label when type == checkbox
        UILabel *leftButtonLabel = [[UILabel alloc] initWithFrame:CGRectMake(
                                                                             leftButtonLabelX, leftButtonLabelY, 
                                                                             leftButtonLabelWidth, leftButtonLabelHeight)];
        leftButtonLabel.backgroundColor = [UIColor clearColor];
        leftButtonLabel.text = @"Don't show again";
        leftButtonLabel.font = [UIFont systemFontOfSize:12];
        leftButtonLabel.lineBreakMode = UILineBreakModeWordWrap;
        leftButtonLabel.textAlignment = UITextAlignmentRight;
        leftButtonLabel.numberOfLines = 1;
        [messageView addSubview:leftButtonLabel];
        [leftButtonLabel release];
        
		//rightButton (when type == checkbox
        CGRect rightButtonFrame = CGRectMake( 
                                             rightButtonX,
                                             messageView.bounds.size.height - 0.5f * buttonSpaceHeight - 0.5f * rightButtonHeight,
                                             rightButtonWidth, rightButtonHeight);
        RLButton *rightButton = [RLButton buttonWithStyle:RLButtonStyleGray target:self
                                                   action:@selector(_removeMessage:) frame:rightButtonFrame];
        [rightButton setText:@"OK"];
        rightButton.showsTouchWhenHighlighted = NO;
        rightButton.tag = dismissButton;
        [messageView addSubview:rightButton];
        
    } else if ( [type isEqualToString:@"OK"] || [type isEqualToString:@"ok"] || [type isEqualToString:@"Ok"] ) {
		//centerButton
        CGRect centerButtonFrame = CGRectMake(
                                              0.5f * (messageView.bounds.size.width - centerButtonWidth),
                                              messageView.bounds.size.height - 0.5f * buttonSpaceHeight - 0.5f * centerButtonHeight,
                                              centerButtonWidth, centerButtonHeight);
        UIButton *centerButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        centerButton.frame = centerButtonFrame;
        [centerButton setTitle:@"OK" forState:UIControlStateNormal];
        centerButton.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        centerButton.showsTouchWhenHighlighted = NO;
        [messageView addSubview:centerButton];
        [centerButton addTarget:self action:@selector(_removeMessage:) forControlEvents:UIControlEventTouchUpInside];
        
    } else if ( [type isEqualToString:@"NO-YES"] || [type isEqualToString:@"no-yes"] ) {
        CCLOG(@"type: %@", type);
    } else {
        CCLOG(@"in showMessageWithTitle:type:text: invalid value for type: %@", type);
        kill( getpid(), SIGABRT );  //crash
    }
    
    messageView.alpha = 0.0f;
    CGFloat fadeInTime = 0.5f;
    [UIView animateWithDuration:fadeInTime 
                     animations:^(void){
                         messageView.alpha = 1.0f;
                     }];
//    [title release];    //title and textString were result of 'copy' in enqueueMesssage...
//    [textString release];
}

@end
