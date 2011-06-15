//
//  Recent_VersionsAppDelegate.h
//  Recent Versions
//
//  Created by Rob Blau on 6/14/11.
//  Copyright 2011 Laika, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class RootViewController;
@class DetailViewController;

@interface Recent_VersionsAppDelegate : NSObject <UIApplicationDelegate> {}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet UISplitViewController *splitViewController;
@property (nonatomic, retain) IBOutlet RootViewController *rootViewController;
@property (nonatomic, retain) IBOutlet DetailViewController *detailViewController;

@end
