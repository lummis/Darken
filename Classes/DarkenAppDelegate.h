//
//  DarkenAppDelegate.h
//  Darken
//
//  Created by Robert Lummis on 5/22/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

#import "RootViewController.h"

@interface DarkenAppDelegate : NSObject <UIApplicationDelegate> {
	UIWindow			*window;
	RootViewController	*viewController;
    
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) RootViewController *viewController;

+(void) initialize;
-(NSUInteger) supportedInterfaceOrientations;
-(BOOL) shouldAutorotate;
-(BOOL) os6;

@end
