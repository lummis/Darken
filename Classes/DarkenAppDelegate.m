//
//  DarkenAppDelegate.m
//  Darken
//
//  Created by Robert Lummis on 5/22/11.
//  Copyright 2011 ElectricTurkey Software. All rights reserved.
//

#import "DarkenAppDelegate.h"
#import "Board.h"
#import "Model.h"
#import "CCArray+Replace.h"
#import "ChoiceScene.h"
#import "RLGameCenter.h"
#import "LocalyticsSession.h"

#ifndef DISABLEMESSAGES
#endif

@implementation DarkenAppDelegate
@synthesize window;
@synthesize viewController;

- (void)dealloc {
    [viewController release];
	[window release];
	[super dealloc];
}

+(void) initialize {    //store the date of first run, and time zone as hours from GMT
                        //don't refer to Common because it's not valid until [model launch] runs
    ANNOUNCE
    CCLOG(@"initialize starting");
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    int storedSessionNumber = [defaults integerForKey:@"sessionNumber"];
        // first time the app runs the defaults file doesn't exist an storedSessionNumber becomes 0
    
    if ( storedSessionNumber == 0 ) {
        CCLOG(@"storedSessionNumber is 0. Doing installation initialization");
        NSDate *today = [NSDate date];
        NSCalendar *gregorian=[[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar];
        unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | 
            NSHourCalendarUnit | NSMinuteCalendarUnit;
        NSDateComponents *components = [gregorian components:unitFlags fromDate:today];
        [gregorian release];
        int day = [components day];
        int month = [components month];
        int year = [components year];
        
        NSString *initializationDate = [NSString stringWithFormat:@"%4d%02d%02d", year, month, day];
        [defaults setObject:initializationDate          forKey:@"initializeDate"];
        
        NSInteger hoursFromGMT = [[NSTimeZone systemTimeZone] secondsFromGMT] / 3600 ;
        [defaults setInteger:hoursFromGMT               forKey:@"h"];
        
        CFUUIDRef cfUUID = CFUUIDCreate(kCFAllocatorDefault); //makes a different uuid every time
        CFStringRef installationUUID = CFUUIDCreateString(kCFAllocatorDefault, cfUUID);
        CFRelease(cfUUID);
        
        choiceCode = cReset;
        [defaults setInteger:0                          forKey:@"c"];   //n corruptions
        [defaults setInteger:choiceCode                 forKey:@"choiceCode"];
        [defaults setInteger:storedSessionNumber        forKey:@"sessionNumber"]; //incremented in didBecomeActive
        
        [defaults setObject:(NSString *)installationUUID    forKey:@"installationUUID"];
        [defaults setInteger:-1                         forKey:@"r"]; // hours from GMT; incremented to 0 in model / launch
        [defaults setInteger:0                          forKey:@"totalSessionTime"]; //minutes - sum of all sessions
        [defaults setInteger:ORIGINALSTARSONHAND        forKey:@"starsOnHand"];
        [defaults setInteger:ORIGINALBOMBSONHAND        forKey:@"bombsOnHand"];
        
        [defaults setBool:NO                            forKey:@"userDidRate"];
        [defaults setInteger:0                          forKey:@"sessionsSinceNag"];
        [defaults setInteger:0                          forKey:@"highsSinceNag"];
        [defaults setBool:NO                            forKey:@"userSaidNoNag"];
        
        [defaults synchronize];
        CFRelease(installationUUID);
    }
}

- (void) removeStartupFlicker
{
    ANNOUNCE
	//
	// THIS CODE REMOVES THE STARTUP FLICKER
	//
	// Uncomment the following code if your Application only supports landscape mode
	//
#if GAME_AUTOROTATION == kGameAutorotationUIViewController
        //9 lines uncommented rcl
	CC_ENABLE_DEFAULT_GL_STATES();
	CCDirector *director = [CCDirector sharedDirector];
	CGSize size = [director winSize];
	CCSprite *sprite = [CCSprite spriteWithFile:@"Default.png"];
	sprite.position = ccp(size.width/2, size.height/2);
	sprite.rotation = -90;
	[sprite visit];
	[[director openGLView] swapBuffers];
	CC_ENABLE_DEFAULT_GL_STATES();
#endif // GAME_AUTOROTATION == kGameAutorotationUIViewController	
    
}

- (void) applicationDidFinishLaunching:(UIApplication*)application {
    ANNOUNCE
    CCLOG(@"++++++++++++++++++++++++++++++++++STATUS applicationDidFinishLaunching");
    CCLOG(@"current system version: %@", [[UIDevice currentDevice] systemVersion]);
    
        //localytics start is supposed to come before rootViewController is changed (?)
        //key for Darken: 719e17e9ca33a2daae65d30-caf01a18-461f-11e2-346c-004b50a28849
        //key for Darkentest: a4e3ba70ffdcf355c07975f-837ccad8-4623-11e2-346e-004b50a28849
        //key for DarkenRC1: 9d46f2028e2210342c0ad50-21b817c8-6a31-11e2-7a13-004535b6c551
    [[LocalyticsSession sharedLocalyticsSession] startSession:@"719e17e9ca33a2daae65d30-caf01a18-461f-11e2-346c-004b50a28849"];
    [[LocalyticsSession sharedLocalyticsSession] setLoggingEnabled:NO];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger sn = [defaults integerForKey:@"sessionNumber"];
    CCLOG(@"sessionNumber from defaults: %d", sn);
    if (sn == 0) {  //first time
        CCLOG(@"reporting first launch to localytics");
        NSInteger h = [defaults integerForKey:@"h"];
        NSString *device = [[UIDevice currentDevice] model];
        NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:h],
                           @"Hours From GMT",
                           device, @"Device", nil];
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"First Launch" attributes:d];
    }
    
        // Init the window
        //autorelease for static analysis
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
	
        // Try to use CADisplayLink director
        // if it fails (SDK < 3.1) use the default director
	if( !!! [CCDirector setDirectorType:kCCDirectorTypeDisplayLink] )
		[CCDirector setDirectorType:kCCDirectorTypeDefault];
    
	CCDirector *director = [CCDirector sharedDirector];
	
        // Init the View Controller
        //autorelease for static anal.
    self.viewController = [[[RootViewController alloc] initWithNibName:nil bundle:nil] autorelease];
	viewController.wantsFullScreenLayout = YES;
	
        //
        // Create the EAGLView manually
        //  1. Create a RGB565 format. Alternative: RGBA8
        //	2. depth format of 0 bit. Use 16 or 24 bit for 3d effects, like CCPageTurnTransition
        //
        //
	EAGLView *glView = [EAGLView viewWithFrame:[window bounds]
								   pixelFormat:kEAGLColorFormatRGB565	// kEAGLColorFormatRGBA8
								   depthFormat:0						// GL_DEPTH_COMPONENT16_OES
						];
	
        // attach the openglView to the director
	[director setOpenGLView:glView];

//	// Enables High Res mode (Retina Display) on iPhone 4 and maintains low res on all other devices

	if( !!![director enableRetinaDisplay:YES] ) {
		CCLOG(@"Retina Display Not supported");
    } else {
        CCLOG(@"Retina display IS supported");
    }
    
	//
	// VERY IMPORTANT:
	// If the rotation is going to be controlled by a UIViewController
	// then the device orientation should be "Portrait".
	//
	// IMPORTANT:
	// By default, this template only supports Landscape orientations.
	// Edit the RootViewController.m file to edit the supported orientations.
	//
#if GAME_AUTOROTATION == kGameAutorotationUIViewController
        [director setDeviceOrientation:kCCDeviceOrientationPortrait];
#else
        [director setDeviceOrientation:kCCDeviceOrientationLandscapeLeft];
#endif
	
	[director setAnimationInterval:1.0/60];
	[director setDisplayFPS:NO];
	
	// make the OpenGLView a child of the view controller
    //in forum riq said the flicker on startup may be helped by changing
    //the following line to:[[viewController view] addSubview:glView];
	[viewController setView:glView];
    
            //	// make the View Controller a child of the main window
            //	[window addSubview: viewController.view];
    
            // comment out statement above and
            // add the following so we can run on iOS 6 as per http://www.cocos2d-iphone.org/forum/topic/49220
            // Set RootViewController to window
    
    if ( [self os6] ) {
        [window setRootViewController:viewController];
    } else {
        [window addSubview:viewController.view];
    }
    
	[window makeKeyAndVisible];
	
	// Default texture format for PNG/BMP/TIFF/JPEG/GIF images
	// It can be RGBA8888, RGBA4444, RGB5_A1, RGB565
	// You can change anytime.
	[CCTexture2D setDefaultAlphaPixelFormat:kCCTexture2DPixelFormat_RGBA8888];
	
	// Removes the startup flicker
	[self removeStartupFlicker];
    
        //move game center initialization to TitleScene

    X.accelerometerWasEnabled = YES;
    X.nowInBoardScene = NO;
    X.nowInChoiceScene = NO;
    X.nowInSettingsScene = NO;
    X.networkIsAvailable = NO;
    X.nagNow = NO;
    [[RLGameCenter singleton] authenticateLocalPlayer];
    
    Model *model = [[[Model alloc] init] autorelease];
    X.modelP = model;
    [model launch];
    
}   //end applicationDidFinishLaunching

-(NSUInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

-(BOOL) shouldAutorotate {
    return YES;
}

//- (NSUInteger)supportedInterfaceOrientationsForWindow:window {
//    return UIInterfaceOrientationMaskLandscape;
//}

- (void) applicationWillResignActive:(UIApplication *)application {
        //this is called with home or lock button press, incoming phone call, or hold lock button to power off 
        //but not called when the app does not run in the background (?)
    ANNOUNCE
    CCLOG(@"++++++++++++++++++++++++++++++++++STATUS applicationWillResignActive");
    
    if (X.level == 2 && X.tutorialsEnabled) {
        X.starsOnHand = X.starsSavedDuringTutorial;
        X.bombsOnHand = X.bombsSavedDuringTutorial;
    }
    [X.modelP printCommonFull];
    [X.modelP putDefaults]; // syncs common variables
    
    [[CCDirector sharedDirector] pause];
        //next goes to applicationDidEnterBackground
}

- (void) applicationDidBecomeActive:(UIApplication *)application {
    ANNOUNCE
    CCLOG(@"++++++++++++++++++++++++++++++++++STATUS applicationDidBecomeActive");
    X.sessionNumber++;
    X.sessionsSinceNag ++;
	[[CCDirector sharedDirector] resume];
}

- (void) applicationDidReceiveMemoryWarning:(UIApplication *)application {
    ANNOUNCE
    CCLOG(@"++++++++++++++++++++++++++++++++++STATUS applicationDidReceiveMemoryWarning");
	[[CCDirector sharedDirector] purgeCachedData];
}

-(void) applicationDidEnterBackground:(UIApplication*)application {
    ANNOUNCE
    CCLOG(@"++++++++++++++++++++++++++++++++++STATUS applicationDidEnterBackground");
        //I wrote this assuming the home button got us here 
        //but unfortunately we get here equally with 'home' or 'power off'
        //I don't think there is any way to discriminate between them
    
    if (X.nowInBoardScene) {
        X.playDeltaTime += [[NSDate date] timeIntervalSinceDate:X.playStartTime];
    }

    [X.modelP printCommonFull];
    if(X.choiceCode == cInterrupted) {  //don't change choiceCode if it's cCompleted or cFailed
        X.choiceCode = cQuit;   
    }
    if (X.level == 2 && X.tutorialsEnabled) {
        X.starsOnHand = X.starsSavedDuringTutorial;
        X.bombsOnHand = X.bombsSavedDuringTutorial;
    }
    [X.modelP putDefaults]; //syncs
    [[CCDirector sharedDirector] stopAnimation];
    
//    [sessionStartTime release];

    if (!!! X.nowInBoardScene) {
        [[[UIApplication sharedApplication] delegate] applicationWillTerminate:[UIApplication sharedApplication]];
    }
    
    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}

-(void) applicationWillEnterForeground:(UIApplication*)application {
    ANNOUNCE
    CCLOG(@"++++++++++++++++++++++++++++++++++STATUS applicationWillEnterForeground");
    [[RLGameCenter singleton] authenticateLocalPlayer];
	[[CCDirector sharedDirector] startAnimation];
    
    X.playStartTime = [NSDate date];
    
    [[LocalyticsSession sharedLocalyticsSession] resume];
    [[LocalyticsSession sharedLocalyticsSession] upload];
}

- (void) applicationWillTerminate:(UIApplication *)application {
    ANNOUNCE
    CCLOG(@"++++++++++++++++++++++++++++++++++STATUS applicationWillTerminate");
    if (X.level == 2 && X.tutorialsEnabled) {
        X.starsOnHand = X.starsSavedDuringTutorial;
        X.bombsOnHand = X.bombsSavedDuringTutorial;
    }
    
    if (X.nowInBoardScene) {
        [[LocalyticsSession sharedLocalyticsSession] tagEvent:@"Power Off In Board Scene"];
    }
    
        //increment quits
    if (X.nowInBoardScene && !!!X.tutorialsEnabled) {
        NSInteger formerQuits = [[X.levelQuits objectAtIndex:X.level -1] integerValue];
        [X.levelQuits replaceObjectAtIndex:X.level - 1 withObject:[NSNumber numberWithInteger:formerQuits + 1]];
    }
    
    [X.modelP putDefaults]; //syncs

    [[LocalyticsSession sharedLocalyticsSession] close];
    [[LocalyticsSession sharedLocalyticsSession] upload];
    
    CCLOG(@"end of applicationWillTerminate");
    fflush(stdout);
    _exit(0);
}

- (void) applicationSignificantTimeChange:(UIApplication *)application {
	[[CCDirector sharedDirector] setNextDeltaTimeZero:YES];
}

-(BOOL) os6 {
    ANNOUNCE
    NSString *targetSystemVersion = @"6.0";
    NSString *currentSystemVersion = [[UIDevice currentDevice] systemVersion];
    if ([currentSystemVersion compare:targetSystemVersion options:NSNumericSearch] == NSOrderedAscending) {
        return NO;  //current system version is less than 6.0
    } else {
        return YES;
    }
}

@end

