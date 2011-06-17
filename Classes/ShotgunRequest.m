//
//  ShotgunRequest.m
//  UnitTests
//
//  Created by Rob Blau on 6/15/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import "SBJson.h"
#import "ASIHTTPRequest.h"

#import "ShotgunConfig.h"
#import "ShotgunRequest.h"
#import "ShotgunEntity.h"

#pragma mark ShotgunHTTPRequest

@interface ShotgunRequest()

- (void)continueAsynchronous;

@end

@implementation ShotgunRequest

@synthesize startedBlock;
@synthesize completionBlock;
@synthesize failedBlock;
@synthesize postProcessBlock;

- (id)initWithConfig:(ShotgunConfig *)config path:(NSString *)path body:(NSString *)body headers:(NSDictionary *)headers andHTTPMethod:(NSString *)method 
{
    self = [super init];
    if (self) {
        _currentAttempt = 0;
        NSURL *url = [[NSURL alloc] initWithScheme:config.scheme host:config.server path:path];
        _request = [[[ASIHTTPRequest alloc] initWithURL:url] retain];
        [url release];
        [_request setUserAgent:@"shotgun-json"];
        [_request setPostBody:[NSMutableData dataWithData:[body dataUsingEncoding:NSUTF8StringEncoding]]];
        [_request setRequestMethod:method];
        [_request setRequestHeaders:[NSMutableDictionary dictionaryWithDictionary:headers]];
        [_request setShouldAttemptPersistentConnection:YES];
        [_request setTimeOutSeconds:config.timeoutSecs];
        maxAttempts = config.maxRpcAttempts;
    }
    return self;
}

- (void)startSynchronous
{
    _currentAttempt = 0;
    NSLog(@"Request is %@:%@", [_request requestMethod], [_request url]);
    NSLog(@"Request headers are %@", [_request requestHeaders]);
    NSString *body = [[NSString alloc] initWithData:[_request postBody] encoding:NSUTF8StringEncoding];
    NSLog(@"Request body is %@", body);
    [body release];
    while (_currentAttempt < maxAttempts) {
        _currentAttempt += 1;
        [_request startSynchronous];
        NSData *data = [_request responseData];
        if (data == Nil)
            continue;
        responseBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] retain];
        if (postProcessBlock)
            processedResults = postProcessBlock([_request responseHeaders], responseBody);
        NSLog(@"Response status is %d %@", [_request responseStatusCode], [_request responseStatusMessage]);
        NSLog(@"Response headers are %@", [_request responseHeaders]);
        NSLog(@"Response body is %@", responseBody);
        NSLog(@"Completed rpc call to %@", [_request requestMethod]);
        if ([_request responseStatusCode] > 300)
            [NSException raise:@"HTTP Error" 
                        format:@"HTTP Error from server %d %@",
             [_request responseStatusCode], 
             [NSHTTPURLResponse localizedStringForStatusCode:[_request responseStatusCode]]];
        return;
    }
    NSError *error = [_request error];
    [NSException raise:@"Unable to connect" format:@"%@. %@", [error localizedDescription], [error localizedFailureReason]];
}

- (void)startAsynchronous
{
    NSLog(@"Request is %@:%@", [_request requestMethod], [_request url]);
    NSLog(@"Request headers are %@", [_request requestHeaders]);
    NSLog(@"Request body is %@", [_request postBody]); 
    _currentAttempt = 0;
    [_request setDelegate:self];
    [_request startAsynchronous];
    if (startedBlock)
        startedBlock();
}

- (void)continueAsynchronous
{
    _currentAttempt += 1;
    [_request startAsynchronous];
}

#pragma mark ASIHTTPRequest Delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
    NSData *data = [request responseData];
    if (data == Nil) {
        [self continueAsynchronous];
        return;
    }
    responseBody = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] retain];
    if (postProcessBlock)
        processedResults = postProcessBlock([request responseHeaders], responseBody);
    else
        processedResults = Nil;
    NSLog(@"Response status is %d %@", [request responseStatusCode], [request responseStatusMessage]);
    NSLog(@"Response headers are %@", [request responseHeaders]);
    NSLog(@"Response body is %@", responseBody);
    NSLog(@"Async Completed rpc call to %@ on queue %@", [request requestMethod], [[NSOperationQueue currentQueue] name]);
    if (completionBlock)
        completionBlock();
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    /// @todo Set class error
    if (_currentAttempt < maxAttempts)
        [self continueAsynchronous];
    else {
        if (failureBlock)
            failureBlock();
    }
        
}

#pragma mark Data Access

- (id)response
{
    if (processedResults == Nil)
        return responseBody;
    return processedResults;
}

- (void)dealloc
{
    [responseBody release];
    [_request release];
    [super dealloc];
}

@end