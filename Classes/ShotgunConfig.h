//
//  ShotgunConfig.h
//  ShotgunApi
//
//  Created by Rob Blau on 6/8/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ShotgunConfig : NSObject {
    NSUInteger maxRpcAttempts;
    NSUInteger timeoutSecs;
    NSString *apiVer;
    NSUInteger recordsPerPage;
    NSString *apiKey;
    NSString *scriptName;
    NSString *sessionUuid;
    NSString *scheme;
    NSString *server;
    NSString *apiPath;
    NSString *sessionToken;
}

@property (readwrite) NSUInteger maxRpcAttempts;
@property (readwrite) NSUInteger timeoutSecs;
@property (retain) NSString *apiVer;
@property (readwrite) NSUInteger recordsPerPage;
@property (retain) NSString *apiKey;
@property (retain) NSString *scriptName;
@property (retain) NSString *sessionUuid;
@property (retain) NSString *scheme;
@property (retain) NSString *server;
@property (retain) NSString *apiPath;
@property (retain) NSString *sessionToken;

- (id)init;

@end
