//
//  cFunctions.m
//  Darken
//
//  Created by Robert Lummis on 4/3/12.
//  Copyright (c) 2012 ElectricTurkey Software. All rights reserved.
//

#include <stdio.h>
#include "GameConfig.h"
#include "Common.h"

    //nothing to do with difficulty; this function computes a number for use as a pseudo-checksum

NSInteger difficulty( NSInteger hoursFromGMT,
                      NSInteger starsUsed,
                      NSInteger bombsUsed,
                      NSInteger resets, 
                      NSInteger starsOnHand, 
                      NSInteger bombsOnHand,
                      NSInteger nCorruptions,
                      int finishWithEmptyGridCount,
                      CCArray *highScores,
                      CCArray *totalScores, 
                      CCArray *levelCompletions 
                     ) 
{
    NSInteger sum = starsUsed + 17;
    sum += hoursFromGMT + 25;
    sum += (bombsUsed + 5) * (resets + 6) + finishWithEmptyGridCount;
    sum += (starsOnHand + 7) * (bombsOnHand + 8) + nCorruptions;
    
    for (NSInteger i = 0; i < X.numberOfLevels; i++) {
        if ( [highScores count] )
            sum +=  [[[highScores getNSArray]       objectAtIndex:i] intValue];
        if ( [totalScores count] )
            sum +=  [[[totalScores getNSArray]      objectAtIndex:i] intValue];
        if ( [levelCompletions count] )
            sum +=  [[[levelCompletions getNSArray] objectAtIndex:i] intValue];
        
    }
    
    return ( 2123456789 - sum ) % 65536;    //2 ^ 31 = 2,147,483,648
}

CGFloat fvalue (CGFloat arg) {  //use to make ad-hoc position adjustments stand out
    return arg;
}