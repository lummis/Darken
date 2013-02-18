//
//  GuideScene.h
//  Darken
//
//  Created by Robert Lummis on 4/22/12.
//  Copyright 2012 ElectricTurkey Software. All rights reserved.
//

@interface GuideScene : CCLayer {
    CGFloat w, h;   //screen width and height
    UIView *host;
    UITextView *textView;
    UIPageControl *pageControl;
}

+(id) scene;
-(void) addTitle;
-(void) addTextView;
-(NSString *) textForDisplay;
-(void) addDoneButton;
-(void) goBack;

@end
