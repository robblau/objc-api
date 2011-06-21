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
#import "ShotgunEntity.h"

#import "ShotgunRequest.h"
#import "ShotgunRequestPrivate.h"

@interface ShotgunRequest()

@property (retain, readwrite, nonatomic) id response;
@property (retain, readwrite, nonatomic) NSError *error;
@property (retain, readwrite, nonatomic) ASIHTTPRequest *request;
@property (assign, readwrite, nonatomic) BOOL isFinished;
@property (assign, readwrite, nonatomic) BOOL isExecuting;

@property (assign, readwrite, nonatomic) NSUInteger currentAttempt;
@property (assign, readwrite, nonatomic) NSUInteger timeout;
@property (assign, readwrite, nonatomic) NSUInteger maxAttempts;
@property (retain, readwrite, nonatomic) ShotgunConfig *config;
@property (retain, readwrite, nonatomic) NSString *path;
@property (retain, readwrite, nonatomic) NSString *body;
@property (retain, readwrite, nonatomic) NSDictionary *headers;
@property (retain, readwrite, nonatomic) NSString *method;

- (void)startSynchronous:(BOOL)synchronous;
- (void)continueSynchronous:(BOOL)synchronous;
- (void)finishSynchronous:(BOOL)synchronous;
- (ASIHTTPRequest *)makeRequest;

@end

#pragma mark ShotgunRequest

@implementation ShotgunRequest

@synthesize response = response_;
@synthesize request = request_;
@synthesize error = error_;
@synthesize queue = queue_;

@synthesize startedBlock = startedBlock_;
@synthesize completionBlock = completionBlock_;
@synthesize failedBlock = failedBlock_;
@synthesize postProcessBlock = postProcessBlock_;

@synthesize isExecuting = isExecuting_;
@synthesize isFinished = isFinished_;

@synthesize currentAttempt = currentAttempt_;
@synthesize timeout = timeout_;
@synthesize maxAttempts = maxAttempts_;
@synthesize config = config_;
@synthesize path = path_;
@synthesize body = body_;
@synthesize headers = headers_;
@synthesize method = method_;

+ (id)shotgunRequestWithConfig:(ShotgunConfig *)config path:(NSString *)path body:(NSString *)body headers:(NSDictionary *)headers andHTTPMethod:(NSString *)method
{
    return [[[ShotgunRequest alloc] initWithConfig:config path:path body:body headers:headers andHTTPMethod:method] autorelease];
}

- (id)initWithConfig:(ShotgunConfig *)config path:(NSString *)path body:(NSString *)body headers:(NSDictionary *)headers andHTTPMethod:(NSString *)method 
{
    self = [super init];
    if (self) {
        self.queue = [NSOperationQueue mainQueue];
        self.config = config;
        self.path = path;
        self.body = body;
        self.headers = headers;
        self.method = method;
    }
    return self;
}

- (void)startSynchronous
{
    [self startSynchronous:YES];
}

- (void)startSynchronous:(BOOL)synchronous
{
    if ((synchronous == NO) && ([NSThread isMainThread] == NO)) {
        [self performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
        return;
    }
    
    self.currentAttempt = 0;
    self.maxAttempts = self.config.maxRpcAttempts;
    self.request = [self makeRequest];
    NSLog(@"Request is %@:%@", [self.request requestMethod], [self.request url]);
    NSLog(@"Request headers are %@", [self.request requestHeaders]);
    NSLog(@"Request body is %@", [NSString stringWithUTF8String:[[self.request postBody] bytes]]); 

    if (synchronous == YES) {
        [self.request startSynchronous];
        [self finishSynchronous:YES];
    } else {
        NSLog(@"Started on queue: %@", [self.queue name]);
        [self willChangeValueForKey:@"isExecuting"];
        self.isExecuting = YES;
        [self didChangeValueForKey:@"isExecuting"];
        [self.request setDelegate:self];
        [self.request startAsynchronous];
        if (self.startedBlock)
            self.startedBlock();  
    }
}

- (void)startAsynchronous
{
    [self.queue addOperation:self];
}

- (void)start
{
    [self startSynchronous:NO];
}

- (void)continueSynchronous:(BOOL)synchronous
{
    if (synchronous == YES) {
        while (self.currentAttempt < self.maxAttempts) {
            self.currentAttempt += 1;
            self.request = [self makeRequest];
            [self.request startSynchronous];
            NSData *data = [self.request responseData];
            if (data != Nil)
                return;
        }
    } else {
        self.currentAttempt += 1;
        self.request = [self makeRequest];
        [self.request startAsynchronous];
    }
}

- (void)finishSynchronous:(BOOL)synchronous
{
    NSData *data = [self.request responseData];
    if ((data == Nil) && (self.currentAttempt < self.maxAttempts)) {
        [self continueSynchronous:synchronous];
        return;
    }

    self.response = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
    if (self.postProcessBlock)
        self.response = [self.postProcessBlock([self.request responseHeaders], self.response) retain];
    NSLog(@"Response status is %d %@", [self.request responseStatusCode], [self.request responseStatusMessage]);
    NSLog(@"Response headers are %@", [self.request responseHeaders]);
    NSLog(@"Response is (rc %d) %@", [self.response retainCount], self.response);
    NSLog(@"Completed rpc call to %@", [self.request requestMethod]);

    if (synchronous == NO) {
        [self willChangeValueForKey:@"isExecuting"];
        [self willChangeValueForKey:@"isFinished"];
        self.isExecuting = NO;
        self.isFinished = YES;
        [self didChangeValueForKey:@"isExecuting"];
        [self didChangeValueForKey:@"isFinished"];
        // Queue will take care of running the completion block
    }
}

#pragma mark ASIHTTPRequest Delegate

- (void)requestFinished:(ASIHTTPRequest *)request
{
    [self finishSynchronous:NO];
}

- (void)requestFailed:(ASIHTTPRequest *)request
{
    /// @todo Set class error
    if (self.currentAttempt < self.maxAttempts) {
        [self continueSynchronous:NO];
        return;
    }
    self.error = [self.request error];
    if (self.failedBlock)
        self.failedBlock();
    [self finishSynchronous:NO];
}

- (void)dealloc
{
    self.response = Nil;
    self.request = Nil;
    self.error = Nil;
    self.queue = Nil;
    self.config = Nil;
    self.path = Nil;
    self.body = Nil;
    self.headers = Nil;
    self.method = Nil;
    // Blocks are deleted automatically when execution returns from the defining scope.
    [super dealloc];
}

- (ASIHTTPRequest *)makeRequest
{
    NSURL *url = [[[NSURL alloc] initWithScheme:self.config.scheme host:self.config.server path:self.path] autorelease];
    ASIHTTPRequest *aRequest = [ASIHTTPRequest requestWithURL:url];
    [aRequest setUserAgent:@"shotgun-json"];
    [aRequest setPostBody:[NSMutableData dataWithData:[self.body dataUsingEncoding:NSUTF8StringEncoding]]];
    [aRequest setRequestMethod:self.method];
    [aRequest setRequestHeaders:[NSMutableDictionary dictionaryWithDictionary:self.headers]];
    [aRequest setShouldAttemptPersistentConnection:YES];
    [aRequest setTimeOutSeconds:self.config.timeoutSecs];
    return aRequest;
}

- (BOOL)isConcurrent
{
    return YES;
}

@end