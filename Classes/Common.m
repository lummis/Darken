    //
    // Common.m
    // Darken
    //
    // Created by Robert Lummis on 8/9/2011
    //

#import "Common.h"

static Common *sharedCommon = nil;

@implementation Common

@synthesize networkIsAvailable;
@synthesize nagNow;
@synthesize userDidRate;
@synthesize sessionsSinceNag;
@synthesize highsSinceNag;
@synthesize userSaidNoNag;

@synthesize standardUserDefaultsIsCorrupted;
@synthesize nCorruptions;
@synthesize modelP;
@synthesize boardP;
@synthesize titleSceneP;
@synthesize choiceSceneP;
@synthesize rvcP;

@synthesize launchTime;
@synthesize playStartTime;
@synthesize playEndTime;
@synthesize playDeltaTime;

@synthesize sessionNumber;
@synthesize levelForStart;
@synthesize levelJustCompleted;
@synthesize numberOfLevels;
@synthesize nRows;
@synthesize nColumns;
@synthesize score;
@synthesize bonus;
@synthesize nColors;
@synthesize nShapes;
@synthesize levelUnlocked;
@synthesize newHighLevel;
@synthesize clappingFlag;
@synthesize newLevelUnlocked;
@synthesize loudnessNumber;
@synthesize choiceCode;
@synthesize resets;
@synthesize levelStartTime;
@synthesize starCost;
@synthesize smartCode;
@synthesize showStar;
@synthesize starsOnHand;
@synthesize starsSavedDuringTutorial;
@synthesize starsUsed;
@synthesize starsUsedThisPlay;
@synthesize bombsOnHand;
@synthesize bombsSavedDuringTutorial;
@synthesize showBomb;
@synthesize bombsUsed;
@synthesize bombsUsedThisPlay;
@synthesize movesThisPlay;
@synthesize smart;
@synthesize developerParameters;
@synthesize completedFlag;
@synthesize rating;
@synthesize seed;
@synthesize buildStringFromDefaults;
@synthesize preselectToken;
@synthesize installationUUID;
@synthesize hoursFromGMT;
@synthesize accelerometerWasEnabled;

    //for achievements
@synthesize finishWithEmptyGridCount;

    //tutorial flags
//@synthesize darkenAllTutorialInProgress;
@synthesize tutorialsEnabled;
@synthesize level1TutorialsCompleted;
@synthesize level2TutorialsCompleted;

@synthesize bestScores;
@synthesize totalScores;
@synthesize levelStarts;
@synthesize levelCompletions;
@synthesize levelQuits;
@synthesize levelMoves;
@synthesize levelTime;

@synthesize showMessageAgain;
@synthesize nowInBoardScene;
@synthesize nowInChoiceScene;
@synthesize nowInSettingsScene;

@synthesize boardSceneMessageQueue;
@synthesize choiceSceneMessageQueue;
@synthesize messageQueueBeingShown;
@synthesize messageIsShowing;
@synthesize bombProductArray;
@synthesize starProductArray;

-(void) dealloc {
    [super dealloc];
}

+ (Common *)sharedCommon {
    @synchronized(self) {
        if (sharedCommon == nil) {
                //autorelease for analyzer
            [[[self alloc] init] autorelease]; // assignment not done here
        }
    }
    return sharedCommon;	
}

+ (id)allocWithZone:(NSZone *)zone {
    
    @synchronized(self) {
        if (sharedCommon == nil) {
        	sharedCommon = [super allocWithZone:zone];

                //Do variable initialize stuff here, if you need
            
        	return sharedCommon;  // assignment and return on first allocation
        }
    }
    return nil; //on subsequent allocation attempts return nil	
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

//
//- (void)release {
//        //do nothing	
//}

- (id)autorelease {
    return self;	
}

-(int) level {
    return level_;
}

-(void) setLevel:(int)level {
    level_ = level;
}

@end