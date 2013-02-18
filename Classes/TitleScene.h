//
//  TitleScene
//  Darken
//
//  Created by Robert Lummis on 9/22/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//


@interface TitleScene : CCLayer {
    UIAlertView *corruptionAlert;
    
}

+(id) scene;
-(void) enableTouch;
-(NSString *) version;
-(NSString *) build;
-(void) showActivityIndicatorThenStart;
-(void) showCorruptionAlert;


@end
