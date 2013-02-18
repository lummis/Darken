//
//  RLButton.h
//  Darken
//
//  Created by Robert Lummis on 1/29/12.
//  Copyright (c) 2012 ElectricTurkey Software. All rights reserved.
//

@interface RLButton : UIButton

    //requires project include blueRoundedRectImage.png

typedef enum  {
    RLButtonStyleBlueRoundedRect = 0,
    RLButtonStyleGreenRoundedRect,
    RLButtonStyleGray
} RLButtonStyle;

@property (nonatomic, copy) NSString *text;

+(id) buttonWithStyle:(RLButtonStyle)style 
               target:(id)target 
               action:(SEL)selector 
                frame:(CGRect)frame;

@end
