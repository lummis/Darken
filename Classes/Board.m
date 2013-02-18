//
//  Board.m
//  Darken
//
//  Created by Robert Lummis on 5/22/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

#import "Board.h"
#import "Pip.h"
#import "Model.h"
#import "CCArray+Replace.h"
#import "DarkenAppDelegate.h"
#import "RootViewController.h"
#import "Explosion.h"
#import "RatingsScene.h"
#import "RLButton.h"
#import "MessageManager.h"
#import "ChoiceScene.h"
//#import "RLGameCenter.h"

CGFloat fvalue(float arg);

@implementation Board
@synthesize isReady;

+(id) boardScene{
	ANNOUNCE
	CCScene *scene = [CCScene node];
	Board *boardNode = [Board node];
	boardNode.isTouchEnabled = YES;
	[scene addChild:boardNode z:BOARDNODEZ];
	return scene;
}

-(void)dealloc {
    ANNOUNCE
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [sae release];    //it's a singleton so this doesn't do anything?
	[pips release];
    [currentSymbols release];
    [accelerometer release];    //it's a singleton so this doesn't do anything?
    [store release];
	[super dealloc];
}

-(void) onEnter {
    ANNOUNCE
    [super onEnter];
}

-(void) onEnterTransitionDidFinish {
    ANNOUNCE
    X.nowInBoardScene = YES;
    [super onEnterTransitionDidFinish];
    [[MessageManager sharedManager] showQueuedMessages];
}

-(void) onExit {
    ANNOUNCE
    X.nowInBoardScene = NO;
    [super onExit];
}

-(id) init {
    ANNOUNCE
    if( (self = [super init]) ) {
        X.boardP = self;
        
        X.playStartTime = [NSDate date];  //time at start of board scene
        
        h = [[CCDirector sharedDirector] winSize].height;
        w = [[CCDirector sharedDirector] winSize].width;
        
            //don't forget to removeTransactionObserver in dealloc (or elsewhere)
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];    //get transaction results
        if ( [[SKPaymentQueue defaultQueue].transactions count] > 0 ) {
            CCLOG(@"Board init; There are %d pending transactions in SKPaymentQueue", [[SKPaymentQueue defaultQueue].transactions count] );
            NSInteger n = 0;
            for ( SKPaymentTransaction *transaction in [SKPaymentQueue defaultQueue].transactions ) {
                n++;
                CCLOG(@"#%d  date: %@", n, transaction.transactionDate);
                CCLOG(@"#%d  identifier: %@", n, transaction.transactionIdentifier);
                CCLOG(@"#%d  state: %d", n, transaction.transactionState);
                CCLOG(@"\n");
            }
        } else {
            CCLOG(@"Board init; There are no transactions in SKPaymentQueue");
        }
        
        productDeliveryLocation = CGPointMake(w / 2, h / 2);
        
        X.preselectToken = YES;  // until some better plan can be found; NO is annoying
        showValidSquares = NO;
        newHighBannerWasShown = NO;
        
//        srandom(clock());
        
        if (X.tutorialsEnabled && X.level < 3) {
            X.starsSavedDuringTutorial = X.starsOnHand;
            X.starsOnHand = TUTORIALSTARS;
            X.bombsSavedDuringTutorial = X.bombsOnHand;
            X.bombsOnHand = TUTORIALBOMBS;
        }

        X.choiceCode = cInterrupted;    //if interrupted this will go into defaults
                                        //if completed, failed, or quit it will be overwritten
            //move the next statement to LoadBoardScene.m
//        [X.modelP setParameters];   //doesn't change parameters if set by developer
        [self setupBoard];
        
        waitLabel = [CCLabelTTF labelWithString:@"WAIT" fontName:@"Arial" fontSize:20];
        waitLabel.color = ccRED;
        waitLabel.position = ccp( 0.5f * leftSpace, 0.40f * [[CCDirector sharedDirector] winSize].height );
        waitLabel.opacity = 0;
        [self addChild:waitLabel];
        
        waitingForTouchAfterCompletion = NO;
        waitingForTutorial0Tap = NO;
        
        sae = [SimpleAudioEngine sharedEngine]; //moved here from initWithCommonData for debugging
        [sae retain];
        [sae preloadEffect:@"placePipChirp2.wav"];
        [sae preloadEffect:@"undo.wav"];
        [sae preloadEffect:@"errorBuzz.wav"];
        [sae preloadEffect:@"movesquare.aiff"];
        [sae preloadEffect:@"clapping11025.wav"];
        [sae preloadEffect:@"completion.aiff"];
        [sae setEffectsVolume:[X.modelP gainForLoudnessNumber:X.loudnessNumber]];

        completionSoundPlayed = NO;
        X.messageIsShowing = NO;
        X.messageQueueBeingShown = NO;
        
            //to detect shaking
            // http://stackoverflow.com/questions/12862983/
        accelerometer = [[UIAccelerometer sharedAccelerometer] retain];
        accelerometer.delegate = self;
        accelerometer.updateInterval = 5.0f / 60.0f;
        effectCount = 0;    //used in descendingPing:
        
        emptyBoardBonusInProgress = NO;
        undoShouldIncreaseShredderNumber = NO;
        
        store = [[Store alloc] init];   //release in dealloc
        
        if ( X.tutorialsEnabled && X.level == 1 ) {
            squaresOn = NO;
            shredderOn = NO;
            [self setShake:NO];
            moveSourceMarkerOn = NO;
            waitingForSimulatorShake = NO;
            starsOn = NO;
            bombsOn = NO;
            
            [self _doTutorial0];    //when tutorial0 is finished it starts tutorial1 and so on
  
        } else if ( X.tutorialsEnabled && X.level == 2 ) {
            squaresOn = YES;
            shredderOn = NO;
            [self setShake:NO];
            moveSourceMarkerOn = NO;
            starsOn = YES;
            bombsOn = YES;
            viewPurchaseMenuOn = NO;
            [self tutorial20a:[NSNotification notificationWithName:nil object:nil]];
        
        } else {
//            X.tutorialsEnabled = NO;
            squaresOn = YES;
            shredderOn = YES;
            [self setShake:YES];
            moveSourceMarkerOn = YES;
            starsOn = YES;
            bombsOn = YES;
            viewPurchaseMenuOn = YES;
            
        }
        
        CCLOG(@"Board; end of init");
    }
    return self;
}

-(id) setupBoard {  //previously called initWithCommonData but starting it with 'init...' triggered diagnostics
	ANNOUNCE
    
//    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
    
    boardLayerColor = [CCLayerColor layerWithColor:BACKGROUNDCOLOR];
    [self addChild:boardLayerColor z:BACKGROUNDZ];
    
    boardWidth = X.nColumns * CELLWIDTH + SIDEFRAMEWIDTH * 2 + DIVIDERWIDTH * (X.nColumns - 1);
    boardHeight = X.nRows * CELLWIDTH + BOTTOMFRAMEWIDTH + TOPFRAMEWIDTH + DIVIDERWIDTH * (X.nRows - 1);
    
    leftSpace = floorf( 0.5 * (w - boardWidth) );	//left of screen to left edge of board
    rightSpace = w - leftSpace - boardWidth;
    bottomSpace = floorf( 0.5 * (h - boardHeight) );	//bottom of screen to bottom border
    
    pips = [[CCArray alloc] initWithCapacity:(X.nRows * X.nColumns + 10)];	//allow for wait & hold pips
    
    shredderBottomLayer = [CCSprite spriteWithFile:@"shredderBottomLayer.png"];
    shredderBottomLayer.position = ccp(0.5f * leftSpace, 0.05 * h);
    shredderBottomLayer.scale = 0.80f;
    shredderBottomLayer.anchorPoint = ccp(0.5f, 0.0f);
    [self addChild:shredderBottomLayer];
    
    shredderTopLayer = [CCSprite spriteWithFile:@"shredderTopLayer.png"];
    shredderTopLayer.position = ccp(0.5f * leftSpace, 0.05 * h);
    shredderTopLayer.scale = 0.80f;
    shredderTopLayer.anchorPoint = ccp(0.5f, 0.0f);
    
    shredderFeetHeight = 5.f;
    shredderSlot =          ccp(shredderTopLayer.position.x, shredderTopLayer.position.y + 42.f + shredderFeetHeight);
    shredderInnerTop =      ccp(shredderTopLayer.position.x, shredderTopLayer.position.y + 35.f + shredderFeetHeight);
    shredderInnerBottom =   ccp(shredderTopLayer.position.x, shredderTopLayer.position.y + 3.f + shredderFeetHeight);
    shredderCenter =        ccp(shredderTopLayer.position.x, shredderTopLayer.position.y + 0.5 * shredderTopLayer.boundingBox.size.height + shredderFeetHeight);
    shredderNumber = 0; //how full it is currently
    shredderCapacity = 3;   //max full
    [self addChild:shredderTopLayer z:PIPZ + 1];
    
    shredderTargetMarker = [CCSprite spriteWithFile:@"roundTarget.png"];
    shredderTargetMarker.position = shredderCenter;
    [self addChild:shredderTargetMarker z:PIPZ + 2];
    [shredderTargetMarker setOpacity:0];
    
    shredderFullLabel = [CCLabelTTF labelWithString:@"FULL!"
                                                       fontName:@"Marker Felt" 
                                                       fontSize:22];
    shredderFullLabel.opacity = 0.f;
    shredderFullLabel.position = ccp(shredderSlot.x, shredderSlot.y + 20.f);
    shredderFullLabel.color = ccRED;
    [self addChild:shredderFullLabel];
    
        //chips is the pile of shreddings that show "inside" the shredder
    chipsScaleX = 0.68f;    //we need this as an ivar so it can be used in inc., dec., and empty
    chips = [CCSprite spriteWithFile:@"chips.png"];
    chips.anchorPoint = ccp(0.5f, 0.0f);
    chips.scaleX = chipsScaleX;
    chips.scaleY = 0.0f;
        //add 1 by trial-&-error to make the chips fit inside the case accurately
    chips.position = ccp(shredderInnerBottom.x + 1, shredderInnerBottom.y);
    chips.opacity = 255.f;
    [self addChild:chips z:5];
    
    lightOn = [CCSprite spriteWithFile:@"lightOn.png"];
    lightOn.anchorPoint = ccp(0.5f, 0.5f);
    lightOn.position = ccp(shredderSlot.x + 12.f, shredderSlot.y - 4.f);
    [self addChild:lightOn z:PIPZ + 2];    //higher than shredderTopLayer z
    lightOn.opacity = 0;
    
    lightOff = [CCSprite spriteWithFile:@"lightOff.png"];
    lightOff.anchorPoint = ccp(0.5f, 0.5f);
    lightOff.position = ccp(shredderSlot.x + 12.f, shredderSlot.y - 4.f);
    [self addChild:lightOff z:PIPZ + 2];    //higher than shredderTopLayer z
    lightOff.opacity = 255;
    
    shreddingDuration = 1.0f;
    
    CGSize labelSize = CGSizeMake(250.f, 35.f);
    CGPoint labelPosition = CGPointMake( 0.5f * w, 0.70f * h );
    emptyBoardBonusLabel = [CCLabelTTF labelWithString:@"Empty Grid Bonus"
                                                       dimensions:labelSize
                                                        alignment:CCTextAlignmentCenter
                                                         fontName:@"ChalkboardSE-Regular"
                                                         fontSize:28.f];
    emptyBoardBonusLabel.position = labelPosition;
    emptyBoardBonusLabel.color = ccc3(0, 170, 0);
    
    bonusLabelBackground = [CCLayerColor layerWithColor:ccc4(255, 255, 255, 235)
                                                           width:labelSize.width
                                                          height:0.8f * labelSize.height];
    bonusLabelBackground.position = CGPointMake(labelPosition.x - 0.5f * labelSize.width, 
                                           labelPosition.y - 0.5f * labelSize.height);
    
    bonusLabelBackground.visible = NO;
    emptyBoardBonusLabel.visible = NO;
    [self addChild:bonusLabelBackground z:7];
    [self addChild:emptyBoardBonusLabel z:8];
    
        //analyze:Instance variable used while 'self' is not set to the result of '[(super or self) init...]'
    undoButton = [CCMenuItemImage 
                  itemFromNormalImage:@"undoEnabled.png"
                  selectedImage:@"undoEnabled.png"
                  disabledImage:@"undoDisabled.png"
                  target:self
                  selector:@selector(undoAction)];
    CGFloat rightSpaceWith9Columns = 62.0f;
    undoButton.scale = 0.95f * rightSpaceWith9Columns / undoButton.contentSize.width;
    undoButton.isEnabled = NO;
    CCMenu *undoMenu = [CCMenu menuWithItems: undoButton, nil];
    [undoMenu alignItemsVertically];
    undoMenu.position = ccp( w - 0.5f * rightSpace, shredderCenter.y);
    [self addChild:undoMenu];
    
    pipSize.width = PIPSIZE;
    pipSize.height = PIPSIZE;
    
    [self setupGrid];
    
    waitingPipSize.width = PIPSIZE;
    waitingPipSize.height = PIPSIZE;
    float waitingSpacing = waitingPipSize.height * 0.60f;	//vertical spacing between waiting pips
    float waitingX = 0.5 * leftSpace;
    wait4.location = ccp(waitingX, h + waitingPipSize.height * 0.5 + 20.);	//just above the screen
    wait3.location = ccp(waitingX, h - 14 - waitingPipSize.height * 0.5);
    wait2.location = ccp(waitingX, wait3.location.y - waitingSpacing - waitingPipSize.height);
    wait1.location = ccp(waitingX, wait2.location.y - waitingSpacing - waitingPipSize.height);
    
    wait1.thePip = nil;
    wait2.thePip = nil;
    wait3.thePip = nil;
    wait4.thePip = nil;
    
        //choose nShapes for this play out of NDEFINEDSYMBOLS shapes
    CCArray *allSymbols = [CCArray arrayWithCapacity:NDEFINEDSYMBOLS];
    for (int i = 0; i < NDEFINEDSYMBOLS; i++) {
        [allSymbols addObject:[NSNumber numberWithInteger:i]];
    }
    currentSymbols = [CCArray arrayWithCapacity:X.nShapes];
    [currentSymbols retain];
    for (int i = 0; i < X.nShapes; i++) {
        int k = arc4random() % [allSymbols count];
        [currentSymbols addObject:[allSymbols objectAtIndex:k]];
        [allSymbols removeObjectAtIndex:k];
    }
    NSAssert([allSymbols count] == NDEFINEDSYMBOLS - X.nShapes, @"allSymbols count wrong");
    NSAssert([currentSymbols count] == X.nShapes, @"currentSymbols count wrong");
    CCLOG(@"currentSymbols: %@", currentSymbols);
    
    float labelOffset = 22.f;   //used for bomb and star
    bombLocation = ccp( w - 0.5f * rightSpace, 0.38 * h );
    bombQuantityLabel = [CCLabelTTF labelWithString: [NSString stringWithFormat:@"%d", X.bombsOnHand]
                                           fontName:@"Arial" fontSize:12];
    bombQuantityLabel.color = ccBLACK;
    bombQuantityLabel.position = ccp(bombLocation.x, bombLocation.y - labelOffset);
    [self addChild:bombQuantityLabel];
    bombPip = [self makePipAt:bombLocation
                  colorNumber:NOCOLOR
                  shapeNumber:X.bombsOnHand > 0 ? BOMBNUMBER : BOMBCROSSEDOUTNUMBER];   //90: no added color
    [self showBomb:X.showBomb];
    
    starLocation = ccp( bombLocation.x, bombLocation.y + 78.f );
    
    starQuantityLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", X.starsOnHand] fontName:@"Arial" fontSize:12];
    starQuantityLabel.color = ccBLACK;
    starQuantityLabel.position = ccp(starLocation.x, starLocation.y - labelOffset);
    [self addChild:starQuantityLabel];
    
    starPip = [self makePipAt:starLocation
                  colorNumber:STARCOLORNUMBER   //very light gray
                  shapeNumber:X.starsOnHand > 0 ? BOUGHTSTARNUMBER : BOUGHTSTARCROSSEDOUTNUMBER];

    X.starCost = 5; //initial cost; maybe it should be 0
    starCostLabel = [CCLabelTTF 
                     labelWithString:[NSString stringWithFormat:@"-%d\npoints", X.starCost]
                     dimensions:CGSizeMake(rightSpace, 40)
                     alignment:UITextAlignmentCenter
                     fontName:@"Arial" 
                     fontSize:12];
    starCostLabel.color = ccBLACK;
    starCostLabel.position = ccp(starLocation.x, starLocation.y + labelOffset);
    [self addChild:starCostLabel];
    
    [self showStar:X.showStar]; //shows or hides depending on model star value
    
        //score label
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    [formatter setPositiveFormat:@"#,##0"];
    scoreLabel = [CCLabelTTF labelWithString:
                  [formatter stringFromNumber:[NSNumber numberWithInteger:X.score]]
                 fontName:@"Arial" 
                 fontSize:16];

    scoreLabel.color = ccBLACK;
    CGSize scoreSize = scoreLabel.contentSize;
    scoreLayer = [CCLayerColor layerWithColor:BACKGROUNDCOLOR 
                                        width:43                  //43 = rightSpace with 10 columns
                                       height:scoreSize.height];
    scoreLayer.position = ccp(w - rightSpace, 0.92 * h);
    [self addChild:scoreLayer];
    scoreLabel.position = ccp(rightSpace / 2, scoreSize.height / 2 );
    [scoreLayer addChild:scoreLabel z:SCORELABELZ];
    
        //high score label
    highScoreLabel = [CCLabelTTF labelWithString:[@"Hi: " stringByAppendingString:
                      [formatter stringFromNumber:[X.bestScores objectAtIndex:(X.level - 1)]]]
                        fontName:@"Arial" 
                        fontSize:10];
    [formatter release];
    highScoreLabel.position = ccp(w - rightSpace / 2, 0.90 * h);
    highScoreLabel.color = ccBLACK;
        //highScoreLabel.opacity = highScore > 0 ? 255 : 0;
    if ( !!!X.tutorialsEnabled || X.level >= 3 ) {
        [self addChild:highScoreLabel];
    }

//    marker = [CCSprite spriteWithFile:@"square81x81.png"];
//    marker.scale = (PIPSIZE * 1.2) / marker.contentSize.width;
    marker = [CCSprite spriteWithFile:@"square40x40.png"];  //no scaling needed
    marker.color = ccBLACK;
    [self addChild:marker];
    
//    starMarker = [CCSprite spriteWithFile:@"starMarker100x200.png"];
//    starMarker.scale = 0.4;     //empirical
    starMarker = [CCSprite spriteWithFile:@"starMarker45x83.png"];
    starMarker.position = CGPointMake(starLocation.x + fvalue(1.f), starLocation.y);
    starMarker.opacity = 0.f;
    starMarker.anchorPoint = CGPointMake(0.5f, 0.425f); //empirical
    [self addChild:starMarker];
    
//    bombMarker = [CCSprite spriteWithFile:@"bombMarker80x128.png"];
//    bombMarker.scale = 0.4f;    //empirical
    bombMarker = [CCSprite spriteWithFile:@"bombMarker35x51.png"];
    bombMarker.position = bombLocation;
    bombMarker.opacity = 0.f;
    bombMarker.anchorPoint = CGPointMake(0.5f, 0.6f); //empirical
    [self addChild:bombMarker];
    
    activeSpot = none;
    cameFromSpot = none;
    activePip = nil;
    if (showValidSquares) [self showValidSquaresForPip:activePip];
    lastSquareCovered = -1;
    lastPipMoved = nil;
    [self makeReady];
    [self feedPip];
    if (X.preselectToken) {
        activePip = wait1.thePip;
        if (showValidSquares) [self showValidSquaresForPip:activePip];
        activeSpot = w1;
        marker.position = wait1.location;
    }
	return self;
}

-(void) setupGrid {
		//squares array holds a struct cell for each square on the grid
		//each struct cell holds information about one square
		//a struct cell doesn't display anything it just holds info. about what
		//pip is on itself and which 4 cells are around itself
    
	for (int i = 0; i < X.nRows * X.nColumns; i++) {	//cell 0 is the top left. It has a high y coord. & low x coord.
		square[i].location.x = leftSpace + SIDEFRAMEWIDTH + CELLWIDTH * 0.5 + CELLSPACING * (i % X.nColumns);
		int row = (X.nRows * X.nColumns - 1 - i) / X.nColumns;
		square[i].location.y = bottomSpace + BOTTOMFRAMEWIDTH + CELLWIDTH * 0.5 + CELLSPACING * row;
        
	}
	
		//set left, right, up, down entries in each square
	for (int i = 0; i < X.nRows * X.nColumns; i++) {
		square[i].darkness = 0;	//all cells start light
		
		int row = i / X.nColumns;	//row number starting at 0
		int col = i - row * X.nColumns;	//column number starting at 0
		if (row == 0) {
			square[i].up = EDGE;
		} else {
			square[i].up = i - X.nColumns;
		}
		if (row == (X.nRows - 1)) {
			square[i].down = EDGE;
		} else {
			square[i].down = i + X.nColumns;
		}
		if (col == 0) {
			square[i].left = EDGE;
		} else {
			square[i].left = i - 1;
		}
		if (col == (X.nColumns -1)) {
			square[i].right = EDGE;
		} else
		{
			square[i].right = i + 1;
		}
		square[i].thePip = nil;	//all squares initially empty
        square[i].pipColor = -1;
        square[i].pipShape = -1;
	}
	
//    CGFloat manual1 = 1.0f;    //trial and error position adjustments on frame pieces
//    CGFloat manual1_5 = 1.5;

	CCSprite *frameTop = [CCSprite spriteWithFile:@"top.png"];
    frameTop.position = ccp(leftSpace + boardWidth / 2, square[0].location.y + CELLWIDTH / 2 + TOPFRAMEWIDTH / 2);
	[self addChild:frameTop z:FRAMETOPANDBOTTOMZ];
	
	CCSprite *frameBottom = [CCSprite spriteWithFile:@"bottom.png"];
	frameBottom.position = ccp(leftSpace +	boardWidth / 2, square[X.nRows * X.nColumns -1].location.y - CELLWIDTH / 2 - BOTTOMFRAMEWIDTH / 2);
	[self addChild:frameBottom z:FRAMETOPANDBOTTOMZ];
	
	CCSprite *frameLeft = [CCSprite spriteWithFile:@"left.png"];
	frameLeft.position = ccp(leftSpace + SIDEFRAMEWIDTH / 2 + fvalue(1.5f), ( frameTop.position.y + frameBottom.position.y) / 2 );
	[self addChild:frameLeft z:FRAMELEFTANDRIGHTZ];
	
	CCSprite *frameRight = [CCSprite spriteWithFile:@"right.png"];
	frameRight.position = ccp(leftSpace + SIDEFRAMEWIDTH * 1.5 + (X.nColumns - 1) * CELLSPACING + CELLWIDTH, ( frameTop.position.y + frameBottom.position.y) / 2 );
	[self addChild:frameRight z:FRAMELEFTANDRIGHTZ];
    
        //corners
    CCSprite *frameUL = [CCSprite spriteWithFile:@"ul.png"];
    CCSprite *frameUR = [CCSprite spriteWithFile:@"ur.png"];
    CCSprite *frameLL = [CCSprite spriteWithFile:@"ll.png"];
    CCSprite *frameLR = [CCSprite spriteWithFile:@"lr.png"];
    
    frameUL.anchorPoint = ccp(0.0, 1.0);
    frameUL.position = ccp(leftSpace + fvalue(1.f), (frameTop.position.y + frameTop.contentSize.height / 2) );
    [self addChild:frameUL z:FRAMETOPANDBOTTOMZ];
    
    frameUR.anchorPoint = ccp(1.0, 1.0);
    frameUR.position = ccp(w - rightSpace, frameUL.position.y);
    [self addChild:frameUR z:FRAMETOPANDBOTTOMZ];
    
    frameLL.anchorPoint = ccp(0.0, 0.0);
    frameLL.position = ccp(leftSpace + fvalue(1.f), frameBottom.position.y - frameBottom.contentSize.height / 2);
    [self addChild:frameLL z:FRAMETOPANDBOTTOMZ];
    
    frameLR.anchorPoint = ccp(1.0, 0.0);
    frameLR.position = ccp(w - rightSpace, frameLL.position.y);
    [self addChild:frameLR z:FRAMETOPANDBOTTOMZ];
    
        //scale straight pieces to just meet the corners
    frameTop.scaleX = (boardWidth - frameUL.contentSize.width - frameUR.contentSize.width) / frameTop.contentSize.width;
    frameBottom.scaleX = (boardWidth - frameLL.contentSize.width - frameLR.contentSize.width) / frameBottom.contentSize.width;
    frameLeft.scaleY = (boardHeight - frameUL.contentSize.height - frameUR.contentSize.height) / frameLeft.contentSize.height;
    frameRight.scaleY = (boardHeight - frameUR.contentSize.height - frameLR.contentSize.height) / frameRight.contentSize.height;
	
	//horizontal dividers  row 0 is the top row
	for ( int i = 0; i < X.nRows - 1; i++ ) {
		CCSprite *divider = [CCSprite spriteWithFile:@"hor10.png"];
		divider.position = ccp(frameTop.position.x + fvalue(1.f), square[i * X.nColumns].location.y - CELLSPACING / 2 );
		[self addChild:divider z:FRAMEDIVIDERZ];
        divider.scaleX = 0.99f * (boardWidth / divider.contentSize.width);  //0.99 from trial and error
        CCLOG(@"divider.contentSize.width: %f", divider.contentSize.width);
	}
	
	//vertical dividers
	for ( int i = 0; i < X.nColumns - 1; i++ ) {
		CCSprite *divider = [CCSprite spriteWithFile:@"vert8.png"];
		divider.position = ccp(square[i].location.x + CELLSPACING / 2, ( frameTop.position.y + frameBottom.position.y) / 2 );
		[self addChild:divider z:FRAMEDIVIDERZ];
        divider.scaleY = (boardHeight - frameTop.contentSize.height) / divider.contentSize.height;
        CCLOG(@"divider.contentSize.height: %f", divider.contentSize.height);
	}
    
        //darknessLayer and darkLabel on each square
	ccColor4B darknessColor = ccc4(255, 255, 255, 255);
    float darkLayerWidth = CELLSPACING - DIVIDERWIDTH;
    float darkLayerHeight = CELLSPACING - DIVIDERWIDTH;
	for (int i = 0; i < (X.nRows * X.nColumns); i++) {
        
            //darknessLayer (starts white)
		CCLayerColor *darkLayer = [CCLayerColor layerWithColor:darknessColor width:darkLayerWidth height:darkLayerHeight];
        CGPoint layerCoords = 
            ccp(square[i].location.x - 0.5 * CELLSPACING + 0.5 * DIVIDERWIDTH, 
                square[i].location.y - 0.5 * CELLSPACING + 0.5 * DIVIDERWIDTH);
		darkLayer.position = layerCoords;
		[self addChild:darkLayer z:DARKNESSLAYERZ];
        square[i].theDarkLayer = darkLayer;

            //darkLabel added as child of the darknessLayer so it flips with it
        CCLabelBMFont *darkLabel = [CCLabelBMFont labelWithString:@"0" fntFile:@"calibri_35.fnt"];
        darkLabel.position = ccp(darkLayerWidth/2, darkLayerHeight/2);
        darkLabel.color = ccWHITE;
        darkLabel.opacity = 0;  //use 255 for testing
        [darkLayer addChild:darkLabel];
        square[i].theDarkLayer = darkLayer;
        square[i].theDarknessLabel = darkLabel;
        
            //used in tutorial
        CCSprite *targetMarker = [CCSprite spriteWithFile:@"roundTarget.png"];
        targetMarker.position = square[i].location;
        square[i].theTargetMarker = targetMarker;
        [self addChild:targetMarker z:4];
        [targetMarker setOpacity:0];
	}
//    CCLOG(@"square[0].location: %f,%f", square[0].location.x, square[0].location.y);
//    CCLOG(@"0.5 * CELLWIDTH: %f", 0.5 * CELLWIDTH);
//    CCLOG(@"frameTop.position: %f,%f", frameTop.position.x, frameTop.position.y);
//    CCLOG(@"frameTop.contentSize.height: %f", frameTop.contentSize.height);
//    CCLOG(@"frameTop.contentSize.width: %f", frameTop.contentSize.width);
//    CCLOG(@"frameTop.anchorpoint: %f,%f", frameTop.anchorPoint.x, frameTop.anchorPoint.y);
//    CCLOG(@"square[0].location.y + 0.5 * CELLWIDTH + 0.5 * frameTop.contentSize.height: %f",
//          square[0].location.y + 0.5 * CELLWIDTH + 0.5 * frameTop.contentSize.height);
//    
//    CCLOG(@"boardWidth, boardHeight: %f, %f", boardWidth, boardHeight);
//    CCLOG(@"leftSpace, rightSpace: %f, %f", leftSpace, rightSpace);
}

-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	ANNOUNCE
    
    if (waitingForSimulatorShake) {
        [X.boardSceneMessageQueue removeAllObjects];
        if (X.tutorialsEnabled && X.level == 1) {
                //assume we are doing tutorial5
            [[NSNotificationCenter defaultCenter] postNotificationName:@"didShakeDevice" object:self];
        }
        [X.modelP endByShaking];
        return; //safety only
    }
    
    if (X.messageIsShowing || X.messageQueueBeingShown) {   //don't respond
        return;
    }
    
    if (waitingForTutorial0Tap) {
        waitingForTutorial0Tap = NO;
        [self _doTutorial1];
        return; //we never get here ???
    }
    
    if (!!! self.isReady || levelIsFinished) {
		CCLOG(@"screen touched when not ready or after level is finished");
        [self flashWait];
		return;
    }
    
    [self makeUnReady];
    
    UITouch *touch = [touches anyObject];
    CGPoint touchLocation = [touch locationInView:[touch view]];
    CGPoint glTouchLocation = [[CCDirector sharedDirector] convertToGL:touchLocation];
    float x = glTouchLocation.x;
    float y = glTouchLocation.y;
    float tolerance = 0.5 * CELLSPACING;
    BOOL touchFound = NO;
    
        //was the touch on a square on the grid?
    touchedSquareIdx = -1;	//-1 means no valid square was touched
    for (int i = 0; i < (X.nRows * X.nColumns); i++) {
        if ( (fabs(square[i].location.x - x) < tolerance) &&
            (fabs(square[i].location.y - y) < tolerance) ) {
            touchedSquareIdx = i;
            touchFound = YES;
            if ( squaresOn == NO ) {
                [self makeReady];
                return;
            }
            break;
        }
    }

         //don't do anything if user tries to put a star or bomb on a square when none remain
    if ( touchFound && touchedSquareIdx > -1 && ((activePip == starPip && X.starsOnHand == 0) || (activePip == bombPip && X.bombsOnHand == 0)) ) {
        [self makeReady];
        return;
    }

    if (touchedSquareIdx > -1) {
        if ( activePip ) {
            if ( [self pip:activePip isOkOnSquare:touchedSquareIdx] ) {
                [self placePipOnSquare:touchedSquareIdx];   //does makeReady
            } else {
                [sae playEffect:@"errorBuzz.wav"];
                [[MessageManager sharedManager] showMessageWithKey:@"buzzing" atEndNotify:nil selector:nil];
                [self makeReady];
            }
        }
    }
    
        //was the touch on the shredder?
        //make tolerance bigger because shredder is bigger
    if(!!!touchFound) {
        tolerance = MIN( leftSpace, shredderBottomLayer.boundingBox.size.height );
        CGPoint loc = shredderCenter;
        
        if ( activePip ) {
            if (fabs(loc.x - x) < tolerance && fabs(loc.y - y) < tolerance) {
                if ( shredderOn == NO ) {
                    [self makeReady];
                    return;
                }
                if (activePip.shapeID < 90) {   //don't shred bomb, dropped star, or bought star
                    [self moveToShredder]; //calls feedPip, makeReady
                    touchFound = YES;
                } else {
                    [sae playEffect:@"errorBuzz.wav"];
                }
            }
        }
    }
    
        //reduce tolerance again
        //was the touch on wait1?
    tolerance = marker.boundingBox.size.width;
    if (!!!touchFound) {
        CGPoint loc = wait1.location;
        if (fabs(loc.x - x) < tolerance && fabs(loc.y - y) < tolerance) {
            if (moveSourceMarkerOn == YES) {
                activePip = wait1.thePip;
                if (showValidSquares) [self showValidSquaresForPip:activePip];
                marker.position = wait1.location;
                marker.opacity = 255.f;
                starMarker.opacity = 0.f;
                bombMarker.opacity = 0.f;
                marker.scale = (PIPSIZE * 1.2) / marker.contentSize.width;
                [sae playEffect:@"movesquare.aiff"];
                activeSpot = w1;
            }
            touchFound = YES;
            [self makeReady];
        }
    }
    
        //was the touch on wait2?
    if (!!!touchFound) {
        CGPoint loc = wait2.location;
        if (fabs(loc.x - x) < tolerance && fabs(loc.y - y) < tolerance) {
            if (moveSourceMarkerOn == YES) {
                activePip = wait2.thePip;
                if (showValidSquares) [self showValidSquaresForPip:activePip];
                marker.position = wait2.location;
                marker.opacity = 255.f;
                starMarker.opacity = 0.f;
                bombMarker.opacity = 0.f;
                marker.scale = (PIPSIZE * 1.2) / marker.contentSize.width;
                [sae playEffect:@"movesquare.aiff"];
                activeSpot = w2;
                if ( X.tutorialsEnabled && X.level == 1 ) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"activePipChanged" object:self];
                }
            }
            touchFound = YES;
            [self makeReady];
        }
    }
    
        //was the touch on wait3?
    if (!!!touchFound) {
        CGPoint loc = wait3.location;
        if (fabs(loc.x - x) < tolerance && fabs(loc.y - y) < tolerance) {
            if (moveSourceMarkerOn == YES) {
                activePip = wait3.thePip;
                if (showValidSquares) [self showValidSquaresForPip:activePip];
                marker.position = wait3.location;
                marker.opacity = 255.f;
                starMarker.opacity = 0.f;
                bombMarker.opacity = 0.f;
                marker.scale = (PIPSIZE * 1.2) / marker.contentSize.width;
                [sae playEffect:@"movesquare.aiff"];
                activeSpot = w3;
                if ( X.tutorialsEnabled && X.level == 1 ) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"activePipChanged" object:self];
                }
            }
            touchFound = YES;
            [self makeReady];
        }
    }
    
        //was the touch on starLocation?
    if (!!!touchFound && X.showStar) {
        CGPoint loc = starLocation;
        if (fabs(loc.x - x) < tolerance && fabs(loc.y - y) < tolerance) {
            if (activeSpot == star && viewPurchaseMenuOn) {   //2nd tap on star (not necessarily double tap)
                [store purchaseStar];
                activeSpot = w1;
                activePip = wait1.thePip;
                if (showValidSquares) [self showValidSquaresForPip:activePip];
                marker.position = wait1.location;
                marker.opacity = 255.f;
                starMarker.opacity = 0.f;
                bombMarker.opacity = 0.f;
            } else {
                activeSpot = star;
                activePip = starPip;    //starPip refers to pip on star pile, not dropped star
                if (showValidSquares) [self showValidSquaresForPip:activePip];
                marker.opacity = 0.f;
                starMarker.opacity = 255.f;
                bombMarker.opacity = 0.f;
                [sae playEffect:@"movesquare.aiff"];
            }
            touchFound = YES;
            [self makeReady];
        }
    }
    
        //was the touch on bombLocation?
    if (!!!touchFound && X.showBomb) {
        CGPoint loc = bombLocation;
        if (fabs(loc.x - x) < tolerance && fabs(loc.y - y) < tolerance) {
            if (activeSpot == bomb && viewPurchaseMenuOn) {
                [store purchaseBomb];
                activeSpot = w1;
                activePip = wait1.thePip;
                if (showValidSquares) [self showValidSquaresForPip:activePip];
                marker.position = wait1.location;
                marker.opacity = 255.f;
                starMarker.opacity = 0.f;
                bombMarker.opacity = 0.f;
            } else {
                activeSpot = bomb;
                activePip = bombPip;
                if (showValidSquares) [self showValidSquaresForPip:activePip];
                marker.opacity = 0.f;
                starMarker.opacity = 0.f;
                bombMarker.opacity = 255.f;
                [sae playEffect:@"movesquare.aiff"];
            }
            touchFound = YES;
            [self makeReady];
        }
    }
    
    if(!!!touchFound) {
        [self signalBackgroundTouch];
        [self makeReady];
    }
}

-(BOOL) pip:(Pip *)pip isOkOnSquare:(int)squareID {
    
    if (pip == nil) {
        return NO;  //needed for showValidSquares
    }
    
    if (PIPREVIEWFLAG) {
        return YES;
    }
    
        //allow bomb only on top of another pip and 
    if (pip.shapeID == BOMBNUMBER && square[squareID].thePip == nil) {
        return NO;
    }
    
        //cell already occupied & not bomb
	if (pip.shapeID != BOMBNUMBER && square[squareID].thePip != nil) {			
        return NO;
	}
    
        //star or bomb ok anywhere not excluded above, provided we have some stars or bombs
	if (pip.shapeID == STARNUMBER) {
        return YES;
    }
    
    if ( pip.shapeID == BOUGHTSTARNUMBER ) {
        return X.starsOnHand > 0 ? YES : NO;
    }
    
    if ( pip.shapeID == BOMBNUMBER ) {
        return X.bombsOnHand > 0 ? YES : NO;
    }
	
	int upSquareID = square[squareID].up;
	int rightSquareID = square[squareID].right;
	int downSquareID = square[squareID].down;
	int leftSquareID = square[squareID].left;
	
	Pip *upPip      = upSquareID == EDGE    ? nil : square[upSquareID].thePip;
	Pip *rightPip   = rightSquareID == EDGE ? nil : square[rightSquareID].thePip;
	Pip *downPip    = downSquareID == EDGE  ? nil : square[downSquareID].thePip;
	Pip *leftPip    = leftSquareID == EDGE  ? nil : square[leftSquareID].thePip;
    
        //pip must be next to another one
    if (!!!upPip && !!!rightPip && !!!downPip && !!!leftPip) {
        return NO;
    }
    
	if (upPip != nil && upPip.shapeID != STARNUMBER && upPip.shapeID != BOUGHTSTARNUMBER) {
		if (upPip.colorID != pip.colorID && upPip.shapeID != pip.shapeID) {
			return NO;
		}
	}
	
	if (rightPip != nil && rightPip.shapeID != STARNUMBER && rightPip.shapeID != BOUGHTSTARNUMBER) {
		if (rightPip.colorID != pip.colorID && rightPip.shapeID != pip.shapeID) {
			return NO;
		}
	}
	
	if (downPip != nil && downPip.shapeID != STARNUMBER && downPip.shapeID != BOUGHTSTARNUMBER) {
		if (downPip.colorID != pip.colorID && downPip.shapeID != pip.shapeID) {
			return NO;
		}
	}
	
	if (leftPip != nil && leftPip.shapeID != STARNUMBER && leftPip.shapeID != BOUGHTSTARNUMBER) {
		if (leftPip.colorID != pip.colorID && leftPip.shapeID != pip.shapeID) {
			return NO;
		}
	}
    return YES;
}

-(void) descendingPing {
    ANNOUNCE
    CCLOG(@"effectCount: %d", effectCount);
    [sae playEffect:@"placePipChirp2.wav" 
              pitch:1.2f - 0.05f * effectCount  //effectCount initialized in init
                pan:0.0f 
               gain:0.6f];
    if (effectCount == maxEffectCount) {
        effectCount = 0;
        [[CCScheduler sharedScheduler] unscheduleSelector:@selector(descendingPing) forTarget:self];
    }
    else {
        effectCount++;
    }
}

-(float) fractionOfPipsInSameRowOrColumn:(int)squareID {   //pips present divided by number of squares in col or row whichever has more
    int rows = X.nRows;
    int cols = X.nColumns;
    int pipCountInRow = 0;
    int pipCountInColumn = 0;
    int theRow = (squareID / cols);
    int theColumn = squareID - cols * (int)(squareID / cols);
    for (int column = 0; column < cols; column++) { //count in same row
        int index = theRow * cols + column;
        if ( square[index].thePip ) {
            pipCountInRow++;
        }
    }
    for (int row = 0; row < rows; row++) {  //count in same column
        int index = row * cols + theColumn;
        if ( square[index].thePip ) {
            pipCountInColumn++;
        }
    }
    float fractionInRow = (float)pipCountInRow / cols;
    float fractionInColumn = (float)pipCountInColumn / rows;
    CCLOG(@"fraction of row, column: %f, %f", fractionInRow, fractionInColumn);
    return MAX(fractionInRow, fractionInColumn);
}

-(void) placePipOnSquare:(int)squareID {    //squareID validated & self.isReady == NO before this is called
            //an action holds a pointer to its target so can't run a single action on two targets simultaneously
            //but can copy (with autorelease) and run the original and a copy on two targets simultaneously
    
//        //handle transactions left from previous play- copied from paymentQueue:updatedTransactions: below
//    if ( [[SKPaymentQueue defaultQueue].transactions count] > 0 ) {
//        for (SKPaymentTransaction *transaction in [SKPaymentQueue defaultQueue].transactions) {
//            switch (transaction.transactionState) {
//                case SKPaymentTransactionStatePurchased:
//                    CCLOG(@"old transaction succeeded: %@", transaction);
//                    CCLOG(@"product identifier: %@", transaction.payment.productIdentifier);
//                    [self completeSuccessfulTransaction:transaction];
//                    break;
//                case SKPaymentTransactionStateFailed:
//                    CCLOG(@"old transaction failed, now remove: %@", transaction);
//                    CCLOG(@"product identifier: %@", transaction.payment.productIdentifier);
//                    [self completeFailedTransaction:transaction];
//                    break;
//                case SKPaymentTransactionStateRestored:
//                    CCLOG(@"old transaction result is restored: %@", transaction);
//                    break;
//                default:
//                    break;
//            }
//        }
//    }
    
    if (X.tutorialsEnabled && X.level == 1) {
            //assume we're doing tutorial3 now
        tutorial3Count++;
        if (tutorial3Count >= 3) {
            [[NSNotificationCenter defaultCenter] postNotificationName:@"didPlace3Pips" object:self];
        }
    }
    
    X.movesThisPlay++;
	undoButton.isEnabled = YES;	//might be set NO in darkenFullRowOrColumn
    
    if (activePip != bombPip) {
        square[squareID].thePip = activePip;
        square[squareID].pipColor = activePip.colorID;
        square[squareID].pipShape = activePip.shapeID;
        CCLOG(@"squareID, shapeID, colorID: %d, %d, %d", squareID, activePip.shapeID, activePip.colorID);
//        [self makeReady]; //after thePip is assigned - if bombPip this is done in doExplosionAction or undo
    }
    
	CCActionInterval *placeAction = [CCMoveTo actionWithDuration:PIPPLACETIME position:square[squareID].location];
	CCEaseOut *easePlaceAction = [CCEaseSineInOut actionWithAction:placeAction];
	CCCallFunc *darkenFullRowOrColumnAction = [CCCallFunc actionWithTarget:self 
                                                         selector:@selector(darkenFullRowOrColumn)];
    CCCallFunc *bombAnimationAction = [CCCallFunc actionWithTarget:self 
                                                          selector:@selector(doBombAnimation)];
    id decrementShredderIfNotFullAction = [CCCallFunc actionWithTarget:self 
                                                           selector:@selector(decrementShredderIfNotFull)];
    CCCallFunc *makeReadyAction = [CCCallFunc actionWithTarget:self selector:@selector(makeReady)];
    CCSequence *seqAction;
    if (activePip == bombPip) {
        seqAction = [CCSequence actions:
                     easePlaceAction,
                     decrementShredderIfNotFullAction,
                     bombAnimationAction,
                     makeReadyAction, nil];
    }
    else {
        seqAction = [CCSequence actions: 
                     decrementShredderIfNotFullAction, 
                     easePlaceAction, 
                     darkenFullRowOrColumnAction, nil];  //must do makeREady at the right time
    }
    
	[activePip runAction:[[seqAction copy] autorelease]];   //so the action can be running on two sprites
    
        //count pips along same row and column
    float fraction  = [self fractionOfPipsInSameRowOrColumn:squareID];
    if (activePip == starPip) {
        [sae playEffect:@"place star.aiff"];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"useBoughtStar" object:nil];    //tutorial
        if (!!!(X.tutorialsEnabled && X.level < 3) ) {
                //for achievement
                //we don't get this far if no stars remain
            X.starsUsedThisPlay++;
        }
        
    } else {
        [sae playEffect:@"placePipChirp2.wav" pitch:MINPITCH + (MAXPITCH - MINPITCH) * fraction pan:0.0f gain:0.6f];
    }

	lastPipMoved = activePip;
    if ( X.preselectToken ) {
        activePip = nil;
    }
	lastSquareCovered = squareID;
	lastLocationMovedTo = square[squareID].location;
	
	waitForPlaceStarSound = NO;    //YES pauses descending ping while place star sfx plays
    switch (activeSpot) {
		case w1:
			wait1.thePip = nil;
			cameFromSpot = w1;
			[self feedPip];
			break;
        case w2:
            wait2.thePip = nil;
            cameFromSpot = w2;
            [self feedPip];
            break;
        case w3:
            wait3.thePip = nil;
            cameFromSpot = w3;
            [self feedPip];
            break;

                //apparently when the pip is a star the following happens before darkenFullRowOrColumn runs,
                //which caused a crash. It was fixed (I'm not clear why) by retaining
                //the Pip before moving it to be a child of the square's layer and then releasing it again
            
            //only get here if X.starsOnHand > 0; X.starsOnHand is decremented below- could go to zero
        case star:
            waitForPlaceStarSound = YES;   //pauses descending ping while place star sfx plays
            starMarker.opacity = 0;
            marker.opacity = 255;
            marker.position = wait1.location;   //w1 is made active spot etc. below
            
            cameFromSpot = star;
            [self decrementStarQuantity];
            
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setPositiveFormat:@"#,##0"];
            [formatter setNegativeFormat:@"-#,##0"];
            
            [self popUpScore:[NSNumber numberWithInteger:-X.starCost]];
            
            if (X.starsOnHand > 0) {
                    //make another star if we have any left
                starPip = [self makePipAt:starLocation colorNumber:STARCOLORNUMBER shapeNumber:BOUGHTSTARNUMBER];
            } else {
                starPip = [self makePipAt:starLocation colorNumber:STARCOLORNUMBER shapeNumber:BOUGHTSTARCROSSEDOUTNUMBER];
            }
            [self showStar:X.showStar];
            oldStarCost = X.starCost;   //for undo
            X.starCost = [self starCost];
            CCLOG(@"X.starCost: %d", X.starCost);   //debug
            starCostLabel.string = [NSString stringWithFormat:@"-%@\nPoints",
                                    [formatter stringFromNumber:[NSNumber numberWithInteger:X.starCost]]];
            CCLOG(@"starCostLabel.string: %@", starCostLabel.string);   //debug
            [formatter release];
            break;
        case bomb:
            cameFromSpot = bomb;
                //don't update counts until bomb explodes -- it might come back due to "UNDO"
            break;
		default:
			CCLOG(@"activeSpot not valid");
			kill( getpid(), SIGABRT );  //crash
			break;
	}
    
    if ( X.preselectToken ) {
        switch (cameFromSpot) {
            case w1:
            case star:
            case bomb:
                activePip = wait1.thePip;
                marker.position = wait1.location;
                activeSpot = w1;
                break;
            case w2:
                activePip = wait2.thePip;
                marker.position = wait2.location;
                activeSpot = w2;
                break;
            case w3:
                activePip = wait3.thePip;
                marker.position = wait3.location;
                activeSpot = w3;
                break;
            default:
                CCLOG(@"invalid cameFrom: not w1, w2, w3, star, or bomb.");
                kill( getpid(), SIGABRT );  //crash
                break;
        }
        if (showValidSquares) [self showValidSquaresForPip:activePip];
    } else {
        activePip = nil;
        activeSpot = none;
        marker.opacity = 0.f;
    }
}

-(void) doBombAnimation {
    ANNOUNCE
    [self makeUnReady];
        //get here only if activePip is bombPip
    CCParticleSystem *sparkle = [ARCH_OPTIMAL_PARTICLE_SYSTEM  particleWithFile:@"sparkle.plist"];
        //the call above throws some error messages but apparently works anyway
        //see issue #1040 - I guess this means it's fixed in a later cocos2d release
    sparkle.position = ccp(bombPip.position.x, bombPip.position.y + 12.f);
    sparkle.scale = 1.0;
    ccBlendFunc bf;
        //following defined in Frameworks/OpenGLES.framework/headers/ES2/gl.h
        //also see http://www.opengl.org/resources/faq/technical/transparency.htm
    bf.src = GL_ONE;
    bf.dst = GL_ONE_MINUS_SRC_ALPHA;  //fair -- a little blocky but probably as good as it gets
//    bf.dst = GL_ZERO;   //poor
//    bf.dst = GL_SRC_COLOR;  //poor
//    bf.dst = GL_SRC_ALPHA;  //poor
//    bf.dst = GL_SRC_ALPHA_SATURATE; //fair
//    bf.dst = GL_ONE;    //white flame, fair
//    bf.dst = GL_DST_ALPHA;    //looks good but not very noticeable
//    bf.dst = GL_ONE_MINUS_DST_ALPHA;    //poor
//    bf.dst = GL_ONE_MINUS_SRC_COLOR;    //looks good but not very noticeable
    sparkle.blendFunc = bf;
//    [self removeChildByTag:BOMBFLAMETAG cleanup:YES];    //remove previous burning if present -- is this needed?
    [self addChild:sparkle z:BOMBFLAMEZ tag:BOMBFLAMETAG];
    [sae playEffect:@"fuse2.0sec.wav"];   //2-sec hiss; length should match CCDelayTime below
    
    id explosionAction = [CCCallFunc actionWithTarget:self selector:@selector(doExplosionAction)];
//move makeReady to doExplosionAction
// duration should match length of sound clip
    explosionSequence = [CCSequence actions:[CCDelayTime actionWithDuration:2.0f], explosionAction, nil];
    [self runAction:explosionSequence];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"useBomb" object:nil];
}

-(void) doExplosionAction {
    ANNOUNCE
    
    bombMarker.opacity = 0;
    marker.opacity = 255;
    marker.position = wait1.location;
    
    NSString *textureString = [NSString stringWithFormat:@"symbol%d.png", square[lastSquareCovered].pipShape];
    ccColor4F explosionColor;
    int pipColorNumber = square[lastSquareCovered].pipColor;    //pipColor member is an int not a color
    switch (pipColorNumber) {
		default:
			CCLOG(@"Exit; color number out of defined range while making explosion texture %d", pipColorNumber);
			kill( getpid(), SIGABRT );  //crash
		case 0:
			explosionColor = ccc4FFromccc3B(ccc3(255, 0, 0));	//red
            break;
		case 1:
			explosionColor = ccc4FFromccc3B(ccc3(75, 75, 255));	//blue
			break;
		case 2:
			explosionColor = ccc4FFromccc3B(ccc3(220, 130, 35));   //orange
			break;
		case 3:
			explosionColor = ccc4FFromccc3B(ccc3(185, 0, 200));	//purple
            break;
		case 4:
			explosionColor = ccc4FFromccc3B(ccc3(255, 255, 0));	//yellow
			break;
		case 5:
			explosionColor = ccc4FFromccc3B(ccc3(170, 255, 170));	//light green
            break;
		case 6:
			explosionColor = ccc4FFromccc3B(ccc3(0, 165, 0));	//darker green
			break;
		case 7:
			explosionColor = ccc4FFromccc3B(ccc3(150, 160, 255));	//pale blue
			break;
        case 8:
        case 95:
        case 96:
        case 97:
            explosionColor = ccc4FFromccc3B(ccc3(255, 255, 255));   //white
            break;
    }
    [self removeChildByTag:BOMBFLAMETAG cleanup:YES];
    unwantedPip = square[lastSquareCovered].thePip;
        //replace dropped star if blown away (not bought star)
    if (unwantedPip.shapeID == STARNUMBER) {
        replaceStar = YES;
    }
    [pips removeObject:unwantedPip];
    [unwantedPip removeFromParentAndCleanup:YES];
    square[lastSquareCovered].thePip = nil;
    square[lastSquareCovered].pipColor = -1;
    square[lastSquareCovered].pipShape = -1;
    [self makeReady];   //after thePip is set
//    [self setZeroMarkerOpacities];
    [self decrementBombQuantity];
    undoButton.isEnabled = NO;
    
    Explosion *explosion = [Explosion node];
    explosion.position = ccp(bombPip.position.x, bombPip.position.y + 15.f);
    CCTextureCache *cache = [CCTextureCache sharedTextureCache];
    explosion.texture = [cache addImage:textureString];
    explosion.scale = 0.4f;
    explosion.startColor = explosionColor;
    explosion.startColorVar = ccc4FFromccc4B(ccc4(0.f, 0.f, 0.f, 0.f));
    explosion.endColor = explosionColor;
    explosion.endColorVar = ccc4FFromccc4B(ccc4(96.f, 96.f, 96.f, 0.f));
    explosion.life = 0.7f;
    explosion.lifeVar = 2;
    explosion.speed = 400.f;
    explosion.speedVar = 125.f;
    explosion.radialAccel = -100.f;
    explosion.radialAccelVar = 20.f;
    explosion.endSpin = 50.f;
    explosion.endSpinVar = 300.f;
    [self addChild:explosion z:5 tag:EXPLOSIONTAG];
    [sae playEffect:@"explosionSound.wav"];
    [self makeReady];
    
    [bombPip removeFromParentAndCleanup:YES];   //needs to appear after all references to it
    if (X.bombsOnHand > 0) {
        bombPip = [self makePipAt:bombLocation colorNumber:NOCOLOR shapeNumber:BOMBNUMBER];
    }
    else {
        bombPip = [self makePipAt:bombLocation colorNumber:NOCOLOR shapeNumber:BOMBCROSSEDOUTNUMBER];
    }
    
        //achievements
    if (!!!(X.tutorialsEnabled && X.level < 3) ) {
        X.bombsUsedThisPlay++;
    }
}

-(void) moveEaseInOut:(Pip *)thePip inTime:(float)t to:(CGPoint)toLocation {
	CCActionInterval *moveAction = [CCMoveTo actionWithDuration:t position:toLocation];
	CCEaseInOut *motion = [CCEaseInOut actionWithAction:moveAction rate:4];
	[thePip runAction:motion];
}

-(void) moveEaseSineInOut:(Pip *)thePip inTime:(float)t to:(CGPoint)toLocation {
	CCActionInterval *moveAction = [CCMoveTo actionWithDuration:t position:toLocation];
	CCEaseOut *motion = [CCEaseSineInOut actionWithAction:moveAction];
	[thePip runAction:motion];
}

-(void) moveEaseBounceOut:(Pip *)thePip inTime:(float)t to:(CGPoint)toLocation {
	CCActionInterval *moveAction = [CCMoveTo actionWithDuration:t position:toLocation];
	CCEaseBounceOut *motion = [CCEaseBounceOut actionWithAction:moveAction];
    CCSequence *seq = [CCSequence actions:motion, nil];
	[thePip runAction:seq];	
}

-(void) makeReady {
    ANNOUNCE
        //enable accelerometer if it was on before - first set on in appDelegate
//    accelerometer.delegate = X.accelerometerWasEnabled ? self : nil;
    self.isReady = YES;
}

-(void) makeUnReady {
    ANNOUNCE
//    X.accelerometerWasEnabled = accelerometer.delegate ? YES : NO;
//    accelerometer.delegate = nil;
	self.isReady = NO;
}

-(void) feedPip {
	ANNOUNCE
	
	//The wait positions either all empty (state A) or exactly one is empty (state B)
	BOOL empty1 = !wait1.thePip;
	BOOL empty2 = !wait2.thePip;
	BOOL empty3 = !wait3.thePip;
	BOOL empty4 = !wait4.thePip;
    int nEmpty = 0;
    if (empty1) nEmpty++;
    if (empty2) nEmpty++;
    if (empty3) nEmpty++;
    if (empty4) nEmpty++;
    CCLOG(@"empty1, 2, 3, 4: %d, %d, %d, %d", empty1, empty2, empty3, empty4);
	BOOL stateA = nEmpty == 4;	//the first time
	BOOL stateB = nEmpty == 1;
	NSAssert(stateA != stateB, @"state error in feedPip");  // != is XOR here
	
        //makeReady is sent in moveEaseBounceOut:
        //[self makeUnReady];	//commented out adhoc, 
        //also comment out makeready in moveeasebounceout
    
    if (stateA) {   //stateA is only used for initial setup of the grid
		float time4_1 = FEEDTIME;
		float time4_2 = FEEDTIME;
		float time4_3 = FEEDTIME;
        [self makeStarOnCenterSquare];
		[self makePipOn4];
		[self moveEaseBounceOut:wait4.thePip inTime:time4_1 to:wait1.location];
		wait1.thePip = wait4.thePip;
        wait1.pipColor = wait4.pipColor;
        wait1.pipShape = wait4.pipShape;
		wait4.thePip = nil;
		[self makePipOn4];
		[self moveEaseInOut:wait4.thePip inTime:time4_2 to:wait2.location];
		wait2.thePip = wait4.thePip;
        wait2.pipColor = wait4.pipColor;
        wait2.pipShape = wait4.pipShape;
		wait4.thePip = nil;
		[self makePipOn4];
		[self moveEaseInOut:wait4.thePip inTime:time4_3 to:wait3.location];
		wait3.thePip = wait4.thePip;
        wait3.pipColor = wait4.pipColor;
        wait3.pipShape = wait4.pipShape;
		wait4.thePip = nil;
		[self makePipOn4];
        [self makeReady];
	} else {    //for every move except initial setup of the grid
                //next is before moveEaseBounceOut so it's set in time for checkIfFailed to use it
		float time2_1 = FEEDTIME;
		float time3_2 = FEEDTIME;
		float time4_3 = FEEDTIME;
        if (empty1) {
            [self moveEaseBounceOut:wait2.thePip inTime:time2_1 to:wait1.location];
            wait1.thePip = wait2.thePip;
            activePip = wait1.thePip;
            if (showValidSquares) [self showValidSquaresForPip:activePip];
            wait1.pipColor = wait2.pipColor;
            wait1.pipShape = wait2.pipShape;
            wait2.thePip = nil;
            [self moveEaseSineInOut:wait3.thePip inTime:time3_2 to:wait2.location];
            wait2.thePip = wait3.thePip;
            wait2.pipColor = wait3.pipColor;
            wait2.pipShape = wait3.pipShape;
            wait3.thePip = nil;
            [self moveEaseSineInOut:wait4.thePip inTime:time4_3 to:wait3.location];
            wait3.thePip = wait4.thePip;
            wait3.pipColor = wait4.pipColor;
            wait3.pipShape = wait4.pipShape;
            wait4.thePip = nil;
            [self makePipOn4];
        } else if (empty2) {
            [self moveEaseBounceOut:wait3.thePip inTime:time3_2 to:wait2.location];
            wait2.thePip = wait3.thePip;
            activePip = wait2.thePip;
            if (showValidSquares) [self showValidSquaresForPip:activePip];
            wait2.pipColor = wait3.pipColor;
            wait2.pipShape = wait3.pipShape;
            wait3.thePip = nil;
            [self moveEaseSineInOut:wait4.thePip inTime:time4_3 to:wait3.location];
            wait3.thePip = wait4.thePip;
            wait3.pipColor = wait4.pipColor;
            wait3.pipShape = wait4.pipShape;
            wait4.thePip = nil;
            [self makePipOn4];
        } else if (empty3) {
            [self moveEaseSineInOut:wait4.thePip inTime:time4_3 to:wait3.location];
            wait3.thePip = wait4.thePip;
            activePip = wait3.thePip;
            if (showValidSquares) [self showValidSquaresForPip:activePip];
            wait3.pipColor = wait4.pipColor;
            wait3.pipShape = wait4.pipShape;
            wait4.thePip = nil;
            [self makePipOn4];
        } else {
            CCLOG(@"invalid cameFrom value. cameFrom: %d", cameFromSpot);
            kill( getpid(), SIGABRT );  //crash
        }
//        [self makeReady];   //this is being called while actions are still running - might cause trouble
	}
}

-(void) makePipOn4 {
    ANNOUNCE
        //don't use 'new' in name
        //make a pip on wait4 with random color and symbol
    int shapeNumber;
    int colorNumber;
    static int previousColorNumber = -1;
    static int previousShapeNumber = -1;
    
    if (replaceStar == NO) {
        switch (X.smart) {
            case 1:         //1 & 3: don't use same shape twice in succession
            case 3:
                do {
                    shapeNumber = (arc4random() % X.nShapes);
//                } while ( ( wait3.thePip != nil && shapeNumber == wait3.pipShape ) || shapeNumber == previousShapeNumber);
                } while ( shapeNumber == previousShapeNumber );
                break;
            default:
                shapeNumber = arc4random() % X.nShapes;       //use random shape
                break;
        }
        
        switch (X.smart) {
            case 2:         //2 & 3: don't use same color twice in succession
            case 3:
                do {
                    colorNumber = arc4random() % X.nColors;
//                } while (colorNumber == wait3.pipColor || colorNumber == previousColorNumber);
                } while ( colorNumber == previousColorNumber );
                break;
            default:
                colorNumber = arc4random() % X.nColors;         //use random color
                break;
        }
    } else {
        colorNumber = STARCOLORNUMBER;   //white
        shapeNumber = STARNUMBER;   //star
        replaceStar = NO;
    }
    
	CCLOG(@"shape, color: %d, %d", shapeNumber, colorNumber);
    Pip *aPip = [self makePipAt:wait4.location 
                     colorNumber:colorNumber 
                     shapeNumber:shapeNumber ];
	wait4.thePip = aPip;
    wait4.pipColor = aPip.colorID;
    wait4.pipShape = aPip.shapeID;
    if (shapeNumber == STARNUMBER) {
        wait4.thePip.scale = 1.3;
    }
    previousColorNumber = colorNumber;
    previousShapeNumber = shapeNumber;
}

-(void) makeStarOnCenterSquare {
    ANNOUNCE
        //find index for center square
    int c = X.nColumns / 2 ;
    int r = X.nRows / 2;
    if ( X.nColumns % 2 == 0 && arc4random() & 01 ) { //if even # columns subtract one 50% of the time
        c--;
    }
    if ( X.nRows % 2 == 0 && arc4random() & 01 ) {  //if even # rows subtract one 50% of the time
        r--;
    }
    int index = r * X.nColumns + c;
    Pip *theStar = [self makePipAt:square[index].location colorNumber:STARCOLORNUMBER shapeNumber:STARNUMBER];
    theStar.scale = 1.3;    //bigger to distinguish from bought stars
    square[index].thePip = theStar;
    square[index].pipColor = STARCOLORNUMBER;
    square[index].pipShape = STARNUMBER;
    
    if ( X.preselectToken ) {
        activePip = wait1.thePip;
        if (showValidSquares) [self showValidSquaresForPip:activePip];
        marker.position = wait1.location;
        marker.opacity = 255.f;
        activeSpot = w1;
    } else {
        activePip = nil;
        if (showValidSquares) [self showValidSquaresForPip:activePip];
        activeSpot = none;
        marker.opacity = 0.f;
    }
}

-(Pip *) makePipAt:(CGPoint)location colorNumber:(int)colorNumber shapeNumber:(int)shapeNumber {
	ANNOUNCE
    
    NSString *imageName;
    
    int realShapeNumber = -1;
    if (shapeNumber < 90) {
        realShapeNumber = [[currentSymbols objectAtIndex:shapeNumber] integerValue];
    } else {
        realShapeNumber = shapeNumber;
    }
    
    if (shapeNumber >= 90) {
        imageName = [NSString stringWithFormat:@"symbol%d.png", shapeNumber];
        CCLOG(@" +++++++++++++ making special pip, shape #: %d ++++++++++++", shapeNumber);
    } else {
        imageName = [NSString stringWithFormat:@"symbol%d.png", realShapeNumber];
    }
    
        //override above imageName for Pip Review
    if (PIPREVIEWFLAG && shapeNumber < 90) {
        static int i = -1;
        imageName = [NSString stringWithFormat:@"symbol%d.png", ++i % NDEFINEDSYMBOLS];
    }
      
    Pip *pip = [[Pip spriteWithFile:imageName] retain];
    pip = [pip initWithColor:colorNumber];
    pip.shapeID = realShapeNumber;
    pip.colorID = colorNumber;
    [pip autorelease];
	pip.position = location;
    if (shapeNumber < 90) {
        [pips addObject:pip];   //don't count star or bomb as a normal pip
        [self addChild:pip z:PIPZ];
    } else if (shapeNumber == BOMBNUMBER || shapeNumber == BOMBCROSSEDOUTNUMBER) {
        pip.scale = 0.8;
        [self addChild:pip z:BOMBZ];
    } else if (shapeNumber == BOUGHTSTARNUMBER) {
        [self addChild:pip z:STARZ];
    } else {    //if we get here it's a dropped star
        [self addChild:pip z:STARZ];
    }
    return pip;
}

-(void) moveWaitingPipsUp {
    ANNOUNCE
    Pip *p = wait4.thePip;
    if (p.shapeID == STARNUMBER) {  //if we're throwing away a dropped star we have to replace it
        replaceStar = YES;
    }
	[pips removeObject:p];  //probably not valid if star but doesn't cause a problem
	[self removeChild:p cleanup:YES];
    
	float speed = MOVESPEED;
	float distance1_2 = ccpDistance(wait1.location, wait2.location);
	float distance2_3 = ccpDistance(wait2.location, wait3.location);
	float distance3_4 = ccpDistance(wait3.location, wait4.location);
	
	float time1_2 = distance1_2 / speed;
	float time2_3 = distance2_3 / speed;
	float time3_4 = distance3_4 / speed;
	
	[self moveEaseSineInOut:wait3.thePip inTime:time3_4 to:wait4.location];
	wait4.thePip = wait3.thePip;
    wait4.pipColor = wait3.pipColor;
    wait4.pipShape = wait3.pipShape;
    wait3.thePip = nil;
    
    if (cameFromSpot != w3) {
        [self moveEaseSineInOut:wait2.thePip inTime:time2_3 to:wait3.location];
        wait3.thePip = wait2.thePip;
        wait3.pipColor = wait2.pipColor;
        wait3.pipShape = wait2.pipShape;
        wait2.thePip = nil;
    }
    
    if (cameFromSpot != w3 && cameFromSpot != w2) {
        [self moveEaseSineInOut:wait1.thePip inTime:time1_2 to:wait2.location];
        wait2.thePip = wait1.thePip;
        wait2.pipColor = wait1.pipColor;
        wait2.pipShape = wait1.pipShape;
        wait1.thePip = nil;
    }
}

-(void) undoAction {
    ANNOUNCE
    if (X.messageIsShowing || X.messageQueueBeingShown) {
        return;
    }
    
	[self makeUnReady];
    X.movesThisPlay--;
    [sae playEffect:@"undo.wav"];
	undoButton.isEnabled = NO;
	
	CGPoint destination;
	switch (cameFromSpot) {
		default:
            destination = wait1.location;   //unused but suppresses Analyze warning
			CCLOG(@"invalid cameFrom value in undoAction");
			kill( getpid(), SIGABRT );  //crash
			break;
            
		case w1:
			destination = wait1.location;
			[self moveWaitingPipsUp];
			wait1.thePip = lastPipMoved;
            wait1.pipColor = lastPipMoved.colorID;
            wait1.pipShape = lastPipMoved.shapeID;
			marker.position = wait1.location;
            marker.opacity = 255.f;
			activePip = wait1.thePip;
			activeSpot = w1;
			break;
            
        case w2:
            destination = wait2.location;
            [self moveWaitingPipsUp];
            wait2.thePip = lastPipMoved;
            wait2.pipColor = lastPipMoved.colorID;
            wait2.pipShape = lastPipMoved.shapeID;
            marker.position = wait2.location;
            marker.opacity = 255.f;
            activePip = wait2.thePip;
            activeSpot = w2;
            break;
            
        case w3:
            destination = wait3.location;
            [self moveWaitingPipsUp];
            wait3.thePip = lastPipMoved;
            wait3.pipColor = lastPipMoved.colorID;
            wait3.pipShape = lastPipMoved.shapeID;
            marker.position = wait3.location;
            marker.opacity = 255.f;
            activePip = wait3.thePip;
            activeSpot = w3;
            break;

        case star:
            destination = starLocation;
            marker.opacity = 0.f;
            starMarker.opacity = 255.f;
            activePip = starPip;
            activeSpot = star;
            if (!!!X.tutorialsEnabled) {
                X.starsUsedThisPlay--;
            }
            [self incrementStarQuantity];
            X.starCost = oldStarCost;
            [self popUpScore:[NSNumber numberWithInteger:X.starCost]];  //calls flipAndUpdateScore:
            NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
            [formatter setPositiveFormat:@"#,##0"];
            starCostLabel.string = [NSString stringWithFormat:@"-%@\nPoints", 
                                    [formatter stringFromNumber:[NSNumber numberWithInteger:X.starCost]]];
            [formatter release];
            break;
            
        case bomb:
            destination = bombLocation;
            marker.opacity = 0.f;
            bombMarker.opacity = 255.f;
            activePip = bombPip;
            activeSpot = bomb;
            [self removeChildByTag:BOMBFLAMETAG cleanup:YES];
            [self stopAction:explosionSequence];
            [self makeReady];
                //update bomb counts after explosion
            break;
	}
    if (showValidSquares) [self showValidSquaresForPip:activePip];
    
    if (undoShouldIncreaseShredderNumber == YES) {
        [self incrementShredderNumber];
        undoShouldIncreaseShredderNumber = NO;
    }
    
        //don't clear square if we are undoing a bomb move
	if (lastSquareCovered > -1 && activePip != bombPip) {
		square[lastSquareCovered].thePip = nil;
		lastSquareCovered = -1;
	}
	
	float distance = ccpDistance(lastLocationMovedTo, destination);
	float speed = MOVESPEED;
	float time = distance / speed;
	[self moveEaseSineInOut:lastPipMoved inTime:time to:destination];
	lastLocationMovedTo = destination;
	[self makeReady];
}

-(void) moveToShredder {
    ANNOUNCE
    
    if (shredderNumber == shredderCapacity) {
        [[MessageManager sharedManager] showMessageWithKey:@"useShredderWhenFull" atEndNotify:nil selector:nil];
        return;
    }

    X.movesThisPlay++;
    cameFromSpot = activeSpot;
    [self makeUnReady];
    float moveDistance = 10.f;
    Pip *pipToShred;
    
    switch (activeSpot) {
        case w1:
            pipToShred = wait1.thePip;
            wait1.thePip = nil;
            moveDistance = ccpDistance(shredderSlot, wait1.location);
            break;
        case w2:
            pipToShred = wait2.thePip;
            wait2.thePip = nil;
            moveDistance = ccpDistance(shredderSlot, wait2.location);
            break;
        case w3:
            pipToShred = wait3.thePip;
            wait3.thePip = nil;
            moveDistance = ccpDistance(shredderSlot, wait3.location);
            break;
        default:
            pipToShred = wait3.thePip;  //useless but suppresses Analyze warning
            CCLOG(@"in 'moveToShredder': activeSpot not valid");
            kill( getpid(), SIGABRT );  //crash
            break;
    }
    
    float moveTime = moveDistance / MOVESPEED;
    float shrinkTime = moveTime;
    float feedDownTime = 0.7f;
    
    CGPoint positionAboveSlot = CGPointMake(shredderSlot.x, shredderSlot.y + 18.f);
    CCActionInterval *moveAction = [CCMoveTo actionWithDuration:moveTime position:positionAboveSlot];
    
    id feedDownAction = [CCMoveTo actionWithDuration:feedDownTime 
                                             position:CGPointMake(shredderSlot.x, shredderSlot.y - 25.f)];
    id shrinkPipAction = [CCScaleBy actionWithDuration:shrinkTime scale:1.0f];

    CCCallFunc *incrementShredAction = [CCCallFunc actionWithTarget:self 
                                                           selector:@selector(incrementShredderNumber)];
    CCCallFuncND *removeAction = [CCCallFuncND actionWithTarget:self 
                                                        selector:@selector(removePip:data:) 
                                                            data:(void *)pipToShred];
    NSNumber *colorNumber = [NSNumber numberWithInteger:pipToShred.colorID];
    CCCallFuncND *doShredActionWithColorAction = 
        [CCCallFuncND actionWithTarget:self 
                              selector:@selector(doShredActionWithColor:data:) 
                                  data:(void *)colorNumber];
    CCCallFunc *makeReadyAction = [CCCallFunc actionWithTarget:self selector:@selector(makeReady)];
    
    CCSequence *seqAction = [CCSequence actions: 
                             [CCSpawn actions:moveAction, shrinkPipAction, nil], 
                             makeReadyAction,
                             incrementShredAction, 
                             [CCSpawn actions:doShredActionWithColorAction, feedDownAction, nil],
                             removeAction,
                             [CCCallBlock actionWithBlock:
                              ^(void){
//                                if (X.tutorialsEnabled) {
//                                    [self checkIfMoveIsAvailable];
//                                }
                                  [self checkIfMoveIsAvailable];
                              }],
                             nil];
    [pipToShred runAction:seqAction];
    [self feedPip];
    undoButton.isEnabled = NO;
    
    if (X.tutorialsEnabled && X.level == 1) {
            //assume we're doing tutorial2 now
        [[NSNotificationCenter defaultCenter] postNotification:
         [NSNotification notificationWithName:@"didUseShredder" object:self userInfo:nil]];
    }
}

-(void) doShredActionWithColor:(id)sender data:(void *)data {
    ANNOUNCE
    NSAssert( [(id)data isKindOfClass:[NSNumber class]], @"data not the right class" );
    CCLOG(@"shredding color number: %@", (NSNumber *)data);
    NSUInteger colorNumber = [(NSNumber *)data integerValue];
//    [(NSNumber *)data release];
    
    ccColor4F shredColor;
    switch (colorNumber) {
        case 0:
            shredColor = ccc4FFromccc3B(ccc3(255, 0, 0));   //red
            break;
        case 1:
			shredColor = ccc4FFromccc3B(ccc3(75, 75, 255));	//blue
			break;
		case 2:
			shredColor = ccc4FFromccc3B(ccc3(220, 130, 35));   //orange
			break;
		case 3:
			shredColor = ccc4FFromccc3B(ccc3(185, 0, 200));	//purple
            break;
		case 4:
			shredColor = ccc4FFromccc3B(ccc3(255, 255, 0));	//yellow
			break;
		case 5:
			shredColor = ccc4FFromccc3B(ccc3(170, 255, 170));	//light green
            break;
		case 6:
			shredColor = ccc4FFromccc3B(ccc3(0, 165, 0));	//darker green
			break;
		case 7:
			shredColor = ccc4FFromccc3B(ccc3(150, 160, 255));	//pale blue
			break;  
        case 8:
            shredColor = ccc4FFromccc3B(ccc3(255, 255, 255));   //white
            break;
        default:
            shredColor = ccc4FFromccc3B(ccc3(255, 0, 0));   //suppress Analyze warning
            CCLOG(@"Exit; color number not valid in shredAction...  colorNumber: %d", colorNumber);
            kill( getpid(), SIGABRT );  //crash
            break;
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"shredStrips" ofType:@"plist"];
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    CCParticleSystem *shreddings = [[[CCParticleSystemQuad alloc] initWithDictionary:dict] autorelease];
    shreddings.position = shredderInnerTop;
    shreddings.scale = 0.1f;
    shreddings.duration = shreddingDuration;
    shreddings.startColor = shredColor;
    ccBlendFunc bf;
    bf.src = GL_ONE;
    bf.dst = GL_ONE_MINUS_SRC_ALPHA;
    shreddings.blendFunc = bf;
    [self addChild:shreddings z:PIPZ + 2];
    [sae playEffect:@"shredder.wav"];
    CCSequence *lightSeq = [CCSequence actions:
                            [CCCallBlock actionWithBlock:^(void){
                                lightOff.opacity = 0;
                                lightOn.opacity = 255;
                            }],
                            [CCDelayTime actionWithDuration:shreddingDuration],
                            [CCCallBlock actionWithBlock:^(void){
                                lightOn.opacity = 0;
                                lightOff.opacity = 255;
                            }],
                            nil];
    [self runAction:lightSeq];
}

-(void) removePip:(id)sender data:(id)thePip {
    ANNOUNCE
    NSAssert( [thePip isKindOfClass:[Pip class]], @"invalid data value in releasePip" );
    [thePip removeFromParentAndCleanup:YES];
    [pips removeObject:thePip]; //pip is a node so it's autoreleased
}

-(void) decrementShredderIfNotFull {
        //decrement shredder unless a row or column is full, in which case we're going to empty shredder
        //code mostly copied from darkenFullRowOrColumn
    ANNOUNCE
	BOOL full;
	
	for (int r = 0; r < X.nRows; r++) {	//search for a full row
        full = YES;
		for (int c = 0; c < X.nColumns; c++) {
			if (square[c + r * X.nColumns].thePip == nil) {
				full = NO;
				break;
			}
		}
		if (full == YES) {
			return;
		}
	}
	
	for (int c = 0; c < X.nColumns; c++) {	//search for a full column
		full = YES;
		for (int r = 0; r < X.nRows; r++) {
			if (square[c + r * X.nColumns].thePip == nil) {
				full = NO;
				break;
			}
		}
		if (full == YES) {
            return;
		}
	}
        //no row or column is full if we get here
    if (shredderNumber > 0) {
        undoShouldIncreaseShredderNumber = YES;
        [self decrementShredderNumber];
    } else {
        undoShouldIncreaseShredderNumber = NO;
    }
}

-(void) decrementShredderNumber {
    ANNOUNCE
    float scalingTime = 0.7f * shreddingDuration;
    if ( shredderNumber > 0 ) {
        shredderNumber--;
    }
    id scaleAction = [CCScaleTo actionWithDuration:scalingTime scaleX:chipsScaleX scaleY:0.72f * shredderNumber];
    [chips runAction:scaleAction];
    shredderFullLabel.opacity = 0.f;    //never full after decrement
}

-(void) incrementShredderNumber {
    ANNOUNCE
    float scalingTime = 0.7f * shreddingDuration;
    shredderNumber++;
    id scaleAction = [CCScaleTo actionWithDuration:scalingTime scaleX:chipsScaleX scaleY:0.72f * shredderNumber];
    [chips runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.2f], scaleAction, nil]];
    if (shredderNumber == shredderCapacity) {
        shredderFullLabel.opacity = 255.f;
    }
}

-(void) emptyShredder {
    ANNOUNCE
    float scalingTime = 0.6f * shreddingDuration;
    shredderNumber = 0;
    id scaleAction = [CCScaleTo actionWithDuration:scalingTime scaleX:chipsScaleX scaleY:0.f];
    [chips runAction:[CCSequence actions:[CCDelayTime actionWithDuration:0.2f], scaleAction, nil]];
    shredderFullLabel.opacity = 0.f;    //not full
}

-(BOOL) validSquareExistsForPip:(Pip *)pip {
    NSAssert( pip != nil, @"nil pip in %@", NSStringFromSelector(_cmd) );
    for (int i = 0; i <  ( X.nRows * X.nColumns ); i++) {
        if ( [self pip:pip isOkOnSquare:i] ) {
            CCLOG(@"pip with color, shape: isOkOnSquare: %d, %d, %d", pip.colorID, pip.shapeID, i);
            return YES;
        }
    }
    return NO;
}

-(void) checkIfMoveIsAvailable {
    ANNOUNCE
    if ( shredderNumber < shredderCapacity || [self validSquareExistsForPip:activePip] || levelIsFinished ) {
        return;
    }
        //get here only if active pip has no move -- caution! this method might be called from more than one place
        //the wait... locations might not be finished updating when we get here
    NSMutableSet *otherPips = [NSMutableSet setWithObjects:wait1.thePip, wait2.thePip, wait3.thePip, nil];
    [otherPips removeObject:activePip];
    for (Pip *pip in otherPips) {
        if ( [self validSquareExistsForPip:pip] ) {
            return;
        }
    }
    
        //get here only if no move is available for any waiting pip
    if ( X.tutorialsEnabled && X.level < 3 ) {
        [[MessageManager sharedManager] enqueueMessageWithKey:@"startAgain" onQueue:X.boardSceneMessageQueue];
        [[MessageManager sharedManager] enqueueMessageWithKey:@"noScore" onQueue:X.choiceSceneMessageQueue];
    } else {
        [[MessageManager sharedManager] enqueueMessageWithKey:@"useSupplyOrShake" onQueue:X.boardSceneMessageQueue];
    }
    [[MessageManager sharedManager] showQueuedMessages];
}

-(void) checkIfLevelCompleted {
		//if every square is darkened call levelCompleted
	ANNOUNCE
    
	for (int i = 0; i < X.nRows * X.nColumns; i++) {
		if (! square[i].darkness) {	//found a square with darkness still 0
            [self makeReady];
			return;
		}
	}
		//get here only if darkness is > 0 on every square
    levelIsFinished = YES; //makeUnReady won't take effect soon enough -- maybe not still needed
    [marker removeFromParentAndCleanup:YES];
    marker = nil;
	[self levelCompleted];
}

-(void) darkenFullRowOrColumn {
		//check if a row or column is full, or both; if so, run actions
		//placing one pip can create both a full row and a full column
	ANNOUNCE
	int fullRow = -1;	//row number of a row that is full (0 to X.nRows-1)
	int fullColumn = -1;
	BOOL full;
	
	for (int r = 0; r < X.nRows; r++) {	//search for a full row
        full = YES;
		for (int c = 0; c < X.nColumns; c++) {
			if (square[c + r * X.nColumns].thePip == nil) {
				full = NO;
				break;
			}
		}
		if (full == YES) {
			fullRow = r;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"fillRow" object:nil];
			break;	//don't check remaining rows; only one can be full
		}
	}
	
	for (int c = 0; c < X.nColumns; c++) {	//search for a full column
		full = YES;
		for (int r = 0; r < X.nRows; r++) {
			if (square[c + r * X.nColumns].thePip == nil) {
				full = NO;
				break;
			}
		}
		if (full == YES) {
			fullColumn = c;
            [[NSNotificationCenter defaultCenter] postNotificationName:@"fillColumn" object:nil];
            break;	//don't check remaining columns; only one can be full
		}
	}
    
    if (fullRow < 0 && fullColumn < 0) {
        [self makeReady];
        return; //no row or column is full so nothing else to do
    }
	
        //if we get here a row or column is full, or both
    undoButton.isEnabled = NO;
    CCArray *squaresToBeCleared = [CCArray arrayWithCapacity:X.nRows + X.nColumns];
    deltaScore = 0;
    if (fullRow > -1) {
		int c = X.nColumns;
		while (--c + 1) {
			int index = c + fullRow * X.nColumns;
			[squaresToBeCleared addObject:[NSNumber numberWithInteger:index]];
            square[index].darkness++;
            square[index].theDarknessLabel.string = 
                [NSString stringWithFormat:@"%d", square[index].darkness];
            deltaScore += square[index].darkness;
		}
    }
    if (fullColumn > -1) {
		int r = X.nRows;
		while (--r + 1) {
			int index = fullColumn + r * X.nColumns;
			[squaresToBeCleared addObject:[NSNumber numberWithInteger:index]];
            square[index].darkness++;
            square[index].theDarknessLabel.string = 
                [NSString stringWithFormat:@"%d", square[index].darkness];
            deltaScore += square[index].darkness;  		}
    }
    NSAssert( ( [squaresToBeCleared count] > 0 ), @"[squaresToBeCleared count] not > 0" );
    
    if (waitForPlaceStarSound) {
        float playPlaceStarTime = 0.85f;
        CCSequence *seq = [CCSequence actions:
                                      [CCDelayTime actionWithDuration:playPlaceStarTime],
                                      [CCSpawn actions:
                                       [CCCallBlock actionWithBlock:^(void){
                                          [self emptyShredder];}],
                                       [CCCallBlock actionWithBlock:^(void){
                                          [self doDarkenActionsOnSquares:squaresToBeCleared];}],
                                       nil],
                                      nil];
        [self runAction:seq];
    } else {
        [self emptyShredder];
        [self doDarkenActionsOnSquares:squaresToBeCleared];
    }
}

-(void) doDarkenActionsOnSquares:(CCArray *)squaresToBeCleared {
    ANNOUNCE
    
        //if dropped star is removed feed another one, but not if purchased star was removed
    for (NSNumber *squareNumber in squaresToBeCleared) {
        if (square[ [squareNumber integerValue] ].thePip.shapeID == STARNUMBER) {
            replaceStar = YES;
            break;
        }
    }
    
            //the following displays darkness numbers in the squares temporarily after they are cleared
            //for each square in squaresToBeCleared
    for (int i = 0; i < [squaresToBeCleared count]; i++) {
        int index = [[squaresToBeCleared objectAtIndex:i] integerValue];
        
        /*font test*/
            //        square[index].theDarknessLabel.string = @"1"; //44 is widest 2-digit string
        
            //move pip from child of grid to child of darkLayer
        Pip *p = square[index].thePip;
        CCLayerColor *layer = square[index].theDarkLayer;
        CGSize layerSize = layer.contentSize;
        p.position = ccp(layerSize.width / 2, layerSize.height / 2);
        [p retain]; //fixes crash when the pip is a star (something about new star is made)
        [p removeFromParentAndCleanup:NO];  //square[index].thePip = nil; in squareInstantAction
        [layer addChild:p]; //wasn't added to layer initially to avoid waiting for move to finish
        [p release];
        
        float clearTime = 2.0f;
        float tweenDownTime = clearTime * 0.2f;
        float tweenUpTime = clearTime * 0.1f;
        float showDarknessTime = clearTime * 0.4f;
        float fadeOutTime = clearTime * 0.1f;
        
            //AA: adjust helper dots if we are showing them now
        id adjustHelperDotsAction = [CCCallBlock actionWithBlock:
                                     ^(void){
                                         if ( showValidSquares ) {
                                             [self showValidSquaresForPip:nil];    //turn off dots
                                         }
                                     }];
        
            //A: tweenDown varies scaleY from 1 to 0
        CCEaseExponentialIn *squareTweenDownAction = [CCEaseExponentialIn 
                                                     actionWithAction:[CCActionTween 
                                                     actionWithDuration:tweenDownTime
                                                     key:@"scaleY" 
                                                     from:1.f 
                                                     to:0.f]];
        
            //B: instantly remove the pip, make the darkness label visible
        CCCallFuncND *squareInstantAction = [CCCallFuncND actionWithTarget:self 
                            selector:@selector(squareInstantAction:data:) data:(void *)index];
        
            //C: tweenUp varies scaleY from 0 to 1
        CCEaseExponentialOut *squareTweenUpAction = [CCEaseExponentialOut actionWithAction:[CCActionTween
                                        actionWithDuration:tweenUpTime
                                        key:@"scaleY"
                                        from:0.f 
                                        to:1.f]];
            //D: fade CCLabelBMFont's to 0 opacity
        id fadeOutAction = [CCCallBlock actionWithBlock:
                                      ^(void){
                                          CCLabelBMFont *label = square[index].theDarknessLabel;
                                          CCFadeOut *fadeOutAction = [CCFadeOut actionWithDuration:fadeOutTime];
                                          [label runAction:fadeOutAction];
                                      }];
            // A, B, C, pause to view, D
        CCSequence *layerSeq = [CCSequence actions:
                                adjustHelperDotsAction,
                                squareTweenDownAction, 
                                squareInstantAction, 
                                squareTweenUpAction, 
                                [CCDelayTime actionWithDuration:showDarknessTime], 
                                fadeOutAction,
                                nil];
        
        [layer runAction:layerSeq];
    }
    
        //H: is level complete?
    id checkIfCompletedAction = [CCCallFunc actionWithTarget:self 
                                                   selector:@selector(checkIfLevelCompleted)];
    
        //J: make ready
    id makeReadyAction = [CCCallFunc actionWithTarget:self selector:@selector(makeReady)];
    
        //K: popUpScore
    id popUpScoreAction = [CCCallFuncO actionWithTarget:self 
                                               selector:@selector(popUpScore:) 
                                                 object:[NSNumber numberWithInteger:deltaScore]];
    
        //L: give empty grid bonus if the grid is empty
    id doEmptyBoardBonusAction = [CCCallFunc actionWithTarget:self selector:@selector(doEmptyBoardBonus)];
    
        //M: if we are in tutorial mode check if move is available
    id checkIfMoveIsAvailableAction = [CCCallFunc actionWithTarget:self selector:@selector(checkIfMoveIsAvailable)];
    
        //sequence all of the above and run it; J, -pause-, K, -pause-, H
    CCSequence *scoreSeq = [CCSequence actions:
                            makeReadyAction,
                            [CCDelayTime actionWithDuration:1.25f], //wait for actions on squares to complete
                            popUpScoreAction,
                            [CCDelayTime actionWithDuration:2.4f],  //wait for popUpScoreAction to finish
                            doEmptyBoardBonusAction,
                            checkIfCompletedAction,
                            checkIfMoveIsAvailableAction,
                            //don't check if failed - shredder was emptied before calling this method
                            nil];

    [scoreLabel runAction:scoreSeq];
    
    maxEffectCount = [squaresToBeCleared count];    //used in descendingPing
    [[CCScheduler sharedScheduler] scheduleSelector:@selector(descendingPing) 
                                          forTarget:self 
                                           interval:0.04f 
                                             paused:NO];
}

-(void) doEmptyBoardBonus { //give bonus = total of all darkness values
    
        //assure that we run the empty grid bonus animation only once
    if (emptyBoardBonusInProgress == YES) {
        return;
    }
    
    emptyBoardBonusInProgress = YES;
    
        //don't do it during level 1 or level 2 tutorials
    if ( X.tutorialsEnabled && X.level < 3 ) {
        return;
    }
    
    int totalDarkness = 0;
    for (int i = 0; i < X.nRows * X.nColumns; i++) {
        if (square[i].thePip != nil) {
            emptyBoardBonusInProgress = NO;
            return; //board isn't empty so nothing to do
        }
        totalDarkness += square[i].darkness;
    }
        //if we got here the grid is empty
    X.finishWithEmptyGridCount++;   //for achievements
    
    id popUpScoreAction = [CCCallFuncO actionWithTarget:self selector:@selector(popUpScore:)
                                                 object:[NSNumber numberWithInteger:totalDarkness]];
    [self runAction:popUpScoreAction];
    
    id showEmptyBoardBonusLabelAction = [CCCallBlock actionWithBlock:^{
        bonusLabelBackground.visible = YES;
        emptyBoardBonusLabel.visible = YES;}];
    
    id hideEmptyBoardBonusLabelAction = [CCCallBlock actionWithBlock:^{
        bonusLabelBackground.visible = NO;
        emptyBoardBonusLabel.visible = NO;}];
    
    id resetEmptyBoardBonusInProgressAction = [CCCallBlock actionWithBlock:^{
        emptyBoardBonusInProgress = NO;}];
    
    id seq = [CCSequence actions:showEmptyBoardBonusLabelAction,
             [CCDelayTime actionWithDuration:2.2f],
              hideEmptyBoardBonusLabelAction, 
              resetEmptyBoardBonusInProgressAction, nil];
    
    [self runAction:seq];
}

-(int) starCost {
    int cost = 0;
    
        //sum darkness in each row
        //for each square use its present darkness + 1 (for case when this is calculated without clearing)
    for (int r = 0; r < X.nRows; r++) {
        int rowSum = 0;
        for (int c = 0; c < X.nColumns; c++) {
            rowSum += square[INDEX].darkness + 1;
        }
        if (rowSum > cost) {
            cost = rowSum;
        }
    }
    
        //sum darkness in each column
    for (int c = 0; c < X.nColumns; c++) {
        int columnSum = 0;
        for (int r = 0; r < X.nRows; r++) {
            columnSum += square[INDEX].darkness + 1;
        }
        if (columnSum > cost) {
            cost = columnSum;
        }
    }
    
    return cost;
}

-(void) popUpScore:(NSNumber *)amount {
    int scoreIncrement = [amount integerValue];
    CCLabelTTF *amountLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%+d", scoreIncrement] 
                                                 fontName:@"Helvetica" 
                                                 fontSize:18];
    [amountLabel setColor:scoreIncrement > 0 ? ccc3(0, 80, 0) : ccRED];
//    amountLabel.color = scoreIncrement > 0 ? ccc3(0, 80, 0) : ccRED;
    amountLabel.opacity = 255;
    amountLabel.scale = 2.3f;
    amountLabel.isRelativeAnchorPoint = YES;
    amountLabel.anchorPoint = ccp(0.5f, 0.5f);
    amountLabel.position = CGPointMake(leftSpace + boardWidth * 0.5f, h * 0.5f);
    
    CCNode *box = [CCSprite spriteWithFile:@"round.png"];   //-hd file is 100x100 px
    box.isRelativeAnchorPoint = YES;
    box.anchorPoint = ccp(0.5f, 0.5f);
    box.position = ccp(0.5f * amountLabel.contentSize.width, 0.5f * amountLabel.contentSize.height);
    box.scale = 1.2f * amountLabel.contentSize.width / box.contentSize.width;
    [self addChild:amountLabel z:PIPZ + 2];
        //box behind amountLabel but in front of everything else; it is mostly opaque
    [amountLabel addChild:box z:-1];
    
    CGPoint dest = CGPointMake(w - 0.5f * rightSpace, 
                               scoreLayer.position.y + 0.5f * scoreLayer.contentSize.height);
    
    float fadeInDuration     = 0.4f;
    float swellByDuration    = 0.1f;
    float swellByAmount      = 1.1f;
    float pauseTime          = 0.4f;
    float moveTime           = 0.7f;
    float shrinkToDuration   = 0.9f;
    float shrinkToAmount     = 0.2f;
    
    CCActionInterval *fadeInAction = [CCFadeIn actionWithDuration:fadeInDuration];
    CCActionInterval *swellByAction = [CCScaleBy actionWithDuration:swellByDuration scale:swellByAmount];
    CCActionInterval *moveAction = [CCMoveTo actionWithDuration:moveTime position:dest];
    CCEaseExponentialInOut *easeMoveAction = [CCEaseExponentialInOut actionWithAction:moveAction];
    CCActionInterval *shrinkToAction = [CCScaleTo actionWithDuration:shrinkToDuration scale:shrinkToAmount];
    CCCallBlock *removeAction = [CCCallBlock actionWithBlock:
                                 ^(void){
                                     [amountLabel removeFromParentAndCleanup:YES];
                                 }];
    
    id flipAndUpdateScoreAction = [CCCallFuncO actionWithTarget:self selector:@selector(flipAndUpdateScore:)
                                                           object:amount]; 
    
    CCSequence *seq = [CCSequence actions:[CCSpawn actions: swellByAction, fadeInAction, nil], 
                       [CCDelayTime actionWithDuration:pauseTime],
                       [CCSpawn actions:easeMoveAction, shrinkToAction, nil],
                       removeAction, flipAndUpdateScoreAction, nil];
    [amountLabel runAction:seq];
}

-(void) flipAndUpdateScore:(NSNumber *)amount { //mostly duplicates code in doDarkenActionOnSquares - factor out
    int newScore = X.score + [amount integerValue]; //for banner
    float tweenDownTime     = 0.3f;
    float tweenUpTime       = 0.3f;
    
        // vary scaleY from 1 to 0
    CCEaseExponentialIn *scoreTweenDownAction = [CCEaseExponentialIn 
                                                 actionWithAction:[CCActionTween
                                                                   actionWithDuration:tweenDownTime 
                                                                   key:@"scaleY" 
                                                                   from:1 
                                                                   to:0]];
    
        //update scoreLabel.string
    id updateScoreAction = [CCCallBlock actionWithBlock:
                            ^(void){
                                X.score += [amount integerValue];
                                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                                [formatter setPositiveFormat:@"#,##0"];
                                NSString *scoreString = [formatter stringFromNumber:[NSNumber numberWithInteger:X.score]];
                                [formatter release];
                                scoreLabel.string = [NSString stringWithFormat:@"%@", scoreString];
                                scoreLabel.opacity = 255;
                            }];
    
        // vary scaleY from 0 to 1
    CCEaseExponentialOut *scoreTweenUpAction = [CCEaseExponentialOut 
                                                actionWithAction:[CCActionTween
                                                                  actionWithDuration:tweenUpTime
                                                                  key:@"scaleY" 
                                                                  from:0 
                                                                  to:1]];
    
    CCSequence *seq = [CCSequence actions:
                       scoreTweenDownAction,
                       updateScoreAction,
                       scoreTweenUpAction,
                       nil];
    [scoreLabel runAction:seq];
    
    int oldBest = [[X.bestScores objectAtIndex:X.level - 1] integerValue];
        //don't rely on X.score to be updated yet, use newScore
    if ( newHighBannerWasShown == NO && oldBest > 0 && newScore > oldBest ) {
        NSString *bannerTitle = @"New High!";
        NSString *bannerText = [NSString stringWithFormat:@"You just scored a new high for level %d.", X.level];
        [GKNotificationBanner showBannerWithTitle:bannerTitle message:bannerText completionHandler:nil];
        newHighBannerWasShown = YES;
        X.highsSinceNag++;
    }
}

-(void) squareInstantAction:(id)node data:(void *)data {
    CCLayerColor *layer = (CCLayerColor *)node;
    int index = (int)data;
    Pip *p = square[index].thePip;
    [pips removeObject:p];
    [p removeFromParentAndCleanup:YES];
    square[index].thePip = nil;
    square[index].pipColor = -1;
    square[index].pipShape = -1;
    [self setLayerColor:layer index:index]; //set the color according to the darkness value
    CCLabelBMFont *squareLabel = square[index].theDarknessLabel;
    squareLabel.opacity = 255;    //string was changed in earlier method
//    [self setZeroMarkerOpacities];
}

-(void) setLayerColor:(CCLayerColor *)layer index:(int)index {
        //set the layer darkness to match the darkness value of the square
        //ccColor3B color;
	GLubyte r, g, b;
    NSInteger nGradations = 16;
    NSInteger d = square[index].darkness; //lightest is d==0 (no darkness)
    d = MIN(d, nGradations);
    
    CGFloat case7Value = 150.f;
    int nCases = 7;
    switch (d) {
        case 0:
            r = g = b = 255;    //include some yellow to help distinguish from white
            break;
        case 1:
            b = 220;
            r = g = b + 25;     //taper off the amount of yellow on subsequent darkness degrees
            break;
        case 2:
            b = 200;
            r = g = b + 25;
            break;
        case 3:
            b = 190;
            r = g = b + 20;
            break;
        case 4:
            b = 180;
            r = g = b + 15;
            break;
        case 5:
            b = 170;
            r = g = b + 10;
            break;
        case 6:
            b = 160;
            r = g = b + 5;
            break;
        default:
            r = g = b = MAX(0, case7Value - ( (CGFloat)d - nCases ) / ( nGradations - nCases ) * case7Value );
            break;
    }
    [layer setColor:ccc3(r, g, b) ];    //color is a property but readonly (why?)
}

//-(void) printSquares {
//    ANNOUNCE
//	for (int r = 0; r < X.nRows; r++) {
//		for (int c = 0; c < X.nColumns; c++) {
//            if ( square[c + r * X.nColumns].thePip == nil ) {
//                printf("%3d", square[INDEX].darkness);
//            } else {
//                printf("  X");
//            }
//		}
//		printf("\n");
//	}
//}

-(void) signalBackgroundTouch {
    ANNOUNCE
	CCLOG(@"***BACKGROUND TOUCHED*** This is the background touched signal");
}

-(void) levelCompleted {
    ANNOUNCE
//	CCArray *remainingPips = [CCArray arrayWithCapacity:(X.nRows * X.nColumns) ];
//	for (int r = 0; r < X.nRows; r++) {
//		for (int c = 0; c < X.nColumns; c++) {
//			int index = c + r * X.nColumns;
//			if (square[index].thePip != nil) {
//				[remainingPips	addObject:square[index].thePip];
//			}
//		}
//	}
        
//    [accelerometer.delegate release];
    accelerometer.delegate = nil;
        // exit level in unReady state. will makeReady on next startup
    [self makeUnReady];
    if (!!!completionSoundPlayed) {
        [sae playEffect:@"completion.aiff"];
        completionSoundPlayed = YES;
    }
    
    CCDelayTime *pauseAction = [CCDelayTime actionWithDuration:3.2f];    //wait for flipAndUpdateScore
//    CCCallFuncND *nextSceneAction = [CCCallFuncND actionWithTarget:self 
//                                                          selector:@selector(nextScene:data:)
//                                                              data:(void *)YES];
    CCCallFunc *nextSceneAction = [CCCallFunc actionWithTarget:self selector:@selector(nextScene)];
    CCSequence *seq = [CCSequence actions:pauseAction, nextSceneAction, nil];
    [self runAction:seq];
}

//-(void) nextScene:(id)sender data:(void *)data {
-(void) nextScene {
    ANNOUNCE
    if (DEVELOPERFLAG) {
        X.completedFlag = YES;
            //            [[CCDirector sharedDirector] replaceScene:[RatingsScene scene]];
        CCDelayTime *delayAction = [CCDelayTime actionWithDuration:0.8f]; //allow all actions to complete
        CCCallFunc *replaceAction = [CCCallFunc actionWithTarget:self selector:@selector(changeToRatingsScene)];
        CCSequence *seq = [CCSequence actionOne:delayAction two:replaceAction];
        [self runAction:seq];
        return; //??
    } else {
        [X.modelP completed];
    }
    
//    } else if(data) {
//        [X.modelP completed];
//    }
//    } else {
//        [X.modelP failed];
//    }
}

-(void) changeToRatingsScene {
    [[CCDirector sharedDirector] replaceScene:[RatingsScene scene]];
}


-(void) swapStringA {
    if (ASwapState) {
        scoreLabel.string = msgALine1;
        ASwapState = NO;
    } else {
        scoreLabel.string = msgBLine1;
        ASwapState = YES;
    }
}

-(void) swapStringB {
    if (BSwapState) {
        highScoreLabel.string = msgALine2;
        BSwapState = NO;
    } else {
        [sae playEffect:@"pluck.wav"];
        highScoreLabel.string = msgBLine2;
        BSwapState = YES;
    }
    scoreLabel.opacity = 0;
}

-(void) flashWait {
    waitLabel.opacity = 255;
    id endFlashAction = [CCCallFunc actionWithTarget:self selector:@selector(endFlash)];
    [waitLabel runAction:[CCSequence actions:[CCDelayTime actionWithDuration:FLASHTIME], endFlashAction, nil]];
}

-(void) endFlash {
    waitLabel.opacity = 0;
}

-(void) incrementBombQuantity {
    if (X.bombsOnHand == 0) {   //remove crossed out bomb sprite and add normal bomb
        [bombPip removeFromParentAndCleanup:YES];
        bombPip = [self makePipAt:bombLocation colorNumber:NOCOLOR shapeNumber:BOMBNUMBER];
    }
    X.bombsOnHand++;
    bombQuantityLabel.string = [NSString stringWithFormat:@"%d", X.bombsOnHand];
}

-(void) decrementBombQuantity {
    if (X.bombsOnHand == 0) {
        return;
    }
    X.bombsOnHand--;
    bombQuantityLabel.string = [NSString stringWithFormat:@"%d", X.bombsOnHand];
}

-(void) incrementStarQuantity {
    if (X.starsOnHand == 0) {
        [starPip removeFromParentAndCleanup:YES];
        starPip = [self makePipAt:starLocation colorNumber:STARCOLORNUMBER shapeNumber:BOUGHTSTARNUMBER];
    }
    X.starsOnHand++;
    starQuantityLabel.string = [NSString stringWithFormat:@"%d", X.starsOnHand];
}

-(void) decrementStarQuantity {
    if (X.starsOnHand == 0) {
        return;
    }
    X.starsOnHand--;
    starQuantityLabel.string = [NSString stringWithFormat:@"%d", X.starsOnHand];
}

-(void) showStar:(BOOL)show {  //make star pile and its quantity label visible or not
    if (show)
    {
        starPip.opacity = 255;
        starQuantityLabel.opacity = 255;
        starCostLabel.opacity = 255;
    }
    else
    {   
        starPip.opacity = 0;
        starQuantityLabel.opacity = 0;
        starCostLabel.opacity = 0;
    }
}

-(void) showBomb:(BOOL)show {  //make bomb and its quantity label visible or not
    if (show) 
    {
        bombPip.opacity = 255;
        bombQuantityLabel.opacity = 255;
    }
    else
    {   
        bombPip.opacity = 0;
        bombQuantityLabel.opacity = 0;
    }
}

-(void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    alertViewIsShowing = NO;
    
    if (buttonIndex == 1) {
        if (alertView.tag == shakeAlertViewTag) {
            accelerometer.delegate = nil;
            [X.boardSceneMessageQueue removeAllObjects];
            if (X.tutorialsEnabled && X.level == 1) {
                    //assume we are doing tutorial5
                [[NSNotificationCenter defaultCenter] postNotificationName:@"didShakeDevice" object:self];
            }
            [X.modelP endByShaking];
        } else if (alertView.tag == bombAlertViewTag) { //bombAlertViewTag not in use
            [self placePipOnSquare:touchedSquareIdx];
        } else {
            CCLOG(@"invalid alertView.tag: %d", alertView.tag);
            kill( getpid(), SIGABRT );  //crash
        }
    }
}

-(void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {

    if (fabsf(acceleration.x) > ACCELEROMETERSENSITIVITY
        || fabsf(acceleration.y) > ACCELEROMETERSENSITIVITY 
        || fabsf(acceleration.z) > ACCELEROMETERSENSITIVITY) {
            if ( !!! alertViewIsShowing ) { //this block could be factored out but xCode misbalances braces 
                UIAlertView *shakeAlertView = [[UIAlertView alloc]
                                          initWithTitle:@"Shaking Detected" 
                                                message:@"End play and return to the level selection screen?"
                                               delegate:self 
                                      cancelButtonTitle:@"No" 
                                      otherButtonTitles:@"Yes", nil];
                shakeAlertView.tag = shakeAlertViewTag;
                [shakeAlertView show];
                [shakeAlertView release];
                alertViewIsShowing = YES;
            }
        }
}

-(void) paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    CCLOG(@"%d transaction(s) in SKPaymentQueue", [[SKPaymentQueue defaultQueue].transactions count] );
    CCLOG(@"%d transaction(s) were updated", [transactions count] );
    
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
                
            case SKPaymentTransactionStatePurchasing:
                    // Item is still in the process of being purchased
				break;

            case SKPaymentTransactionStatePurchased:
                CCLOG(@"transaction succeeded: %@", transaction);
                CCLOG(@"product identifier: %@", transaction.payment.productIdentifier);
                CCLOG(@"product receipt: %@", [transaction transactionReceipt] );
                [self completeSuccessfulTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateFailed:
                CCLOG(@"transaction failed, now remove: %@", transaction);
                CCLOG(@"product identifier: %@", transaction.payment.productIdentifier);
                [self completeFailedTransaction:transaction];
                break;
                
            case SKPaymentTransactionStateRestored:
                CCLOG(@"transaction result is restored: %@", transaction);
                break;
                
            default:
                break;
        }
    }
}

-(void) completeSuccessfulTransaction:(SKPaymentTransaction *)transaction {
    ANNOUNCE
        //productIdentifier should look like: @"com.electricTurkey.useBomb_10"
    NSArray *transactionFields = [transaction.payment.productIdentifier
                                  componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"._"]];
//    productTypeString = [[transactionFields objectAtIndex:2] copy];
    NSString *productTypeStringOriginal = [[transactionFields objectAtIndex:2] copy];
    productTypeString = [[productTypeStringOriginal stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]] retain];
    [productTypeStringOriginal release];
    productQuantity = [[transactionFields objectAtIndex:3] integerValue];
    if ( ( [productTypeString isEqualToString:@"stars"] || [productTypeString isEqualToString:@"bombs"] ) && productQuantity > 0 ) {
        pendingTransaction = transaction;
        [pendingTransaction retain];
        [self notifyProductHasArrivedForTransaction:transaction];
    } else {
        CCLOG(@"(transaction completed but product type is not stars or bombs) or productQuantity !> 0");
        CCLOG(@"deleting transaction");
        if (!!! alertViewIsShowing) {
            NSString *msgString = [NSString stringWithFormat:@"An invalid purchase transaction is being discarded. The transaction appears to be %d %@.", productQuantity, productTypeString];
            alertViewIsShowing = YES;
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"Invalid Purchase Transaction"
                                      message:msgString
                                      delegate:self
                                      cancelButtonTitle:@"Dismiss"
                                      otherButtonTitles:nil];
            [alertView show];
            [alertView release];
        }
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction]; //successful transaction finish is done in deliverProducts
    }
}

-(void) completeFailedTransaction:(SKPaymentTransaction *)transaction {
    
    NSString *reasonString = [NSString stringWithFormat:@"Reason given by Apple: \"%@\"",
                               [[transaction.error userInfo] valueForKey:@"NSLocalizedDescription"]];
    alertViewIsShowing = YES;
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:@"Purchase Not Completed" 
                              message:reasonString
                              delegate:self 
                              cancelButtonTitle:@"Dismiss" 
                              otherButtonTitles:nil];
    [alertView show];
    [alertView release];

    CCLOG(@"removing failed transaction: %@", transaction);
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

-(void) notifyProductHasArrivedForTransaction:(SKPaymentTransaction *)transaction {
        //notify user to touch this view
        //we know type is either @"stars" or @"bombs"
    ANNOUNCE
    X.messageIsShowing = YES;   //Board don't respond to touch
    CGFloat hostWidth = 200.f;
    CGFloat hostHeight = 80.f;
    CGRect frame = CGRectMake( (w - hostWidth) / 2, (h - hostHeight) / 2, hostWidth, hostHeight);
    deliveryMessageView = [PopUpView viewWithFrame:frame backgroundColor:[UIColor whiteColor]];
    UILabel *L1 = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, hostWidth, hostHeight / 2.f)];
    L1.backgroundColor = [UIColor clearColor];
    L1.textAlignment = UITextAlignmentCenter;
    L1.textColor = [UIColor blackColor];
    L1.numberOfLines = 1;
    L1.text = [NSString stringWithFormat:@"Your %@ have arrived", productTypeString];
    CCLOG(@"productTypeString: %@", productTypeString);
    L1.font = [UIFont systemFontOfSize:16];
    [deliveryMessageView addSubview:L1];
    [L1 release];
    
    CGFloat buttonWidth = 75.f;
    CGFloat buttonHeight = 30.f;
    CGRect buttonFrame = CGRectMake( (hostWidth - buttonWidth) / 2.f, hostHeight / 2.f, buttonWidth, buttonHeight);
    RLButton *button = [RLButton buttonWithStyle:RLButtonStyleGray 
                                          target:self 
                                          action:@selector(deliverProducts) 
                                           frame:buttonFrame];
    button.text = @"OK";
    [deliveryMessageView addSubview:button];
    button.enabled = YES;
    button.hidden = NO;
    button.opaque = YES;
}

-(void) deliverProducts {
    ANNOUNCE
    [deliveryMessageView remove];
    SKPaymentQueue *queue = [SKPaymentQueue defaultQueue];
    [queue finishTransaction:pendingTransaction];
    [pendingTransaction release];
    pendingTransaction = nil;
    SEL selector;
    if ( [productTypeString isEqualToString:@"stars"] ) {
        selector = @selector(incrementStarQuantity);
    } else {
        selector = @selector(incrementBombQuantity);
    }
    [productTypeString release];
    CCSequence *deliverOneAction = [CCSequence actions:
                                    [CCDelayTime actionWithDuration:0.15],
                                    [CCSpawn actions:
                                        [CCCallFunc actionWithTarget:self
                                                            selector:selector],
                                        [CCCallBlock actionWithBlock:^(void) {
                                            [sae playEffect:@"card flap.wav"];
                                        }], nil],
                                    nil];
    CCSequence *seq = [CCSequence actions:
                        [CCDelayTime actionWithDuration:1.2f],  //wait for message to be removed
                        [CCRepeat actionWithAction:deliverOneAction
                                    times:productQuantity], 
                        [CCCallBlock actionWithBlock:^(void){
                             X.messageIsShowing = NO;
                         }],
                        nil];
    [self runAction:seq];
}

#pragma mark - Tutorials

-(void) showValidSquaresForPip:(Pip *)pip {
    ANNOUNCE
//    Pip *thePip = nil;
//    switch (activeSpot) {
//        case star:
//        case w1:
//            thePip = wait1.thePip;
//            break;
//        case w2:
//            thePip = wait2.thePip;
//            break;
//        case w3:
//            thePip = wait3.thePip;
//            break;
//            
//        default:
//            break;
//    }
    int nValidSquares = 0;
    for (int i = 0; i < X.nRows * X.nColumns; i++) {
        if ( [self pip:pip isOkOnSquare:i] ) {
            [square[i].theTargetMarker setOpacity:255];
            nValidSquares++;
        } else {
            [square[i].theTargetMarker setOpacity:0];
        }
    }
    if (nValidSquares == 0 && shredderNumber < shredderCapacity) {   //if no squares, mark shredder though it's always valid
        [shredderTargetMarker setOpacity:255];
    } else {
        [shredderTargetMarker setOpacity:0];
    }
}

-(void) setShake:(BOOL)onOff {
    accelerometer.delegate = onOff ? self : nil;
    detectShakeIsOn = onOff;
//    if ( [[[UIDevice currentDevice] model] isEqualToString:@"iPhone Simulator"] ) {
//        waitingForSimulatorShake = onOff;
//    }
}

-(void) _doTutorial0 {
    ANNOUNCE
    CGFloat wait = 1.0f;
    [[MessageManager sharedManager] enqueueMessageWithText:@"This is the main playing screen. You will select pips on the left and move them onto the grid. The pips come in many colors and shapes. Other objects on the screen are a shredder, your score, and an undo button. Tap \"OK\" below and take a look at the screen." title:@"The Main Screen" delay:wait onQueue:X.boardSceneMessageQueue];
    [[MessageManager sharedManager] showQueuedMessages];
    waitingForTutorial0Tap = YES;
    
        //removeMessages sends @"messageRemoved" notification; if we don't catch it now it will be caught at the wrong time
    [self uponNotification:nil withExpectedName:nil setReceiverForName:@"messageRemoved" target:self selectorName:@"_doTutorial0a:"];
}

-(void) _doTutorial0a:(NSNotification *)notification {
    ANNOUNCE
    [self uponNotification:notification withExpectedName:@"messageRemoved" setReceiverForName:nil target:nil selectorName:nil];
    CCLabelTTF *tutorial0label = [CCLabelTTF labelWithString:@"Tap the screen to continue." fontName:@"Helvetica" fontSize:20];
    tutorial0label.position = ccp(w/2, 0.10f*h);
    [tutorial0label setColor:ccBLACK];
    [self addChild:tutorial0label z:2 tag:TUTORIAL0LABELTAG];
}

-(void) _doTutorial1 {
    ANNOUNCE
    [[self getChildByTag:TUTORIAL0LABELTAG] removeFromParentAndCleanup:YES];
    moveSourceMarkerOn = YES;
    CGFloat wait = 0.2f;
    [[MessageManager sharedManager] enqueueMessageWithText:@"The 3 pips on the left side of the screen are waiting to be moved onto the grid. The one with a black box around it is the \"active pip\". It will be moved next. You can make a different pip the active pip by tapping one of the others. Change the active pip now. Pointers will show you where you can tap."
                                                     title:@"The Pips" delay:wait onQueue:X.boardSceneMessageQueue];
    [[MessageManager sharedManager] showQueuedMessages];
    [self uponNotification:nil withExpectedName:nil setReceiverForName:@"messageRemoved" target:self selectorName:@"_setArrowsOnPips:"];
}

-(void) _setArrowsOnPips:(NSNotification *)notification {
    ANNOUNCE
    [self uponNotification:notification withExpectedName:@"messageRemoved" setReceiverForName:@"activePipChanged" target:self selectorName:@"_finishTutorial1:"];
    
    CCSprite *pointerA = [CCSprite spriteWithFile:@"targetPointer.png"];
    CCSprite *pointerB = [CCSprite spriteWithFile:@"targetPointer.png"];

    pointerA.scale = 0.7f;
    pointerB.scale = 0.7f;

    CGFloat offset = 40.f;
    pointerA.position = ccp(wait2.location.x - offset, wait2.location.y);
    pointerB.position = ccp(wait3.location.x - offset, wait3.location.y);

    [self addChild:pointerA z:7 tag:MARK1TAG];
    [self addChild:pointerB z:7 tag:MARK2TAG];
}

-(void) _finishTutorial1:(NSNotification *)notification {
    ANNOUNCE
    [self uponNotification:notification withExpectedName:@"activePipChanged" setReceiverForName:@"messageRemoved" target:self selectorName:@"_doTutorial2:"];
    [[self getChildByTag:MARK1TAG] removeFromParentAndCleanup:YES];
    [[self getChildByTag:MARK2TAG] removeFromParentAndCleanup:YES];
    CGFloat wait = 0.5f;
    [[MessageManager sharedManager] enqueueMessageWithText:@"Good! You activated a different pip. Whichever pip has the black box around it will be moved next."
                                                     title:@"The Active Pip" delay:wait onQueue:X.boardSceneMessageQueue];
    [[MessageManager sharedManager] showQueuedMessages];
}

-(void) _doTutorial2:(NSNotification *)notification {
    ANNOUNCE
    [self uponNotification:notification withExpectedName:@"messageRemoved" setReceiverForName:@"messageRemoved" target:self selectorName:@"_setArrowOnShredder:"];
        //moveSourceMarkerOn is YES at this point because we just finished tutorial1
    shredderOn = YES;
    CGFloat wait = 0.8f;
    [[MessageManager sharedManager] enqueueMessageWithText:@"Tap the shredder at the lower left corner of the screen and the active pip will be shredded and replaced by a new one. Shredding is the way to remove a pip that you don't want to put on the grid. Shred the active pip now. A pointer will show you where to tap."
                                                     title:@"Shred The Active Pip" delay:wait onQueue:X.boardSceneMessageQueue];
    [[MessageManager sharedManager] showQueuedMessages];
}

-(void) _setArrowOnShredder:(NSNotification *)notification {
    ANNOUNCE
    [self uponNotification:notification withExpectedName:@"messageRemoved" setReceiverForName:@"didUseShredder" target:self selectorName:@"_finishTutorial2:"];
    CCSprite *pointer = [CCSprite spriteWithFile:@"targetPointer.png"];
    pointer.tag = MARK1TAG;
    pointer.scale = 0.7f;
    CGFloat offset = 40.f;
    pointer.position = ccp(shredderInnerTop.x - offset, shredderInnerTop.y - 10.f);
    [self addChild:pointer z:5];
}

-(void) _finishTutorial2:(NSNotification *)notification {
    ANNOUNCE
    [self uponNotification:notification withExpectedName:@"didUseShredder" setReceiverForName:@"messageRemoved" target:self selectorName:@"_doTutorial3:"];

    [[self getChildByTag:MARK1TAG] removeFromParentAndCleanup:YES];
    CGFloat wait = 1.2f;
    [[MessageManager sharedManager] enqueueMessageWithText:@"When you shred a pip it is replaced by a new pip so there are always 3 pips waiting to be moved onto the grid. The shredder holds only 3 pips at a time. It partially empties every time you move a pip onto the grid and completely empties when you fill a row or column."
                                                     title:@"You Got a New Pip" delay:wait onQueue:X.boardSceneMessageQueue];
    [[MessageManager sharedManager] showQueuedMessages];

}

-(void) _doTutorial3:(NSNotification *)notification {
    ANNOUNCE
    [self uponNotification:notification withExpectedName:@"messageRemoved" setReceiverForName:@"messageRemoved" target:self selectorName:@"_setTargetMarksOnSquares:"];
    squaresOn = YES;
    CGFloat wait = 0.8f;
    [[MessageManager sharedManager] enqueueMessageWithText:@"Play some pips onto the grid by tapping squares. A pip can only be put next to a star, or next to another pip with a matching color or shape. Play some pips onto the grid now. Activate different pips and green dots will show you the valid squares."
                                                     title:@"Put Pips on the Grid" delay:wait onQueue:X.boardSceneMessageQueue];
    [[MessageManager sharedManager] showQueuedMessages];
    showValidSquares = YES;
    tutorial3Count = 0; //number of times a pip is put on the grid
}

-(void) _setTargetMarksOnSquares:(NSNotification *)notification {
    ANNOUNCE
    [self uponNotification:notification withExpectedName:@"messageRemoved" setReceiverForName:@"didPlace3Pips" target:self selectorName:@"tutorial3b:"];
    [self showValidSquaresForPip:activePip];
}

-(void) tutorial3b:(NSNotification *)notification {
    ANNOUNCE
        //next message is triggered by 'fillRow' or 'fillColumn' notifications sent to Tutor
    [self uponNotification:notification withExpectedName:@"didPlace3Pips" setReceiverForName:@"messageRemoved" target:self selectorName:@"tutorial3c:"];
    CGFloat wait = 0.5f;
    [[MessageManager sharedManager] enqueueMessageWithText:@"Continue adding pips to the grid until a row or column is filled. If there is no place on the grid for the active pip's color and shape, activate a different one. The green helper dots will not appear during normal play."
                                                     title:@"Now Fill a Row Or Column"
                                                     delay:wait
                                                   onQueue:X.boardSceneMessageQueue];
    [[MessageManager sharedManager] showQueuedMessages];
}

-(void) tutorial3c:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tutorial4:)
                                                 name:@"fillRow"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(tutorial4:)
                                                 name:@"fillColumn"
                                               object:nil];
}

-(void) tutorial4:(NSNotification *)notification {
    ANNOUNCE
    NSString *name = [notification name];
    
        //remove the following?
    if ( X.tutorialsEnabled && X.level == 1 && ( [name isEqualToString:@"fillRow"] || [name isEqualToString:@"fillColumn"] ) ) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"fillRow" object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"fillColumn" object:nil];
    } else {
        CCLOG(@"wrong notification");
        return;
    }
    
        //fillRow
    if ( [name isEqualToString:@"fillRow"] ) {
        [[MessageManager sharedManager] enqueueMessageWithText:@"The pips in that row were cleared away, the squares got a shade darker, and you won some points. Rows and columns can be filled repeatedly. Each time their squares get darker and their point values increase. Filling a row or column repeatedly is the way to get a high score." title:@"Good! You Filled a Row" delay:4.0f onQueue:X.boardSceneMessageQueue];
        
            //fillColumn
    } else if ( [name isEqualToString:@"fillColumn"] ) {
        [[MessageManager sharedManager] enqueueMessageWithText:@"The pips in that column were cleared away, the squares got a shade darker, and you won some points. Rows and columns can be filled repeatedly. Each time their squares get darker and their point values increase. Filling a row or column repeatedly is the way to get a high score." title:@"Good! You Filled a Column" delay:4.0f onQueue:X.boardSceneMessageQueue];
        
    }
    
    [[MessageManager sharedManager] showQueuedMessages];
    [self uponNotification:nil withExpectedName:nil setReceiverForName:@"messageRemoved" target:self selectorName:@"tutorial5:"];
    
}

-(void) tutorial5:(NSNotification *)notification {
    ANNOUNCE
    if (showValidSquares) {
        [self showValidSquaresForPip:activePip];
    }
    [self uponNotification:notification withExpectedName:@"messageRemoved" setReceiverForName:@"messageRemoved" target:self selectorName:@"_showShakeLabel:"];
    CGFloat wait = 1.0f;
    [[MessageManager sharedManager] enqueueMessageWithText:[NSString stringWithFormat:@"Shaking your %@ lets you go directly back to the level selection screen without filling rows and columns, but also without any score. To see how that works tap \"OK\" below, shake the %@, then select \"Yes\" on the message that pops up.", [[UIDevice currentDevice] model], [[UIDevice currentDevice] model]]
                                                     title:@"Shaking"
                                                     delay:wait
                                                   onQueue:X.boardSceneMessageQueue];
    [[MessageManager sharedManager] showQueuedMessages];
}

-(void) _showShakeLabel:(NSNotification *)notification {
    ANNOUNCE
    [self uponNotification:notification withExpectedName:@"messageRemoved" setReceiverForName:@"didShakeDevice" target:X.choiceSceneP selectorName:@"tutorial5b:"];
    CCLabelTTF *shakeLabela = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"Shake the %@", [[UIDevice currentDevice] model]]  fontName:@"Helvetica" fontSize:20];
    [shakeLabela setColor:ccBLACK];
    shakeLabela.position = ccp( w/2, 0.13f * h );
    [self addChild:shakeLabela z:2];
    
    CCLabelTTF *shakeLabelb = [CCLabelTTF labelWithString:@"and tap YES" fontName:@"Helvetica" fontSize:20];
    [shakeLabelb setColor:ccBLACK];
    shakeLabelb.position = ccp( w/2, 0.06f * h );
    [self addChild:shakeLabelb z:2];
    
    showValidSquares = YES;
    moveSourceMarkerOn = YES;
    shredderOn = YES;
    squaresOn = NO;
    [self setShake:YES];
    if ( [[[UIDevice currentDevice] model] isEqualToString:@"iPhone Simulator"] ) {
        waitingForSimulatorShake = YES;
    }
}

-(void) uponNotification:(NSNotification *)notification withExpectedName:(NSString *)expectedName
      setReceiverForName:(NSString *)newName target:(id)target selectorName:(NSString *)selName {
    ANNOUNCE

    if ( expectedName != nil && !!! [[notification name] isEqualToString:expectedName] ) {
            //debug
        NSLog(@"uponNotification... expected notification name: %@ but received notification name: %@", expectedName, [notification name]);
        kill( getpid(), SIGABRT );  //crash
    }
    
    if ( expectedName != nil && newName != nil ) {
        CCLOG(@"removing observer for notification name: %@ and setting observer for name: %@ to be: %@ / %@",
          [notification name], newName, target, selName);
    } else if (expectedName == nil )  {
        CCLOG(@"setting observer for notification name: %@ to be: %@ / %@", newName, target, selName);
    } else if (newName == nil) {
        CCLOG(@"removing observer for notification name: %@", [notification name]);
    } else {
        ANNOUNCE
        NSLog(@"uponNotification... expectedName and newName are both nil");
        kill( getpid(), SIGABRT );  //crash
    }
    
    if ( expectedName != nil ) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:[notification name] object:nil];
    }
    
    if ( selName != nil ) {
        [[NSNotificationCenter defaultCenter] addObserver:target selector:NSSelectorFromString(selName) name:newName object:nil];
    }
}

-(void) tutorial20a:(NSNotification *)notification;
{
    [self uponNotification:notification withExpectedName:nil setReceiverForName:@"messageRemoved" target:self selectorName:@"tutorial20b:"];
    [[MessageManager sharedManager] enqueueMessageWithText:@"Now you have a supply of small stars and bombs on the right. Like the big star you've already seen, these stars match pips of any color or shape and they can be put anywhere on the grid. But you get a point penalty every time you use one of these. Tap the small star then tap a square on the grid." title:@"Stars" delay:0.5f onQueue:X.boardSceneMessageQueue];
    [[MessageManager sharedManager] showQueuedMessages];
}

-(void) tutorial20b:(NSNotification *)notification {
    starsOn = YES;
    [self uponNotification:notification withExpectedName:@"messageRemoved" setReceiverForName:@"useBoughtStar" target:self selectorName:@"tutorial21a:"];
    useStarLabel = [CCLabelTTF labelWithString:@"Put a star on any square"
                                                fontName:@"Helvetica" fontSize:20];
    [useStarLabel setColor:ccBLACK];
    useStarLabel.position = ccp( w/2, 0.07f * h );
    [self addChild:useStarLabel z:2];
    starsOn = YES;
}

-(void) tutorial21a:(NSNotification *)notification {
    [self uponNotification:notification withExpectedName:@"useBoughtStar" setReceiverForName:@"messageRemoved" target:self selectorName:@"tutorial21b:"];
    [useStarLabel removeFromParentAndCleanup:YES];
    [[MessageManager sharedManager] enqueueMessageWithText:@"A bomb can be used to get rid of a pip after it is on the grid. There is no penalty for using a bomb. Put at least one pip on the grid then put a bomb on it to blow it away. The stars and bombs you use now will be replaced at the end of these tutorials." title:@"Bombs" delay:2.0f onQueue:X.boardSceneMessageQueue];
    [[MessageManager sharedManager] showQueuedMessages];

}

-(void) tutorial21b:(NSNotification *)notification {
    [self uponNotification:notification withExpectedName:@"messageRemoved" setReceiverForName:@"useBomb" target:self selectorName:@"tutorial22a:"];
    useBombLabel = [CCLabelTTF labelWithString:@"Put a bomb on a pip on the grid"
                                      fontName:@"Helvetica" fontSize:20];
    [useBombLabel setColor:ccBLACK];
    useBombLabel.position = ccp( w/2, 0.07f * h );
    [self addChild:useBombLabel z:2];
    bombsOn = YES;
    starsOn = NO;
}

-(void) tutorial22a:(NSNotification *)notification {
    [self uponNotification:notification withExpectedName:@"useBomb" setReceiverForName:@"messageRemoved" target:self selectorName:@"tutorial22b:"];
    [useBombLabel removeFromParentAndCleanup:YES];
    [[MessageManager sharedManager] enqueueMessageWithText:@"If you use up all the stars or bombs you can buy more from the App Store. To buy more, tap the star or bomb once then tap it a second time and the purchase menu will appear. Do that now so you see how it works. Choose \"Cancel\" on the purchase menu so you will not actually buy anything." title:@"Buying Supplies" delay:4.0f onQueue:X.boardSceneMessageQueue];
    [[MessageManager sharedManager] showQueuedMessages];
    viewPurchaseMenuOn = YES;
    starsOn = NO;
    bombsOn = NO;
}

-(void) tutorial22b:(NSNotification *)notification {
    [self uponNotification:notification withExpectedName:@"messageRemoved" setReceiverForName:@"didCancelPurchase" target:self selectorName:@"tutorial23a:"];
    viewPurchaseMenuLabela = [CCLabelTTF labelWithString:@"Tap the star or bomb a second time"
                                      fontName:@"Helvetica" fontSize:20];
    [viewPurchaseMenuLabela setColor:ccBLACK];
    viewPurchaseMenuLabela.position = ccp( w/2, 0.13f * h );
    [self addChild:viewPurchaseMenuLabela z:2];
    viewPurchaseMenuLabelb = [CCLabelTTF labelWithString:@"then select Cancel"
                                                fontName:@"Helvetica" fontSize:20];
    [viewPurchaseMenuLabelb setColor:ccBLACK];
    viewPurchaseMenuLabelb.position = ccp( w/2, 0.06f * h );
    [self addChild:viewPurchaseMenuLabelb z:2];
}

-(void) tutorial23a:(NSNotification *)notification {
    [self uponNotification:notification withExpectedName:@"didCancelPurchase" setReceiverForName:@"messageRemoved" target:self selectorName:@"tutorial23b:"];
    [viewPurchaseMenuLabela removeFromParentAndCleanup:YES];
    [viewPurchaseMenuLabelb removeFromParentAndCleanup:YES];
    [[MessageManager sharedManager] enqueueMessageWithText:[NSString stringWithFormat:@"To advance to the next level you must fill rows or columns until you darken all the squares on the grid. Remember you can change which waiting pip is active, you can shred, or you can use a star or bomb from the right side of the screen. And, as a last resort, you can shake the %@ to start over.", [[UIDevice currentDevice] model]] title:@"Now Darken All Squares" delay:0.5f onQueue:X.boardSceneMessageQueue];
    [[MessageManager sharedManager] showQueuedMessages];
    viewPurchaseMenuOn = NO;
    [self setShake:YES];
    starsOn = YES;
    bombsOn = YES;
}

-(void) tutorial23b:(NSNotification *)notification {
    [self uponNotification:notification withExpectedName:@"messageRemoved" setReceiverForName:@"endByCompleting" target:X.choiceSceneP selectorName:@"tutorial23c:"];
    darkenAllSquaresLabel = [CCLabelTTF labelWithString:@"Darken all squares"
                                               fontName:@"Helvetica" fontSize:20];
    shredderOn = YES;
    [self setShake:YES];
    moveSourceMarkerOn = YES;
    [darkenAllSquaresLabel setColor:ccBLACK];
    darkenAllSquaresLabel.position = ccp( w/2, 0.07f * h );
    [self addChild:darkenAllSquaresLabel z:2];
}

@end
    



