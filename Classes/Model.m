    //
    // Darken
    // Model.m created 8/15/2011 by Robert Lummis
    //


#import "Model.h"
#import "ChoiceScene.h"
#import "DeveloperScene.h"
#import "LoadBoardScene.h"
#import "Board.h"
#import "CCArray+Replace.h"
#import "TitleScene.h"
#import "GuideScene.h"
#import "RootViewController.h"
#import "DarkenAppDelegate.h"
#import "RatingsScene.h"
#import "MessageManager.h"
#import "RLGameCenter.h"
#import "LocalyticsSession.h"

    /*
     min. number of colors needed to avoid the degenerate solution in which 
     each color is assigned to an alternate row (or column)
        5 rows:4 colors
        6 rows:4 colors
        7 rows:5 colors
        8 rows:5 colors
        9 rows:6 colors
       10 rows:6 colors
    make nShapes = MAX (rows, columns)
     */

parameters parameterValues[] = {
    
/*  lvl row col clr shp bmb str smt  */
    { 1,  5,  5,  3,  3,  0,  0,  3},   //tutorial 4 assumes the board is 5 x 5
    { 2,  5,  7,  4,  5,  1,  1,  0},
    { 3,  6,  7,  6,  7,  1,  1,  0},
    { 4,  7,  7,  6, 10,  1,  1,  0},
    { 5,  7,  8,  7, 13,  1,  1,  0},
    { 6,  8,  8,  8, 16,  1,  1,  0},
    { 7,  8,  9,  9, 18,  1,  1,  0},
    { 8,  8,  9,  9, 21,  1,  1,  0},
    { 9,  8,  9,  9, 24,  1,  1,  0},
    {10,  8,  9,  9, 28,  1,  1,  0}
};

NSInteger difficulty( NSInteger, NSInteger, NSInteger, NSInteger, NSInteger,
                     NSInteger, NSInteger, int, CCArray*, CCArray*, CCArray* );

@implementation Model

-(void) dealloc {
    [super dealloc];    
}

-(id) init {
    self = [super init];
    retinaDisplay = [self hasRetinaDisplay];
    return self;
}

-(BOOL) hasRetinaDisplay {
    return ([[UIScreen mainScreen] respondsToSelector:@selector(displayLinkWithTarget:selector:)] && ([UIScreen mainScreen].scale == 2.0))?1:0;
}

-(void) launch {
    ANNOUNCE
    
    /*****  this was moved here from appDelegate *****/
    
        //initialize game variables if this is the first launch or if game
        //was "reset" which can be done by setting choiceCode to cReset
        //or if defaults file was corrupted
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        //if corrupted, choiceCode is set to cReset by alertView:clickedButtonAtIndex:
        //and nCorruptions ("c") was incremented
        //and both were synchronized to the defaults file
    
    if ( cReset == [defaults integerForKey:@"choiceCode"] ) {
        CCLOG(@"initializing for first launch or after reset");
        X.standardUserDefaultsIsCorrupted = NO;
        X.numberOfLevels = NUMBEROFLEVELS;
        [defaults setInteger:X.numberOfLevels     forKey:@"numberOfLevels"];
        int resets = [defaults integerForKey:@"r"];    //was set to -1 in appDelegate
        [defaults setInteger:++resets             forKey:@"resets"];    //resets initially 0
        [defaults setBool:NO                      forKey:@"tutorialsEnabled"];
        [defaults setBool:NO                      forKey:@"level1TutorialsCompleted"];
        [defaults setBool:NO                      forKey:@"level2TutorialsCompleted"];
        [defaults setInteger:1                    forKey:@"level"];
        [defaults setInteger:1                    forKey:@"levelForStart"];
        [defaults setInteger:1                    forKey:@"levelJustCompleted"];
        [defaults setInteger:1                    forKey:@"levelUnlocked"];
        [defaults setInteger:DEFAULTLOUDNESS      forKey:@"loudnessNumber"];
        [defaults setBool:NO                      forKey:@"preselectToken"];
        [defaults setInteger:0                    forKey:@"finishWithEmptyGridCount"];
        [defaults setInteger:0                    forKey:@"starsUsed"];
        [defaults setInteger:0                    forKey:@"bombsUsed"];
        
            //bombs and stars are reset to original values (IAPs are lost)
        [defaults setInteger:ORIGINALSTARSONHAND  forKey:@"starsOnHand"];
        [defaults setInteger:ORIGINALBOMBSONHAND  forKey:@"bombsOnHand"];
        
            //store arrays of NSNumbers into defaults, all set to zeros
            //defaults requires NSArrays, the singleton Common requires (I think) CCArrays
            //when these arrays are read from defaults they are not mutable
        CCArray *highScores =        [CCArray arrayWithCapacity:X.numberOfLevels];
        CCArray *totalScore =        [CCArray arrayWithCapacity:X.numberOfLevels];
        CCArray *levelStarts =       [CCArray arrayWithCapacity:X.numberOfLevels];   //times started
        CCArray *levelCompletions =  [CCArray arrayWithCapacity:X.numberOfLevels];   //times completed
        CCArray *levelQuits =        [CCArray arrayWithCapacity:X.numberOfLevels];   //times quit by shaking or power off
        CCArray *levelMoves =        [CCArray arrayWithCapacity:X.numberOfLevels];   //moves in level
        CCArray *levelTime =         [CCArray arrayWithCapacity:X.numberOfLevels];   //minutes in level
        
        for (int i = 0; i < X.numberOfLevels; i++) {
            [highScores         addObject:[NSNumber numberWithInteger:0]];
            [totalScore         addObject:[NSNumber numberWithInteger:0]];
            [levelStarts        addObject:[NSNumber numberWithInteger:0]];
            [levelCompletions   addObject:[NSNumber numberWithInteger:0]];
            [levelQuits         addObject:[NSNumber numberWithInteger:0]];
            [levelMoves         addObject:[NSNumber numberWithInteger:0]];
            [levelTime          addObject:[NSNumber numberWithInteger:0]];
        }
        
        [defaults setObject:[highScores getNSArray]              forKey:@"highScores"];
        [defaults setObject:[totalScore getNSArray]              forKey:@"totalScore"];
        [defaults setObject:[levelStarts getNSArray]             forKey:@"levelStarts"];
        [defaults setObject:[levelCompletions getNSArray]        forKey:@"levelCompletions"];
        [defaults setObject:[levelQuits getNSArray]              forKey:@"levelQuits"];
        [defaults setObject:[levelMoves getNSArray]              forKey:@"levelMoves"];
        [defaults setObject:[levelTime getNSArray]               forKey:@"levelTime"];
        
        NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
        [defaults setObject:[infoDict objectForKey:@"CFBundleVersion"]  forKey:@"buildString"]; //build number
        
        NSMutableDictionary *showMessageAgain = [NSMutableDictionary dictionaryWithCapacity:1];
        [showMessageAgain setObject:@"One" forKey:@"key1"];
        [defaults setObject:showMessageAgain                            forKey:@"showMessageAgain"];
        
        [defaults synchronize];
    }
    
    /*****                              *****/
    
    [self getDefaults];
    
    X.launchTime = [NSDate date];
    
    if (X.choiceCode != cReset && NO == [self commonIsValid]) {
        NSLog(@"Common is CORRUPTED");
        X.standardUserDefaultsIsCorrupted = YES;
//        [self corruptionRestart];
    } else {
        X.standardUserDefaultsIsCorrupted = NO;
        CCLOG(@"Common OK");
    }
    
        //debug
    CCLOG( @"initializeDate: %@", [defaults objectForKey:@"initializeDate"] );
    CCLOG( @"initializeTime: %@", [defaults objectForKey:@"initializeTime"] );
    CCLOG( @"hoursFromGMT: %@", [defaults objectForKey:@"h"] );
    
    X.newLevelUnlocked = NO;
    X.choiceSceneMessageQueue = [CCArray arrayWithCapacity:3];
    X.boardSceneMessageQueue = [CCArray arrayWithCapacity:3];

    
    RootViewController *rvc = [((DarkenAppDelegate *)[[UIApplication sharedApplication] delegate]) viewController];
    X.rvcP = rvc;
    
        //store message texts on every startup. setMessage also sets show to YES
        //keep delays short here so this message doesn't block another one triggered in Board
    
    [[MessageManager sharedManager] setMessageWithTitle:@"Advisory: Not a Valid Square"  text:@"The active pip can't be put on that square. It must be put next to another pip with a matching shape or color, or next to a star. A star can be put on any empty square." type:@"checkbox" key:@"buzzing" delay:0.3f];
    
    [[MessageManager sharedManager] setMessageWithTitle:@"Advisory: Start Again" text:[NSString stringWithFormat:@"None of these pips can be placed on the grid and the shredder is full so you will have to start over. Return to the Level Selection screen by shaking your %@.", [[UIDevice currentDevice] model]] type:@"checkbox" key:@"startAgain" delay:0.3f];
    
    [[MessageManager sharedManager] setMessageWithTitle:@"Advisory: No Score" text:@"You failed to complete the last level so you get no score. Try again!" type:@"checkbox" key:@"noScore" delay:0.8f];
    
    [[MessageManager sharedManager] setMessageWithTitle:@"Advisory: No Move" text:[NSString stringWithFormat:@"None of the waiting pips can be placed on the grid and the shredder is full. You must use a small star or a bomb to clear some space or shake the %@ to return to the level selection screen and start again.", [[UIDevice currentDevice] model]] type:@"checkbox" key:@"useSupplyOrShake" delay:0.8f];
    
    [[MessageManager sharedManager] setMessageWithTitle:@"Advisory: Shredder is Full" text:@"The shredder holds only three pips and now it is full. If you can't put any of the waiting pips onto the grid you must either user a star or bomb to make a valid square or shake the device to start over." type:@"checkbox" key:@"useShredderWhenFull" delay:0.5f];
    
    [[MessageManager sharedManager] setMessageWithTitle:@"Advisory: Get more stars" text:@"To get more stars double tap on the star pile." type:@"checkbox" key:@"getStars" delay:0.5f];
    
    [[MessageManager sharedManager] setMessageWithTitle:@"Advisory: Get more bombs" text:@"To get more bombs double tap on the bomb pile." type:@"checkbox" key:@"getBombs" delay:0.5f];
    
    CCLOG(@"Printing common in model/launch");
    [self printCommonFull];
    X.developerParameters = NO;
    
        //initialize so count is valid if SKProductsRequest gets no response
    X.starProductArray = [NSMutableArray arrayWithObjects:nil];
    X.bombProductArray = [NSMutableArray arrayWithObjects:nil];
    
#if TARGET_IPHONE_SIMULATOR
    
    CCLOG(@"The iphone simulator CANNOT make payments");
    
#else
    
    NSSet *bombProductIdentifiers = [NSSet setWithObjects:
                                   @"com.electricTurkey.bombs1_7",
                                   @"com.electricTurkey.bombs3_25",
                                   @"com.electricTurkey.bombs5_50",
                                   nil];
    bombProductsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:bombProductIdentifiers];
        //release in productsRequest: didReceiveResponse:
    bombProductsRequest.delegate = self;
    [bombProductsRequest start];
    
    NSSet *starProductIdentifiers = [NSSet setWithObjects:
                                     @"com.electricTurkey.stars1_6",
                                     @"com.electricTurkey.stars3_22",
                                     @"com.electricTurkey.stars5_50",
                                     nil];
    
    starProductsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:starProductIdentifiers];
        //release in productsRequest: didReceiveResponse:
    starProductsRequest.delegate = self;
    
    [starProductsRequest start];
    
    if ( [SKPaymentQueue canMakePayments] == YES ) {
        CCLOG(@"This device CAN make payments");
    } else {
        CCLOG(@"This device CANNOT make payments");
    }
    
#endif
    
    finishedTagString = @"not initialized";       //for localytics reporting
    
    CCDirector *director = [CCDirector sharedDirector];
    if ( [director runningScene] ) {
        [director replaceScene:[TitleScene scene]];
    } else {
        [director runWithScene:[TitleScene scene]];
    }
}


-(void) productsRequest:(SKProductsRequest *)productsRequest didReceiveResponse:(SKProductsResponse *)response {
    ANNOUNCE
    
    CCLOG(@"productsRequest: %@", productsRequest);
    if (productsRequest == bombProductsRequest) {
        X.bombProductArray = [response products];
        for (SKProduct *product in X.bombProductArray) {
            CCLOG(@"product.localizedTitle: %@", product.localizedTitle);
            CCLOG(@"product.localizedDescription: %@", product.localizedDescription);
            CCLOG(@"product.price: %@", product.price);
            CCLOG(@"product.productIdentifier: %@\n\n", product.productIdentifier);
        }
        
        for (NSString *invalidProduct in response.invalidProductIdentifiers) {
            CCLOG(@"Invalid: %@", invalidProduct);
        }
    } else if (productsRequest == starProductsRequest) {
        X.starProductArray = [response products];
        CCLOG(@"[X.starProductArray count]: %d", [X.starProductArray count] );
        for (SKProduct *product in X.starProductArray) {
            CCLOG(@"product.localizedTitle: %@", product.localizedTitle);
            CCLOG(@"product.localizedDescription: %@", product.localizedDescription);
            CCLOG(@"product.price: %@", product.price);
            CCLOG(@"product.productIdentifier: %@\n\n", product.productIdentifier);
        }
        
        for (NSString *invalidProduct in response.invalidProductIdentifiers) {
            CCLOG(@"Invalid: %@", invalidProduct);
        }
    } else {
        CCLOG(@"unexpected productRequest");
    }
    [productsRequest release];  // this is the same object alloc'ed in launch
    X.networkIsAvailable = YES;
}


-(void) setParameters {
    ANNOUNCE
    if (X.developerParameters == YES) {
        return;
    }
    CCLOG(@"setting parameters for level %d", X.level);
    
    for (int i = 0; i < X.numberOfLevels; i++) {
        p[i] = parameterValues[i];
    }
    
    int i = MIN(X.level - 1, X.numberOfLevels - 1);  //use params for X.numberOfLevels if X.level is higher
    X.nRows = p[i].rows;
    X.nColumns = p[i].columns;
    X.nColors = p[i].colors;
    X.nShapes = p[i].shapes;
    X.showStar = p[i].stars ? YES : NO;
    X.showBomb = p[i].bombs ? YES : NO;
    X.smart = p[i].smart;
    
        //over ride if PIPREVIEWFLAG
        //10x8 grid for viewing all pips
    if (PIPREVIEWFLAG == YES) {
        X.nRows = 8;
        X.nColumns = 10;
        X.nColors = 8;
    }
}

-(parameters) parametersForLevel:(int)level {
    return parameterValues[level - 1];
}

-(void) outputParametersAll {
        //write current parameters to file ~/Documents/parameters-all.txt
    NSString *path = [@"~/Documents/parameters-all.txt" stringByExpandingTildeInPath];
    BOOL success = [[NSFileManager defaultManager] createFileAtPath:path contents:nil attributes:nil];
    if (!!!success) {
        CCLOG(@"File not created at path: %@\n", path);
    }
    NSFileHandle *out = [NSFileHandle fileHandleForWritingAtPath:path];
    NSDate *today = [NSDate date];
    NSCalendar *gregorian=[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | 
    NSHourCalendarUnit | NSMinuteCalendarUnit;
    NSDateComponents *components = [gregorian components:unitFlags fromDate:today];
    [gregorian release];
    int day = [components day];
    int month = [components month];
        //    int year = [components year];
    int hour = [components hour];
    int minute = [components minute];
    NSString *timestamp = [NSString stringWithFormat:@"%02d/%02d %02d:%02d\n", month, day, hour, minute];
    [out writeData:[timestamp dataUsingEncoding:NSUTF8StringEncoding]];
    [out writeData:[@" lvl  row col   clr shp   bmb str   smt   lvl\n" dataUsingEncoding:NSUTF8StringEncoding]];
    NSString *line = @"";
    for (int i = 0; i < X.numberOfLevels; i++) {
        line = [NSString stringWithFormat:@"%2d=>  %2d  %2d    %2d  %2d    %2@  %2@    %2d    <=%-2d\n", 
                p[i].level, 
                p[i].rows, p[i].columns, 
                p[i].colors, p[i].shapes, 
                p[i].bombs == 1 ? @" Y" : @"  ", 
                p[i].stars == 1 ? @" Y" : @"  ", 
                p[i].smart, 
                p[i].level];
        [out writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
        if (i%2 == 1) {
            [out writeData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
}

-(void) outputParametersForLevel:(int)level rating:(int)rating comment:(NSString *)comment {
    ANNOUNCE
    NSString *path = [@"~/Documents/ratings.txt" stringByExpandingTildeInPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL appending = YES;
    if (!!! [fileManager isWritableFileAtPath:path] ) {
        appending = NO;
        BOOL success = [fileManager createFileAtPath:path contents:nil attributes:nil];
        if (!!!success) {
            CCLOG(@"File not created at path: %@\n", path);
            kill( getpid(), SIGABRT );  //crash
        }
    }
    NSFileHandle *out = [NSFileHandle fileHandleForWritingAtPath:path];
    if (appending) {
        [out seekToEndOfFile];
    }
    
//    NSDate *today = [NSDate date];
//    NSCalendar *gregorian=[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
//    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | 
//    NSHourCalendarUnit | NSMinuteCalendarUnit;
//    NSDateComponents *components = [gregorian components:unitFlags fromDate:today];
//    int day = [components day];
//    int month = [components month];
//        //    int year = [components year];
//    int hour = [components hour];
//    int minute = [components minute];
//    NSString *timestamp = [NSString stringWithFormat:@"%02d/%02d %02d:%02d\n", month, day, hour, minute];
//    [out writeData:[timestamp dataUsingEncoding:NSUTF8StringEncoding]];
    if (!!! appending) {
        [out writeData:[@" lvl  row col   clr shp    bmb str   smt   rating comment\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    int i = level - 1;
    NSString *line = [NSString stringWithFormat:@"%2d    %2d  %2d    %2d  %2d    %2@  %2@    %2d  %2d   %@\n", 
            p[i].level, 
            p[i].rows, p[i].columns, 
            p[i].colors, p[i].shapes, 
            p[i].bombs == 1 ? @" Y" : @"  ", 
            p[i].stars == 1 ? @" Y" : @"  ", 
            p[i].smart, 
            rating,
            comment];
    [out writeData:[line dataUsingEncoding:NSUTF8StringEncoding]];
}

-(void) start {
    ANNOUNCE
        // get here after Title scene or after interruption
    [self setParameters];
    if (DEVELOPERFLAG) {
        [self outputParametersAll];
    }
    
        //override for pip review
        //10x8 grid for viewing all pips
    if (PIPREVIEWFLAG == YES) {
        X.nRows = 8;
        X.nColumns = 10;
    }
    
    CCTransitionFade *tran;
    X.newLevelUnlocked = NO;
    CCLOG(@"debug: X.choiceCode: %d", X.choiceCode);
    if (X.choiceCode == cReset)     //game reset or this is first run
    {
        X.choiceCode = cLevel1;
        
    NSInteger computedDifficulty =  difficulty(X.hoursFromGMT,
                                               X.starsUsed,
                                               X.bombsUsed,
                                               X.resets,
                                               X.starsOnHand,
                                               X.bombsOnHand,
                                               X.nCorruptions,
                                               X.finishWithEmptyGridCount,
                                               X.bestScores,
                                               X.totalScores,
                                               X.levelCompletions
                                               );
    
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setInteger:computedDifficulty forKey:@"seed"];     //this is the real checksum
        [defaults setInteger:255                forKey:@"depth"];    //phony- subsequently random (128 - 255)
        [defaults setInteger:1                  forKey:@"aiNext"];   //phony- subsequently random (0 - 15)
        [defaults setInteger:0                  forKey:@"checksum"]; //phony- subsequently random (0 - 65535)

        tran = [CCTransitionFade transitionWithDuration:1.0f scene:[ GuideScene scene ]];
        CCLOG(@"tran = GuideScene");
    } else {
        tran = [CCTransitionFade transitionWithDuration:1.0f scene:[ ChoiceScene scene ]];
        CCLOG(@"tran = ChoiceScene");
    }
    [[CCDirector sharedDirector] replaceScene:tran];
}

-(void) completed {
    ANNOUNCE

    if (X.developerParameters == NO) {  //don't save parameters set in developer scene
        [self putDefaults];
    }

    X.choiceCode = cCompleted;
    X.score += X.bonus;
    
    if ( !!!(X.tutorialsEnabled && X.level < 3) ) {
        [self updateTotalScoresForLevel:X.level withScore:X.score];
        [self updateBestScoresForLevel:X.level withScore:X.score];
    }
    
    X.levelJustCompleted = X.level;
        //restore whatever quantity of supplies they had before starting level 2
    if ( X.level == 2 && X.tutorialsEnabled ) {
            //now finished with tutorials
        X.starsOnHand = X.starsSavedDuringTutorial;
        X.bombsOnHand = X.bombsSavedDuringTutorial;
        X.starsSavedDuringTutorial = -1;   //debug
        X.bombsSavedDuringTutorial = -1;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"endByCompleting" object:nil];
    }
    
    if (X.level == X.levelUnlocked && X.level < X.numberOfLevels) {
        X.newLevelUnlocked = YES;
            // X.level incremented in choiceScene
    }
    X.levelUnlocked = MIN( X.numberOfLevels, MAX( X.levelUnlocked, X.level + 1 ));
    
    [self incrementCountForLevel:X.level inCCArray:X.levelCompletions];  //must be before updateBestScoresForLevel

    int level10Completions = [[X.levelCompletions objectAtIndex:9] integerValue];
    CCLOG(@"level 10 completions: %d", level10Completions);
    if (X.level == 10 && level10Completions == 1) {
        [[RLGameCenter singleton] submitAchievement:@"com.electricturkey.darken.level10_1"     percentComplete:(double)100. showBanner:YES];
        CCLOG(@"achievement name: %@", @"com.electricturkey.darken.level10_1");
    }
    
    if (X.level == 10 && level10Completions <= 25) {
        double percent = (double)level10Completions / 25. * 100.;
        [[RLGameCenter singleton] submitAchievement:@"com.electricturkey.darken.level10_20"     percentComplete:percent showBanner:YES];
        CCLOG(@"achievement name: %@, percent: %g", @"com.electricturkey.darken.level10_20", percent);
        CCLOG(@"the above achievement is level 10 completed 25 times in spite of its name");
    }
    
    CCLOG(@"X.finishWithEmptyGridCount: %d", X.finishWithEmptyGridCount);
    if (X.finishWithEmptyGridCount == 1) {
        [[RLGameCenter singleton] submitAchievement:@"com.electricturkey.darken.emptyGrid_1"
                                    percentComplete:(double)100. showBanner:YES];
        CCLOG(@"achievement name: %@", @"com.electricturkey.darken.emptyGrid_1");
    }
    
    if (X.finishWithEmptyGridCount <= 25) {
        double percent = (double)X.finishWithEmptyGridCount / 25.f * 100.;
        [[RLGameCenter singleton] submitAchievement:@"com.electricturkey.darken.emptyGrid_25"
                                    percentComplete:percent showBanner:YES];
        CCLOG(@"achievement name: %@, percent: %g", @"com.electricturkey.darken.emptyGrid_25", percent);
    }
    
    finishedTagString = [NSString stringWithFormat:@"Completed Level %d", X.level];
    
    [self finishPlay];
}

-(void) endByShaking {
    if (X.tutorialsEnabled && ( X.level == 1 || X.level == 2 )) {
        X.starsOnHand = X.starsSavedDuringTutorial;
        X.bombsOnHand = X.bombsSavedDuringTutorial;
    }
    
    if (X.tutorialsEnabled && X.level == 1) {
            //shaking is part of the level 1 tutorial
        X.choiceCode = cTutorialLevel2;
    } else {
        X.choiceCode = cQuit;
        [self incrementCountForLevel:X.level inCCArray:X.levelQuits];
    }
    
    if(X.tutorialsEnabled && X.level == 2) {
        [[NSNotificationCenter defaultCenter] removeObserver:X.choiceSceneP];
        [[MessageManager sharedManager] enqueueMessageWithText:@"You have now seen all the tutorial messages but you didn't darken every square at level 2. To finish the level 2 tutorials fill rows or columns until every square is darkened at least once." title:@"Try level 2 again" delay:0.5f onQueue:X.choiceSceneMessageQueue];
    }
    
    finishedTagString = [NSString stringWithFormat:@"Failed level %d", X.level];
    
    [self finishPlay];
}

-(void) finishPlay {
    ANNOUNCE

    X.playDeltaTime += [[NSDate date] timeIntervalSinceDate:X.playStartTime];
    UInt32 minutesThisPlay = (UInt32)(X.playDeltaTime / 60.f + 0.5f);
    [self incrementTimeBy:minutesThisPlay forLevel:X.level];
    
    X.starsUsed += X.starsUsedThisPlay;
    X.bombsUsed += X.bombsUsedThisPlay;
    
    double percent;

    percent = X.starsUsed / 10. * 100.;
        //submitAchievement limits percent complete to 100.
    [[RLGameCenter singleton] submitAchievement:@"com.electricturkey.darken.useStar_10"
                                percentComplete:percent showBanner:YES];
    CCLOG(@"achievement name: com.electricturkey.darken.useStar_10, percent: %g", percent);
    
    percent = X.starsUsed / 100. * 100.;
    [[RLGameCenter singleton] submitAchievement:@"com.electricturkey.darken.useStar_100"
                                percentComplete:percent showBanner:YES];
    CCLOG(@"achievement name: com.electricturkey.darken.useStar_100, percent: %g", percent);
    
    percent = X.bombsUsed / 10. * 100.;
    [[RLGameCenter singleton] submitAchievement:@"com.electricturkey.darken.useBomb_10"
                                percentComplete:percent showBanner:YES];
    CCLOG(@"achievement name: com.electricturkey.darken.useBomb_10, percent: %g", percent);
    
    percent = X.bombsUsed / 100. * 100.;
    [[RLGameCenter singleton] submitAchievement:@"com.electricturkey.darken.useBomb_100"
                                percentComplete:percent showBanner:YES];
    CCLOG(@"achievement name: com.electricturkey.darken.useBomb_100, percent: %g", percent);
    
    int totalMoves = [[X.levelMoves objectAtIndex:(X.level - 1)] integerValue] + X.movesThisPlay;
    [X.levelMoves replaceObjectAtIndex:(X.level - 1) withObject:[NSNumber numberWithInteger:totalMoves]];
    
    if (X.level >= 3) {
        NSDictionary *d = [self localyticsAttributesWithLevel:X.level
                                                sessionNumber:(UInt32)X.sessionNumber
                                               moves:(UInt32)X.movesThisPlay
                                             minutes:(UInt32)minutesThisPlay
                                               score:(UInt32)X.score
                                           bestScore:(UInt32)[[X.bestScores objectAtIndex:X.level - 1] integerValue]
                                           starsUsed:(UInt32)X.starsUsedThisPlay
                                           bombsUsed:(UInt32)X.bombsUsedThisPlay];
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:finishedTagString attributes:d];
        CCLOG(@"tagEvent: %@, attributes: %@", finishedTagString, d);
    }
    
    CCTransitionFade *tran = [CCTransitionFade transitionWithDuration:0.5f scene:[ ChoiceScene scene ]];
    [[CCDirector sharedDirector] replaceScene:tran];
}

-(void) getRating {
    CCTransitionFade *tran = [CCTransitionFade transitionWithDuration:0.5f scene:[RatingsScene scene]];
    [[CCDirector sharedDirector] replaceScene:tran];

}

-(void) updateTotalScoresForLevel:(int)level withScore:(int)score {
    ANNOUNCE

    if (level < 3 && X.tutorialsEnabled) {
        return;
    }
    
    NSNumber *oldTotal = [X.totalScores objectAtIndex:(level - 1)];
    NSNumber *newTotal = [NSNumber numberWithInteger:[oldTotal integerValue] + score];
    [X.totalScores replaceObjectAtIndex:(level - 1) withObject:newTotal];
    
        // GAMECENTER
        //report sum of all scores to game center
    NSInteger sumOfTotalScores = 0;
    for (NSUInteger i = 0; i < X.numberOfLevels; i++) {
        sumOfTotalScores += [[X.totalScores objectAtIndex:i] integerValue];
    }
    NSString *leaderboardIdentifier = [kLeaderboardScoreBase stringByAppendingString:@".sum"];
    CCLOG(@"Board; reporting sum of all scores. leaderboardIdentifier: %@, value: %d", leaderboardIdentifier, sumOfTotalScores);
    [[RLGameCenter singleton] submitScore:(int64_t)sumOfTotalScores category:leaderboardIdentifier];
}

-(void) updateBestScoresForLevel:(int)level withScore:(int)score {
    ANNOUNCE

    if (level < 3 && X.tutorialsEnabled) {
        return;
    }
    
    X.newHighLevel = 0;
    if ( score > [[X.bestScores objectAtIndex:(level - 1)] integerValue] ) {
        [X.bestScores replaceObjectAtIndex:(level - 1) withObject:[NSNumber numberWithInteger:score]];
        
            //set newHighLevel only if this is not the first completion
        if ( [[X.levelCompletions objectAtIndex:(level - 1)] integerValue] > 1 ) {
            X.newHighLevel = level; //for choiceScene
            X.clappingFlag = YES;   //separate because clapping shouldn't happen when scrolling back to cell
            
            NSUInteger session = X.sessionNumber;
            NSString *sessionBin;
            if (session < 4) sessionBin = @"1 - 3";
            else if (session <= 10) sessionBin = @"4 - 10";
            else if (session <= 30) sessionBin = @"11 - 30";
            else if (session <= 100) sessionBin = @"31 - 100";
            else if (session <= 300) sessionBin = @"101 - 300";
            else sessionBin = @"> 300";
            
            NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                               sessionBin, @"Session Number",
                               [NSNumber numberWithInt:X.level], @"Level", nil];
            [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"New High" attributes:d];
        }
    }
        
        // GAMECENTER
    NSString *leaderboardIdentifier;
    NSUInteger best;
    leaderboardIdentifier = [kLeaderboardScoreBase stringByAppendingFormat:@".best%d", level];
    best = [[X.bestScores objectAtIndex:(level - 1)] integerValue];
        //report the best score for this level whether it changed or not
        //no leaderboard for levels below 3
    if (level >= 3) {
        CCLOG(@"Board; reporting best score for level %d; leaderboardIdentifier: %@, value: %d", level,
              leaderboardIdentifier, best);
        [[RLGameCenter singleton] submitScore:(int64_t)best category:leaderboardIdentifier];
    }

    NSInteger sumOfBestScores = 0;
    for (NSUInteger i = 0; i < X.numberOfLevels; i++) {
        sumOfBestScores += [[X.bestScores objectAtIndex:i] integerValue];
    }
    
    leaderboardIdentifier = [kLeaderboardScoreBase stringByAppendingString:@".sumofbest"];
    [[RLGameCenter singleton] submitScore:(int64_t)sumOfBestScores category:leaderboardIdentifier];

        //once per runtime; it doesn't matter if these achievements are submitted again
    static dispatch_once_t onceToken1k, onceToken10k, onceToken50k;
    if (sumOfBestScores > 50000) {
        dispatch_once(&onceToken50k, ^{
            [[RLGameCenter singleton] submitAchievement:@"com.electricturkey.darken.best_50k"
                                        percentComplete:(double)100. showBanner:YES];
        });
    }
    
    if (sumOfBestScores > 10000) {
        dispatch_once(&onceToken10k, ^{
            [[RLGameCenter singleton] submitAchievement:@"com.electricturkey.darken.best_10k"
                                        percentComplete:(double)100. showBanner:YES];
        });
    }
    
    if (sumOfBestScores > 1000) {
        dispatch_once(&onceToken1k, ^{
            [[RLGameCenter singleton] submitAchievement:@"com.electricturkey.darken.best_1k"
                                        percentComplete:(double)100. showBanner:YES];
        });
    }
    
}

-(void) incrementCountForLevel:(int)level inCCArray:(CCArray *)array {
    ANNOUNCE
    int former = [[array objectAtIndex:(level - 1)] integerValue];
    [array replaceObjectAtIndex:(level - 1) withObject:[NSNumber numberWithInteger:++former]];
}

-(void) decrementCountForLevel:(int)level inCCArray:(CCArray *)array {
    ANNOUNCE
    int former = [[array objectAtIndex:(level - 1)] integerValue];
    [array replaceObjectAtIndex:(level - 1) withObject:[NSNumber numberWithInteger:--former]];
}

-(void) incrementTimeBy:(NSTimeInterval)time forLevel:(int)level {
    int formerLevelTime = [[X.levelTime objectAtIndex:(level - 1)] integerValue];
    [X.levelTime replaceObjectAtIndex:(level - 1) 
                           withObject:[NSNumber numberWithInteger:(formerLevelTime + time)]];
}

-(float) gainForLoudnessNumber:(int)loudnessNumber {
    switch (loudnessNumber) {
        case 0:
            return 0.0f;
            break;
        case 1:
            return 0.04f;
            break;
        case 2:
            return 0.11f;
            break;
        case 3:
            return 0.33f;
            break;
        case 4:
            return 1.0f;
            break;
        default:
            CCLOG(@"in gainForLoudnessNumber: invalid loudnessNumber");
            kill( getpid(), SIGABRT );  //crash
            break;
    }
    return 0.33f;   //stops compiler warning
}

-(void) printCommonFull {   //debug
    ANNOUNCE
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CCLOG(@"initializationDate: %@",    [defaults stringForKey:@"initializationDate"] );
    CCLOG(@"hours from GMT: %d",        [defaults integerForKey:@"h"] );
    CCLOG(@"totalSessionTime: %d",      [defaults integerForKey:@"totalSessionTime"] );
    CCLOG(@"resets: %d",                X.resets);
    [self printCommon];
}

-(void) printCommon {   //debug
    ANNOUNCE
    CCLOG(@"sessionNumber: %d",         X.sessionNumber);
    CCLOG(@"resets: %d",                X.resets);
    CCLOG(@"level: %d",                 X.level);
    CCLOG(@"levelForStart: %d",         X.levelForStart);
    CCLOG(@"levelUnlocked: %d",         X.levelUnlocked);
    CCLOG(@"nRows: %d",                 X.nRows);
    CCLOG(@"nColumns: %d",              X.nColumns);
    CCLOG(@"nColors: %d",               X.nColors);
    CCLOG(@"nShapes: %d",               X.nShapes);
    CCLOG(@"loudnessNumber: %d",        X.loudnessNumber);
    CCLOG(@"score: %d",                 X.score);
    CCLOG(@"choiceCode: %d",            X.choiceCode);
    CCLOG(@"developerParameters: %d",   X.developerParameters);
    CCLOG(@"smart: %d",                 X.smart);
    CCLOG(@"starsOnHand: %d",           X.starsOnHand);
    CCLOG(@"starsUsed: %d",             X.starsUsed);
    CCLOG(@"bombsOnHand: %d",           X.bombsOnHand);
    CCLOG(@"bombsUsed: %d",             X.bombsUsed);
    CCLOG(@"preselectToken: %d",        X.preselectToken);
    CCLOG(@"showMessageAgain: %@",      X.showMessageAgain);

    CCLOG(@"  best total start compl quits moves  mins");
    for (int i = 0; i < X.numberOfLevels; i++) {
        CCLOG(@"%6d%6d%6d%6d%6d%6d%6d",
              [[X.bestScores        objectAtIndex:i] integerValue],
              [[X.totalScores       objectAtIndex:i] integerValue],
              [[X.levelStarts       objectAtIndex:i] integerValue],
              [[X.levelCompletions  objectAtIndex:i] integerValue],
              [[X.levelQuits        objectAtIndex:i] integerValue],
              [[X.levelMoves        objectAtIndex:i] integerValue],
              [[X.levelTime         objectAtIndex:i] integerValue]);
    }
    CCLOG(@"done printing common");
}

-(void) getDefaults {
    ANNOUNCE
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    X.installationUUID =        [defaults   objectForKey:@"installationUUID"];
    X.hoursFromGMT =            [defaults   integerForKey:@"h"];
    X.movesThisPlay =           [defaults   integerForKey:@"movesThisPlay"];
    X.bombsUsedThisPlay =       [defaults   integerForKey:@"bombsUsedThisPlay"];
    X.starsUsedThisPlay =       [defaults   integerForKey:@"starsUsedThisPlay"];
    X.playDeltaTime =           [defaults   doubleForKey:@"playDeltaTime"];
    X.nCorruptions =            [defaults   integerForKey:@"c"];
    X.numberOfLevels =          [defaults   integerForKey:@"numberOfLevels"];
    X.levelUnlocked =           [defaults   integerForKey:@"levelUnlocked"];
    X.sessionNumber =           [defaults   integerForKey:@"sessionNumber"];
    X.level =                   [defaults   integerForKey:@"level"];
    X.levelForStart =           [defaults   integerForKey:@"levelForStart"];
    X.levelJustCompleted =      [defaults   integerForKey:@"levelJustCompleted"];
    X.score =                   [defaults   integerForKey:@"score"];
    X.nRows =                   [defaults   integerForKey:@"rows"];
    X.nColumns =                [defaults   integerForKey:@"columns"];
    X.nColors =                 [defaults   integerForKey:@"colors"];
    X.nShapes =                 [defaults   integerForKey:@"shapes"];
    X.loudnessNumber =          [defaults   integerForKey:@"loudnessNumber"];
    X.choiceCode =              [defaults   integerForKey:@"choiceCode"];
    X.resets =                  [defaults   integerForKey:@"r"];
    X.starsOnHand =             [defaults   integerForKey:@"starsOnHand"];
    X.starsUsed =               [defaults   integerForKey:@"starsUsed"];
    X.bombsOnHand =             [defaults   integerForKey:@"bombsOnHand"];
    X.bombsUsed =               [defaults   integerForKey:@"bombsUsed"];
    X.seed =                    [defaults   integerForKey:@"seed"];
    X.buildStringFromDefaults = [defaults   objectForKey:@"buildString"];
    X.preselectToken =          [defaults   boolForKey:@"preselectToken"];
    X.finishWithEmptyGridCount = [defaults  integerForKey:@"finishWithEmptyGridCount"];
    
        //tutorial state
    X.tutorialsEnabled =            [defaults boolForKey:@"tutorialsEnabled"];
    X.level1TutorialsCompleted =    [defaults boolForKey:@"level1TutorialsCompleted"];
    X.level2TutorialsCompleted =    [defaults boolForKey:@"level2TutorialsCompleted"];
    
    X.levelTime = [CCArray arrayWithNSArray:            [defaults arrayForKey:@"levelTime"]];
    X.bestScores = [CCArray arrayWithNSArray:           [defaults arrayForKey:@"highScores"]];
    X.totalScores = [CCArray arrayWithNSArray:          [defaults arrayForKey:@"totalScore"]];
    X.levelStarts = [CCArray arrayWithNSArray:          [defaults arrayForKey:@"levelStarts"]];
    X.levelCompletions = [CCArray arrayWithNSArray:     [defaults arrayForKey:@"levelCompletions"]];
    X.levelQuits = [CCArray arrayWithNSArray:           [defaults arrayForKey:@"levelQuits"]];
    X.levelMoves = [CCArray arrayWithNSArray:           [defaults arrayForKey:@"levelMoves"]];
    
    X.showMessageAgain = [NSMutableDictionary dictionaryWithCapacity:10];
    [X.showMessageAgain setDictionary:[defaults dictionaryForKey:@"showMessageAgain"]];
    
    X.userDidRate =         [defaults boolForKey:@"userDidRate"];
    X.sessionsSinceNag =    [defaults integerForKey:@"sessionsSinceNag"];
    X.highsSinceNag =       [defaults integerForKey:@"highsSinceNag"];
    X.userSaidNoNag =       [defaults boolForKey:@"userSaidNoNag"];
}

-(void) putDefaults {
    if (X.standardUserDefaultsIsCorrupted == YES) {
        return;
    }
    
        //sessionNumber updated in initialize
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setObject:    X.installationUUID     forKey:@"installationUUID"]; //doesn't change
    [defaults setInteger:   X.hoursFromGMT         forKey:@"h"]; //doesn't change
    [defaults setInteger:   X.movesThisPlay        forKey:@"movesThisPlay"];
    [defaults setInteger:   X.starsUsedThisPlay    forKey:@"starsUsedThisPlay"];
    [defaults setInteger:   X.bombsUsedThisPlay    forKey:@"bombsUsedThisPlay"];
    [defaults setDouble:    X.playDeltaTime        forKey:@"playDeltaTime"];
    [defaults setInteger:   X.nCorruptions         forKey:@"c"];
    [defaults setInteger:   X.numberOfLevels       forKey:@"numberOfLevels"];
    [defaults setInteger:   X.levelUnlocked        forKey:@"levelUnlocked"];
    [defaults setInteger:   X.sessionNumber        forKey:@"sessionNumber"];
    [defaults setInteger:   X.level                forKey:@"level"];
    [defaults setInteger:   X.levelForStart        forKey:@"levelForStart"];
    [defaults setInteger:   X.levelJustCompleted   forKey:@"levelJustCompleted"];
    [defaults setInteger:   X.score                forKey:@"score"];
    [defaults setInteger:   X.nRows                forKey:@"rows"];
    [defaults setInteger:   X.nColumns             forKey:@"columns"];
    [defaults setInteger:   X.nColors              forKey:@"colors"];
    [defaults setInteger:   X.nShapes              forKey:@"shapes"];
    [defaults setInteger:   X.loudnessNumber       forKey:@"loudnessNumber"];
    [defaults setInteger:   X.choiceCode           forKey:@"choiceCode"];
    [defaults setInteger:   X.resets               forKey:@"r"];
    [defaults setInteger:   X.starsOnHand          forKey:@"starsOnHand"];
    [defaults setInteger:   X.starsUsed            forKey:@"starsUsed"];
    [defaults setInteger:   X.bombsOnHand          forKey:@"bombsOnHand"];
    [defaults setInteger:   X.bombsUsed            forKey:@"bombsUsed"];
    [defaults setBool:      X.preselectToken       forKey:@"preselectToken"];
    [defaults setInteger:   X.finishWithEmptyGridCount forKey:@"finishWithEmptyGridCount"];
    
        //tutorials state
    [defaults setBool:      X.tutorialsEnabled            forKey:@"tutorialsEnabled"];
    [defaults setBool:      X.level1TutorialsCompleted    forKey:@"level1TutorialsCompleted"];
    [defaults setBool:      X.level2TutorialsCompleted    forKey:@"level2TutorialsCompleted"];
    
    [defaults setInteger:random()%(2 * 65536)   forKey:@"checksum"];
    [defaults setInteger:128 + random()%128     forKey:@"depth"];
    [defaults setInteger:random()%16            forKey:@"aiNext"];
    
    NSUInteger computedDifficulty = difficulty(X.hoursFromGMT,
                                               X.starsUsed,
                                               X.bombsUsed,
                                               X.resets, 
                                               X.starsOnHand, 
                                               X.bombsOnHand,
                                               X.nCorruptions,
                                               X.finishWithEmptyGridCount,
                                               X.bestScores,
                                               X.totalScores,
                                               X.levelCompletions
                                               );
    
    [defaults setInteger:computedDifficulty             forKey:@"seed"];
    [defaults setObject:[self build]                    forKey:@"buildString"];
    [defaults setObject:[X.levelTime getNSArray]        forKey:@"levelTime"];
    [defaults setObject:[X.bestScores getNSArray]       forKey:@"highScores"];
    [defaults setObject:[X.totalScores getNSArray]      forKey:@"totalScore"];
    [defaults setObject:[X.levelStarts getNSArray]      forKey:@"levelStarts"];
    [defaults setObject:[X.levelCompletions getNSArray] forKey:@"levelCompletions"];
    [defaults setObject:[X.levelQuits getNSArray]       forKey:@"levelQuits"];
    [defaults setObject:[X.levelMoves getNSArray]       forKey:@"levelMoves"];
    [defaults setObject:X.showMessageAgain              forKey:@"showMessageAgain"];
    
    [defaults setBool:X.userDidRate                     forKey:@"userDidRate"];
    [defaults setInteger:X.sessionsSinceNag             forKey:@"sessionsSinceNag"];
    [defaults setInteger:X.highsSinceNag                forKey:@"highsSinceNag"];
    [defaults setBool:X.userSaidNoNag                   forKey:@"userSaidNoNag"];

    [defaults synchronize];
}

-(BOOL) commonIsValid {
    /* debug */
//    return NO;
    
    NSUInteger computedDifficulty =  difficulty(X.hoursFromGMT,
                                                X.starsUsed,
                                                X.bombsUsed,
                                                X.resets,
                                                X.starsOnHand,
                                                X.bombsOnHand,
                                                X.nCorruptions,
                                                X.finishWithEmptyGridCount,
                                                X.bestScores,
                                                X.totalScores,
                                                X.levelCompletions
                                                );
    
    CCLOG(@"computedDifficulty, X.seed: %d, %d", computedDifficulty, X.seed);
    return computedDifficulty == X.seed;
}



-(void) corruptionRestart {
    CCLOG(@"resetting game due to data corruption");
    X.choiceCode = cReset;    //causes reset on the next launch -- see launch method
    X.nCorruptions++;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:X.nCorruptions forKey:@"c"];   //can't do this it's in difficulty() calculation
    [defaults setInteger:X.choiceCode   forKey:@"choiceCode"];
    [defaults synchronize];
    
    NSString *corruptionString;
    if (X.nCorruptions > 20) corruptionString = @"> 20";
    else if (X.nCorruptions > 10) corruptionString = @"11 - 20";
    else if (X.nCorruptions > 3) corruptionString = @"4 - 10";
    else if (X.nCorruptions > 1) corruptionString = @"2 - 3";
    else if (X.nCorruptions == 1) corruptionString = @"1";
    else corruptionString = @"unknown";
    
    NSString *sn;
    if (X.sessionNumber == 1) sn = @"1";
    else if (X.sessionNumber == 2) sn = @"2";
    else if (X.sessionNumber <= 5) sn = @"3 - 5";
    else if (X.sessionNumber <= 10) sn = @"6 - 10";
    else if (X.sessionNumber <= 20) sn = @"11 - 20";
    else if (X.sessionNumber <= 100) sn = @"21 - 100";
    else sn = @"> 100";
    
    NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                       corruptionString, @"Number of Corruptions",
                       sn, @"Session Number",
                       nil];
    [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Corruption Reset" attributes:d];

    [self launch];
}

-(NSString *) build {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

-(NSDictionary *) localyticsAttributesWithLevel:(int)level
                                  sessionNumber:(UInt32)session
                                          moves:(UInt32)moves
                                        minutes:(UInt32)time
                                          score:(UInt32)score
                                      bestScore:(UInt32)best
                                      starsUsed:(UInt32)stars
                                      bombsUsed:(UInt32)bombs {
    
    NSInteger starts = [[X.levelStarts objectAtIndex:level - 1] integerValue];
    NSString *startsBin;
    if (starts <= 1) startsBin = @"1";
    else if (starts <= 5) startsBin = @"2 - 5";
    else if (starts <= 10) startsBin = @"6 - 10";
    else if (starts <= 20) startsBin = @"11 - 20";
    else if (starts <= 50) startsBin = @"21 - 50";
    else startsBin = @"> 50";
    
    NSString *sessionBin;
    if (session < 4) sessionBin = @"1 - 3";
    else if (session <= 10) sessionBin = @"4 - 10";
    else if (session <= 30) sessionBin = @"11 - 30";
    else if (session <= 100) sessionBin = @"31 - 100";
    else if (session <= 300) sessionBin = @"101 - 300";
    else sessionBin = @"> 300";
    
    NSString *movesBin;
    if (moves <= 20) movesBin = @"1 - 20";
    else if (moves <= 50) movesBin = @"21 - 50";
    else if (moves <= 100) movesBin = @"51 -100";
    else if (moves <= 250) movesBin = @"101 - 250";
    else if (moves <= 500) movesBin = @"251 - 500";
    else if (moves <= 1000) movesBin = @"501 - 1,000";
    else movesBin = @"> 1000";
    
    NSString *timeBin;
    if (time <= 1) timeBin = @"0 - 1";
    else if (time <= 5) timeBin = @"2 - 5";
    else if (time <= 10) timeBin = @"6 - 10";
    else if (time <= 20) timeBin = @"11 - 20";
    else if (time <= 40) timeBin = @"21 - 40";
    else if (time <= 60) timeBin = @"41 - 60";
    else if (time <= 90) timeBin = @"61 - 90";
    else timeBin = @"> 90";
    
    NSString *scoreBin;
    if (score <= 100) scoreBin = @"<= 100";
    else if (score <= 300) scoreBin = @"101 - 300";
    else if (score <= 1000) scoreBin = @"301 - 1,000";
    else if (score <= 3000) scoreBin = @"1,001 - 3,000";
    else if (score <= 10000) scoreBin = @"3,001 - 10,000";
    else scoreBin = @"> 10000";
    
    CGFloat scoreRatio;
    if (best == 0) {
        scoreRatio = -1.;
    } else {
        scoreRatio = (float)score/best;
    }
    NSString *scoreRatioBin;
    if (scoreRatio == -1.) scoreRatioBin        = @"first score";
    else if (scoreRatio <= 0.1) scoreRatioBin = @"< 0.1";
    else if (scoreRatio <= 0.7) scoreRatioBin = @"0.1 - 0.7";
    else if (scoreRatio <= 1) scoreRatioBin   = @"0.7 - 1.0";
    else if (scoreRatio <= 1.3) scoreRatioBin = @"1.0 - 1.3";
    else if (scoreRatio <= 2.5) scoreRatioBin = @"1.3 - 2.5";
    else if (scoreRatio <= 10) scoreRatioBin  = @"2.5 - 10";
    else scoreRatioBin                        = @"> 10";
    
    NSString *starsBin;
    if (stars == 0)      starsBin = @"0";
    else if (stars == 1) starsBin = @"1";
    else if (stars <= 3) starsBin = @"2 - 3";
    else if (stars <= 7) starsBin = @"4 - 7";
    else                 starsBin = @"> 7";
    
    NSString *bombsBin;
    if (bombs == 0)      bombsBin = @"0";
    else if (bombs == 1) bombsBin = @"1";
    else if (bombs <= 3) bombsBin = @"2 - 3";
    else if (bombs <= 7) bombsBin = @"4 - 7";
    else                 bombsBin = @"> 7";
    
    NSString *sumOfBestBin;
    NSInteger sum = 0;
    for (NSUInteger i = 0; i < X.numberOfLevels; i++) {
        sum += [[X.bestScores objectAtIndex:i] integerValue];
    }
    if (sum <= 500)         sumOfBestBin = @"<= 500";
    else if (sum <= 1000)   sumOfBestBin = @"501 - 1,000";
    else if (sum <= 2000)   sumOfBestBin = @"1,001 - 2,000";
    else if (sum <= 5000)   sumOfBestBin = @"2,001 - 5,000";
    else if (sum <= 10000)  sumOfBestBin = @"5,001 - 10,000";
    else if (sum <= 20000)  sumOfBestBin = @"10,001 - 20,000";
    else if (sum <= 50000)  sumOfBestBin = @"20,001 - 50,000";
    else                    sumOfBestBin = @"> 50,000";
    
    
//    CCLOG(@"Session Number, Plays This Level, Moves This Play, Minutes This Play, Score, Score / Best, Stars Used This Play, Bombs Used This Play: %@, %@, %@, %@, %@, %@, %@, %@",
//          sessionBin, startsBin, movesBin, timeBin, scoreBin, scoreRatioBin, starsBin, bombsBin);
    
    return [NSDictionary dictionaryWithObjects:
            [NSArray arrayWithObjects:sessionBin, startsBin, movesBin, timeBin, scoreBin, scoreRatioBin,
             starsBin, bombsBin, sumOfBestBin, nil]
                                       forKeys:
            [NSArray arrayWithObjects:@"Session Number", @"Plays This Level", @"Moves This Play", @"Minutes This Play", @"Score", @"Score / Best", @"Stars Used This Play", @"Bombs Used This Play", @"Sum of Best Scores", nil]];
}



@end