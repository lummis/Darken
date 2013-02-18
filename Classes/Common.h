    //
    //  Common.h
    //  Fireworks Fun
    //
    //  Created by Robert Lummis on 8/9/2011
    //

#import "RootViewController.h"

@class Board;
@class Model;
@class Tutor;
@class ChoiceScene;
@class TitleScene;

    //Common is a singleton. It holds "global" values used by other classes
@interface Common : NSObject
{
    int level_;  //this is what board uses to know what level to set up
}
    //nag
@property (nonatomic, assign) BOOL networkIsAvailable;
@property (nonatomic, assign) BOOL nagNow;
@property (nonatomic, assign) BOOL userDidRate;
@property (nonatomic, assign) int sessionsSinceNag;
@property (nonatomic, assign) int highsSinceNag;
@property (nonatomic, assign) BOOL userSaidNoNag;

@property (nonatomic, assign) BOOL standardUserDefaultsIsCorrupted;
@property (nonatomic, assign) int nCorruptions;
@property (nonatomic, retain) Model *modelP;
@property (nonatomic, retain) Board *boardP;
@property (nonatomic, retain) TitleScene *titleSceneP;
@property (nonatomic, retain) ChoiceScene *choiceSceneP;
@property (nonatomic, retain) RootViewController *rvcP;

@property (nonatomic, retain) NSDate *launchTime;   //when program starts - set in Model /launch
@property (nonatomic, retain) NSDate *playStartTime;    //when board scene starts - set in board
@property (nonatomic, retain) NSDate *playEndTime;      //when we leave board scene - set in appDelegate and Model
@property (nonatomic, assign) NSTimeInterval playDeltaTime;

@property (nonatomic, assign) int sessionNumber;
@property (nonatomic, assign) int level;
@property (nonatomic, assign) int levelForStart;
@property (nonatomic, assign) int levelJustCompleted;
@property (nonatomic, assign) int numberOfLevels;
@property (nonatomic, assign) int nRows;
@property (nonatomic, assign) int nColumns;
@property (nonatomic, assign) int score;
@property (nonatomic, assign) int bonus;
@property (nonatomic, assign) int nColors;
@property (nonatomic, assign) int nShapes;
@property (nonatomic, assign) int levelUnlocked;
@property (nonatomic, assign) int newHighLevel;
@property (nonatomic, assign) BOOL clappingFlag;
@property (nonatomic, assign) BOOL newLevelUnlocked;
@property (nonatomic, assign) int loudnessNumber;
@property (nonatomic, assign) int choiceCode;
@property (nonatomic, assign) int resets;
@property (nonatomic, retain) NSDate *levelStartTime;
@property (nonatomic, assign) int starCost;
@property (nonatomic, assign) int smartCode;
@property (nonatomic, assign) BOOL showStar;
@property (nonatomic, assign) int starsOnHand;
@property (nonatomic, assign) int starsSavedDuringTutorial;
@property (nonatomic, assign) int starsUsed;            //cumulative total, never resets
@property (nonatomic, assign) int starsUsedThisPlay;    //starts at 0 on each play
@property (nonatomic, assign) BOOL showBomb;
@property (nonatomic, assign) int bombsOnHand;
@property (nonatomic, assign) int bombsSavedDuringTutorial;
@property (nonatomic, assign) int bombsUsed;            //cumulative total, never resets
@property (nonatomic, assign) int bombsUsedThisPlay;    //starts at 0 on each play
@property (nonatomic, assign) int movesThisPlay;        //starts at 0 on each play
@property (nonatomic, assign) int smart;
@property (nonatomic, assign) BOOL developerParameters;
@property (nonatomic, assign) BOOL completedFlag;
@property (nonatomic, assign) int rating;
@property (nonatomic, assign) int seed; //checksum in NSUserDefaults file
@property (nonatomic, retain) NSString *buildStringFromDefaults;
@property (nonatomic, assign) BOOL preselectToken;
@property (nonatomic, retain) NSString *installationUUID;
@property (nonatomic, assign) int hoursFromGMT;
@property (nonatomic, assign) BOOL accelerometerWasEnabled; //affects makeReady

    //for achievements
@property (nonatomic, assign) int finishWithEmptyGridCount;

    //tutorial flags
//@property (nonatomic, assign) BOOL darkenAllTutorialInProgress;
@property (nonatomic, assign) BOOL tutorialsEnabled;
@property (nonatomic, assign) BOOL level1TutorialsCompleted;
@property (nonatomic, assign) BOOL level2TutorialsCompleted;

@property (nonatomic, retain) CCArray *bestScores;  //update in Model; best score of all plays for level
@property (nonatomic, retain) CCArray *totalScores; //update in Model; total of all plays for level
@property (nonatomic, retain) CCArray *levelStarts; //update in Board
@property (nonatomic, retain) CCArray *levelCompletions;    //update in Model
@property (nonatomic, retain) CCArray *levelQuits;  //exit by shaking or power off
@property (nonatomic, retain) CCArray *levelMoves;  //update in Model
@property (nonatomic, retain) CCArray *levelTime;   //update in Model

@property (nonatomic, retain) NSMutableDictionary *showMessageAgain;    //whether to show messages @"YES" or @"NO"
@property (nonatomic, assign) BOOL nowInBoardScene;   //determines if exit on home button & which msg queue to use
@property (nonatomic, assign) BOOL nowInChoiceScene;
@property (nonatomic, assign) BOOL nowInSettingsScene;
@property (nonatomic, retain) CCArray *boardSceneMessageQueue;
@property (nonatomic, retain) CCArray *choiceSceneMessageQueue;
@property (nonatomic, assign) BOOL messageQueueBeingShown;
@property (nonatomic, assign) BOOL messageIsShowing;
@property (nonatomic, retain) NSArray *bombProductArray;
@property (nonatomic, retain) NSArray *starProductArray;
      //array of SKProduct objects with properties: 
      //   .localizedTitle
      //   .localizedDescription
      //   .price
      //   .productIdentifier

+(Common *)sharedCommon;

@end