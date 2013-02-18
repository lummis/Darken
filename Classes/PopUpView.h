//
//  PopUpView.h
//  Darken
//
//  Created by Robert Lummis on 7/12/12.
//  Copyright (c) 2012 ElectricTurkey Software. All rights reserved.
//
//  adds a UIView to the glView and returns a pointer to it
//  arguments specify its frame and background color
//  the view is centered in the window and has a thin dark gray border
//  the view fades in quickly
//  this is a convenience constructor - it returns an autoreleased view

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface PopUpView : UIView {
    
    UIView *scrim;
}

+(id) viewWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor;
-(id) initWithBorderAndBackgroundColor:backgroundColor;
-(void) remove;

@end
