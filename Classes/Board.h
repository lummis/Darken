//
//  Board.h
//  Darken
//
//  Created by Robert Lummis on 5/22/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

// z:-2 for background, set in +boardScene
// z:1 for darkness layer on each square, set in setUpGrid, with tag:(squareID + 2000)
// z:3 for pip, set in newPipAt...
// z:2 for darknessValueLabel (score on each square), set in darken

#import "SimpleAudioEngine.h"
#import "Store.h"
#import "StoreKit/StoreKit.h"
#import "PopUpView.h"

@class Pip;

@interface Board : CCLayer <UIAlertViewDelegate, UIAccelerometerDelegate, SKPaymentTransactionObserver> {
    #define nDefinedSymbols 11	//number of symbols defined, whether used in current level or not

    SimpleAudioEngine *sae;
    UIAccelerometer *accelerometer;

    float w, h; //screen width and height
    float leftSpace, rightSpace, bottomSpace;	//distance from screen edge to outside of board frame
    
    float boardWidth, boardHeight;
    CGSize pipSize;	//size of the pips on the grid;
    CCArray *pips;	//array of all existing pips
    CGSize waitingPipSize;	//size of the pips waiting to be placed
    
    CCArray *currentSymbols;

    ccColor4B backgroundColor;
    CCLayerColor *boardLayerColor;

    int deltaScore;
    CCLayerColor *scoreLayer;
    CCLabelTTF *scoreLabel;
    CCLabelTTF *highScoreLabel;
    CCLabelTTF *waitLabel;

    BOOL isReady;	//board is ready to receive a touch; set to NO to prevent touches coming too fast or to lock board when a level is finished
    BOOL levelIsFinished;   //touches began tests this
    BOOL waitingForTouchAfterCompletion;
    CCLabelTTF *emptyBoardBonusLabel;
    CCLayerColor *bonusLabelBackground;

    CCSprite *marker;	//marker square indicates active pip
    CCSprite *starMarker;   //marker when star is active pip
    CCSprite *bombMarker;   //marker when bomb is active pip
    Pip *activePip;	//the pip that will be placed next
    Pip *unwantedPip;  //the pip that is being put in the shredder

    struct waitCell {
        CGPoint location;
        Pip *thePip;	//nil if empty
        int pipColor;
        int pipShape;
    } wait1, wait2, wait3, wait4;	//wait1 is the bottom one. wait4 is off the screen at the top

    CCSprite *shredderBottomLayer, *shredderTopLayer;
    CCSprite *chips;
    float shreddingDuration;        //duration of the shredding animations
    CGPoint shredderSlot;           //the slot of the shredder, the pip moves here first, then down
    CGPoint shredderInnerTop;       //top of shredder bin, the shredding fall from here
    CGPoint shredderInnerBottom;    //bottom of shredder bin, the chips sit here
    CGPoint shredderCenter;         //center of the shredder
    CGFloat shredderFeetHeight;     //used to adjust the other shredder points up
    int shredderNumber;
    int shredderCapacity;
    CCLabelTTF *shredderFullLabel;
    float chipsScaleX;  //scale chips to just fit the width of the shredder
    CCSprite *lightOn;
    CCSprite *lightOff;
    
    CGPoint bombLocation;
    Pip *bombPip;
    CCLabelTTF *bombQuantityLabel;
    CCSequence *explosionSequence;
    
    CGPoint starLocation;
    Pip *starPip;
    CCLabelTTF *starQuantityLabel;
    CCLabelTTF *starCostLabel;
    int oldStarCost;    //save the previous value for use in undo
    BOOL waitForPlaceStarSound;
    BOOL replaceStar;
    
    CGPoint productDeliveryLocation;

    int effectCount;
    int maxEffectCount; //doDarkenActions sets to number of pips being cleared
    int countdown;
    
    struct gridCell {	//square[0] is at the top left; index increases left-to-right top-to-bottom
        int up;		//square number (index) of the cell above this one (EDGE if this is a border cell)
        int down;
        int left;	//square number (index) of the cell left of this one (EDGE if this is a border cell)
        int right;
        int darkness;	//0 = lightest shade
        Pip *thePip;    //pointer to the pip sitting on this square, nil if no pip
        CCSprite *theTargetMarker;
        int pipColor;
        int pipShape;
        CCLayerColor *theDarkLayer;
        CCLabelBMFont *theDarknessLabel;
        CGPoint location;	//position of the center of this cell
    } square[MAXROWS * MAXCOLUMNS];

    enum namedLocation {
        none, w1, w2, w3, star, bomb 
    } activeSpot, cameFromSpot;
    
    CGPoint lastLocationMovedTo;	//for undo
    Pip *lastPipMoved;	//used for undo; nil if none
    int lastSquareCovered;	//for undo; when we undo from placing on grid this is the square; -1 if not on grid; also for explosion action

    CCMenuItemImage *undoButton;

    NSString *msgALine1, *msgALine2, *msgBLine1, *msgBLine2;
    BOOL ASwapState, BSwapState;
    CCLabelTTF *busyIndicator;
    
    int touchedSquareIdx;   //set in ccTouchesBegan:withEvent: and possibly used in alertView
    enum {
        shakeAlertViewTag,
        bombAlertViewTag
    } alertViewTags;
    
    BOOL waitingForTutorial0Tap;
    BOOL newHighBannerWasShown;
    BOOL alertViewIsShowing;
    BOOL emptyBoardBonusInProgress;
    BOOL undoShouldIncreaseShredderNumber;
    BOOL completionSoundPlayed; //shouldn't be needed; Use it instead of figuring out why it plays twice
    
    Store *store;
    SKProduct *productRequestedFromAppStore;
    SKPaymentTransaction *pendingTransaction;
    NSString *productTypeString;    //@"stars", @"bombs", or nil
    NSInteger productQuantity;
    PopUpView *deliveryMessageView;
    UIView *scrim;
    
        //for tutorials - move source is always on
    BOOL showValidSquares;
    BOOL squaresOn;
    BOOL detectShakeIsOn;
    BOOL waitingForSimulatorShake;
    BOOL shredderOn;
    BOOL moveSourceMarkerOn;
    BOOL starsOn;
    BOOL bombsOn;
    BOOL viewPurchaseMenuOn;
    CCLabelTTF *useStarLabel;
    CCLabelTTF *useBombLabel;
    CCLabelTTF *viewPurchaseMenuLabela;
    CCLabelTTF *viewPurchaseMenuLabelb;
    CCLabelTTF *darkenAllSquaresLabel;
    NSInteger tutorial3Count;
    CCSprite *shredderTargetMarker;
}

@property (nonatomic, assign) BOOL isReady;

+(id) boardScene;
-(id) setupBoard;
-(void) setupGrid;	//the squares that make up the board
-(void) ccTouchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
-(void) undoAction;
-(void) moveToShredder;
-(void) removePip:(id)sender data:(id)thePip;
-(void) decrementShredderNumber;
-(void) incrementShredderNumber;
-(void) decrementShredderIfNotFull;   //decrement shredderNumber if this move didn't fill a row or column
-(void) emptyShredder;
-(BOOL) validSquareExistsForPip:(Pip *)pip;
-(void) checkIfMoveIsAvailable;
-(void) descendingPing;
-(float) fractionOfPipsInSameRowOrColumn:(int)squareID;
-(void) placePipOnSquare:(int)squareID;
-(void) moveWaitingPipsUp;
-(void) doBombAnimation;
-(void) doExplosionAction;
-(void) doShredActionWithColor:(id)sender data:(void *)data;
-(void) moveEaseInOut:(Pip *)thePip inTime:(float)t to:(CGPoint)toLocation;
-(void) moveEaseBounceOut:(Pip *)thePip inTime:(float)t to:(CGPoint)toLocation;
-(void) feedPip;	//either fill wait positions or move down
-(void) makeStarOnCenterSquare;
-(void) makePipOn4;
-(Pip *) makePipAt:(CGPoint)location colorNumber:(int)colorNumber shapeNumber:(int)shapeNumber;
-(BOOL) pip:(Pip *)pip isOkOnSquare:(int)squareID;
-(void) darkenFullRowOrColumn;
-(void) doDarkenActionsOnSquares:(CCArray *)squaresToBeCleared;
-(void) doEmptyBoardBonus;
-(int) starCost;
-(void) popUpScore:(NSNumber *)amount;
-(void) flipAndUpdateScore:(NSNumber *)amount;
-(void) squareInstantAction:(id)node data:(void *)data;
-(void) setLayerColor:(CCLayerColor *)layer index:(int)index;
-(void) checkIfLevelCompleted;
-(void) levelCompleted;
//-(void) nextScene:(id)sender data:(void *)data;
-(void) nextScene;
-(void) changeToRatingsScene;
-(void) swapStringA;
-(void) swapStringB;
//-(void) printSquares;
-(void) makeReady;
-(void) makeUnReady;
-(void) signalBackgroundTouch;	//play sound to indicate touch on background
-(void) flashWait;
-(void) endFlash;
-(void) showStar:(BOOL)show;
-(void) showBomb:(BOOL)show;
-(void) showValidSquaresForPip:(Pip *)pip;
-(void) setShake:(BOOL)onOff;

    //update number of bombs label
-(void) incrementBombQuantity;
-(void) decrementBombQuantity;

    //update number of stars label
-(void) incrementStarQuantity;
-(void) decrementStarQuantity;

-(void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
//-(void) update:(ccTime)delta;

-(void) completeSuccessfulTransaction:(SKPaymentTransaction *)transaction;
-(void) completeFailedTransaction:(SKPaymentTransaction *)transaction;
-(void) notifyProductHasArrivedForTransaction:(SKPaymentTransaction *)transaction;
-(void) deliverProducts;

-(void) uponNotification:(NSNotification *)n1 withExpectedName:(NSString *)expectedName
setReceiverForName:(NSString *)newName target:(id)target selectorName:(NSString *)selName;

-(void) tutorial20a:(NSNotification *)notification;
-(void) tutorial20b:(NSNotification *)notification;
-(void) tutorial21a:(NSNotification *)notification;
-(void) tutorial21b:(NSNotification *)notification;
-(void) tutorial22a:(NSNotification *)notification;
-(void) tutorial22b:(NSNotification *)notification;
-(void) tutorial23a:(NSNotification *)notification;

@end
