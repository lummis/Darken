//
//  DeveloperScene.m
//  Darken
//
//  Created by Robert Lummis on 5/22/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

#import "DeveloperScene.h"
#import "ChoiceScene.h"
#import "Model.h"

enum nodeTags{
    kRowsValueTag,
    kColumnsValueTag,
    kColorsValueTag,
    kShapesValueTag
};

float titleY = 300.f;
float rowsY = 240.f;
float columnsY = 205.f;
float colorsY = 170.f;
float shapesY = 135.f;
float returnY = 30.f;
float setAllMenuY = 90.f;
float setAllMenuX = 370.f; //anchorPoint middle
float labelsX = 80.f;  //anchor point at right end
float valuesX = 155.f;  //anchor point in middle

@implementation DeveloperScene

-(void) dealloc {
    CCLOG(@"DeveloperScene: dealloc");
    [super dealloc];
}

+(id) scene {
	ANNOUNCE
	CCScene *scene = [CCScene node];
	DeveloperScene *developerSceneNode = [DeveloperScene node];
	developerSceneNode.isTouchEnabled = YES;
	[scene addChild:developerSceneNode z:0];
	return scene;
}

-(id) init {
	ANNOUNCE
	if( (self = [super init]) ) {
		w = [[CCDirector sharedDirector] winSize].width;
        h = [[CCDirector sharedDirector] winSize].height;
//		CCLayerColor *cl = [CCLayerColor layerWithColor:ccc4(250, 50, 50, 255)];
//		[self addChild:cl z:-1];
		CCLabelTTF *label = [CCLabelTTF labelWithString:@"Developer Options" fontName:@"Arial Rounded MT Bold" fontSize:24];
		label.position =  ccp( w * 0.5f, titleY );
		label.color = ccBLACK;
		[self addChild:label z:0];
		
		[CCMenuItemFont setFontName:@"Helvetica-Bold"];
		[CCMenuItemFont setFontSize:20];
		CCMenuItemFont *discardReturnButton = [CCMenuItemFont itemFromString:@"Return Without Saving" target:self selector:@selector(discardChangesAndReturn)];
		discardReturnButton.isEnabled = YES;
        
		CCMenuItemFont *saveReturnButton = [CCMenuItemFont itemFromString:@"Save and Return" target:self selector:@selector(saveChangesAndReturn)];
        saveReturnButton.isEnabled = YES;
        
		CCMenu *returnMenu = [CCMenu menuWithItems:discardReturnButton, saveReturnButton, nil];
		returnMenu.position = ccp(w / 2.f, returnY);
		[returnMenu setColor: ccBLACK];
		[self addChild:returnMenu];
		[returnMenu alignItemsHorizontallyWithPadding:40];

        [self addAdjustmentButtons];
        
        X.developerParameters = NO;
        setAllByLevel = YES;
	}
	return self;
}

-(void) addAdjustmentButtons {
    float leftColumnX = 110.f;
    float rightColumnX = 0.5f * w + leftColumnX;
    float topY = 260.f;
    float dX1 = 14.f;   //label-to-value distance
    float dX2 = 70.f;   //label-to-buttons distance
    float deltaY = 35.f;    //vertical separation between items
    
    /*
     rows       stars
     columns    bombs
     colors     
     shapes     smart
     level
     */
    
    /* parameters: lvl row col clr shp bmb str smt */
    
    defaultParameters = [X.modelP parametersForLevel:X.level];
    
        //level
    level = X.level;
    levelSetByButtons = level;  //initialize with level but if changed keep new value in levelSetByButtons
    CCLabelTTF *levelLabel = [CCLabelTTF labelWithString:@"Level" fontName:@"Arial" fontSize:16];
    levelLabel.color = ccBLACK;
    levelLabel.anchorPoint = ccp(1.f, 0.5f);
    levelLabel.position = ccp(leftColumnX, topY - 4.f * deltaY);
    [self addChild:levelLabel];
    levelValueLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", level]
                                         fontName:@"Arial" 
                                         fontSize:16];
    levelValueLabel.color = ccBLACK;
    levelValueLabel.anchorPoint = ccp(0.0f, 0.5f);
    levelValueLabel.position = ccp(leftColumnX + dX1, topY - 4.f * deltaY);
    [self addChild:levelValueLabel];
    CCMenuItemImage *plusLevelButton = [CCMenuItemImage 
                                       itemFromNormalImage:@"plusButton.png"
                                       selectedImage:@"plusButton.png"
                                       disabledImage:@"plusButton.png"
                                       target:self
                                       selector:@selector(plusLevel)];
    CCMenuItemImage *minusLevelButton = [CCMenuItemImage 
                                        itemFromNormalImage:@"minusButton.png"
                                        selectedImage:@"minusButton.png"
                                        disabledImage:@"minusButton.png"
                                        target:self
                                        selector:@selector(minusLevel)];
    plusLevelButton.scale = 0.3f;
    minusLevelButton.scale = 0.3f;
    plusLevelButton.isEnabled = YES;
    minusLevelButton.isEnabled = YES;
    CCMenu *levelMenu = [CCMenu menuWithItems: minusLevelButton, plusLevelButton, nil];
    levelMenu.anchorPoint = ccp(0.5f, 0.5f);
    [levelMenu alignItemsHorizontally];
    levelMenu.position = ccp(leftColumnX + dX2, topY - 4.f * deltaY);
    [self addChild:levelMenu];
    
        //set all for level
    CCMenuItemFont *setForLevelButton = [CCMenuItemFont itemFromString:@"Set all for Level" target:self selector:@selector(setAllForLevel)];
    CCMenu *setAllMenu = [CCMenu menuWithItems:setForLevelButton, nil];
    setAllMenu.anchorPoint = ccp(0.5, 0.5);
    setAllMenu.position = ccp(rightColumnX, topY - 4.f * deltaY);
    [setAllMenu setColor:ccBLACK];
    [setAllMenu alignItemsHorizontally];
    [self addChild:setAllMenu];
    
        //get bombs
    CCMenuItemFont *getBombsButton = [CCMenuItemFont itemFromString:@"Get bombs" target:self selector:@selector(getBombs)];
    CCMenu *getBombsMenu = [CCMenu menuWithItems:getBombsButton, nil];
    getBombsMenu.anchorPoint = ccp(0.0, 0.5);
    getBombsMenu.position = ccp(leftColumnX, topY - 5.f * deltaY);
    [getBombsMenu setColor:ccBLACK];
    [getBombsMenu alignItemsHorizontally];
    [self addChild:getBombsMenu];
    
        //get stars
    CCMenuItemFont *getStarsButton = [CCMenuItemFont itemFromString:@"Get stars" target:self selector:@selector(getStars)];
    CCMenu *getStarsMenu = [CCMenu menuWithItems:getStarsButton, nil];
    getStarsMenu.anchorPoint = ccp(0.0, 0.5);
    getStarsMenu.position = ccp(rightColumnX, topY - 5.f * deltaY);
    [getStarsMenu setColor:ccBLACK];
    [getStarsMenu alignItemsHorizontally];
    [self addChild:getStarsMenu];
    
        //rows
    nRows = defaultParameters.rows;
    CCLabelTTF *rowsLabel = [CCLabelTTF labelWithString:@"Rows" fontName:@"Arial" fontSize:16];
    rowsLabel.color = ccBLACK;
    rowsLabel.anchorPoint = ccp(1.f, 0.5f);
    rowsLabel.position = ccp(leftColumnX, topY);
    [self addChild:rowsLabel];
    rowsValueLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", nRows]
                                        fontName:@"Arial" 
                                        fontSize:16];
    rowsValueLabel.color = ccBLACK;
    rowsValueLabel.anchorPoint = ccp(0.0f, 0.5f);
    rowsValueLabel.position = ccp(leftColumnX + dX1, topY);
    [self addChild:rowsValueLabel];
    CCMenuItemImage *plusRowsButton = [CCMenuItemImage 
                  itemFromNormalImage:@"plusButton.png"
                  selectedImage:@"plusButton.png"
                  disabledImage:@"plusButton.png"
                  target:self
                selector:@selector(plusRows)];
    CCMenuItemImage *minusRowsButton = [CCMenuItemImage 
                  itemFromNormalImage:@"minusButton.png"
                  selectedImage:@"minusButton.png"
                  disabledImage:@"minusButton.png"
                  target:self
                  selector:@selector(minusRows)];
    plusRowsButton.scale = 0.3f;
    minusRowsButton.scale = 0.3f;
    plusRowsButton.isEnabled = YES;
    minusRowsButton.isEnabled = YES;
    CCMenu *rowsMenu = [CCMenu menuWithItems: minusRowsButton, plusRowsButton, nil];
    rowsMenu.anchorPoint = ccp(0.5f, 0.5f);
    [rowsMenu alignItemsHorizontally];
    rowsMenu.position = ccp(leftColumnX + dX2, topY);
    [self addChild:rowsMenu];
    
        //columns
    nColumns = defaultParameters.columns;
    CCLabelTTF *columnsLabel = [CCLabelTTF labelWithString:@"Columns" fontName:@"Arial" fontSize:16];
    columnsLabel.color = ccBLACK;
    columnsLabel.anchorPoint = ccp(1.f, 0.5f);
    columnsLabel.position = ccp(leftColumnX, topY - deltaY);
    [self addChild:columnsLabel];
    columnsValueLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", nColumns]
                                        fontName:@"Arial" 
                                        fontSize:16];
    columnsValueLabel.color = ccBLACK;
    columnsValueLabel.anchorPoint = ccp(0.0f, 0.5f);
    columnsValueLabel.position = ccp(leftColumnX + dX1, topY - deltaY);
    [self addChild:columnsValueLabel];
    CCMenuItemImage *plusColumnsButton = [CCMenuItemImage 
                                       itemFromNormalImage:@"plusButton.png"
                                       selectedImage:@"plusButton.png"
                                       disabledImage:@"plusButton.png"
                                       target:self
                                       selector:@selector(plusColumns)];
    CCMenuItemImage *minusColumnsButton = [CCMenuItemImage 
                                        itemFromNormalImage:@"minusButton.png"
                                        selectedImage:@"minusButton.png"
                                        disabledImage:@"minusButton.png"
                                        target:self
                                        selector:@selector(minusColumns)];
    plusColumnsButton.scale = 0.3f;
    minusColumnsButton.scale = 0.3f;
    plusColumnsButton.isEnabled = YES;
    minusColumnsButton.isEnabled = YES;
    CCMenu *columnsMenu = [CCMenu menuWithItems: minusColumnsButton, plusColumnsButton, nil];
    columnsMenu.anchorPoint = ccp(0.5f, 0.5f);
    [columnsMenu alignItemsHorizontally];
    columnsMenu.position = ccp(leftColumnX + dX2, topY - deltaY);
    [self addChild:columnsMenu];
    
        //colors
    nColors = defaultParameters.colors;
    CCLabelTTF *colorsLabel = [CCLabelTTF labelWithString:@"Colors" fontName:@"Arial" fontSize:16];
    colorsLabel.color = ccBLACK;
    colorsLabel.anchorPoint = ccp(1.0f, 0.5f);
    colorsLabel.position = ccp(rightColumnX, topY);
    [self addChild:colorsLabel];
    colorsValueLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", nColors]
                                        fontName:@"Arial" 
                                        fontSize:16];
    colorsValueLabel.color = ccBLACK;
    colorsValueLabel.anchorPoint = ccp(0.0f, 0.5f);
    colorsValueLabel.position = ccp(rightColumnX + dX1, topY);
    [self addChild:colorsValueLabel];
    CCMenuItemImage *plusColorsButton = [CCMenuItemImage 
                                       itemFromNormalImage:@"plusButton.png"
                                       selectedImage:@"plusButton.png"
                                       disabledImage:@"plusButton.png"
                                       target:self
                                       selector:@selector(plusColors)];
    CCMenuItemImage *minusColorsButton = [CCMenuItemImage 
                                        itemFromNormalImage:@"minusButton.png"
                                        selectedImage:@"minusButton.png"
                                        disabledImage:@"minusButton.png"
                                        target:self
                                        selector:@selector(minusColors)];
    plusColorsButton.scale = 0.3f;
    minusColorsButton.scale = 0.3f;
    plusColorsButton.isEnabled = YES;
    minusColorsButton.isEnabled = YES;
    CCMenu *colorsMenu = [CCMenu menuWithItems: minusColorsButton, plusColorsButton, nil];
    colorsMenu.anchorPoint = ccp(0.5f, 0.5f);
    [colorsMenu alignItemsHorizontally];
    colorsMenu.position = ccp(rightColumnX + dX2, topY);
    [self addChild:colorsMenu];
    
        //shapes
    nShapes = defaultParameters.shapes;
    CCLabelTTF *shapesLabel = [CCLabelTTF labelWithString:@"Shapes" fontName:@"Arial" fontSize:16];
    shapesLabel.color = ccBLACK;
    shapesLabel.anchorPoint = ccp(1.f, 0.5f);
    shapesLabel.position = ccp(rightColumnX, topY - deltaY);
    [self addChild:shapesLabel];
    shapesValueLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", nShapes]
                                           fontName:@"Arial" 
                                           fontSize:16];
    shapesValueLabel.color = ccBLACK;
    shapesValueLabel.anchorPoint = ccp(0.0f, 0.5f);
    shapesValueLabel.position = ccp(rightColumnX + dX1, topY - deltaY);
    [self addChild:shapesValueLabel];
    CCMenuItemImage *plusShapesButton = [CCMenuItemImage 
                                          itemFromNormalImage:@"plusButton.png"
                                          selectedImage:@"plusButton.png"
                                          disabledImage:@"plusButton.png"
                                          target:self
                                          selector:@selector(plusShapes)];
    CCMenuItemImage *minusShapesButton = [CCMenuItemImage 
                                           itemFromNormalImage:@"minusButton.png"
                                           selectedImage:@"minusButton.png"
                                           disabledImage:@"minusButton.png"
                                           target:self
                                           selector:@selector(minusShapes)];
    plusShapesButton.scale = 0.3f;
    minusShapesButton.scale = 0.3f;
    plusShapesButton.isEnabled = YES;
    minusShapesButton.isEnabled = YES;
    CCMenu *shapesMenu = [CCMenu menuWithItems: minusShapesButton, plusShapesButton, nil];
    shapesMenu.anchorPoint = ccp(0.5f, 0.5f);
    [shapesMenu alignItemsHorizontally];
    shapesMenu.position = ccp(rightColumnX + dX2, topY - deltaY);
    [self addChild:shapesMenu];

        //smarts
    smartCode = defaultParameters.smart;
    CCLabelTTF *smartLabel = [CCLabelTTF labelWithString:@"Smart Code" fontName:@"Arial" fontSize:16];
    smartLabel.color = ccBLACK;
    smartLabel.anchorPoint = ccp(1.f, 0.5f);
    smartLabel.position = ccp(rightColumnX, topY - 3.f * deltaY);
    [self addChild:smartLabel];
    smartValueLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", smartCode]
                                         fontName:@"Arial" 
                                         fontSize:16];
    smartValueLabel.color = ccBLACK;
    smartValueLabel.anchorPoint = ccp(0.0f, 0.5f);
    smartValueLabel.position = ccp(rightColumnX + dX1, topY - 3.0f * deltaY);
    [self addChild:smartValueLabel];
    CCMenuItemImage *plusSmartButton = [CCMenuItemImage 
                                        itemFromNormalImage:@"plusButton.png"
                                        selectedImage:@"plusButton.png"
                                        disabledImage:@"plusButton.png"
                                        target:self
                                        selector:@selector(plusSmart)];
    CCMenuItemImage *minusSmartButton = [CCMenuItemImage 
                                         itemFromNormalImage:@"minusButton.png"
                                         selectedImage:@"minusButton.png"
                                         disabledImage:@"minusButton.png"
                                         target:self
                                         selector:@selector(minusSmart)];
    plusSmartButton.scale = 0.3f;
    minusSmartButton.scale = 0.3f;
    plusSmartButton.isEnabled = YES;
    minusSmartButton.isEnabled = YES;
    CCMenu *smartMenu = [CCMenu menuWithItems: minusSmartButton, plusSmartButton, nil];
    smartMenu.anchorPoint = ccp(0.5f, 0.5f);
    [smartMenu alignItemsHorizontally];
    smartMenu.position = ccp(rightColumnX + dX2, topY - 3.0f * deltaY);
    [self addChild:smartMenu];

        //stars
    showStar = defaultParameters.stars ? YES : NO;
    nStars = showStar ? 10 : 0;
    CCLabelTTF *starsLabel = [CCLabelTTF labelWithString:@"Show Stars" fontName:@"Arial" fontSize:16];
    starsLabel.color = ccBLACK;
    starsLabel.anchorPoint = ccp(1.f, 0.5f);
    starsLabel.position = ccp(leftColumnX, topY - 2.f * deltaY);
    [self addChild:starsLabel];
    starsValueLabel = [CCLabelTTF labelWithString:showStar ? @"Yes" : @"No"
                                         fontName:@"Arial" 
                                         fontSize:16];
    starsValueLabel.color = ccBLACK;
    starsValueLabel.anchorPoint = ccp(0.0f, 0.5f);
    starsValueLabel.position = ccp(leftColumnX + dX1, topY - 2.0f * deltaY);
    [self addChild:starsValueLabel];
    
    CCMenuItemImage *toggleStarsButton = [CCMenuItemImage 
                                        itemFromNormalImage:@"toggleButton.png"
                                        selectedImage:@"toggleButton.png"
                                        disabledImage:@"toggleButton.png"
                                        target:self
                                        selector:@selector(toggleStars)];
    toggleStarsButton.scale = 0.35f;
    toggleStarsButton.isEnabled = YES;
    CCMenu *starsMenu = [CCMenu menuWithItems:toggleStarsButton, nil];
    
    starsMenu.anchorPoint = ccp(0.5f, 0.5f);
    [starsMenu alignItemsHorizontally];
    starsMenu.position = ccp(leftColumnX + dX2, topY - 2.0f * deltaY);
    [self addChild:starsMenu];
        
        //bombs
    showBomb = defaultParameters.bombs ? YES : NO;
    nBombs = showBomb ? 10 : 0;
    CCLabelTTF *bombsLabel = [CCLabelTTF labelWithString:@"Show Bombs" fontName:@"Arial" fontSize:16];
    bombsLabel.color = ccBLACK;
    bombsLabel.anchorPoint = ccp(1.f, 0.5f);
    bombsLabel.position = ccp(leftColumnX, topY - 3.f * deltaY);
    [self addChild:bombsLabel];
    bombsValueLabel = [CCLabelTTF labelWithString:showBomb ? @"Yes" : @"No"
                                         fontName:@"Arial" 
                                         fontSize:16];
    bombsValueLabel.color = ccBLACK;
    bombsValueLabel.anchorPoint = ccp(0.0f, 0.5f);
    bombsValueLabel.position = ccp(leftColumnX + dX1, topY - 3.0f * deltaY);
    [self addChild:bombsValueLabel];
    
    CCMenuItemImage *toggleBombsButton = [CCMenuItemImage 
                                          itemFromNormalImage:@"toggleButton.png"
                                          selectedImage:@"toggleButton.png"
                                          disabledImage:@"toggleButton.png"
                                          target:self
                                          selector:@selector(toggleBombs)];
    toggleBombsButton.scale = 0.35f;
    toggleBombsButton.isEnabled = YES;
    CCMenu *bombsMenu = [CCMenu menuWithItems:toggleBombsButton, nil];
    
    bombsMenu.anchorPoint = ccp(0.5f, 0.5f);
    [bombsMenu alignItemsHorizontally];
    bombsMenu.position = ccp(leftColumnX + dX2, topY - 3.0f * deltaY);
    [self addChild:bombsMenu];

}

-(void) plusRows {
    if (nRows < MAXROWS) {
        nRows++;
        rowsValueLabel.string = [NSString stringWithFormat:@"%d", nRows];
        setAllByLevel = NO;
    }
}

-(void) minusRows {
    if (nRows > MINROWS) {
        nRows--;
        rowsValueLabel.string = [NSString stringWithFormat:@"%d", nRows];
        setAllByLevel = NO;
    }
}

-(void) plusColumns {
    if (nColumns < MAXCOLUMNS) {
        nColumns++;
        columnsValueLabel.string = [NSString stringWithFormat:@"%d", nColumns];
        setAllByLevel = NO;
    }
}

-(void) minusColumns {
    if (nColumns > MINCOLUMNS) {
        nColumns--;
        columnsValueLabel.string = [NSString stringWithFormat:@"%d", nColumns];
        setAllByLevel = NO;
    }
}

-(void) plusColors {
    if (nColors < NDEFINEDCOLORS) {
        nColors++;
        colorsValueLabel.string = [NSString stringWithFormat:@"%d", nColors];
        setAllByLevel = NO;
    }
}

-(void) minusColors {
    if (nColors > MINCOLORS) {
        nColors--;
        colorsValueLabel.string = [NSString stringWithFormat:@"%d", nColors];
        setAllByLevel = NO;
    }
}

-(void) plusShapes {
    if (nShapes < NDEFINEDSYMBOLS) {
        nShapes++;
        shapesValueLabel.string = [NSString stringWithFormat:@"%d", nShapes];
        setAllByLevel = NO;
    }
}

-(void) minusShapes {
    if (nShapes > MINSYMBOLS) {
        nShapes--;
        shapesValueLabel.string = [NSString stringWithFormat:@"%d", nShapes];
        setAllByLevel = NO;
    }
}

-(void) plusSmart {
    if (smartCode < MAXSMART) {
        smartCode++;
        smartValueLabel.string = [NSString stringWithFormat:@"%d", smartCode];
        setAllByLevel = NO;
    }
}

-(void) minusSmart {
    if (smartCode > MINSMART) {
        smartCode--;
        smartValueLabel.string = [NSString stringWithFormat:@"%d", smartCode];
        setAllByLevel = NO;
    }
}

-(void) toggleStars {
    showStar = showStar ? NO : YES;
    starsValueLabel.string = [NSString stringWithFormat:showStar ? @"Yes" : @"No"];
    setAllByLevel = NO;
}

-(void) toggleBombs {
    showBomb = showBomb ? NO : YES;
    bombsValueLabel.string = [NSString stringWithFormat:showBomb ? @"Yes" : @"No"];
    setAllByLevel = NO;
}

-(void) plusLevel {
    if (levelSetByButtons < X.numberOfLevels) {
        levelSetByButtons++;
        levelValueLabel.string = [NSString stringWithFormat:@"%2d", levelSetByButtons];
    }
}

-(void) minusLevel {
    CCLOG(@"minusLevel action");
    if (levelSetByButtons > 1) {
        levelSetByButtons--;
        levelValueLabel.string = [NSString stringWithFormat:@"%2d", levelSetByButtons];
    }
}

-(void) setAllForLevel {
    CCLOG(@"setAllForLevel");
        //set parameters to their 'default' values for the level set by the level button
    defaultParameters = [X.modelP parametersForLevel:levelSetByButtons];
    nRows = defaultParameters.rows;
    nColumns = defaultParameters.columns;
    nColors = defaultParameters.colors;
    nShapes = defaultParameters.shapes;
    smartCode = defaultParameters.smart;
    showStar = defaultParameters.stars ? YES : NO;
    showBomb = defaultParameters.bombs ? YES : NO;
    
    rowsValueLabel.string = [NSString stringWithFormat:@"%d", nRows];
    columnsValueLabel.string = [NSString stringWithFormat:@"%d", nColumns];
    colorsValueLabel.string = [NSString stringWithFormat:@"%d", nColors];
    shapesValueLabel.string = [NSString stringWithFormat:@"%d", nShapes];
    smartValueLabel.string = [NSString stringWithFormat:@"%d", smartCode];
    starsValueLabel.string = [NSString stringWithFormat:showStar ? @"Yes" : @"No"];
    bombsValueLabel.string = [NSString stringWithFormat:showBomb ? @"Yes" : @"No"];
    
    setAllByLevel = YES;
}

-(void) saveChangesAndReturn {
    if (setAllByLevel) {
        X.developerParameters = NO;
        X.level = levelSetByButtons;
    } else {
        X.developerParameters = YES;    //may be set to a locked level
        X.nRows = nRows;
        X.nColumns = nColumns;
        X.nColors = nColors;
        X.nShapes = nShapes;
        X.smartCode = smartCode;
        X.starsOnHand = showStar ? 10 : 0;
        X.showStar = showStar;
        X.showBomb = showBomb;
        X.bombsOnHand = showBomb ? 10 : 0;
    }
    
    CCTransitionFade *tran = [CCTransitionFade transitionWithDuration:0.5f scene:[ChoiceScene scene]];
	[[CCDirector sharedDirector] replaceScene:tran];
}

-(void) discardChangesAndReturn {
    X.developerParameters = NO;
    CCTransitionFade *tran = [CCTransitionFade transitionWithDuration:0.5f scene:[ChoiceScene scene]];
    [[CCDirector sharedDirector] replaceScene:tran];
}

-(void) getBombs {
    X.bombsOnHand += 15;
}

-(void) getStars {
    X.starsOnHand += 5;
}

@end

