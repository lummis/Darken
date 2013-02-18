//
//  PopUpView.m
//  Darken
//
//  Created by Robert Lummis on 7/12/12.
//  Copyright (c) 2012 ElectricTurkey Software. All rights reserved.
//

#import "PopUpView.h"

@implementation PopUpView

+(id) viewWithFrame:(CGRect)frame backgroundColor:(UIColor *)backgroundColor {
        //when these are nested Analyze gives a diagnostic
        //probably need to revise this if I want to subclass it
    PopUpView *theView = [[self alloc] initWithFrame:frame];
    return ( [[theView initWithBorderAndBackgroundColor:backgroundColor] autorelease] );
}

-(id) initWithBorderAndBackgroundColor:backgroundColor {
    
    CGFloat w = [[CCDirector sharedDirector] winSize].width;
    CGFloat h = [[CCDirector sharedDirector] winSize].height;
    
    self.backgroundColor = backgroundColor;
    
    CGFloat borderThickness = 7.f;
    UIImage *hBorder = [UIImage imageNamed:@"grayFrameHorizontal.png"];
    UIImage *vBorder = [UIImage imageNamed:@"grayFrameVertical.png"];
    
    UIImageView *topBorder = [[UIImageView alloc] initWithImage:hBorder];
    CGFloat nudge = 2.0f;   //empirical
    topBorder.frame = CGRectMake(0.f - borderThickness, 
                                 0.f - borderThickness, 
                                 self.bounds.size.width + 2.f * borderThickness, 
                                 borderThickness);
    [self addSubview:topBorder];    //add border outside of view
    [topBorder release];
    
    UIImageView *bottomBorder = [[UIImageView alloc] initWithImage:hBorder];
    bottomBorder.frame = CGRectMake(0.f - borderThickness, 
                                    self.bounds.size.height - nudge,   //fix an anomaly
                                    self.bounds.size.width + 2.f * borderThickness, 
                                    borderThickness);
    [self addSubview:bottomBorder];
    [bottomBorder release];
    
    UIImageView *leftBorder = [[UIImageView alloc] initWithImage:vBorder];
    leftBorder.frame = CGRectMake(0.f - borderThickness, 
                                  0.f - borderThickness + nudge, 
                                  borderThickness, 
                                  self.bounds.size.height + borderThickness + nudge);
    [self addSubview:leftBorder];
    [leftBorder release];
    
    UIImageView *rightBorder = [[UIImageView alloc] initWithImage:vBorder];
    rightBorder.frame = CGRectMake(self.bounds.size.width, 
                                   0.f - borderThickness + nudge, 
                                   borderThickness, 
                                   self.bounds.size.height + borderThickness + nudge); //looks ok but not == leftBorder
    [self addSubview:rightBorder];
    [rightBorder release];
    
    scrim = [[UIView alloc] initWithFrame:CGRectMake(0, 0, w, h)];
    scrim.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.4];
    UIView *glView = [CCDirector sharedDirector].openGLView;
    [glView addSubview:scrim];
    [scrim release];
    
    scrim.alpha = 0.0f;
    self.alpha = 0.0f;
    CGFloat fadeInTime = 1.0f;
    [UIView animateWithDuration:fadeInTime 
                     animations:^(void){
                         self.alpha = 1.0f;
                         scrim.alpha = 1.0f;
                     }];
    [scrim addSubview:self];
        //self was autoreleased in viewWithFrame:backgroundColor:
    return self;
}

-(void) remove {
    CGFloat fadeOutTime = 1.0f;
    [UIView animateWithDuration:fadeOutTime animations:^{ 
        self.alpha = 0.f;
        scrim.alpha = 0.f;
    } completion:^(BOOL finished){
        [scrim removeFromSuperview];
            //        [host removeFromSuperview];
    }];
}

@end
