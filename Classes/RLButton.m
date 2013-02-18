//
//  RLButton.m
//  Darken
//
//  Created by Robert Lummis on 1/29/12.
//  Copyright (c) 2012 ElectricTurkey Software. All rights reserved.
//

#import "RLButton.h"

@implementation RLButton

-(void) dealloc {
    [super dealloc];
}

+(id) buttonWithStyle:(RLButtonStyle)style 
               target:(id)target 
               action:(SEL)selector 
                frame:(CGRect)frame {
    
    RLButton *theButton = [super buttonWithType:UIButtonTypeCustom]; //class method inherited from UIButton

        //style determines which background image to use from the bundle
    switch (style) {
        case RLButtonStyleBlueRoundedRect:
            [theButton setBackgroundImage:[UIImage imageNamed:@"blueButton.png"] forState:UIControlStateNormal];
            break;
        case RLButtonStyleGreenRoundedRect:
            [theButton setBackgroundImage:[UIImage imageNamed:@"greenRoundedRectImage.png"] forState:UIControlStateNormal];
            break;
        case RLButtonStyleGray:
            [theButton setBackgroundImage:[UIImage imageNamed:@"grayButton.png"] forState:UIControlStateNormal];
            break;
        default:
            NSLog(@"RLButton called with invalid style: %d\n", style);
            kill( getpid(), SIGABRT );  //crash
    }
    
    [theButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    theButton.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    theButton.titleLabel.shadowColor = [UIColor blackColor];
    theButton.titleLabel.shadowOffset = CGSizeMake(-1.0f, -1.0f);
    theButton.showsTouchWhenHighlighted = NO;   //not needed - is default
    [theButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    [theButton setFrame:frame]; //theButton.frame = should be ok but don't use theButton.frame.size = 
    theButton.opaque = NO;   //YES means there is no transparency in the image
    return theButton;
}

-(void) setText:(NSString *)text {
    ANNOUNCE
    NSString *_text = [[text copy] autorelease];
    [self setTitle:_text forState:UIControlStateNormal];
}

-(NSString *) text {
    return [self titleForState:UIControlStateNormal];
}

@end
