//
//  ShotgunApiLongTests.m
//  ShotgunApiLongTests
//
//  Created by Rob Blau on 6/20/11.
//  Copyright 2011 Laika. All rights reserved.
//

#import "ShotgunApiTestBase.h"

@interface ShotgunApiLongTest : ShotgunApiTestBase {}
@end

@implementation ShotgunApiLongTest

// Test Schema
- (NSArray *)schemaTestRequests
{
    ShotgunRequest *req1 = [shotgun schemaEntityRead];
    ShotgunRequest *req2 = [shotgun schemaRead];
    ShotgunRequest *req3 = [shotgun schemaFieldReadForEntityOfType:@"Version"];
    ShotgunRequest *req4 = [shotgun schemaFieldReadForEntityOfType:@"Version" forField:@"user"];
    ShotgunRequest *req5 = [shotgun schemaFieldCreateForEntityOfType:@"Version" 
                                                          ofDataType:@"number"
                                                     withDisplayName:@"Monkey Count" 
                                                       andProperties:@"{\"description\": \"How many monkeys were needed\"}"];
    NSArray *requests = [NSArray arrayWithObjects:req1, req2, req3, req4, req5, nil];
    return requests;
}

- (void)schemaTestResponses:(NSArray *)responses
{
    id res1 = [responses objectAtIndex:0];
    id res2 = [responses objectAtIndex:1];
    id res3 = [responses objectAtIndex:2];
    id res4 = [responses objectAtIndex:3];
    id res5 = [responses objectAtIndex:4];
    GHTestLog(@"RES1: %@", res1);
    GHTestLog(@"RES2: %@", res2);
    GHTestLog(@"RES3: %@", res3);
    GHTestLog(@"RES4: %@", res4);
    GHTestLog(@"RES5: %@", res5);
    GHAssertTrue([res1 isKindOfClass:[NSDictionary class]], @"SchemaEntityRead was not an NSDictionary");
    GHAssertTrue([res1 count]>0, @"SchemaEntityRead count was zero");
    GHAssertTrue([res2 isKindOfClass:[NSDictionary class]], @"SchemaRead was not an NSDictionary");
    GHAssertTrue([res2 count]>0, @"SchemaRead count was zero");
    GHAssertTrue([res3 isKindOfClass:[NSDictionary class]], @"SchemaFieldRead was not an NSDictionary");
    GHAssertTrue([res3 count]>0, @"SchemaFieldRead count was zero");
    GHAssertTrue([res4 isKindOfClass:[NSDictionary class]], @"SchemaFieldRead was not an NSDictionary");
    GHAssertTrue([res4 count]>0, @"SchemaFieldRead count was zero");
    GHAssertTrue([res4 objectForKey:@"user"] != Nil, @"SchemaFieldRead did not have user");
    GHAssertTrue([res5 isKindOfClass:[NSString class]], @"SchemaFieldCreate was not an NSString");
    
    ShotgunRequest *update = [shotgun schemaFieldUpdateForEntityOfType:@"Version"
                                                              forField:res5
                                                        withProperties:@"{\"description\": \"How many monkeys turned up\"}"];
    [update startSynchronous];
    GHAssertTrue([[update response] isKindOfClass:[NSNumber class]], @"SchemaFieldUpdate was not an NSNumber");
    GHAssertTrue([[update response] boolValue] == YES, @"SchemaFieldUpdate did not return true.");

    ShotgunRequest *delete = [shotgun schemaFieldDeleteForEntityOfType:@"Version" forField:res5];
    [delete startSynchronous];
    GHAssertTrue([[delete response] isKindOfClass:[NSNumber class]], @"SchemaFieldUpdate was not an NSNumber");
    GHAssertTrue([[delete response] boolValue] == YES, @"SchemaFieldUpdate did not return true.");
}

- (void)testSchemaSync
{
    NSArray *requests = [self schemaTestRequests];
    NSMutableArray *responses = [NSMutableArray arrayWithCapacity:[requests count]];
    for (ShotgunRequest *request in requests) {
        [request startSynchronous];
        [responses addObject:[request response]];
    }
    [self schemaTestResponses:responses];
}

- (void)testSchemaAsync
{
    [self prepare:@selector(testSchemaAsync)];
    NSArray *requests = [self schemaTestRequests];
    __block NSMutableArray *successes = [[NSMutableArray alloc] initWithCapacity:[requests count]];
    __block NSMutableArray *failures = [[NSMutableArray alloc] initWithCapacity:[requests count]];
    for (NSUInteger index=0; index<[requests count]; index++) {
        ShotgunRequest *request = [requests objectAtIndex:index];
        [request setCompletionBlock:^{
            @synchronized(self) {
                [successes addObject:[NSNumber numberWithInt:index]];
                if ([successes count] == [requests count])
                    [self notify:kGHUnitWaitStatusSuccess forSelector:@selector(testSchemaAsync)];
            }
        }];
        [request setFailedBlock:^{
            @synchronized(self) {
                [failures addObject:[NSNumber numberWithInt:index]];
                [self notify:kGHUnitWaitStatusFailure forSelector:@selector(testSchemaAsync)];
            }
        }];
        [request startAsynchronous];
    }
    [self waitForStatus:kGHUnitWaitStatusSuccess timeout:10.0];
    GHAssertTrue([successes count] == [requests count], @"Success count not equal to the number of requests: %@ of %d", successes, [requests count]);
    GHAssertTrue([failures count] == 0, @"Failure count is non-zero: %@", failures);
    NSMutableArray *responses = [NSMutableArray arrayWithCapacity:[requests count]];
    for (ShotgunRequest *request in requests) {
        id response = [request response];
        [responses addObject:response ? response : [NSNull null]];
    }
    [self schemaTestResponses:responses];
    [failures release];
    [successes release];
}

@end