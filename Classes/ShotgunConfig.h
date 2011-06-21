//
//  ShotgunConfig.h
//  ShotgunApi
//
//  Created by Rob Blau on 6/8/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ShotgunConfig : NSObject;

@property (assign, readwrite, nonatomic) NSUInteger maxRpcAttempts;
@property (assign, readwrite, nonatomic) NSUInteger timeoutSecs;
@property (assign, readwrite, nonatomic) NSUInteger recordsPerPage;
@property (retain, readwrite, nonatomic) NSString *apiVer;
@property (retain, readwrite, nonatomic) NSString *apiKey;
@property (retain, readwrite, nonatomic) NSString *scheme;
@property (retain, readwrite, nonatomic) NSString *server;
@property (retain, readwrite, nonatomic) NSString *apiPath;
@property (retain, readwrite, nonatomic) NSString *scriptName;
@property (retain, readwrite, nonatomic) NSString *sessionUuid;
@property (retain, readwrite, nonatomic) NSString *sessionToken;

+ (id)config;
- (id)init;
- (void)dealloc;

@end
