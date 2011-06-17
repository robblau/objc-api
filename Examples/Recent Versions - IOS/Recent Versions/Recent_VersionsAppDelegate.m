//
//  Recent_VersionsAppDelegate.m
//  Recent Versions
//
//  Created by Rob Blau on 6/14/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import "Recent_VersionsAppDelegate.h"
#import "RootViewController.h"

@implementation Recent_VersionsAppDelegate

@synthesize window=_window;
@synthesize splitViewController=_splitViewController;
@synthesize rootViewController=_rootViewController;
@synthesize detailViewController=_detailViewController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window.rootViewController = self.splitViewController;
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {}
- (void)applicationDidEnterBackground:(UIApplication *)application {}
- (void)applicationWillEnterForeground:(UIApplication *)application {}
- (void)applicationDidBecomeActive:(UIApplication *)application {}
- (void)applicationWillTerminate:(UIApplication *)application {}

- (void)dealloc
{
    [_window release];
    [_splitViewController release];
    [_rootViewController release];
    [_detailViewController release];
    [super dealloc];
}

@end
