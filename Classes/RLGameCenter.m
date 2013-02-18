//
//  RLGameCenter.m
//  Darken
//
//  Created by Robert Lummis on 11/7/12.
//  Copyright (c) 2012 ElectricTurkey Software. All rights reserved.
//

#import "RLGameCenter.h"

@implementation RLGameCenter

-(void) dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark -  Singleton stuff

+(id) singleton {
    static RLGameCenter *singleton;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[RLGameCenter alloc] init];
    });
    return singleton;
}

-(id) init {
    ANNOUNCE
    if ( ( self = [super init] ) ) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self
               selector:@selector(authenticationChanged)
                   name:GKPlayerAuthenticationDidChangeNotificationName
                 object:nil];
    }
    return self;
}

#pragma mark - Authenticate Local Player

-(void) authenticateLocalPlayer {
    ANNOUNCE
    GKLocalPlayer *localPlayer = [GKLocalPlayer localPlayer];
    _lastError = nil;
    
            //iOS 6
    if ( [self os6] ) {
        localPlayer.authenticateHandler = ^(UIViewController *loginVC, NSError *error) {
            CCLOG(@"in authenticateHandler 1");
            [self setLastError:error];
                //... resume application responses
            [[CCDirector sharedDirector] resume];   //if not paused does nothing 
            if ( [GKLocalPlayer localPlayer].authenticated ) {
                CCLOG(@"in authenticateHandler 2 - local player is authenticated");
            } else if (loginVC) {
                CCLOG(@"in authenticateHandler 3 - local player is not authenticated, will present VC");
                    //... pause applications responses
                [[CCDirector sharedDirector] pause];
                [self presentViewController:loginVC];
            } else {
                CCLOG(@"in authenticateHandler 4 - local player is NOT authenticated, no VC returned");
            }
            CCLOG(@"authenticateHandler error: %@", error.localizedDescription);
        };
        
            //iOS 5
    } else {
        if ( [GKLocalPlayer localPlayer].authenticated == NO ) {
                //no completion handler because we're relying on NSNotificationCenter
            [[GKLocalPlayer localPlayer] authenticateWithCompletionHandler:nil];
            CCLOG(@"local player authentication requested");
        } else {
            CCLOG(@"local player was already authenticated");
        }
    }
}

-(void) authenticationChanged {
    ANNOUNCE
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        if ( [GKLocalPlayer localPlayer].authenticated ) {
            CCLOG(@"authenticationChanged: player is authenticated");
        } else {
            CCLOG(@"authenticationChanged: now player is not authenticated");
        }
    });
}

#pragma mark - Error stuff

-(void) setLastError:(NSError *)error {
    ANNOUNCE
    _lastError = [error copy];
    if (_lastError) {
        CCLOG(@"RLGameCenter Error: %@", _lastError.localizedDescription);
        CCLOG(@"local player is authenticated: %d", [GKLocalPlayer localPlayer].authenticated);
        errorAlert = [[UIAlertView alloc]
                                    initWithTitle:@"Game Center Error"
                                    message:[NSString stringWithFormat:@"%@",_lastError]
                                    delegate:self cancelButtonTitle:@"OK"
                                    otherButtonTitles:nil];
        [errorAlert show];
    }
    [_lastError release];
}

-(void) alertView:(id)sender clickedButtonAtIndex:(NSInteger)buttonIndex {
    ANNOUNCE
        //the following assert causes a crash and maybe damages the app if an Apple alert is showing and is dismissed
//    NSAssert(sender == errorAlert, @"AlertView: unrecognized sender");
    [errorAlert release];
    errorAlert = nil;
    return; //the OK button was tapped in the alert
}

#pragma mark - UIViewController stuff

-(void) presentViewController:(UIViewController *)vc {
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    [rootVC presentViewController:vc animated:YES completion:nil];
}

#pragma mark - submit to game center

-(void) submitScore:(int64_t)score category:(NSString *)leaderboardIdentifier {
    ANNOUNCE
    if (!!![GKLocalPlayer localPlayer].authenticated) {
        return;
    }
    
    GKScore *gkScore = [[[GKScore alloc] initWithCategory:leaderboardIdentifier] autorelease];
    gkScore.value = score;
    [gkScore reportScoreWithCompletionHandler:^(NSError *error) {
        [self setLastError:error];
    }];
}

-(void) submitAchievement:(NSString *)achievementName percentComplete:(double)percentComplete showBanner:(BOOL)showBanner {
    ANNOUNCE
    if (!!![GKLocalPlayer localPlayer].authenticated) {
        return;
    }
    NSAssert(percentComplete >= 0.0, @"percentComplete not >= 0.0");
    if (percentComplete > 100.) percentComplete = 100.;
    CCLOG(@"reporting achievement:%@, percentComplete:%g, banner:%d", achievementName, percentComplete, showBanner);
    
    GKAchievement *achievement = [[[GKAchievement alloc] initWithIdentifier:achievementName] autorelease];
    achievement.showsCompletionBanner = showBanner;
    achievement.percentComplete = percentComplete;
    
    NSString *blockAchievementName = [achievementName copy];    //can't use method arg in block ?
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
        if (error) {
            CCLOG(@"achievement not reported: %@", blockAchievementName);
            CCLOG(@"loadAchievementsWithCompletionHandler error: %@", error.localizedDescription);
            [self setLastError:error];
            [blockAchievementName release];
            return;
        }
        
        CCLOG(@"loadAchievementsWithCompletionHandler [achievements count]: %d", [achievements count]);
        for (GKAchievement *ach in achievements) {
            if ( [ach.identifier isEqualToString:achievementName] && ach.completed) {
                CCLOG(@"achievement already completed: %@ so don't submit", achievementName);
                [blockAchievementName release];
                return;
            }
        }
            //if we get here the achievement was not already submitted & the localPlayer is authenticated
        [achievement reportAchievementWithCompletionHandler:^(NSError *error) {
            if (error) {
                CCLOG(@"failed to report achievement: %@, error: %@", blockAchievementName, error.localizedDescription );
            } else {
                CCLOG(@"achievement: %@ reported successfully with percent complete: %f.", blockAchievementName, achievement.percentComplete);
            }
            [blockAchievementName release];
        }];
    }];
}

-(void) logAchievements {
    ANNOUNCE
    if (!!![GKLocalPlayer localPlayer].authenticated) {
        return;
    }
    [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
        if (error) {
            CCLOG(@"loadAchievementsWithCompletionHandler error: %@", error.localizedDescription);
            [self setLastError:error];
            return;
        }
        else {
            CCLOG(@"loadAchievementsWithCompletionHandler returned %d achievements:", [achievements count]);
            for (GKAchievement *ach in achievements) {
                CCLOG(@"achievement name: %@, percent complete: %f", ach.identifier, ach.percentComplete);
            }
        }
    }];
}

        //not good as is - we aren't dealing with the possibility of no response or other error
        //also I think this has to have main thread stuff

    //developer use only
-(void) resetAchievements {
    ANNOUNCE
    if (!!![GKLocalPlayer localPlayer].authenticated) {
        CCLOG(@"Can't reset achievements because local player is not authenticated");
        return;
    }
    [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error) {
        if (error) {
            CCLOG(@"failed to reset achievements. error: %@", error.localizedDescription );
            [self setLastError:error];
        } else {
            CCLOG(@"achievements reset");
        }
    }];
}

#pragma mark - GKGameCenterControllerDelegate required method

-(void) gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController {
        //GKLocalPlayer class reference says the game center VC is dismissed automatically
    ANNOUNCE
        //... resume application responses
}


-(BOOL) os6 {
    ANNOUNCE
    NSString *targetSystemVersion = @"6.0";
    NSString *currentSystemVersion = [[UIDevice currentDevice] systemVersion];
    if ([currentSystemVersion compare:targetSystemVersion options:NSNumericSearch] == NSOrderedAscending) {
        return NO;  //current system version is less than 6.0
    } else {
        return YES;
    }
}

@end
