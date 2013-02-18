//
//  GameConfig.h
//  Darken
//
//  Created by Robert Lummis on 5/22/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

#ifndef __GAME_CONFIG_H
#define __GAME_CONFIG_H

    // COCOS2D_DEBUG is set in project Build Settings / Preprocessor Macros

struct params {   //used in developer scene
    int level; 
    int rows; 
    int columns; 
    int colors; 
    int shapes; 
    int bombs; 
    int stars; 
    int smart;
};

typedef struct params parameters;

enum choiceCodes {
    cMin,
    cReset,
    cLevel1,
    cTutorialLevel2,
    cInterrupted,
    cOtherLaunch,
    cCompleted,
    cFailed,
    cQuit,
    cMax
} choiceCode;

NSDate *nowDate;
NSTimeInterval elapsedTime;

#define X [Common sharedCommon]
#define NUMBEROFLEVELS 10
//#define FIRSTREPORTEDLEVEL 3    //sum of scores, etc. includes this level and higher levels
#define DEVELOPERFLAG NO
#define TESTFLAG NO
#define GRIDFLAG NO
#define PIPREVIEWFLAG NO

    //the following ANNOUNCE is for use with the redefined CCLOG (2 \n removed at end)
#define ANNOUNCE CCLOG( @"\n|... THREAD: %@\n|... SELF:   %@\n|... METHOD: %@(%d)", \
[NSThread currentThread], self, NSStringFromSelector(_cmd), __LINE__) ;

#define kLeaderboardScoreBase @"com.electricturkey.darken"

#define HIGHSFORNAG 3
#define SESSIONSFORNAG 7
#define ORIGINALSTARSONHAND 5
#define ORIGINALBOMBSONHAND 8
#define TUTORIALSTARS 3
#define TUTORIALBOMBS 3
#define BOMBFLAMETAG 77
#define EXPLOSIONTAG 78
#define LEVELLABELTAG 702   //LEVELTABLETAG is below
#define STATSLABELTAG 703
#define NEWHIGHTAG 704
#define HIGHSCORELABELTAG 705
#define HIGHSCOREVALUETAG 706
#define TOTALSCORELABELTAG 707
#define TOTALSCOREVALUETAG 708
#define LOCKVIEWTAG 709
#define PRODUCTLABELTAG 710
#define TUTORIALLABELTAG 711
#define LEVELTABLETAG 712
#define ZEROMARKERTAGBASE 1000
#define MARK1TAG 601
#define MARK2TAG 602
#define MARK3TAG 603
#define MARK4TAG 604
#define TUTORIAL0LABELTAG 605

#define BOARDNODEZ 0
#define BACKGROUNDZ -1
#define FRAMETOPANDBOTTOMZ 2
#define FRAMELEFTANDRIGHTZ 1
#define FRAMEDIVIDERZ 0
#define DARKNESSLAYERZ 0
#define DARKNESSLABELZ 3
#define PIPZ 4
#define ZEROMARKERZ PIPZ + 1
#define STARZ 4
#define BOMBZ 5
#define SCORELABELZ 1
#define DELTALABELZ 2
#define BOMBFLAMEZ 5    //put flame on bomb so this isn't used???

#define BACKGROUNDCOLOR ccc4(210, 210, 210, 255)    //   0.824 = 210/255
#define UIBACKGROUNDCOLOR [UIColor colorWithRed:0.824f green:0.824f blue:0.824f alpha:1.f]
#define MAXROWS 8	//no room for more
#define MINROWS 3   //probably should be 4. fewer too trivial
#define	MAXCOLUMNS 10	//no room for more; with 10 columns the undo button is too big and the scores could be too long
#define MINCOLUMNS 3    //probably should be 4. fewer too trivial
#define NDEFINEDCOLORS 9	//number of colors defined in Pip.m; color numbers are 0 ... (NDEFINEDCOLORS - 1)
                            //remember to adjust doExplosionAction, and PIP / initWithColor:(NSUInteger)colorNumber
                            //rembmer to adjust in doShredActionWithColor:(id)sender data:(void *)dat
#define MINCOLORS 3
#define NDEFINEDSYMBOLS 43	//n of symbol files (symbol0-hd.png to symbol<N-1>-hd.png) 99 star not included in count
#define MINSYMBOLS 3
#define MAXSMART 20
#define MINSMART 0
#define STARNUMBER 99   //symbol number of dropped star
#define BOUGHTSTARNUMBER 98
#define BOUGHTSTARCROSSEDOUTNUMBER 97
#define STARCOLORNUMBER 96  //very light gray
#define BOMBNUMBER 95    //symbol number of bomb without a flame
#define BOMBCROSSEDOUTNUMBER 94 //same as symbol 95 overlaid with a red "X"
#define NOCOLOR 90      //color number when we don't want to put a color on the pip

#define MINGAIN 0.0   //effects volume overall
#define MAXGAIN 0.99
#define MAXPITCH 1.2    //affect ping sounds
#define MINPITCH 0.5

#define PIPPLACETIME 0.4	//seconds to place pip on grid
#define FLASHTIME 0.3

#define EDGE -1
#define NOTILE -1
//#define EMPTY -99	//square is empty
#define FONTSIZE 32	//size of the symbols on the pips

//dimensions of 10x8 board (w x h)
#define BOTTOMFRAMEWIDTH 9	//width of border around the grid (depends on graphic)
#define TOPFRAMEWIDTH 9
#define SIDEFRAMEWIDTH 9
#define DIVIDERWIDTH 3	//width of dividers between cells of the grid (depends on graphic)
#define BOARDWIDTH 395	//width of the board, measured outside the border (depends on graphic)
#define BOARDHEIGHT 319	//height of the board, measured outside the border (depends on graphic)
#define CELLSPACING 38	//cell-to-cell distance in the grid
#define CELLWIDTH ( CELLSPACING - DIVIDERWIDTH )	//cell size

#define SIDEWIDTHLEFT 64	//area for pips, buttons, etc. on the left
#define	SIDEWIDTHRIGHT 63	//area for pips, buttons, etc. on the right
#define BUTTONWIDTH 38		//width of the buttons
#define PIPSIZE ( CELLWIDTH - 2 )	//width (& height) of a pip when on the grid

#define FEEDTIME 0.75	//seconds
#define MOVESPEED 550.	//points per second
#define DEFAULTLOUDNESS 3   //loudness setting at installation
#define ACCELEROMETERSENSITIVITY 1.3f    //lower is more sensitive
#define INDEX r*X.nColumns+c

	//
	// Supported Autorotations:
	//		None,
	//		UIViewController,
	//		CCDirector
	//
#define kGameAutorotationNone 0
#define kGameAutorotationCCDirector 1
#define kGameAutorotationUIViewController 2

	//
	// Define here the type of autorotation that you want for your game
	// 

    //the following up to "end copy" comment copied 10/15/2011 from the version distributed with cocos2d V1.0
    // 3rd generation and newer devices: Rotate using UIViewController. Rotation should be supported on iPad apps.
    // TIP:
    // To improve the performance, you should set this value to "kGameAutorotationNone" or "kGameAutorotationCCDirector"
#if defined(__ARM_NEON__) || TARGET_IPHONE_SIMULATOR
#define GAME_AUTOROTATION kGameAutorotationUIViewController

    // ARMv6 (1st and 2nd generation devices): Don't rotate. It is very expensive
#elif __arm__
#define GAME_AUTOROTATION kGameAutorotationNone


    // Ignore this value on Mac
#elif defined(__MAC_OS_X_VERSION_MAX_ALLOWED)

#else
#error(unknown architecture)
#endif
    //end copy

	// this must be from an older version. Seems that nothing can create portrait. Giving up for now.

    //#define GAME_AUTOROTATION kGameAutorotationUIViewController

#endif // __GAME_CONFIG_H