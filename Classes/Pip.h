//
//  Tile.h
//  Darken
//
//  Created by Robert Lummis on 5/22/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

    //pip keeps no information about where it is or where it came from

@interface Pip : CCSprite {
}

-(id) initWithTexture:(CCTexture2D *)texture rect:(CGRect)rect;
-(id) initWithColor:(NSUInteger)colorNumber;

@property (nonatomic, assign) int shapeID;
@property (nonatomic, assign) int colorID;

@end
