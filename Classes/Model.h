    //
    // Darken
    // Model.h created 8/15/2011 by Robert Lummis
    //

#import <StoreKit/StoreKit.h>

@class CCArray;

#ifndef DISABLEMESSAGES
@class MessageViewController;
#endif

@interface Model : NSObject <SKProductsRequestDelegate>

{
    parameters p[NUMBEROFLEVELS];
    UIAlertView *corruptionAlert;
    SKProductsRequest *bombProductsRequest;
    SKProductsRequest *starProductsRequest;
    BOOL retinaDisplay; //YES if the device has a retina display
    NSString *finishedTagString;
}

-(BOOL) hasRetinaDisplay;
-(void) launch;
-(void) outputParametersAll;
-(void) outputParametersForLevel:(int)level rating:(int)rating comment:(NSString *)comment;
-(void) start;
-(void) completed;
-(void) endByShaking;   //shake (or power off ?)
-(void) finishPlay;
-(void) getRating;
-(void) setParameters;
-(parameters) parametersForLevel:(int)level;
-(void) updateTotalScoresForLevel:(int)level withScore:(int)score;
-(void) updateBestScoresForLevel:(int)level withScore:(int)score;
-(void) incrementCountForLevel:(int)level inCCArray:(CCArray *)array;
-(void) decrementCountForLevel:(int)level inCCArray:(CCArray *)array;
-(void) incrementTimeBy:(NSTimeInterval)time forLevel:(int)level;
-(float) gainForLoudnessNumber:(int)loudnessNumber;
-(void) printCommon;    //for debugging
-(void) printCommonFull;
-(void) putDefaults;    //Common ==> user defaults
-(void) getDefaults;    //Common <== user defaults
-(BOOL) commonIsValid;
-(NSString *) build;
-(NSDictionary *) localyticsAttributesWithLevel:(int)level
                                  sessionNumber:(UInt32)session
                                          moves:(UInt32)moves
                                        minutes:(UInt32)time
                                          score:(UInt32)score
                                      bestScore:(UInt32)best
                                      starsUsed:(UInt32)stars
                                      bombsUsed:(UInt32)bombs;
-(void) corruptionRestart;

@end

