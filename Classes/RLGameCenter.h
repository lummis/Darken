//
//  RLGameCenter.h
//  Darken
//
//  Created by Robert Lummis on 11/7/12.
//  Copyright (c) 2012 ElectricTurkey Software. All rights reserved.
//

#import <GameKit/GameKit.h>

//#define ANNOUNCE NSLog( @"\n|... THREAD: %@\n|... SELF:   %@\n|... METHOD: %@(%d)", \
//[NSThread currentThread], self, NSStringFromSelector(_cmd), __LINE__) ;

@interface RLGameCenter : NSObject <GKGameCenterControllerDelegate> {

    NSError *_lastError;
    __block NSArray *serverAchievements;
    UIAlertView *errorAlert;
}

@property (nonatomic, readonly) NSError *lastError;

+(id) singleton;
-(void) authenticateLocalPlayer;
-(void) authenticationChanged;
-(void) setLastError:(NSError *)err;
-(void) alertView:(id)sender clickedButtonAtIndex:(NSInteger)buttonIndex;
-(void) presentViewController:(UIViewController *)vc;
-(void) submitScore:(int64_t)score category:(NSString *)category;
-(void) submitAchievement:(NSString *)achievementName percentComplete:(double)percentComplete showBanner:(BOOL)showBanner;
-(void) logAchievements;
-(void) resetAchievements;
-(BOOL) os6;    // iOS version; if YES iOS 6, if NO assume iOS 5

@end
