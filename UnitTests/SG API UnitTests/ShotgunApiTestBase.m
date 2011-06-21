//
//  ShotgunApiTestBase.m
//  UnitTests
//
//  Created by Rob Blau on 6/20/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import "ShotgunApiTestBase.h"


@implementation ShotgunApiTestBase

- (void)setUp 
{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"Config" ofType:@"plist"];
    NSDictionary *config = [[[NSDictionary alloc] initWithContentsOfFile:path] autorelease];
    shotgun = [[Shotgun alloc] initWithUrl:[config objectForKey:@"url"]
                                 scriptName:[config objectForKey:@"script"] 
                                     andKey:[config objectForKey:@"key"]];    
}

- (void)tearDown
{
    [shotgun release];
    shotgun = Nil;
}

@end
