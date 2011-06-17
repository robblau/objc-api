//
//  ShotgunConfig.m
//  ShotgunApi
//
//  Created by Rob Blau on 6/8/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import "ShotgunConfig.h"

@implementation ShotgunConfig

@synthesize maxRpcAttempts;
@synthesize timeoutSecs;
@synthesize apiVer;
@synthesize recordsPerPage;
@synthesize apiKey;
@synthesize scriptName;
@synthesize sessionUuid;
@synthesize scheme;
@synthesize server;
@synthesize apiPath;
@synthesize sessionToken;

- (id)init {
    self = [super init];
    if (self) {
        maxRpcAttempts = 3;
        timeoutSecs = 3;
        apiVer = [[NSString alloc] initWithString:@"api3"];
        recordsPerPage = 500;
        apiKey = Nil;
        scriptName = Nil;
        sessionUuid = Nil;
        scheme = Nil;
        server = Nil;
        apiPath = Nil;
        sessionToken = Nil;
    }
    
    return self;
}

- (void)dealloc {
    [apiVer release];
    [super dealloc];
}

@end
