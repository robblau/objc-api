//
//  Config.m
//  ShotgunApi
//
//  Created by Rob Blau on 6/8/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import "Config.h"

@implementation Config

@synthesize maxRpcAttempts;
@synthesize timeoutSecs;
@synthesize apiVer;
@synthesize convertDatetimesToUTC;
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
        convertDatetimesToUTC = TRUE;
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
    [super dealloc];
}

@end
