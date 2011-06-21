//
//  ShotgunConfig.m
//  ShotgunApi
//
//  Created by Rob Blau on 6/8/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import "ShotgunConfig.h"

@implementation ShotgunConfig

@synthesize maxRpcAttempts = maxRpcAttempts_;
@synthesize timeoutSecs= timeoutSecs_;
@synthesize apiVer = apiVer_;
@synthesize recordsPerPage = recordsPerPage_;
@synthesize apiKey = apiKey_;
@synthesize scriptName = scriptName_;
@synthesize sessionUuid = sessionUuid_;
@synthesize scheme = scheme_;
@synthesize server = server_;
@synthesize apiPath = apiPath_;
@synthesize sessionToken = sessionToken_;

+ (id)config
{
    return [[[ShotgunConfig alloc] init] autorelease];
}

- (id)init 
{
    self = [super init];
    if (self) {
        self.maxRpcAttempts = 3;
        self.timeoutSecs = 3;
        self.apiVer = @"api3";
        self.recordsPerPage = 500;
        self.apiKey = Nil;
        self.scheme = Nil;
        self.server = Nil;
        self.apiPath = Nil;
        self.scriptName = Nil;
        self.sessionUuid = Nil;
        self.sessionToken = Nil;
    }
    return self;
}

- (void)dealloc 
{
    self.apiVer = Nil;
    self.apiKey = Nil;
    self.scheme = Nil;
    self.server = Nil;
    self.apiPath = Nil;
    self.scriptName = Nil;
    self.sessionUuid = Nil;
    self.sessionToken = Nil;
    [super dealloc];
}

@end
