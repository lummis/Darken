//
//  ChoiceScene.h
//  Darken
//
//  Created by Robert Lummis on 5/22/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

#import "RLButton.h"
#import <GameKit/GameKit.h>
#import "SimpleAudioEngine.h"

@interface ChoiceScene : CCLayer 
    <UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate, UIAccelerometerDelegate> {
        CGFloat w;  //screen width
        CGFloat h;  //screen height
        UIView *host;
        UIAccelerometer *accelerometer;
            
        BOOL alertViewIsShowing;
        
        CGPoint developerPoint;
        CGPoint printPoint;
            
        NSNumberFormatter *formatter;

        UIImage *borderImage;
        CGFloat borderThickness;
        CGFloat statusMessageX, statusMessageY, statusMessageW, statusMessageH;
        CGFloat sumColonX;
        CGFloat sum1Y, sum1H;
        CGFloat sum2Y, sum2H;
        CGFloat scrollLabelX, scrollLabelY, scrollLabelW, scrollLabelH;
        CGFloat easyLabelX, easyLabelY, easyLabelW, easyLabelH;
        CGFloat levelTableRowHeight, levelTableX, levelTableY, levelTableW, levelTableH;
    //    CGFloat levelTableHeaderH;
        CGFloat settingsButtonX, settingsButtonY, settingsButtonW, settingsButtonH;
        CGFloat buyButtonX, buyButtonY, buyButtonW, buyButtonH;
        CGFloat leaderButtonX, leaderButtonY, leaderButtonW, leaderButtonH;
        CGFloat achievementsButtonX, achievementsButtonY, achievementsButtonW, achievementsButtonH;
        CGFloat playButtonX, playButtonY, playButtonW, playButtonH;

        enum _cellType {
            unlocked,   //unlocked
            locked      //locked
        } cellType;

        CGFloat cellTextX, cellColonX, cellScoreX;
        UILabel *scrollLabel;
        UILabel *levelLabel;
        UILabel *tutorialLabel;
        UILabel *highScoreLabel;
        UILabel *highScoreValueLabel;
        UILabel *totalScoreLabel;
        UILabel *totalScoreValueLabel;
        UILabel *noScoreLabelLine1;
        UILabel *noScoreLabelLine2;
        UILabel *statsLabel;
        UILabel *newHighLabel;
        UIImageView *lockView;
        
            //normal colors are the same for all cells
        UIColor *normalLevelLabelColor;
        UIColor *normalTutorialLabelColor;
        UIColor *normalStatsLabelColor;
        
        UILabel *statusMessage;
            
        UILabel *developerLabel;
        UILabel *printLabel;
        
        UITableView *levelTable;
        RLButton *settingsButton;
        RLButton *buyButton;
        RLButton *leaderButton;
        RLButton *achievementsButton;
        RLButton *playButton;
        
        NSInteger countdown;
        
        SimpleAudioEngine *sae;
        
        UIAlertView *nagAlertView;
	
}

+(id) scene;
-(void) onEnterTransitionDidFinish;
-(void) addLevelTable;
-(void) selectAndWhiten:(NSIndexPath *)indexPath;
-(void) addSumLabels;
    //whiten and also scroll to that row (doesn't always scroll properly)
-(void) whitenTextInNewCell:(UITableView *)tableView newIndexPath:(NSIndexPath *)newIndexPath oldIndexPath:(NSIndexPath *)oldIndexPath;
-(void) addGrid;
-(void) addSettingsButton;
-(void) addPlayButton;
-(void) registerWithTouchDispatcher;
-(BOOL) ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event;
-(BOOL) isClose:(CGPoint)pointA to:(CGPoint)pointB allowedRange:(CGSize)range;
-(void) goDeveloper;
-(void) goSettings;
-(void) goPlay;
-(void) alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex;
//-(void) accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration;

-(void) tutorial5b:(NSNotification *)notification;
-(void) tutorial23c:(NSNotification *)notification;


@end
