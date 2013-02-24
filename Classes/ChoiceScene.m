//
//  ChoiceScene.m
//  Darken
//
//  Created by Robert Lummis on 5/22/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

#import "ChoiceScene.h"
#import "DeveloperScene.h"
#import "SettingsScene.h"
#import "Board.h"
#import "LoadBoardScene.h"
#import "CCArray+Replace.h"
#import "Model.h"
#import "DarkenAppDelegate.h"   //for game center viewcontroller
#import "MessageManager.h"
#import "RLGameCenter.h"
#import "LocalyticsSession.h"

CGFloat fvalue(CGFloat arg);

@implementation ChoiceScene

-(void)dealloc {
    ANNOUNCE
    [formatter release];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

+(id) scene {
    ANNOUNCE
    CCScene *scene = [CCScene node];
	ChoiceScene *choiceNode = [ChoiceScene node];
    [scene addChild:choiceNode z:0];
	return scene;
}

-(void) onEnter {
    ANNOUNCE
    [super onEnter];
}

-(void) onEnterTransitionDidFinish {
    ANNOUNCE
    [super onEnterTransitionDidFinish];
    X.nowInChoiceScene = YES;
    
        //nag for rating
    BOOL test = NO;
    if (test || (X.sessionsSinceNag >= SESSIONSFORNAG
                 && X.highsSinceNag >= HIGHSFORNAG
                 && X.networkIsAvailable
                 && !!!X.userDidRate
                 && !!!X.userSaidNoNag) ) {
        X.sessionsSinceNag = 0;
        X.highsSinceNag = 0;
        nagAlertView = [[UIAlertView alloc]
                                       initWithTitle:@"Will you please rate Darken?\nAdding a review is optional."
                                       message:nil
                                       delegate:self
                                       cancelButtonTitle:@"No, and don't ask again"
                                       otherButtonTitles:
                        @"OK go to rating page now.",
                        @"Yes, but not now",
                        nil];
        [nagAlertView show];
    }
    
    [[MessageManager sharedManager] showQueuedMessages];
}

-(void) onExit {
    ANNOUNCE
    CCLOG(@"ChoiceScene/onExit; [[host subviews] count]: %d", [[host subviews] count]);
    X.nowInChoiceScene = NO;
    [super onExit];
}

-(id) init{
    ANNOUNCE
    if( (self=[super init]) ) {
        
CCLOG(@"init X.choiceCode: %d", X.choiceCode);
        
        /***************** example *******
         if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
         // The device is an iPad running iOS 3.2 or later.
         }
         else {
         // The device is an iPhone or iPod touch.
         }
        *******************************/
        
        X.choiceSceneP = self;
        
        sae = [SimpleAudioEngine sharedEngine];
        [sae preloadEffect:@"pluck.wav"];
        
		CGSize screenSize = [[CCDirector sharedDirector] winSize];
        w = screenSize.width;
        h = screenSize.height;
        
        formatter = [[NSNumberFormatter alloc] init];
        [formatter setPositiveFormat:@"#,##0"];
        
        statusMessageX = 0.f;
        statusMessageY = 6.f;
        statusMessageW = w;
        statusMessageH = 45.f;  //bigger than minimum; does that create a problem?
        
        borderImage = [UIImage imageNamed:@"levelTableBorder.png"];
        borderThickness = 7.f;  //points
        levelTableRowHeight = 54.f;
//        levelTableX = 25.f;
        levelTableX = 0.5 * ( w - borderImage.size.width) + borderThickness;
        levelTableY = 72.f;
        levelTableW = w - 2.f * levelTableX + fvalue(2.f);
        levelTableH = 3.0f * levelTableRowHeight;
        
        sumColonX = w * 0.55f;;
        sum1H = 20.f;
        sum1Y = levelTableY + levelTableH + 10.f;
        sum2H = 20.f;
        sum2Y = levelTableY + levelTableH + 29.f;
        
        cellTextX = 20.f;
        cellColonX = 325.f;
        cellScoreX = cellColonX + 4.f;
        
        scrollLabelX = levelTableX;
        scrollLabelY = levelTableY - 28.f;
        scrollLabelW = 250.f;
        scrollLabelH = 20.f;

        settingsButtonW = 94.f;
        settingsButtonH = 30.f;
        settingsButtonX = levelTableX - 9;  //9 is thickness of frame
        settingsButtonY = h - 45.f;
        
        playButtonW = 94.f;
        playButtonH = 30.f;
        playButtonX = w - settingsButtonX - playButtonW;
        playButtonY = settingsButtonY;
        
        leaderButtonW = 105.f;
        leaderButtonH = 30.f;
        achievementsButtonW = 105.f;
        achievementsButtonH = 30.f;
        
        CGFloat space = playButtonX - settingsButtonX - settingsButtonW - leaderButtonW - achievementsButtonW;
        
        leaderButtonX = settingsButtonX + settingsButtonW + space / 3.f;
        leaderButtonY = settingsButtonY;

        achievementsButtonX = leaderButtonX + leaderButtonW + space / 3.f;
        achievementsButtonY = settingsButtonY;
        
        normalLevelLabelColor   =   [UIColor blackColor];
        normalTutorialLabelColor =   [UIColor blackColor];
        normalLevelLabelColor   =   [UIColor blackColor];
        normalStatsLabelColor   =   [UIColor darkGrayColor];
        
        glClearColor(0.85f, 0.85f, 0.85f, 1.0f);
        host = [CCDirector sharedDirector].openGLView;
        
        if (GRIDFLAG) {
            [self addGrid];
        }

        if(X.level == 0 || X.nRows == 0 || X.nColumns == 0 || X.nColors == 0 || X.nShapes == 0){
            CCLOG(@"ChoiceScene: a parameter is zero");
            CCLOG(@"X.level: %d,    X.nRows: %d,    X.nColumns: %d,    X.nColors: %d,    X.nShapes: %d", 
                  X.level, X.nRows, X.nColumns, X.nColors, X.nShapes);
            kill( getpid(), SIGABRT );  //crash
        }
        
        self.isTouchEnabled = YES;

        [self addLevelTable];
        [self addSettingsButton];
        [self addPlayButton];
        [self addSumLabels];
        
        if (DEVELOPERFLAG) {
            developerPoint = CGPointMake(w * 0.05f, 10.f);
            CGRect dFrame = CGRectMake(developerPoint.x, developerPoint.y, 15.f, 15.f);
            developerLabel = [[UILabel alloc] initWithFrame:dFrame];
            developerLabel.text = @"D";
            developerLabel.backgroundColor = [UIColor clearColor];
            developerLabel.textColor = [UIColor blueColor];
            [host addSubview:developerLabel];
            [developerLabel release];
            developerLabel = nil;

            printPoint = CGPointMake(w * 0.90f, 10.f);
            CGRect pFrame = CGRectMake(printPoint.x, printPoint.y, 15.f, 15.f);
            printLabel = [[UILabel alloc] initWithFrame:pFrame];
            printLabel.text = @"P";
            printLabel.backgroundColor = [UIColor clearColor];
            printLabel.textColor = [UIColor blueColor];
            [host addSubview:printLabel];
            [printLabel release];
            printLabel = nil;
         }
        
        CGRect rect = CGRectMake(statusMessageX, statusMessageY, statusMessageW, statusMessageH);
        statusMessage = [[UILabel alloc] initWithFrame:rect];
        statusMessage.font = [UIFont systemFontOfSize:15];
        statusMessage.numberOfLines = 0;
        statusMessage.lineBreakMode = UILineBreakModeWordWrap;
        statusMessage.textAlignment = UITextAlignmentCenter;
        statusMessage.backgroundColor = [UIColor clearColor];
        statusMessage.textColor = [UIColor blueColor];
        
        CCLOG(@"A X.choiceCode: %d", X.choiceCode);
        
        if (X.developerParameters == YES) {
            statusMessage.text = [NSString stringWithFormat:
                  @"row:%d,  clm:%d,  color:%d,  shape:%d,  star:%d,  bomb:%d", 
                  X.nRows, X.nColumns, X.nColors, X.nShapes, X.starsOnHand, X.bombsOnHand];
        
        } else if (X.choiceCode == cLevel1) {
            if (X.tutorialsEnabled) {
                statusMessage.text = @"Play level 1 in tutorial mode.";
            } else {
                statusMessage.text = [NSString stringWithFormat:@"Play level 1 of %d levels.", X.numberOfLevels];
            }
            
        } else if (X.choiceCode == cTutorialLevel2) {
            if (X.tutorialsEnabled) {
                statusMessage.text = @"Play level 2 in tutorial mode.";
                playButton.text = @"Do tutorial 2";
            } else {
                statusMessage.text = @"Play level 2";
                playButton.text = @"Play level 2";
            }
            X.level = 2;    //so they don't inadvertently replay level 1
            X.newLevelUnlocked = YES;
            X.levelUnlocked = MAX(2, X.levelUnlocked);
            
       
        } else if (X.choiceCode == cOtherLaunch) {
            statusMessage.text = [NSString stringWithFormat: @"You last played level %d.", X.level];
        
        } else if (X.choiceCode == cInterrupted) {
            statusMessage.text = [NSString stringWithFormat: @"You were interrupted while playing level %d.", X.level];
        
        } else if (X.choiceCode == cCompleted) {
            
             if (X.newLevelUnlocked == NO) {
                statusMessage.text = [NSString stringWithFormat:@"You completed level %d with a score of %@.", X.levelJustCompleted,
                                      [formatter stringFromNumber:[NSNumber numberWithInteger:X.score]]];
            } else {
                statusMessage.text = [NSString  
                          stringWithFormat:@"You completed level %d with a score of %@.\nLevel %d is unlocked.",
                                X.levelJustCompleted,
                                [formatter stringFromNumber:[NSNumber numberWithInteger:X.score]],
                                X.levelJustCompleted + 1];
                X.newLevelUnlocked = NO;
            }
        }
        
        else if (X.choiceCode == cFailed) {
            statusMessage.text = [NSString stringWithFormat:@"No score. You overloaded the shredder in level %d. Try again.", X.level];
            X.score = 0;    //not needed here?
            if (X.tutorialsEnabled && X.level < 3) {
                playButton.text = [NSString stringWithFormat:@"Do tutorial %d", X.level];
            } else {
                playButton.text = [NSString stringWithFormat:@"Play level %d", X.level];
            }
        }
        
        else if (X.choiceCode == cQuit) {
            statusMessage.text = [NSString stringWithFormat:@"No score. You quit while playing level %d.", X.level];
            X.score = 0;    //not needed here?
            X.newLevelUnlocked = NO;
            if (X.tutorialsEnabled && X.level < 3) {
                playButton.text = [NSString stringWithFormat:@"Do tutorial %d", X.level];
            } else {
                playButton.text = [NSString stringWithFormat:@"Play level %d", X.level];
            }
        
        } else {
            CCLOG(@"invalid X.choiceCode in ChoiceScene: %d", X.choiceCode);
            kill( getpid(), SIGABRT );  //crash
        }

        [host addSubview:statusMessage];
        [statusMessage release];
        statusMessage = nil;
        
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:X.level - 1 inSection:0];
        
            //apparently needed because table setup takes some time and would overwrite the color property
            //how much delay is enough?
            //db
//        [self performSelector:@selector(selectAndWhiten:) withObject:indexPath afterDelay:0.80f];
        [self selectAndWhiten:indexPath];
        if ( X.clappingFlag ) {
            [[SimpleAudioEngine sharedEngine] playEffect:@"clapping11025.wav"];
            X.clappingFlag = NO;
        }
	}
    CCLOG(@"in ChoiceScene; just before init 'return self'");
	return self;
}

#pragma mark - UITableViewDataSource methods

-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

-(NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    ANNOUNCE
    return X.numberOfLevels;
}

    //UITableViewDataSource callback
-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ANNOUNCE
    UITableViewCell *cell = nil;
    
    cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault 
                                       reuseIdentifier:@"cell"] autorelease];
            //setting backgroundColor here doesn't work. set it in tableView:willDisplayCell:forIndexPath:
        
        levelLabel = [[[UILabel alloc] initWithFrame:CGRectMake(cellTextX, 
                           0.08f * cell.contentView.bounds.size.height,
                           175.f, //allow space to insert "Play..."
                           cell.contentView.bounds.size.height * 0.5f)] autorelease];
        levelLabel.backgroundColor = [UIColor clearColor];
        levelLabel.font = [UIFont boldSystemFontOfSize:18];
        levelLabel.tag = LEVELLABELTAG;
        [cell.contentView addSubview:levelLabel];
        
        statsLabel = [[[UILabel alloc] initWithFrame:CGRectMake(cellTextX, 
                       0.55f * cell.contentView.bounds.size.height,     //also sets totalScoreLabel.y below
                       w - cellTextX, 
                       0.5f * cell.contentView.bounds.size.height )] autorelease];
        statsLabel.backgroundColor = [UIColor clearColor];
        statsLabel.font = [UIFont systemFontOfSize:15];
        statsLabel.tag = STATSLABELTAG;
        [cell.contentView addSubview:statsLabel];
        
        highScoreLabel = [[[UILabel alloc] initWithFrame:
                           CGRectMake(0.0f,
                                      0.08f * cell.contentView.bounds.size.height,
                                      cellColonX, 
                                      0.5f * cell.contentView.bounds.size.height)] autorelease];
        highScoreLabel.text = @"High score:";
        highScoreLabel.hidden = YES;
        highScoreLabel.textAlignment = UITextAlignmentRight;
        highScoreLabel.backgroundColor = [UIColor clearColor];
        highScoreLabel.font = [UIFont systemFontOfSize:15];
        highScoreLabel.tag = HIGHSCORELABELTAG;
        [cell.contentView addSubview:highScoreLabel];
        
        highScoreValueLabel = [[[UILabel alloc] initWithFrame:
                                CGRectMake(cellScoreX,
                                           0.08f * cell.contentView.bounds.size.height,
                                           (levelTableW - cellScoreX),
                                           0.5f * cell.contentView.bounds.size.height)] autorelease];
        highScoreValueLabel.textAlignment = UITextAlignmentLeft;
        highScoreValueLabel.textColor = [UIColor blackColor];
        highScoreValueLabel.backgroundColor = [UIColor clearColor];
        highScoreValueLabel.hidden = YES;
        highScoreValueLabel.font = [UIFont systemFontOfSize:15];
        highScoreValueLabel.tag = HIGHSCOREVALUETAG;
        [cell.contentView addSubview:highScoreValueLabel];
        
        totalScoreLabel = [[[UILabel alloc] initWithFrame:
                            CGRectMake(0.0f, 
                                       statsLabel.frame.origin.y,
                                       cellColonX, 
                                       0.55f * cell.contentView.bounds.size.height)] autorelease];
        totalScoreLabel.text = @""; //set text in willDisplay... depending on # completions
        totalScoreLabel.hidden = YES;
        totalScoreLabel.textAlignment = UITextAlignmentRight;
        totalScoreLabel.backgroundColor = [UIColor clearColor];
        totalScoreLabel.font = [UIFont systemFontOfSize:15];
        totalScoreLabel.tag = TOTALSCORELABELTAG;
        [cell.contentView addSubview:totalScoreLabel];
        
        totalScoreValueLabel = [[[UILabel alloc] initWithFrame:
                                 CGRectMake(cellScoreX,
                                            statsLabel.frame.origin.y,
                                            (levelTableW - cellScoreX),
                                            0.55f * cell.contentView.bounds.size.height)] autorelease];
        totalScoreValueLabel.textAlignment = UITextAlignmentLeft;
        totalScoreValueLabel.textColor = [UIColor blackColor];
        totalScoreValueLabel.backgroundColor = [UIColor clearColor];
        totalScoreValueLabel.hidden = YES;
        totalScoreValueLabel.font = [UIFont systemFontOfSize:15];
        totalScoreValueLabel.tag = TOTALSCOREVALUETAG;
        [cell.contentView addSubview:totalScoreValueLabel];
        
        CGRect newHighFrame = CGRectMake(0.50f * cell.contentView.bounds.size.width - 7.f,
                                         2.f,
                                         w,
                                         0.52f * cell.contentView.bounds.size.height);
        newHighLabel = [[[UILabel alloc] initWithFrame:newHighFrame] autorelease];
        newHighLabel.text = @"New High!";
        newHighLabel.textColor = [UIColor colorWithRed:1.0f green:0.60f blue:0.60f alpha:1.0f];
        newHighLabel.backgroundColor = [UIColor clearColor];
        newHighLabel.font = [UIFont fontWithName:@"Marker Felt" size:22];
        newHighLabel.textAlignment = UITextAlignmentLeft;
        newHighLabel.tag = NEWHIGHTAG;
        [cell.contentView addSubview:newHighLabel];
        
        UIImage *lockImage = [UIImage imageNamed:@"lock.png"];
        lockView = [[UIImageView alloc] initWithImage:lockImage];
        CGFloat imageScale = 0.25f;
        CGFloat lockImageX = 0.5f * cell.contentView.bounds.size.width;
        CGFloat lockImageY = 0.5f * (cell.contentView.bounds.size.height - imageScale * lockImage.size.height);
        lockView.frame = CGRectMake(lockImageX, lockImageY, 
                                    imageScale * lockImage.size.width, 
                                    imageScale * lockImage.size.height);
        lockView.tag = LOCKVIEWTAG;
        [cell.contentView addSubview:lockView];
        [lockView release];
        lockView = nil;
        
    } else {
        levelLabel = (UILabel *) [cell.contentView viewWithTag:LEVELLABELTAG];
        statsLabel = (UILabel *) [cell.contentView viewWithTag:STATSLABELTAG];
        newHighLabel = (UILabel *) [cell.contentView viewWithTag:NEWHIGHTAG];
        highScoreLabel = (UILabel *) [cell.contentView viewWithTag:HIGHSCORELABELTAG];
        lockView = (UIImageView *) [cell.contentView viewWithTag:LOCKVIEWTAG];
    }
    
        //set text color depending on whether the row is selected or not
    if (indexPath.row == X.level - 1) {
        levelLabel.textColor = [UIColor whiteColor];
        statsLabel.textColor = [UIColor whiteColor];
    } else {
        levelLabel.textColor = normalLevelLabelColor;   //remove whiteness if it was off screen when unselected
        statsLabel.textColor = normalStatsLabelColor;
    }
    
    if ( indexPath.row + 1 < 3 ) {
        if ( cell.selected == YES ) {
                tutorialLabel.textColor = [UIColor whiteColor] ;
            } else {
                tutorialLabel.textColor = normalTutorialLabelColor;
            }
    }
    
        //hide or unhide newHighLabel
    newHighLabel.hidden = indexPath.row + 1 == X.newHighLevel ? NO : YES;

    return cell;
}

#pragma mark - UITableViewDelegate methods

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath   {
    ANNOUNCE
    cell.backgroundColor = [UIColor whiteColor];
    
    levelLabel =            (UILabel *)     [cell.contentView viewWithTag:LEVELLABELTAG];
    tutorialLabel =         (UILabel *)     [cell.contentView viewWithTag:TUTORIALLABELTAG];
    statsLabel =            (UILabel *)     [cell.contentView viewWithTag:STATSLABELTAG];
    highScoreLabel =        (UILabel *)     [cell.contentView viewWithTag:HIGHSCORELABELTAG];
    highScoreValueLabel =   (UILabel *)     [cell.contentView viewWithTag:HIGHSCOREVALUETAG];
    totalScoreLabel =       (UILabel *)     [cell.contentView viewWithTag:TOTALSCORELABELTAG];
    totalScoreValueLabel =  (UILabel *)     [cell.contentView viewWithTag:TOTALSCOREVALUETAG];
    lockView =              (UIImageView *) [cell.contentView viewWithTag:LOCKVIEWTAG];
    
    NSString *string1 = @"";
    int starts = [[X.levelStarts objectAtIndex:indexPath.row] integerValue];
    switch (starts) {
        case 0:
            string1 = @"Never played.   ";
            break;
        case 1:
            string1 = @"played once, ";
            break;
        default:    //2 or more
            string1 = [NSString stringWithFormat:@"%@ plays, ", 
                       [formatter stringFromNumber:[X.levelStarts objectAtIndex:indexPath.row]]];
            break;
    }
        
    NSString *string2 = @"";
    int completions = [[X.levelCompletions objectAtIndex:indexPath.row] integerValue];
    switch (completions) {
        case 0:
            string2 = [string1 isEqualToString:@"Never played.   "] ? @"" : @"not completed.";
            break;
        case 1:
            string2 = @"completed once.";
            break;
        default:    //2 or more
            string2 = [NSString stringWithFormat:@"%@ completions.",
                       [formatter stringFromNumber:[X.levelCompletions objectAtIndex:indexPath.row]]];
            break;
    }
    
    if ( completions > 0 ) {
        totalScoreLabel.hidden = NO;
        totalScoreValueLabel.hidden = NO;
        NSNumber *totalNumber = [X.totalScores objectAtIndex:indexPath.row];
        totalScoreValueLabel.text = [formatter stringFromNumber:totalNumber];
    } else {
        totalScoreLabel.hidden = YES;
        totalScoreValueLabel.hidden = YES;
    }
    
    totalScoreLabel.text = completions > 1 ? @"Total score:" : @"Score: ";
    
    if ( completions > 1 ) {
        highScoreLabel.hidden = NO;
        highScoreValueLabel.hidden = NO;
        NSNumber *bestNumber = [X.bestScores objectAtIndex:indexPath.row];
        highScoreValueLabel.text = [formatter stringFromNumber:bestNumber];
    } else {
        highScoreLabel.hidden = YES;
        highScoreValueLabel.hidden = YES;
    }
    
        //override above visibility determinations if tutorials are enabled
        //labels hidden no matter how many completions
    if ( X.tutorialsEnabled && indexPath.row + 1 < 3 ) {
        totalScoreLabel.hidden = YES;
        totalScoreValueLabel.hidden = YES;
        highScoreLabel.hidden = YES;
        highScoreValueLabel.hidden = YES;
    }

    statsLabel.text = [string1 stringByAppendingString:string2];
    
    if (X.tutorialsEnabled && indexPath.row + 1 < 3) {
        levelLabel.text = [NSString stringWithFormat:@"Tutorial Part %d", indexPath.row + 1];
    } else {
        levelLabel.text = [NSString stringWithFormat:@"Level %d", indexPath.row + 1];
    }
    
    if (indexPath.row + 1 == X.level) {
        levelLabel.textColor = [UIColor whiteColor];
        statsLabel.textColor = [UIColor whiteColor];
        highScoreLabel.textColor = [UIColor whiteColor];
        highScoreValueLabel.textColor = [UIColor whiteColor];
        totalScoreLabel.textColor = [UIColor whiteColor];
        totalScoreValueLabel.textColor = [UIColor whiteColor];
        cell.backgroundColor = [UIColor colorWithRed:0.3f green:0.3f blue:1.0f alpha:1.0f]; //match system blue
    } else {
        levelLabel.textColor = [UIColor blackColor];
        statsLabel.textColor = [UIColor blackColor];
        cell.backgroundColor = [UIColor whiteColor];
        highScoreLabel.textColor = [UIColor blackColor];
        highScoreValueLabel.textColor = [UIColor blackColor];
        totalScoreLabel.textColor = [UIColor blackColor];
        totalScoreValueLabel.textColor = [UIColor blackColor];
    }

    lockView.hidden = indexPath.row + 1 <= X.levelUnlocked ? YES : NO;
    [cell setUserInteractionEnabled: indexPath.row + 1 <= X.levelUnlocked ? YES : NO];

}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)newIndexPath {
    ANNOUNCE
    if (newIndexPath.row == X.level - 1) {
        return; //tapped the row that was already selected. Don't want to whiten its text.
    }
    NSIndexPath *oldIndexPath = [NSIndexPath indexPathForRow:X.level - 1 inSection:0];
    UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:oldIndexPath];
    [oldCell setSelected:NO animated:NO];
    X.level = newIndexPath.row + 1;
    [self whitenTextInNewCell:tableView newIndexPath:newIndexPath oldIndexPath:oldIndexPath];
    if (X.tutorialsEnabled && X.level < 3) {
        playButton.text = [NSString stringWithFormat:@"Do tutorial %d", X.level];
    } else {
        playButton.text = [NSString stringWithFormat:@"Play level %d", X.level];
    }
}

-(void) selectAndWhiten:(NSIndexPath *)indexPath {
    ANNOUNCE
    [levelTable selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    UITableViewCell *cell = [levelTable cellForRowAtIndexPath:indexPath];
    
    levelLabel = (UILabel *)[cell viewWithTag:LEVELLABELTAG];
    levelLabel.font = [UIFont boldSystemFontOfSize:17];
    levelLabel.textColor = [UIColor whiteColor];
    
    tutorialLabel = (UILabel *)[cell viewWithTag:TUTORIALLABELTAG];
    tutorialLabel.textColor = [UIColor whiteColor];
    
    statsLabel = (UILabel *)[cell viewWithTag:STATSLABELTAG];
    statsLabel.textColor = [UIColor whiteColor];
    
    highScoreLabel = (UILabel *)[cell viewWithTag:HIGHSCORELABELTAG];
    highScoreLabel.textColor = [UIColor whiteColor];
    
    highScoreValueLabel = (UILabel *)[cell viewWithTag:HIGHSCOREVALUETAG];
    highScoreValueLabel.textColor = [UIColor whiteColor];
    
    totalScoreLabel = (UILabel *)[cell viewWithTag:TOTALSCORELABELTAG];
    totalScoreLabel.textColor = [UIColor whiteColor];
    
    totalScoreValueLabel = (UILabel *)[cell viewWithTag:TOTALSCOREVALUETAG];
    totalScoreValueLabel.textColor = [UIColor whiteColor];
}

    //scroll to selected cell and whiten text
-(void) whitenTextInNewCell:(UITableView *)tableView newIndexPath:(NSIndexPath *)newIndexPath
              oldIndexPath:(NSIndexPath *)oldIndexPath {
    ANNOUNCE
        //following does NOT call didSelectRowAtIndexPath...
    [levelTable selectRowAtIndexPath:newIndexPath animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    if (oldIndexPath != nil) {
        UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:oldIndexPath];
        levelLabel = (UILabel *)[oldCell viewWithTag:LEVELLABELTAG];
        levelLabel.font = [UIFont boldSystemFontOfSize:17];
        levelLabel.textColor = normalLevelLabelColor;
        tutorialLabel = (UILabel *)[oldCell viewWithTag:TUTORIALLABELTAG];
        tutorialLabel.textColor = normalTutorialLabelColor;
        statsLabel = (UILabel *)[oldCell viewWithTag:STATSLABELTAG];
        statsLabel.textColor = normalStatsLabelColor;
        highScoreLabel = (UILabel *)[oldCell viewWithTag:HIGHSCORELABELTAG];
        highScoreLabel.textColor = normalStatsLabelColor;
        highScoreValueLabel = (UILabel *)[oldCell viewWithTag:HIGHSCOREVALUETAG];
        highScoreValueLabel.textColor = normalStatsLabelColor;
        totalScoreLabel = (UILabel *)[oldCell viewWithTag:TOTALSCORELABELTAG];
        totalScoreLabel.textColor = normalStatsLabelColor;
        totalScoreValueLabel = (UILabel *)[oldCell viewWithTag:TOTALSCOREVALUETAG];
        totalScoreValueLabel.textColor = normalStatsLabelColor;
        oldCell.backgroundColor = [UIColor whiteColor];
    }
    UITableViewCell *newCell = [tableView cellForRowAtIndexPath:newIndexPath];
    levelLabel = (UILabel *)[newCell viewWithTag:LEVELLABELTAG];
    levelLabel.font = [UIFont boldSystemFontOfSize:17];
    levelLabel.textColor = [UIColor whiteColor];
    tutorialLabel = (UILabel *)[newCell viewWithTag:TUTORIALLABELTAG];
    tutorialLabel.textColor = [UIColor whiteColor];
    statsLabel = (UILabel *)[newCell viewWithTag:STATSLABELTAG];
    statsLabel.textColor = [UIColor whiteColor];
    highScoreLabel = (UILabel *)[newCell viewWithTag:HIGHSCORELABELTAG];
    highScoreLabel.textColor = [UIColor whiteColor];
    highScoreValueLabel = (UILabel *)[newCell viewWithTag:HIGHSCOREVALUETAG];
    highScoreValueLabel.textColor = [UIColor whiteColor];
    totalScoreLabel = (UILabel *)[newCell viewWithTag:TOTALSCORELABELTAG];
    totalScoreLabel.textColor = [UIColor whiteColor];
    totalScoreValueLabel = (UILabel *)[newCell viewWithTag:TOTALSCOREVALUETAG];
    totalScoreValueLabel.textColor = [UIColor whiteColor];
}

#pragma mark - add parts

-(void) addLevelTable {
    ANNOUNCE
    
    UIImageView *borderView = [[UIImageView alloc] initWithImage:borderImage];
    
    CGRect scrollFrame = CGRectMake(scrollLabelX, scrollLabelY, scrollLabelW, scrollLabelH);
    UILabel *scrollMessage = [[UILabel alloc] initWithFrame:scrollFrame];
    scrollMessage.text = @"Scroll to select a level...";
    scrollMessage.textAlignment = UITextAlignmentLeft;
    scrollMessage.backgroundColor = [UIColor clearColor];
    scrollMessage.textColor = [UIColor blueColor];
    scrollMessage.font = [UIFont systemFontOfSize:12];
    [host addSubview:scrollMessage];
    [scrollMessage release];
    
//    CGRect tableFrame = CGRectMake(levelTableX, levelTableY, levelTableW, levelTableH);
    CGRect tableFrame = CGRectMake(levelTableX, levelTableY, borderImage.size.width - 2 * borderThickness, levelTableH);
    levelTable = [[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain];
    levelTable.rowHeight = levelTableRowHeight;
    levelTable.separatorColor = [UIColor blueColor];
    levelTable.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    levelTable.delegate = self;
    levelTable.dataSource = self;
    levelTable.allowsSelection = YES;   //is default
    levelTable.tag = LEVELTABLETAG;
    [host addSubview:levelTable];
    [levelTable release];
    
    CGFloat manual2 = 2.f;  //ad hoc adjustment
    CGFloat manual10 = 10.f;
//    borderThickness += manual2;
    borderView.frame = CGRectMake( levelTableX - borderThickness, levelTableY - borderThickness,
                                  borderImage.size.width - manual2, borderImage.size.height + manual10);
    [host addSubview:borderView];
    [borderView release];
}

-(void) addSumLabels {
        //no sum labels or values unless we have scores for at least 2 reportable levels
    if ( X.levelUnlocked < 3 && X.tutorialsEnabled ) {
        return;
    }
    
    NSInteger sumOfBestScores = 0;
    for (NSUInteger i = 0; i < X.numberOfLevels; i++) {
        sumOfBestScores += [[X.bestScores objectAtIndex:i] integerValue];
    }
    
    UILabel *sum1Label = [[UILabel alloc] initWithFrame:CGRectMake(levelTableX, sum1Y, sumColonX - levelTableX, sum1H)];
    sum1Label.text = [NSString stringWithFormat:@"Sum of high scores: "];
    sum1Label.font = [UIFont systemFontOfSize:15];
    sum1Label.textColor = [UIColor blueColor];
    sum1Label.backgroundColor = [UIColor clearColor];
    sum1Label.textAlignment = UITextAlignmentRight;
    [host addSubview:sum1Label];
    [sum1Label release];
    
    UILabel *sum1Value = [[UILabel alloc] initWithFrame:CGRectMake(sumColonX, sum1Y, w - sumColonX, sum1H)];
    sum1Value.text = [formatter stringFromNumber:[NSNumber numberWithInteger:sumOfBestScores]];
    sum1Value.textAlignment = UITextAlignmentLeft;
    sum1Value.font = [UIFont systemFontOfSize:15];
    sum1Value.textColor = [UIColor blueColor];
    sum1Value.backgroundColor = [UIColor clearColor];
    [host addSubview:sum1Value];
    [sum1Value release];
    
    NSInteger sumOfTotalScores = 0;
    for (NSUInteger i = 0; i < X.numberOfLevels; i++) {
        sumOfTotalScores += [[X.totalScores objectAtIndex:i] integerValue];
    }
    
    UILabel *sum2Label = [[UILabel alloc] initWithFrame:CGRectMake(levelTableX, sum2Y, sumColonX - levelTableX, sum2H)];
    sum2Label.text = [NSString stringWithFormat:@"Sum of all scores: "];
    sum2Label.font = [UIFont systemFontOfSize:15];
    sum2Label.textColor = [UIColor blueColor];
    sum2Label.backgroundColor = [UIColor clearColor];
    sum2Label.textAlignment = UITextAlignmentRight;
    [host addSubview:sum2Label];
    [sum2Label release];
    
    UILabel *sum2Value = [[UILabel alloc] initWithFrame:CGRectMake(sumColonX, sum2Y, w - sumColonX, sum2H)];
    sum2Value.text = [formatter stringFromNumber:[NSNumber numberWithInteger:sumOfTotalScores]];
    sum2Value.textAlignment = UITextAlignmentLeft;
    sum2Value.font = [UIFont systemFontOfSize:15];
    sum2Value.textColor = [UIColor blueColor];
    sum2Value.backgroundColor = [UIColor clearColor];
    [host addSubview:sum2Value];
    [sum2Value release];
}

-(void) addGrid {
    for (CGFloat x = 0.f; x < 480.f; x += 50.f) {
        CGRect f = CGRectMake(x, 5.f, 0.5f, 310.f);
        UIView *v = [[UIView alloc] initWithFrame:f];
        v.backgroundColor = [UIColor blueColor];
        [host addSubview:v];
        [v release];
        v = nil;
    }
    for (CGFloat y = 0.f; y < 320; y += 50.f) {
        CGRect f = CGRectMake(5.f, y, 470.f, 0.5f);
        UIView *v = [[UIView alloc] initWithFrame:f];
        v.backgroundColor = [UIColor blueColor];
        [host addSubview:v];
        [v release];
        v = nil;
    }
}

-(void) addSettingsButton {
    CGRect frame = CGRectMake(settingsButtonX, settingsButtonY, settingsButtonW, settingsButtonH);
    settingsButton = [RLButton buttonWithStyle:RLButtonStyleBlueRoundedRect  
                                        target:self action:@selector(goSettings) frame:frame];
    settingsButton.text = @"Settings";
    settingsButton.tag = 11;
    [host addSubview:settingsButton];
}

-(void) addPlayButton {
    CGRect frame = CGRectMake(playButtonX, playButtonY, playButtonW, playButtonH);
    playButton = [RLButton buttonWithStyle:RLButtonStyleBlueRoundedRect 
                                    target:self action:@selector(goPlay) frame:frame];
    if (X.tutorialsEnabled && X.level < 3) {
        playButton.text = [NSString stringWithFormat:@"Do tutorial %d", X.level];
    } else {
        playButton.text = [NSString stringWithFormat:@"Play level %d", X.level];
    }
    [host addSubview:playButton];
}

#pragma mark -

-(void) registerWithTouchDispatcher {  //needed for ccTouchBegan:withEvent: to work (not needed for buttons)
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:INT_MIN + 1 swallowsTouches:NO];
}

-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {  //not used unless developer flag is on ?

    CGSize touchRange = CGSizeMake( w * 0.06, h * 0.08 );
	CGPoint touchLocation = [touch locationInView:[touch view]];
    
    if ( [self isClose:touchLocation to:printPoint allowedRange:touchRange] && DEVELOPERFLAG ) {
        CCLOG(@"printPoint");
        self.isTouchEnabled = NO;
        [X.modelP printCommon];
    }
    
    if ( DEVELOPERFLAG && [self isClose:touchLocation to:developerPoint allowedRange:touchRange] ) {
        CCLOG(@"developerPoint");
        self.isTouchEnabled = NO;
        [self goDeveloper];
    }
    
    self.isTouchEnabled = YES;
	return YES;
}

-(BOOL) isClose:(CGPoint)pointA to:(CGPoint)pointB allowedRange:(CGSize)range {
	if ( fabsf(pointA.x - pointB.x) > range.width || fabsf(pointA.y - pointB.y) > range.height )  {
		return NO;
	} else {
		return YES;
	}
}

-(void) goPlay {
    ANNOUNCE
    if ( [X.choiceSceneMessageQueue count] > 0 || X.messageIsShowing ) {
        return; //don't goPlay until tutorial messages are finished, otherwise they will show at the wrong time
    }
//    [[MessageManager sharedManager] clearQueue:X.choiceSceneMessageQueue];  //in case user taps play button immediately
    X.newHighLevel = 0;
    X.levelStartTime = [NSDate date];
    [[host subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    CCTransitionFade *tran = [CCTransitionFade transitionWithDuration:0.5f scene:[ LoadBoardScene scene ]];
    [[CCDirector sharedDirector] replaceScene:tran];
}

-(void) goDeveloper {
    ANNOUNCE
    X.newHighLevel = 0;
    CCArray *subviews = [CCArray arrayWithNSArray:[host subviews]];
    CCTransitionFade *tran = [CCTransitionFade transitionWithDuration:0.5f scene:[DeveloperScene scene]];
    [[CCDirector sharedDirector] replaceScene:tran];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

-(void) goSettings {
    ANNOUNCE
    CCArray *subviews = [CCArray arrayWithNSArray:[host subviews]];
    CCTransitionFade *tran = [CCTransitionFade transitionWithDuration:0.5f scene:[SettingsScene scene]];
    [[CCDirector sharedDirector] replaceScene:tran];
    [subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
}

-(void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView == nagAlertView) {
            //0: No and don't ask again
            //1: OK now
            //2: Ok but not now
        CCLOG(@"nagAlertView dismissed with button %d", buttonIndex);
        
        switch (buttonIndex) {
            case 0:
                X.userSaidNoNag = YES;
                break;
                
            case 1:
                ;   //avoid compiler bug
                NSString *sessionBin;
                if ( X.sessionNumber <= 10 ) sessionBin = @"<= 10";
                else if ( X.sessionNumber <= 20 ) sessionBin = @"11 - 20";
                else if ( X.sessionNumber <= 50 ) sessionBin = @"21 - 50";
                else sessionBin = @"> 50";
                NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:sessionBin, @"Session Number",
                                   [NSNumber numberWithInt:X.levelUnlocked], @"Highest unlocked level", nil];
                [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Agreed to Rate" attributes:d];
                X.userDidRate = YES;
//                NSString *ID = @"577138009";    //Infestor
//                NSString *ID = @"327702034";    //exoplanet
                NSString *ID = @"552773145";   //darken
                    //reviewURL might only work on device
                NSString *reviewURL = [@"itms-apps://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?type=Purple+Software&id=" stringByAppendingString:ID];
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:reviewURL]];
                break;
                
            case 2:
                X.highsSinceNag = 0;
                X.sessionsSinceNag = 0;
            default:
                break;
        }
    }
    else {
        NSLog(@"Unexpected alertView: %@ dismissed with button %d", alertView, buttonIndex);
    }
}

-(void) tutorial5b:(NSNotification *)notification {
    ANNOUNCE
    if (X.tutorialsEnabled) {
        X.level1TutorialsCompleted = YES;
    }
    
    if (X.level2TutorialsCompleted) {
        [[RLGameCenter singleton] submitAchievement:@"com.electricturkey.darken.finishedTutorials"
                                    percentComplete:(double)100.0
                                         showBanner:YES];
    }
    
    [X.boardP uponNotification:notification withExpectedName:@"didShakeDevice" setReceiverForName:nil target:nil selectorName:nil];
    [[MessageManager sharedManager] enqueueMessageWithText:@"Sometimes there will be no valid square for any of the waiting pips and the shredder will be full. If that happens you can use shaking to get back to this screen and start over." title:@"Why Use Shaking?"
                                                     delay:0.2f
                                                   onQueue:X.choiceSceneMessageQueue];
    if (X.level2TutorialsCompleted) {
        [[MessageManager sharedManager] enqueueMessageWithText:@"A final tip: high scores are gotten by keeping some squares undarkened, so play doesn't end, while darkening others again and again. As you gain tactical experience you will find your scores getting higher and higher." title:@"You Completed the Tutorials" delay:0.5f onQueue:X.choiceSceneMessageQueue];
        X.tutorialsEnabled = NO;
    } else {
        [[MessageManager sharedManager] enqueueMessageWithText:@"You completed the level 1 tutorials. Now tap the \"Do tutorial 2\" button and you will see a few more Darken features." title:@"Now do Tutorial 2"
                                                         delay:0.01f
                                                       onQueue:X.choiceSceneMessageQueue];
    }
    
    [[MessageManager sharedManager] showQueuedMessages];
}

-(void) tutorial23c:(NSNotification *)notification {
    ANNOUNCE
    [X.boardP uponNotification:notification withExpectedName:@"endByCompleting" setReceiverForName:nil target:nil selectorName:nil];
    X.level2TutorialsCompleted = YES;
    if (X.level1TutorialsCompleted) {
        [[RLGameCenter singleton] submitAchievement:@"com.electricturkey.darken.finishedTutorials"
                                    percentComplete:(double)100.0
                                         showBanner:YES];
    
        [[MessageManager sharedManager] enqueueMessageWithText:@"A final tip: high scores are gotten by keeping some squares undarkened, so play doesn't end, while darkening others again and again. As you gain tactical experience you will find your scores getting higher and higher." title:@"You Completed the Tutorials!" delay:0.5f onQueue:X.choiceSceneMessageQueue];
        X.tutorialsEnabled = NO;
    } else {
        [[MessageManager sharedManager] enqueueMessageWithText:@"You completed the level 2 tutorials. It is recommended that you also play the level 1 tutorials so you fully understand the features of Darken." title:@"You Can Now Advance to Level 3" delay:0.5f onQueue:X.choiceSceneMessageQueue];
    }
    
    [[MessageManager sharedManager] showQueuedMessages];
}


@end

