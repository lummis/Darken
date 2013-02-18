//
//  DeveloperScene.h
//  Darken
//
//  Created by Robert Lummis on 5/22/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

@interface DeveloperScene : CCLayer {
    
    parameters defaultParameters;
    
    float w, h; //winSize width and height
    int level;
    int levelSetByButtons;
    int nRows;
    int nColumns;
    int nColors;
    int nShapes;
    int smartCode;
    int nStars;
    int nBombs;
    BOOL showStar;
    BOOL showBomb;
    BOOL setAllByLevel;
    
    CCLabelTTF *rowsValueLabel;
    CCLabelTTF *columnsValueLabel;
    CCLabelTTF *colorsValueLabel;
    CCLabelTTF *shapesValueLabel;
    CCLabelTTF *smartValueLabel;
    CCLabelTTF *starsValueLabel;
    CCLabelTTF *bombsValueLabel;
    CCLabelTTF *levelValueLabel;
    
}

+(id) scene;
-(void) setAllForLevel;
-(void) saveChangesAndReturn;
-(void) discardChangesAndReturn;
-(void) addAdjustmentButtons;
-(void) plusRows;
-(void) minusRows;
-(void) plusColumns;
-(void) minusColumns;
-(void) plusColors;
-(void) minusColors;
-(void) plusShapes;
-(void) minusShapes;
-(void) plusSmart;
-(void) minusSmart;
-(void) toggleStars;
-(void) toggleBombs;
-(void) plusLevel;
-(void) minusLevel;
-(void) getBombs;
-(void) getStars;

@end

