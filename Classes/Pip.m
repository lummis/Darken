//
//  Tile.m
//  Darken
//
//  Created by Robert Lummis on 5/22/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

#import "Pip.h"

@implementation Pip
@synthesize colorID, shapeID;

    //designated initializer
-(id) initWithTexture:(CCTexture2D *)texture rect:(CGRect)rect {
    if ( (self = [super initWithTexture:texture rect:rect]) ) {
    }
    return self;
}

-(id) initWithColor:(NSUInteger)colorNumber {
    switch (colorNumber) {
        default:
            CCLOG(@"Exit; new pip with colorNumber out of defined range. colorNumber: %d", colorNumber);
            kill( getpid(), SIGABRT );  //crash
        case 0:
            self.color = ccc3(255, 0, 0);	//red
            break;
        case 1:
            self.color = ccc3(75, 75, 255);	//dark blue
            break;
        case 2:
            self.color = ccc3(220, 130, 35);   //orange
            break;
        case 3:
            self.color = ccc3(185, 0, 200);	//purple
            break;
        case 4:
            self.color = ccc3(255, 255, 0);	//yellow
            break;
        case 5:
            self.color = ccc3(170, 255, 170);	//light green
            break;
        case 6:
            self.color = ccc3(0, 165, 0);	//darker green
            break;
        case 7:
            self.color = ccc3(150, 160, 255);	//pale blue
            break;
        case 8:
            self.color = ccc3(255, 255, 255);   //white
            break;
        case 9:
            self.color = ccc3(100, 100, 100);   //gray - too close to green so don't use
            break;
            
                //colorNumbers >= 90 are special
        case 99:
            self.color = ccc3(0, 0, 0);	//black -- used for bomb
            break;		
        case 98:
            self.color = ccc3(72, 72, 72);	//dark gray
            break;
        case 97:
            self.color = ccc3(128, 128, 128);	//medium gray
            break;
        case 96:
            self.color = ccc3(240, 240, 240);	//very light gray
            break;
        case 95:
            self.color = ccc3(255, 255, 255);	//white -- used for small star
            break;
        case 90:
            break;  //don't apply a color
    }
	return self;
}

@end
